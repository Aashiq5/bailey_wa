const express = require('express');
const router = express.Router();

// Get connection status
router.get('/status', (req, res) => {
  const whatsapp = req.app.get('whatsapp');
  res.json({
    connected: whatsapp.isConnected(),
    qr: whatsapp.getQR()
  });
});

// Get all contacts
router.get('/contacts', (req, res) => {
  const whatsapp = req.app.get('whatsapp');
  if (!whatsapp.isConnected()) {
    return res.status(503).json({ error: 'Not connected to WhatsApp' });
  }
  res.json(whatsapp.getContacts());
});

// Get all groups
router.get('/groups', (req, res) => {
  const whatsapp = req.app.get('whatsapp');
  if (!whatsapp.isConnected()) {
    return res.status(503).json({ error: 'Not connected to WhatsApp' });
  }
  res.json(whatsapp.getGroups());
});

// Get group info
router.get('/groups/:id', async (req, res) => {
  const whatsapp = req.app.get('whatsapp');
  if (!whatsapp.isConnected()) {
    return res.status(503).json({ error: 'Not connected to WhatsApp' });
  }
  
  try {
    const info = await whatsapp.getGroupInfo(req.params.id);
    res.json(info);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get messages
router.get('/messages', (req, res) => {
  const whatsapp = req.app.get('whatsapp');
  const limit = parseInt(req.query.limit) || 50;
  res.json(whatsapp.getMessages(limit));
});

// Send message to single recipient
router.post('/send', async (req, res) => {
  const whatsapp = req.app.get('whatsapp');
  const { to, message } = req.body;

  if (!to || !message) {
    return res.status(400).json({ error: 'Missing "to" or "message" field' });
  }

  if (!whatsapp.isConnected()) {
    return res.status(503).json({ error: 'Not connected to WhatsApp' });
  }

  try {
    const result = await whatsapp.sendMessage(to, message);
    res.json(result);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Send bulk messages
router.post('/send-bulk', async (req, res) => {
  const whatsapp = req.app.get('whatsapp');
  const { recipients, message, delay } = req.body;

  if (!recipients || !Array.isArray(recipients) || !message) {
    return res.status(400).json({ 
      error: 'Missing "recipients" array or "message" field' 
    });
  }

  if (!whatsapp.isConnected()) {
    return res.status(503).json({ error: 'Not connected to WhatsApp' });
  }

  try {
    const results = await whatsapp.sendBulkMessages(
      recipients, 
      message, 
      delay || 2000
    );
    res.json({ results });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Logout
router.post('/logout', async (req, res) => {
  const whatsapp = req.app.get('whatsapp');
  try {
    await whatsapp.logout();
    res.json({ success: true, message: 'Logged out successfully' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Trigger manual message check
router.post('/check-messages', async (req, res) => {
  const whatsapp = req.app.get('whatsapp');
  const io = req.app.get('io');
  
  if (!whatsapp.isConnected()) {
    return res.status(503).json({ error: 'Not connected to WhatsApp' });
  }

  const unread = await whatsapp.getUnreadMessages();
  io.emit('manual-check', { 
    timestamp: new Date().toISOString(),
    unreadCount: unread.length,
    messages: unread
  });
  
  res.json({ 
    success: true, 
    unreadCount: unread.length,
    messages: unread 
  });
});

module.exports = router;
