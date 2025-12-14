/**
 * Cloud Function to cleanup expired notes
 * Triggered by Cloud Scheduler (cron job)
 */

const { MongoClient } = require('mongodb');

exports.cleanupExpiredNotes = async (req, res) => {
  const mongoUrl = process.env.MONGODB_URL;
  
  if (!mongoUrl) {
    console.error('MONGODB_URL environment variable not set');
    return res.status(500).json({ error: 'MongoDB URL not configured' });
  }

  const client = new MongoClient(mongoUrl);
  
  try {
    await client.connect();
    console.log('Connected to MongoDB');
    
    const db = client.db('quickpad');
    const notes = db.collection('notes');
    
    const now = new Date();
    const result = await notes.deleteMany({
      expires_at: { $lt: now }
    });
    
    console.log(`Cleaned up ${result.deletedCount} expired notes`);
    
    res.status(200).json({ 
      success: true, 
      deletedCount: result.deletedCount,
      timestamp: now.toISOString()
    });
  } catch (error) {
    console.error('Cleanup failed:', error);
    res.status(500).json({ 
      error: error.message,
      timestamp: new Date().toISOString()
    });
  } finally {
    await client.close();
  }
};

