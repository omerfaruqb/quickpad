# =========================================
# Stage 1: Development - Node.js Server
# =========================================
ARG NODE_VERSION=22-alpine

# Use a lightweight Node.js image for development
FROM node:${NODE_VERSION} AS dev

# Set environment variable to indicate development mode
ENV NODE_ENV=development

# Set the working directory inside the container
WORKDIR /usr/src/app

# Copy package-related files first to leverage Docker's caching mechanism
COPY package.json package-lock.json ./

# Install project dependencies with caching
RUN --mount=type=cache,target=/root/.npm npm ci --include=dev

# Copy the rest of the application source code into the container
COPY . .

# Change ownership of the application directory to the node user
RUN chown -R node:node /usr/src/app

# Switch to the node user
USER node

# Expose the port used by the Express server
EXPOSE 5030

# Use nodemon for development with hot reload
CMD ["npm", "run", "dev"]

