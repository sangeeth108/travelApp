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


router.post('/api/listings', auth, async (req, res) => {
  const { name, type, location, description, pricePerNight, amenities } = req.body;

  try {
    const user = await User.findById(req.user.id);
    if (user.role !== 'partner') {
      return res.status(403).json({ message: 'Access denied. Only partners can create listings.' });
    }

    const newListing = new Listing({
      name,
      type,
      location,
      description,
      images,
      pricePerNight,
      amenities,
      partnerId: req.user.id,
    });

    await newListing.save();
    res.json(newListing);
  } catch (err) {
    res.status(500).send('Server error');
  }
});

router.put('/api/listings/:id', auth, async (req, res) => {
  const { name, type, location, description, images, pricePerNight, amenities } = req.body;

  try {
    const listing = await Listing.findById(req.params.id);

    if (!listing) return res.status(404).json({ message: 'Listing not found' });
    if (listing.partnerId.toString() !== req.user.id) {
      return res.status(403).json({ message: 'Access denied. You can only update your own listings.' });
    }

    listing.name = name;
    listing.type = type;
    listing.location = location;
    listing.description = description;
    listing.images = images;
    listing.pricePerNight = pricePerNight;
    listing.amenities = amenities;

    await listing.save();
    res.json(listing);
  } catch (err) {
    res.status(500).send('Server error');
  }
});


router.delete('/api/listings/:id', auth, async (req, res) => {
  try {
    const listing = await Listing.findById(req.params.id);

    if (!listing) return res.status(404).json({ message: 'Listing not found' });
    if (listing.partnerId.toString() !== req.user.id) {
      return res.status(403).json({ message: 'Access denied. You can only delete your own listings.' });
    }

    await listing.remove();
    res.json({ message: 'Listing removed' });
  } catch (err) {
    res.status(500).send('Server error');
  }
});


router.get('/api/listings', async (req, res) => {
  try {
    const listings = await Listing.find();
    res.json(listings);
  } catch (err) {
    res.status(500).send('Server error');
  }
});


const Booking = require('../models/Booking');

router.post('/api/bookings', auth, async (req, res) => {
  const { listingId, checkInDate, checkOutDate } = req.body;

  try {
    const listing = await Listing.findById(listingId);
    if (!listing) return res.status(404).json({ message: 'Listing not found' });

    const booking = new Booking({
      listingId,
      userId: req.user.id,
      checkInDate,
      checkOutDate,
      totalPrice: listing.pricePerNight * ((new Date(checkOutDate) - new Date(checkInDate)) / (1000 * 60 * 60 * 24)),
    });

    await booking.save();
    res.json(booking);
  } catch (err) {
    res.status(500).send('Server error');
  }
});



module.exports = router;
