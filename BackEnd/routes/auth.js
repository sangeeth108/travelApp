const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const User = require('../models/User');
const auth = require('../middleware/auth');
const Listing = require('../models/Listings');

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

  try {
    // Create a new listing instance
    const newListing = new Listing({
      name,
      location,
      description,
      type,
      owner,
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




module.exports = router;
