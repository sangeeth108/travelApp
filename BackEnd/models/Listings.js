const mongoose = require('mongoose');

const ListingSchema = new mongoose.Schema({
  name: {
    type: String,
    required: true,
  },
  location: {
    latitude: {
      type: Number,
      required: true,
    },
    longitude: {
      type: Number,
      required: true,
    },
  },
  description: {
    type: String,
    required: true,
  },
  price: {
    type: Number, // Price per night
    required: true,
  },
  rooms: {
    type: Number, // Total number of rooms
    required: true,
  },
  amenities: {
    type: [String], // List of amenities (e.g., WiFi, Pool)
    default: [],
  },
  owner: {
    type: String,
    required: true, // Owner email or user ID
  },
  dateAdded: {
    type: Date,
    default: Date.now,
  },
});

module.exports = mongoose.model('Listing', ListingSchema);
