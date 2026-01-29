import SOS from '../models/sos.model.js';
import User from '../models/User.model.js';
import { sendPush } from '../utils/sns.js';

/**
 * CREATE SOS
 * POST /sos
 */
export const createSOS = async (req, res) => {
  try {
    const {
      sendToCloseFriends,
      sendToNearby,
      message,
      location,
      radiusKm = 2,
    } = req.body;

    // Prevent multiple active SOS from same user
    const existing = await SOS.findOne({
      userId: req.user._id,
      status: 'active',
    });

    if (existing) {
      return res.status(400).json({
        message: 'An SOS is already active',
        sosId: existing._id,
      });
    }

    const sos = await SOS.create({
      userId: req.user._id,
      message,
      sendToCloseFriends,
      sendToNearby,
      radiusKm,
      location: location
        ? {
            type: 'Point',
            coordinates: [location.lng, location.lat],
          }
        : undefined,
    });

    /* --------------------------------
       NEARBY USERS (2km GEO QUERY)
    --------------------------------- */
    let nearbyUsers = [];

    if (sendToNearby && location) {
      nearbyUsers = await User.find({
        _id: { $ne: req.user._id },
        location: {
          $near: {
            $geometry: {
              type: 'Point',
              coordinates: [location.lng, location.lat],
            },
            $maxDistance: radiusKm * 1000,
          },
        },
      }).select('awsPushEndpointArn');
    }

    /* --------------------------------
       PUSH NOTIFICATIONS (AWS SNS)
    --------------------------------- */
    for (const user of nearbyUsers) {
      if (!user.awsPushEndpointArn) continue;

      await sendPush(user.awsPushEndpointArn, {
        title: 'Emergency SOS Nearby',
        body: 'Someone nearby needs immediate help',
        data: {
          sosId: sos._id.toString(),
          type: 'SOS',
        },
      });
    }

    return res.status(201).json({
      sosId: sos._id,
      nearbyCount: nearbyUsers.length,
    });
  } catch (error) {
    console.error('CREATE SOS ERROR:', error);
    return res.status(500).json({ message: 'Failed to create SOS' });
  }
};

/**
 * GET SOS (Owner / Admin)
 * GET /sos/:id
 */
export const getSOS = async (req, res) => {
  try {
    const sos = await SOS.findById(req.params.id).populate(
      'userId',
      'username name avatar'
    );

    if (!sos) {
      return res.status(404).json({ message: 'SOS not found' });
    }

    // Only owner or admin/helper should see
    if (
      sos.userId._id.toString() !== req.user._id.toString()
    ) {
      return res.status(403).json({ message: 'Access denied' });
    }

    return res.json(sos);
  } catch (error) {
    return res.status(500).json({ message: 'Failed to fetch SOS' });
  }
};

/**
 * UPDATE SOS LOCATION
 * PUT /sos/:id/location
 */
export const updateSOSLocation = async (req, res) => {
  try {
    const { lat, lng } = req.body;

    if (!lat || !lng) {
      return res.status(400).json({ message: 'Invalid location data' });
    }

    const sos = await SOS.findOne({
      _id: req.params.id,
      userId: req.user._id,
      status: 'active',
    });

    if (!sos) {
      return res.status(404).json({ message: 'Active SOS not found' });
    }

    sos.location = {
      type: 'Point',
      coordinates: [lng, lat],
    };

    await sos.save();
    return res.json({ success: true });
  } catch (error) {
    return res.status(500).json({ message: 'Failed to update location' });
  }
};

/**
 * CANCEL SOS (OWNER)
 * PUT /sos/:id/cancel
 */
export const cancelSOS = async (req, res) => {
  try {
    const sos = await SOS.findOne({
      _id: req.params.id,
      userId: req.user._id,
      status: 'active',
    });

    if (!sos) {
      return res.status(404).json({ message: 'SOS not found or already closed' });
    }

    sos.status = 'cancelled';
    await sos.save();

    return res.json({ success: true });
  } catch (error) {
    return res.status(500).json({ message: 'Failed to cancel SOS' });
  }
};

/**
 * RESOLVE SOS (HELPER / ADMIN)
 * PUT /sos/:id/resolve
 */
export const resolveSOS = async (req, res) => {
  try {
    const sos = await SOS.findById(req.params.id);

    if (!sos) {
      return res.status(404).json({ message: 'SOS not found' });
    }

    if (sos.status !== 'active') {
      return res.status(400).json({ message: 'SOS already closed' });
    }

    sos.status = 'resolved';
    sos.resolvedBy = req.user._id;
    sos.resolvedAt = new Date();

    await sos.save();

    return res.json({ success: true });
  } catch (error) {
    return res.status(500).json({ message: 'Failed to resolve SOS' });
  }
};
