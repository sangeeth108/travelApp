const mongoose = require('mongoose');

const ListingSchema = new mongoose.Schema({
  name: {
    type: String,
    required: true,
  },
  type: {
    type: String,
    enum: ['restaurant', 'resort'],
    required: true,
  },
  location: {
    type: String,
    required: true,
  },
  description: {
    type: String,
    required: true,
  },
  images: [
    {
      type: String, // URLs or paths to images
    },
  ],
  pricePerNight: {
    type: Number, // This can be the price per night for resorts, or average meal cost for restaurants
    required: true,
  },
  partnerId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true, // This is the partner who owns the listing
  },
  amenities: [
    {
      type: String, // List of amenities (e.g., Wi-Fi, Parking, Pool)
    },
  ],
  createdAt: {
    type: Date,
    default: Date.now,
  },
});

module.exports = mongoose.model('Listing', ListingSchema);
