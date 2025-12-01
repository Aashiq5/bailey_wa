#!/bin/bash

# Bailey WA - Termux Setup Script
# Run this script if you're having npm install issues

echo "🔧 Fixing npm configuration..."

# Clear ALL npm config
rm -rf ~/.npm
rm -rf ~/.npmrc
npm config delete registry 2>/dev/null
npm config delete _auth 2>/dev/null
npm config delete _authToken 2>/dev/null
npm config delete //registry.npmjs.org/:_authToken 2>/dev/null

# Set fresh config
npm config set registry https://registry.npmjs.org/

echo "✅ npm config cleaned"

# Verify config
echo "📋 Current npm config:"
npm config list

# Navigate to server directory
cd ~/bailey_wa/server 2>/dev/null || cd "$(dirname "$0")"

echo "🗑️ Removing old node_modules..."
rm -rf node_modules package-lock.json

echo "📦 Installing dependencies..."
npm install --prefer-offline=false

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Setup complete!"
    echo "🚀 Run 'npm start' to start the server"
    echo "🌐 Then open http://localhost:3000 in your browser"
else
    echo ""
    echo "❌ Installation failed. Try:"
    echo "   1. Switch to mobile data (WiFi may be blocking npm)"
    echo "   2. Run: pkg install yarn && yarn install"
fi
