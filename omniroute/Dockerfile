FROM node:22-alpine

WORKDIR /app

# Install omniroutr globally
RUN npm install -g omniroute

# Default port (change if Omniroute uses a different port)
EXPOSE 20128

# Start Omniroute
CMD ["omniroute"]
