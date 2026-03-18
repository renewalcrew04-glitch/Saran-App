import express from 'express';
import { adminProtect } from '../middleware/admin.middleware.js';
import SOS from '../models/sos.model.js';

const router = express.Router();

router.get('/', adminProtect, async (req, res) => {
  const list = await SOS.find({ status: 'active' })
    .select('-location')
    .populate('userId', 'username name')
    .lean();

  res.json(list);
});

router.put('/:id/resolve', adminProtect, async (req, res) => {
  const sos = await SOS.findById(req.params.id);
  if (!sos) return res.status(404).json({ message: 'Not found' });

  sos.status = 'resolved';
  await sos.save();

  res.json({ success: true });
});

export default router;
