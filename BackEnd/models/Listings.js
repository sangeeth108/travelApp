const mongoose = require('mongoose');

const ListingSchema = new mongoose.Schema({
  name: {
    type: String,
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
  type: {
    type: String,
    enum: ['restaurant', 'resort'], // Add other types if necessary
    required: true,
  },
  owner: {
    type: String,
  },
  dateAdded: {
    type: Date,
    default: Date.now,
  },

});

module.exports = mongoose.model('Listing', ListingSchema);
