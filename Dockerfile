# ---------- Stage 1: build the static site ----------

# Base image for the build stage: pinned Node.js on Alpine, named "builder" so stage 2 can copy from it
FROM node:22-alpine AS builder

# Set /app as the working directory for all following instructions
WORKDIR /app

# Copy only package.json and package-lock.json first so the npm ci layer stays cached until dependencies change
COPY package*.json ./

# Install the exact dependency versions from package-lock.json (includes Parcel)
RUN npm ci

# Copy the HTML pages into the build container (changes often, so it comes after npm ci)
COPY src/ ./src/

# Copy the shared stylesheet into the build container
COPY styles/ ./styles/

# Run the Parcel build script, which generates the static site in /app/dist
RUN npm run build

# ---------- Stage 2: serve with Nginx ----------

# Base image for the final runtime: pinned Nginx on Alpine, with no Node.js or node_modules
FROM nginx:1.27-alpine

# Copy only the built static files from the builder stage into Nginx's web root
COPY --from=builder /app/dist /usr/share/nginx/html

# Document that the container listens on port 80
EXPOSE 80

# Start Nginx in the foreground so the container keeps running
CMD ["nginx", "-g", "daemon off;"]