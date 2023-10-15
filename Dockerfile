# Use a lightweight Node.js base image
FROM node:18-bullseye-slim AS base

# Set the working directory in the container
WORKDIR /app

# Install required system packages
RUN apt-get update && apt-get install -y openssl

# Install npm globally
RUN npm install -g npm

# Copy your project files to the container
COPY . .

# Create a builder image
FROM base AS builder

# Install additional system packages (if needed)
RUN apt-get install -y git

# Set the working directory
WORKDIR /app

# Install project dependencies using npm
RUN npm install

# Build your project (replace with your build command)
RUN npm run build

# Create a runner image
FROM base AS runner

# Set the working directory
WORKDIR /app

# Copy built assets from the builder stage
COPY --from=builder /app/apps/${SCOPE}/.next/standalone ./
COPY --from=builder /app/apps/${SCOPE}/.next/static ./apps/${SCOPE}/.next/static

# Copy public assets
COPY --from=builder /app/apps/${SCOPE}/public ./apps/${SCOPE}/public

# Copy runtime environment dependencies
COPY --from=builder /app/node_modules/.npm/chalk@4.1.2/node_modules/chalk ./node_modules/chalk
COPY --from=builder /app/node_modules/.npm/chalk@4.1.2/node_modules/ansi-styles ./node_modules/ansi-styles
COPY --from=builder /app/node_modules/.npm/chalk@4.1.2/node_modules/supports-color ./node_modules/supports-color
COPY --from=builder /app/node_modules/.npm/has-flag@4.0.0/node_modules/has-flag ./node_modules/has-flag
COPY --from=builder /app/node_modules/.npm/next-runtime-env@1.6.2/node_modules/next-runtime-env/build ./node_modules/next-runtime-env/build

# Copy Prisma and generate the schema
COPY ./packages/prisma/postgresql ./packages/prisma/postgresql
COPY --from=builder /app/node_modules/.npm/@prisma+client@5.0.0_prisma@5.0.0/node_modules/@prisma/client ./node_modules/@prisma/client
COPY --from=builder /app/node_modules/.npm/@prisma+engines@5.0.0/node_modules/@prisma/engines ./node_modules/@prisma/engines
COPY --from=builder /app/node_modules/.npm/prisma@5.0.0/node_modules/prisma ./node_modules/prisma
COPY --from=builder /app/node_modules/.bin/prisma ./node_modules/.bin/prisma

# Copy your entrypoint script
COPY scripts/${SCOPE}-entrypoint.sh ./

# Make the entrypoint script executable
RUN chmod +x ./${SCOPE}-entrypoint.sh

# Set the container's entrypoint command
ENTRYPOINT ./${SCOPE}-entrypoint.sh

# Expose the port your application is listening on
EXPOSE 3000

# Set an environment variable for the port
ENV PORT=3000
