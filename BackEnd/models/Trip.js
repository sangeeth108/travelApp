const mongoose = require('mongoose');

const TripSchema = new mongoose.Schema({
  tripName: {
    type: String,
    required: true,
  },
  startLocation: {
    latitude: {
      type: Number,
      required: true,
    },
    longitude: {
      type: Number,
      required: true,
    },
  },
  destination: {
    latitude: {
      type: Number,
      required: true,
    },
    longitude: {
      type: Number,
      required: true,
    },
  },
  startDate: {
    type: Date,
    required: true,
  },
  endDate: {
    type: Date,
    required: true,
  },
  createdBy: {
    type: String,
    required: true,
  },
  dateCreated: {
    type: Date,
    default: Date.now,
  },
  participants: [{
    type: String,
    required: true,
  }],
});

module.exports = mongoose.model('Trip', TripSchema);
