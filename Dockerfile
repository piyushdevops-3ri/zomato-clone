# ---- Build Stage ----
FROM node:18-alpine AS builder

WORKDIR /app

# Copy package files first (leverage Docker layer cache)
COPY package*.json ./

# Install ALL dependencies (including devDeps needed for react-scripts build)
RUN npm ci

# Copy source code
COPY . .

# Build the React app for production
RUN npm run build

# ---- Production Stage ----
FROM node:18-alpine

WORKDIR /app

# Install only 'serve' to serve the static build
RUN npm install -g serve

# Copy only the built output from builder stage
COPY --from=builder /app/build ./build

# Expose port
EXPOSE 3000

# Serve the built React app
CMD ["serve", "-s", "build", "-l", "3000"]
