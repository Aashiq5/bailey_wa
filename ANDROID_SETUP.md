# Running Bailey WA on Android

Since Baileys requires Node.js (which doesn't run natively on Android), here are your options:

---

## Option 1: Termux (Recommended - Easiest)

**Termux** is a Linux terminal emulator for Android that can run Node.js.

### Step 1: Install Termux
- Download from **F-Droid** (NOT Google Play Store - the Play Store version is outdated)
- Link: https://f-droid.org/packages/com.termux/

### Step 2: Setup Node.js
Open Termux and run these commands:

```bash
# Update packages
pkg update && pkg upgrade -y

# Install Node.js and Git
pkg install nodejs git -y

# Clone your project (or copy files)
cd ~
git clone https://github.com/YOUR_USERNAME/bailey_wa.git

# Or if you copied the files manually to Downloads:
# cp -r /storage/emulated/0/Download/bailey_wa ~/

# Navigate to server folder
cd bailey_wa/server

# Install dependencies
npm install

# Start the server
npm start
```

### Step 3: Access the App
- Open your Android browser (Chrome, Firefox, etc.)
- Go to: `http://localhost:3000`
- Scan QR code or use phone number to connect!

### Pro Tips for Termux:
```bash
# Keep server running in background
npm start &

# Or use tmux to keep it running when Termux closes
pkg install tmux
tmux new -s bailey
npm start
# Press Ctrl+B then D to detach
# Reattach with: tmux attach -t bailey

# Auto-start on boot (requires Termux:Boot add-on)
mkdir -p ~/.termux/boot
echo "cd ~/bailey_wa/server && npm start" > ~/.termux/boot/start-bailey.sh
chmod +x ~/.termux/boot/start-bailey.sh
```

---

## Option 2: Use a VPS/Cloud Server

Run the server on a cloud service (free options available):

### Free Hosting Options:
1. **Railway.app** - Free tier available
2. **Render.com** - Free tier with limitations
3. **Fly.io** - Free tier available
4. **Oracle Cloud** - Always free VPS

### Deploy to Railway:
1. Push code to GitHub
2. Go to railway.app
3. Create new project from GitHub repo
4. Set root directory to `server`
5. Deploy!

Your app will be available at `https://your-app.railway.app`

Then use the Flutter WebView app to connect to that URL.

---

## Option 3: Embedded Node.js (Advanced)

For a truly self-contained Android app with Node.js inside:

### Using nodejs-mobile-react-native:
- Embeds Node.js engine inside the app
- More complex setup
- Larger APK size (~30MB+)

Repository: https://github.com/nicknisi/nodejs-mobile-react-native

### Using aspect-build for bundling:
- Bundle Node.js with your app
- Requires native Android development

---

## Quick Start (Termux)

Copy this entire block and paste in Termux:

```bash
pkg update -y && pkg upgrade -y && pkg install nodejs git -y && cd ~ && git clone https://github.com/Aashiq5/bailey_wa.git && cd bailey_wa/server && npm install && echo "Setup complete! Run 'npm start' to begin" 
```

Then:
```bash
npm start
```

Open browser → `http://localhost:3000` → Login with QR or Phone Number!

---

## Get Latest Updates

To pull the latest code from GitHub in Termux:

```bash
cd ~/bailey_wa
git pull origin master
cd server
npm install
npm start
```

### If you get "commit or stash" error:

This happens when you have local changes. Use one of these solutions:

**Option A: Discard local changes and get latest (Recommended)**
```bash
cd ~/bailey_wa
git fetch origin
git reset --hard origin/master
cd server
npm install
npm start
```

**Option B: Stash your changes, pull, then restore**
```bash
cd ~/bailey_wa
git stash
git pull origin master
git stash pop
cd server
npm install
npm start
```

**Option C: Force overwrite everything (Nuclear option)**
```bash
cd ~
rm -rf bailey_wa
git clone https://github.com/Aashiq5/bailey_wa.git
cd bailey_wa/server
npm install
npm start
```

---

## Troubleshooting

### "npm install fails with E401 error"
Run the setup script:
```bash
cd ~/bailey_wa/server
chmod +x setup-termux.sh
./setup-termux.sh
```

### "Storage permission denied"
```bash
termux-setup-storage
```

### "Node not found after restart"
Node is installed per-session. Just run:
```bash
pkg install nodejs
```

### "Cannot connect to localhost"
Make sure the server is running. Check with:
```bash
curl http://localhost:3000
```

### "QR code not showing"
Baileys may need a fresh start:
```bash
rm -rf auth_info
npm start
```
