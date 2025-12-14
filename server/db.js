import mongoose from "mongoose";

async function connectDB() {
    try {
        const mongoUrl = process.env.MONGODB_URL || 'mongodb://mongodb:27017/quickpad';
        await mongoose.connect(mongoUrl);
        console.log('✅ DB connected...');
    } catch (error) {
        console.error('❌ DB connection failed:', error.message);
        process.exit(1);
    }
}

export default connectDB;
