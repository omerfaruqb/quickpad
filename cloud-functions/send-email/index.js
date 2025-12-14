/**
 * Cloud Function to send welcome emails to new users
 * Triggered by Pub/Sub when a user signs up
 */

const { MongoClient } = require('mongodb');

exports.sendWelcomeEmail = async (pubSubEvent, context) => {
  const pubsubMessage = pubSubEvent.data;
  const userData = JSON.parse(Buffer.from(pubsubMessage, 'base64').toString());
  
  console.log('Processing welcome email for user:', userData.email);
  
  // In a real implementation, you would integrate with SendGrid, Mailgun, etc.
  // For this project, we'll just log the action
  
  try {
    // Simulate email sending
    console.log(`Sending welcome email to ${userData.email} for user ${userData.username}`);
    
    // You can integrate with SendGrid, Mailgun, or Gmail API here
    // Example with SendGrid:
    // const sgMail = require('@sendgrid/mail');
    // sgMail.setApiKey(process.env.SENDGRID_API_KEY);
    // await sgMail.send({
    //   to: userData.email,
    //   from: 'noreply@quickpad.com',
    //   subject: 'Welcome to Quickpad!',
    //   text: `Welcome ${userData.username}!`
    // });
    
    return { success: true, message: `Welcome email processed for ${userData.email}` };
  } catch (error) {
    console.error('Error sending welcome email:', error);
    throw error;
  }
};

