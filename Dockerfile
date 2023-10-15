# Use the official Node.js 18 image
FROM node:18-slim

# Set the working directory to /app
WORKDIR /app

# Add ARG for the SCOPE, which can be passed during CapRover app creation
ARG SCOPE
ENV SCOPE=${SCOPE}

# Update package lists and install required packages
RUN apt-get update -qy && \
    apt-get install -qy --no-install-recommends \
        openssl && \
    apt-get autoremove -yq && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install pnpm globally
RUN npm install -g pnpm

# Create a non-root user for running the app for improved security
RUN groupadd -r nextjs && useradd -r -g nextjs nextjs
USER nextjs

# Set environment variables
ENV NODE_ENV=production

# Copy package.json and package-lock.json to the container
COPY package*.json ./

# Install dependencies using pnpm
RUN pnpm install

# Copy your application source code to the container
COPY . .

# Build your application
RUN pnpm turbo run build --filter=${SCOPE}

# Expose the port your app will run on
EXPOSE 3000

# Start your application using the command from your CapRover procfile
CMD ["pnpm", "start"]
