const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const User = require('../models/User');
const auth = require('../middleware/auth');
const Listing = require('../models/Listings');
const Trip = require('../models/Trip');
const WEATHER_API_KEY = '392cb59f772e4361d30eeb6807906bcd';

const axios = require('axios');
const router = express.Router();

// @route   POST /api/auth/signup
// @desc    Register user
router.post('/api/auth/signup', async (req, res) => {
  const { name, email, password, role } = req.body;
  
  try {
    let user = await User.findOne({ email });
    if (user) {
      return res.status(400).json({ message: 'User already exists' });
    }

    user = new User({ name, email, password, role });

    const salt = await bcrypt.genSalt(10);
    user.password = await bcrypt.hash(password, salt);

    await user.save();

    const payload = { user: { id: user.id, role: user.role } }; // Include role in payload

    jwt.sign(payload, process.env.JWT_SECRET, { expiresIn: '1h' }, (err, token) => {
      if (err) throw err;
      res.status(200).json({ token, user }); // Return the user object along with the token
    });
  } catch (err) {
    console.error(err); // Log the error for debugging
    res.status(500).send('Server error');
  }
});


// @route   POST /api/auth/login
// @desc    Authenticate user & get token
router.post('/api/auth/login', async (req, res) => {
  const { email, password, } = req.body;
  try {
    let user = await User.findOne({ email });
    if (!user) {
      return res.status(400).json({ message: 'Invalid credentials' });
    }

    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      return res.status(400).json({ message: 'Invalid credentials' });
    }

    const payload = { user: { id: user.id } };

    jwt.sign(payload, process.env.JWT_SECRET, { expiresIn: '1h' }, (err, token) => {
      if (err) throw err;
      res.json({ token, user }); // Include the username here
    });
  } catch (err) {
    res.status(500).send('Server error');
  }
});


// @route   GET /api/auth/user
// @desc    Get logged in user
router.get('/api/auth/user', auth, async (req, res) => {
  try {
    const user = await User.findById(req.user.id).select('-password');
    res.json(user);
  } catch (err) {
    res.status(500).send('Server error');
  }
});



// @route   POST /api/auth/logout
// @desc    Logout user (just a notification)
router.post('/api/auth/logout', auth, (req, res) => {
  // You can perform additional tasks here, like logging out the user from the server-side perspective
  res.json({ message: 'User logged out successfully' });
});


// POST /api/partners/addListing - Add a new listing
router.post('/api/partners/addListing', async (req, res) => {
  const { name, location, description, type, owner } = req.body;

  // Ensure location has both latitude and longitude
  if (!location || !location.latitude || !location.longitude) {
    return res.status(400).json({ message: 'Invalid location data' });
  }

  try {
    // Create a new listing instance
    const newListing = new Listing({
      name,
      location: {
        latitude: location.latitude,
        longitude: location.longitude
      },
      description,
      type,
      owner
    });

    // Save the listing to the database
    await newListing.save();

    // Send a success response
    res.status(200).json({ message: 'Listing added successfully!' });
  } catch (err) {
    console.error(err.message);
    res.status(500).json({ message: 'Server error' });
  }
});


// GET /api/partners/myListings - Get all listings for a specific partner
router.get('/api/partners/myListings', async (req, res) => {
  const { owner } = req.query;

  try {
    // If an owner is specified, filter by owner, otherwise get all listings
    const filter = owner ? { owner } : {}; 
    const listings = await Listing.find(filter);

    res.status(200).json(listings);
  } catch (err) {
    console.error(err.message);
    res.status(500).json({ message: 'Failed to fetch listings' });
  }
});



// DELETE /api/partners/deleteListing/:id - Delete a listing by ID
router.delete('/api/partners/deleteListing/:id', async (req, res) => {
  const { id } = req.params;

  try {
    // Find the listing by ID and delete it
    const deletedListing = await Listing.findByIdAndDelete(id);
    if (!deletedListing) {
      return res.status(404).json({ message: 'Listing not found' });
    }

    res.status(200).json({ message: 'Listing deleted successfully!' });
  } catch (err) {
    console.error(err.message);
    res.status(500).json({ message: 'Failed to delete listing' });
  }
});


// PUT /api/partners/editListing/:id - Edit a listing by ID
router.put('/api/partners/editListing/:id', async (req, res) => {
  const { id } = req.params;
  const { name, location, description, type } = req.body;

  try {
    // Find listing by ID and update it
    const updatedListing = await Listing.findByIdAndUpdate(
      id,
      { name, location, description, type },
      { new: true }
    );

    if (!updatedListing) {
      return res.status(404).json({ message: 'Listing not found' });
    }

    res.status(200).json({ message: 'Listing updated successfully!', listing: updatedListing });
  } catch (err) {
    console.error(err.message);
    res.status(500).json({ message: 'Failed to update listing' });
  }
});


