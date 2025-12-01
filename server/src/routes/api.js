const express = require('express');
const router = express.Router();
const multer = require('multer');
const path = require('path');
const fs = require('fs');

// Configure multer for file uploads
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    const uploadDir = path.join(__dirname, '../../uploads');
    if (!fs.existsSync(uploadDir)) {
      fs.mkdirSync(uploadDir, { recursive: true });
    }
    cb(null, uploadDir);
  },
  filename: (req, file, cb) => {
    cb(null, `${Date.now()}-${file.originalname}`);
  }
});
const upload = multer({ storage, limits: { fileSize: 50 * 1024 * 1024 } }); // 50MB limit

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

// Request message history sync
router.post('/sync-history', async (req, res) => {
  const whatsapp = req.app.get('whatsapp');

  if (!whatsapp.isConnected()) {
    return res.status(503).json({ error: 'Not connected to WhatsApp' });
  }

  try {
    const result = await whatsapp.requestHistorySync();
    res.json(result);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Send message to single recipient (contact or group)
router.post('/send', async (req, res) => {
  const whatsapp = req.app.get('whatsapp');
  const { to, message, isGroup } = req.body;

  if (!to || !message) {
    return res.status(400).json({ error: 'Missing "to" or "message" field' });
  }

  if (!whatsapp.isConnected()) {
    return res.status(503).json({ error: 'Not connected to WhatsApp' });
  }

  try {
    let result;
    if (isGroup || to.endsWith('@g.us')) {
      result = await whatsapp.sendGroupMessage(to, message);
    } else {
      result = await whatsapp.sendMessage(to, message);
    }
    res.json(result);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Send message to group
router.post('/send-group', async (req, res) => {
  const whatsapp = req.app.get('whatsapp');
  const { groupId, message } = req.body;

  if (!groupId || !message) {
    return res.status(400).json({ error: 'Missing "groupId" or "message" field' });
  }

  if (!whatsapp.isConnected()) {
    return res.status(503).json({ error: 'Not connected to WhatsApp' });
  }

  try {
    const result = await whatsapp.sendGroupMessage(groupId, message);
    res.json(result);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Send media (image, video, document, audio)
router.post('/send-media', upload.single('file'), async (req, res) => {
  const whatsapp = req.app.get('whatsapp');
  const { to, mediaType, caption, isGroup } = req.body;

  if (!to) {
    return res.status(400).json({ error: 'Missing "to" field' });
  }
  
  if (!req.file) {
    return res.status(400).json({ error: 'No file uploaded' });
  }

  if (!whatsapp.isConnected()) {
    return res.status(503).json({ error: 'Not connected to WhatsApp' });
  }

  try {
    console.log('Sending media:', req.file.path, 'type:', mediaType);
    
    // Check if file exists
    if (!fs.existsSync(req.file.path)) {
      return res.status(400).json({ error: 'Uploaded file not found' });
    }
    
    const mediaBuffer = fs.readFileSync(req.file.path);
    const type = mediaType || getMediaType(req.file.mimetype);
    
    let jid = to;
    if (!jid.includes('@')) {
      if (isGroup === 'true' || isGroup === true) {
        jid = `${to}@g.us`;
      } else {
        jid = `${to}@s.whatsapp.net`;
      }
    }

    console.log('Sending to:', jid, 'type:', type, 'size:', mediaBuffer.length);

    const result = await whatsapp.sendMedia(jid, mediaBuffer, type, {
      caption: caption || '',
      mimetype: req.file.mimetype,
      fileName: req.file.originalname
    });

    // Clean up uploaded file
    fs.unlinkSync(req.file.path);

    res.json(result);
  } catch (error) {
    console.error('Send media error:', error);
    // Clean up on error
    if (req.file && fs.existsSync(req.file.path)) {
      fs.unlinkSync(req.file.path);
    }
    res.status(500).json({ error: error.message });
  }
});

// Download media from message
router.get('/download-media/:messageId', async (req, res) => {
  const whatsapp = req.app.get('whatsapp');

  if (!whatsapp.isConnected()) {
    return res.status(503).json({ error: 'Not connected to WhatsApp' });
  }

  try {
    const result = await whatsapp.downloadMedia(req.params.messageId);
    
    // Send file as download
    res.download(result.filepath, result.filename, (err) => {
      if (err) {
        console.error('Download error:', err);
      }
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get downloaded media list
router.get('/media', (req, res) => {
  const mediaFolder = path.join(__dirname, '../../media');
  
  if (!fs.existsSync(mediaFolder)) {
    return res.json([]);
  }

  const files = fs.readdirSync(mediaFolder).map(filename => {
    const filepath = path.join(mediaFolder, filename);
    const stats = fs.statSync(filepath);
    return {
      filename,
      size: stats.size,
      created: stats.birthtime
    };
  });

  res.json(files);
});

// Helper function to determine media type
function getMediaType(mimetype) {
  if (mimetype.startsWith('image/')) return 'image';
  if (mimetype.startsWith('video/')) return 'video';
  if (mimetype.startsWith('audio/')) return 'audio';
  return 'document';
}

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

// Export messages to JSON
router.get('/export-messages', (req, res) => {
  const whatsapp = req.app.get('whatsapp');
  
  try {
    const messages = whatsapp.messages;
    const oneMonthAgo = Date.now() - (30 * 24 * 60 * 60 * 1000);
    
    // Filter last month messages
    const recentMessages = messages.filter(m => 
      new Date(m.timestamp).getTime() > oneMonthAgo
    );
    
    const exportData = {
      exportedAt: new Date().toISOString(),
      messageCount: recentMessages.length,
      messages: recentMessages
    };
    
    res.setHeader('Content-Type', 'application/json');
    res.setHeader('Content-Disposition', `attachment; filename=whatsapp-messages-${Date.now()}.json`);
    res.json(exportData);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Import messages from JSON (append only, no duplicates)
router.post('/import-messages', express.json({ limit: '50mb' }), (req, res) => {
  const whatsapp = req.app.get('whatsapp');
  const io = req.app.get('io');
  
  try {
    const { messages: importedMessages } = req.body;
    
    if (!importedMessages || !Array.isArray(importedMessages)) {
      return res.status(400).json({ error: 'Invalid import data. Expected { messages: [...] }' });
    }
    
    // Get existing message IDs to avoid duplicates
    const existingIds = new Set(whatsapp.messages.map(m => m.id));
    
    let importedCount = 0;
    let skippedCount = 0;
    
    for (const msg of importedMessages) {
      if (msg.id && !existingIds.has(msg.id)) {
        whatsapp.messages.push(msg);
        existingIds.add(msg.id);
        importedCount++;
      } else {
        skippedCount++;
      }
    }
    
    // Sort messages by timestamp (newest first)
    whatsapp.messages.sort((a, b) => 
      new Date(b.timestamp) - new Date(a.timestamp)
    );
    
    // Notify clients of new messages
    io.emit('messages-imported', { 
      importedCount, 
      skippedCount,
      totalMessages: whatsapp.messages.length 
    });
    
    res.json({ 
      success: true, 
      importedCount, 
      skippedCount,
      totalMessages: whatsapp.messages.length 
    });
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

// Trigger manual message check - get all messages from last week
router.post('/check-messages', async (req, res) => {
  const whatsapp = req.app.get('whatsapp');
  const io = req.app.get('io');
  
  if (!whatsapp.isConnected()) {
    return res.status(503).json({ error: 'Not connected to WhatsApp' });
  }

  const recentMessages = await whatsapp.getRecentMessages();
  io.emit('manual-check', { 
    timestamp: new Date().toISOString(),
    messageCount: recentMessages.length,
    messages: recentMessages
  });
  
  res.json({ 
    success: true, 
    messageCount: recentMessages.length,
    messages: recentMessages 
  });
});

module.exports = router;
