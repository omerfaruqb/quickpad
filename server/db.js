import mongoose from "mongoose";

async function connectDB() {
    try {
        const mongoUrl = process.env.MONGODB_URL;
        if (!mongoUrl) {
            throw new Error('MONGODB_URL environment variable is required');
        }
        await mongoose.connect(mongoUrl);
        console.log('✅ DB connected...');
    } catch (error) {
        console.error('❌ DB connection failed:', error.message);
        process.exit(1);
    }
}

export default connectDB;
