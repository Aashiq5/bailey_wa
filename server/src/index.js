const express = require('express');
const { createServer } = require('http');
const { Server } = require('socket.io');
const path = require('path');
const cors = require('cors');
const cron = require('node-cron');

const WhatsAppService = require('./services/whatsapp');
const apiRoutes = require('./routes/api');

const app = express();
const httpServer = createServer(app);
const io = new Server(httpServer, {
  cors: {
    origin: "*",
    methods: ["GET", "POST"]
  }
});

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.static(path.join(__dirname, '../public')));

// Initialize WhatsApp Service
const whatsapp = new WhatsAppService(io);

// Make whatsapp service available to routes
app.set('whatsapp', whatsapp);
app.set('io', io);

// API Routes
app.use('/api', apiRoutes);

// Serve web app
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, '../public/index.html'));
});

// Socket.IO connection handling
io.on('connection', (socket) => {
  console.log('Client connected:', socket.id);
  
  // Send current connection status
  socket.emit('status', { 
    connected: whatsapp.isConnected(),
    qr: whatsapp.getQR()
  });

  // Handle phone number pairing request
  socket.on('request-pairing', async (phoneNumber) => {
    console.log('Pairing requested for:', phoneNumber);
    // Clear existing auth and reconnect with phone number
    const authFolder = require('path').join(__dirname, '../auth_info');
    const fs = require('fs');
    if (fs.existsSync(authFolder)) {
      fs.rmSync(authFolder, { recursive: true, force: true });
    }
    await whatsapp.connect(phoneNumber);
  });

  socket.on('disconnect', () => {
    console.log('Client disconnected:', socket.id);
  });
});

// Schedule hourly message check
cron.schedule('0 * * * *', async () => {
  console.log('Running hourly message check...');
  if (whatsapp.isConnected()) {
    const unread = await whatsapp.getUnreadMessages();
    io.emit('hourly-check', { 
      timestamp: new Date().toISOString(),
      unreadCount: unread.length,
      messages: unread
    });
  }
});

// Start server
const PORT = process.env.PORT || 3000;
httpServer.listen(PORT, () => {
  console.log(`Bailey WA Server running on http://localhost:${PORT}`);
  
  // Start WhatsApp connection
  whatsapp.connect();
});
