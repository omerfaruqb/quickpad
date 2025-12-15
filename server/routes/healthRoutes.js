import express from 'express';

const router = express.Router();

router.get('/health', (req, res) => {
  res.status(200).json({ 
    status: 'healthy', 
    timestamp: new Date().toISOString(),
    service: 'quickpad-backend'
  });
});

export default router;

