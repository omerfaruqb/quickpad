/**
 * Cloud Function to process analytics data
 * HTTP trigger for generating note statistics
 */

const { MongoClient } = require('mongodb');

exports.processAnalytics = async (req, res) => {
  const mongoUrl = process.env.MONGODB_URL;
  
  if (!mongoUrl) {
    return res.status(500).json({ error: 'MongoDB URL not configured' });
  }

  const client = new MongoClient(mongoUrl);
  
  try {
    await client.connect();
    const db = client.db('quickpad');
    const notes = db.collection('notes');
    const users = db.collection('users');
    
    // Calculate statistics
    const totalNotes = await notes.countDocuments();
    const totalUsers = await users.countDocuments();
    const notesWithPassword = await notes.countDocuments({ password_hash: { $exists: true, $ne: null } });
    const notesWithoutPassword = totalNotes - notesWithPassword;
    
    // Get notes created in last 24 hours
    const yesterday = new Date();
    yesterday.setDate(yesterday.getDate() - 1);
    const recentNotes = await notes.countDocuments({ created_at: { $gte: yesterday } });
    
    // Average note length
    const avgLengthResult = await notes.aggregate([
      { $group: { _id: null, avgLength: { $avg: { $strLenCP: "$content" } } } }
    ]).toArray();
    const avgNoteLength = avgLengthResult[0]?.avgLength || 0;
    
    const analytics = {
      totalNotes,
      totalUsers,
      notesWithPassword,
      notesWithoutPassword,
      recentNotes24h: recentNotes,
      averageNoteLength: Math.round(avgNoteLength),
      timestamp: new Date().toISOString()
    };
    
    res.status(200).json(analytics);
  } catch (error) {
    console.error('Analytics processing failed:', error);
    res.status(500).json({ error: error.message });
  } finally {
    await client.close();
  }
};

