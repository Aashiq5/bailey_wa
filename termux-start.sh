#!/bin/bash
# Bailey WA - Termux Auto-Start Script

cd ~/bailey_wa/server

# Pull latest changes
git fetch origin
git reset --hard origin/master

# Install dependencies if needed
npm install --silent 2>/dev/null

# Start the server
echo "🚀 Starting Bailey WA..."
node src/index.js