//create trip
// POST /api/trips/create
router.post('/api/trips/create', async (req, res) => {
  const { trip_name, start_location, destination, start_date, end_date, created_by, participants } = req.body;

  // Ensure all required fields are provided
  if (!trip_name || !start_location || !start_location.latitude || !start_location.longitude ||
      !destination || !destination.latitude || !destination.longitude ||
      !start_date || !end_date || !created_by) {
    return res.status(400).json({ message: 'Please fill in all required fields' });
  }

  // Ensure participants are provided as an array
  if (!Array.isArray(participants) || participants.length === 0) {
    return res.status(400).json({ message: 'Please provide a list of participants.' });
  }

  try {
    // Step 1: Validate if all participants exist in the User collection
    const existingUsers = await User.find({ email: { $in: participants } });
    const existingEmails = existingUsers.map(user => user.email);
    
    // Step 2: If some participants are not found, return an error
    const invalidParticipants = participants.filter(email => !existingEmails.includes(email));
    if (invalidParticipants.length > 0) {
      return res.status(400).json({
        message: `User(s) with email(s) ${invalidParticipants.join(', ')} not found.`,
      });
    }

    // Step 3: Proceed with creating the trip
    const newTrip = new Trip({
      tripName: trip_name,
      startLocation: {
        latitude: start_location.latitude,
        longitude: start_location.longitude,
      },
      destination: {
        latitude: destination.latitude,
        longitude: destination.longitude,
      },
      startDate: new Date(start_date),
      endDate: new Date(end_date),
      createdBy: created_by,
      participants: participants, // Save participants emails
    });

    await newTrip.save();

    res.status(200).json({ message: 'Trip created successfully!', trip: newTrip });
  } catch (err) {
    console.error(err.message);
    res.status(500).json({ message: 'Server error' });
  }
});


// GET /api/trips/:tripId - Fetch a specific trip by ID


// GET /api/trips/user/:userId - Fetch all trips for a specific user
router.get('/api/trips/user', async (req, res) => {
  const { email } = req.query;
  try {
    // Fetch trips where the user is a participant or the creator
    const trips = await Trip.find({
      $or: [
        { participants: email },  // User is a participant
        { createdBy: email }       // User is the creator
      ]
    });

    res.status(200).json(trips);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
});


router.get('/api/trips/:tripId', async (req, res) => {
  const { tripId } = req.params;
  try {
    const trip = await Trip.findById(tripId);
    if (!trip) {
      return res.status(404).json({ message: 'Trip not found' });
    }
    res.status(200).json(trip);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
});


// 2. Add Participant to Trip
router.post('/api/trips/:tripId/add-participant', async (req, res) => {
  const { participant } = req.body;

  // Check if the participant email is provided
  if (!participant) {
    return res.status(400).json({ message: 'Participant email is required.' });
  }

  try {
    // Validate if the participant exists in the User collection
    const user = await User.findOne({ email: participant });
    if (!user) {
      return res.status(400).json({ message: 'User with this email does not exist.' });
    }

    // Find the trip and add the participant if they are not already added
    const trip = await Trip.findById(req.params.tripId);
    if (!trip) {
      return res.status(404).json({ message: 'Trip not found.' });
    }

    if (trip.participants.includes(participant)) {
      return res.status(400).json({ message: 'Participant already added to this trip.' });
    }

    trip.participants.push(participant);
    await trip.save();

    res.status(200).json({ message: 'Participant added successfully!', trip });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error while adding participant.' });
  }
});



router.post('/weather', async (req, res) => {
  const { latitude, longitude, startDate, endDate } = req.body;

  try {
    // OpenWeatherMap One Call API
    const response = await axios.get('https://api.openweathermap.org/data/2.5/weather', {
      params: {
        lat: latitude,
        lon: longitude,
        appid: WEATHER_API_KEY,
        exclude: 'minutely,hourly,alerts',
        units: 'metric',
      },
    });

    const weatherData = response.data;
    const dailyWeather = weatherData.daily.filter((day) => {
      const timestamp = day.dt * 1000;
      const date = new Date(timestamp).toISOString().split('T')[0];
      return date >= startDate && date <= endDate;
    });

    res.json({ dailyWeather });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Failed to fetch weather data' });
  }
});

router.post('/api/addListing', async (req, res) => {
  try {
    const { name, location, description, price, rooms, amenities, owner } = req.body;

    // Validate required fields
    if (!name || !location || !location.latitude || !location.longitude || !description || !price || !rooms || !owner) {
      return res.status(400).json({ error: 'Please provide all required fields.' });
    }

    // Create a new listing
    const newListing = new Listing({
      name,
      location: {
        latitude: location.latitude,
        longitude: location.longitude,
      },
      description,
      price,
      rooms,
      amenities,
      owner,
    });

    // Save the listing to the database
    const savedListing = await newListing.save();

    res.status(200).json({ message: 'Listing added successfully.', listing: savedListing });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'An error occurred while adding the listing.' });
  }
});




module.exports = router;
