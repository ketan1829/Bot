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

# Create a non-root user for running the app with a specific user ID (1000)
RUN useradd -m -u 1000 nextjs

# Set environment variables
ENV NODE_ENV=production

# Change the ownership of the /app directory to the nextjs user
RUN chown -R nextjs:nextjs /app

# Switch to the nextjs user
USER nextjs

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
