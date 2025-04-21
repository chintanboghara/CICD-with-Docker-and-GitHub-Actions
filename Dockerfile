# ---- Base Stage ----
# Use a specific version for reproducibility. Slim is a good balance.
FROM node:18-slim AS base
ENV NODE_ENV=production
WORKDIR /app
# Install OS dependencies if needed (e.g., for certain native modules)
# RUN apt-get update && apt-get install -y --no-install-recommends some-package && rm -rf /var/lib/apt/lists/*

# ---- Dependencies Stage ----
# Install production dependencies using npm ci for speed and reliability
FROM base AS deps
WORKDIR /app
COPY package.json package-lock.json* ./
# Use npm ci for cleaner, faster, reproducible installs based on lock file
# Only install production dependencies
RUN npm ci --only=production --ignore-scripts
# If you have native dependencies needing build tools, you might need a more complex builder stage first

# ---- Application Stage (Final) ----
FROM base AS final
WORKDIR /app

# Create a non-root user and group
RUN addgroup --system --gid 1001 nodejs && \
    adduser --system --uid 1001 nodejs

# Copy installed production dependencies from the 'deps' stage
COPY --from=deps --chown=nodejs:nodejs /app/node_modules ./node_modules

# Copy application code
# Ensure sensitive files are excluded via .dockerignore
COPY --chown=nodejs:nodejs . .

# Optional: Add build step here if needed (e.g., for TypeScript)
# COPY --from=builder /app/dist ./dist

# Switch to the non-root user
USER nodejs

# Expose the application port
EXPOSE 5001

# Define the command to run the application
# Using node directly can sometimes be slightly more efficient than npm start
# Adjust 'server.js' to your application's entry point if different
# CMD ["node", "server.js"]
# Or stick with npm start if it does more setup:
CMD ["npm", "start"]
