const makeWASocket = require('@whiskeysockets/baileys').default;
const { 
  useMultiFileAuthState, 
  DisconnectReason,
  fetchLatestBaileysVersion,
  makeCacheableSignalKeyStore,
  downloadMediaMessage
} = require('@whiskeysockets/baileys');
const pino = require('pino');
const path = require('path');
const fs = require('fs');
const QRCode = require('qrcode');

class WhatsAppService {
  constructor(io) {
    this.io = io;
    this.sock = null;
    this.qrCode = null;
    this.pairingCode = null;
    this.connected = false;
    this.contacts = new Map();
    this.groups = new Map();
    this.messages = [];
    this.authFolder = path.join(__dirname, '../../auth_info');
    this.mediaFolder = path.join(__dirname, '../../media');
    this.usePairingCode = false;
    this.phoneNumber = null;
    
    // Create media folder
    if (!fs.existsSync(this.mediaFolder)) {
      fs.mkdirSync(this.mediaFolder, { recursive: true });
    }
  }

  async connect(phoneNumber = null) {
    try {
      // Ensure auth folder exists
      if (!fs.existsSync(this.authFolder)) {
        fs.mkdirSync(this.authFolder, { recursive: true });
      }

      const { state, saveCreds } = await useMultiFileAuthState(this.authFolder);
      const { version } = await fetchLatestBaileysVersion();

      // Check if we should use pairing code
      this.usePairingCode = !!phoneNumber;
      this.phoneNumber = phoneNumber;

      this.sock = makeWASocket({
        version,
        logger: pino({ level: 'silent' }),
        printQRInTerminal: !this.usePairingCode,
        auth: {
          creds: state.creds,
          keys: makeCacheableSignalKeyStore(state.keys, pino({ level: 'silent' }))
        },
        generateHighQualityLinkPreview: true
      });

      // Handle connection updates
      this.sock.ev.on('connection.update', async (update) => {
        const { connection, lastDisconnect, qr } = update;

        if (qr && !this.usePairingCode) {
          // Generate QR code as data URL
          this.qrCode = await QRCode.toDataURL(qr);
          this.io.emit('qr', this.qrCode);
          console.log('QR Code generated - scan with WhatsApp');
        }

        // Request pairing code if using phone number method
        if (qr && this.usePairingCode && this.phoneNumber && !this.pairingCode) {
          try {
            // Clean phone number (remove +, spaces, dashes)
            const cleanNumber = this.phoneNumber.replace(/[\s\-\+]/g, '');
            console.log('Requesting pairing code for:', cleanNumber);
            
            const code = await this.sock.requestPairingCode(cleanNumber);
            this.pairingCode = code;
            this.io.emit('pairing-code', code);
            console.log('Pairing code:', code);
          } catch (err) {
            console.error('Failed to get pairing code:', err.message);
            this.io.emit('pairing-error', err.message);
          }
        }

        if (connection === 'close') {
          this.connected = false;
          this.pairingCode = null;
          this.io.emit('status', { connected: false });
          
          const shouldReconnect = 
            lastDisconnect?.error?.output?.statusCode !== DisconnectReason.loggedOut;
          
          if (shouldReconnect) {
            console.log('Connection closed. Reconnecting...');
            setTimeout(() => this.connect(), 3000);
          } else {
            console.log('Logged out. Please scan QR code again.');
            // Clear auth to force new QR
            if (fs.existsSync(this.authFolder)) {
              fs.rmSync(this.authFolder, { recursive: true, force: true });
            }
            this.usePairingCode = false;
            this.phoneNumber = null;
            setTimeout(() => this.connect(), 1000);
          }
        }

        if (connection === 'open') {
          this.connected = true;
          this.qrCode = null;
          this.pairingCode = null;
          this.io.emit('status', { connected: true });
          console.log('Connected to WhatsApp!');
          
          // Load contacts and groups
          await this.loadContacts();
          await this.loadGroups();
        }
      });

      // Save credentials on update
      this.sock.ev.on('creds.update', saveCreds);

      // Handle incoming messages
      this.sock.ev.on('messages.upsert', async ({ messages, type }) => {
        if (type === 'notify') {
          for (const msg of messages) {
            if (!msg.key.fromMe) {
              const messageData = this.parseMessage(msg);
              this.messages.unshift(messageData);
              this.io.emit('new-message', messageData);
              console.log('New message from:', messageData.sender);
            }
          }
        }
      });

      // Handle contacts update
      this.sock.ev.on('contacts.update', (updates) => {
        for (const update of updates) {
          if (update.id) {
            this.contacts.set(update.id, {
              ...this.contacts.get(update.id),
              ...update
            });
          }
        }
        this.io.emit('contacts-updated', this.getContacts());
      });

    } catch (error) {
      console.error('Connection error:', error);
      setTimeout(() => this.connect(), 5000);
    }
  }

  parseMessage(msg) {
    const jid = msg.key.remoteJid;
    const isGroup = jid.endsWith('@g.us');
    
    // Get the actual sender for group messages
    let senderJid = jid;
    let senderName = msg.pushName || jid.split('@')[0];
    
    if (isGroup && msg.key.participant) {
      // For group messages, participant is the actual sender
      senderJid = msg.key.participant;
      senderName = msg.pushName || senderJid.split('@')[0];
    }
    
    // Clean up weird phone numbers (remove :XX suffix from JID)
    const cleanNumber = (num) => {
      if (!num) return '';
      return num.split('@')[0].split(':')[0];
    };
    
    let mediaInfo = null;
    const msgType = this.getMessageType(msg.message);
    
    // Store message reference for media download
    if (['image', 'video', 'audio', 'document', 'sticker'].includes(msgType)) {
      const mediaMsg = msg.message?.[`${msgType}Message`];
      mediaInfo = {
        messageId: msg.key.id,
        hasMedia: true,
        mediaType: msgType,
        mimetype: mediaMsg?.mimetype,
        filename: msg.message?.documentMessage?.fileName,
        filesize: mediaMsg?.fileLength,
        caption: mediaMsg?.caption
      };
    }
    
    // Get text content
    let textContent = msg.message?.conversation || 
               msg.message?.extendedTextMessage?.text ||
               msg.message?.imageMessage?.caption ||
               msg.message?.videoMessage?.caption ||
               '';
    
    // Get group name
    const groupInfo = isGroup ? this.groups.get(jid) : null;
    const groupName = groupInfo?.name || (isGroup ? 'Unknown Group' : null);
    
    return {
      id: msg.key.id,
      from: jid,
      sender: senderName,
      senderNumber: cleanNumber(senderJid),
      isGroup,
      groupId: isGroup ? jid : null,
      groupName: groupName,
      content: textContent,
      timestamp: new Date(msg.messageTimestamp * 1000).toISOString(),
      type: msgType,
      hasMedia: !!mediaInfo,
      mediaType: mediaInfo?.mediaType || null,
      mediaInfo: mediaInfo,
      rawMessage: msg // Store for media download
    };
  }

  getMessageType(message) {
    if (!message) return 'unknown';
    if (message.conversation || message.extendedTextMessage) return 'text';
    if (message.imageMessage) return 'image';
    if (message.videoMessage) return 'video';
    if (message.audioMessage) return 'audio';
    if (message.documentMessage) return 'document';
    if (message.stickerMessage) return 'sticker';
    return 'unknown';
  }

  async loadContacts() {
    try {
      const contacts = await this.sock.store?.contacts || {};
      for (const [id, contact] of Object.entries(contacts)) {
        this.contacts.set(id, contact);
      }
      console.log(`Loaded ${this.contacts.size} contacts`);
    } catch (error) {
      console.error('Error loading contacts:', error);
    }
  }

  async loadGroups() {
    try {
      const groups = await this.sock.groupFetchAllParticipating();
      for (const [id, group] of Object.entries(groups)) {
        this.groups.set(id, {
          id,
          name: group.subject,
          participants: group.participants,
          creation: group.creation,
          desc: group.desc
        });
      }
      console.log(`Loaded ${this.groups.size} groups`);
      this.io.emit('groups-loaded', this.getGroups());
    } catch (error) {
      console.error('Error loading groups:', error);
    }
  }

  isConnected() {
    return this.connected;
  }

  getQR() {
    return this.qrCode;
  }

  getContacts() {
    return Array.from(this.contacts.values()).map(c => ({
      id: c.id,
      name: c.name || c.notify || c.id?.split('@')[0],
      number: c.id?.split('@')[0]
    })).filter(c => c.id && !c.id.endsWith('@g.us'));
  }

  getGroups() {
    return Array.from(this.groups.values());
  }

  getMessages(limit = 50) {
    return this.messages.slice(0, limit);
  }

  async getUnreadMessages() {
    // Return messages from last hour
    const oneHourAgo = Date.now() - (60 * 60 * 1000);
    return this.messages.filter(m => 
      new Date(m.timestamp).getTime() > oneHourAgo
    );
  }

  async sendMessage(jid, message) {
    if (!this.connected) {
      throw new Error('Not connected to WhatsApp');
    }

    try {
      // Format JID if needed
      let formattedJid = jid;
      if (!jid.includes('@')) {
        // Check if it's a group ID (numeric only, typically longer)
        formattedJid = `${jid}@s.whatsapp.net`;
      }
      // Keep @g.us suffix for groups
      if (jid.endsWith('@g.us')) {
        formattedJid = jid;
      }

      await this.sock.sendMessage(formattedJid, { text: message });
      
      return {
        success: true,
        to: formattedJid,
        message,
        timestamp: new Date().toISOString()
      };
    } catch (error) {
      console.error('Error sending message:', error);
      throw error;
    }
  }

  // Send message to group by group ID
  async sendGroupMessage(groupId, message) {
    if (!this.connected) {
      throw new Error('Not connected to WhatsApp');
    }

    try {
      // Ensure group ID has correct format
      let formattedGroupId = groupId;
      if (!groupId.endsWith('@g.us')) {
        formattedGroupId = `${groupId}@g.us`;
      }

      await this.sock.sendMessage(formattedGroupId, { text: message });
      
      return {
        success: true,
        to: formattedGroupId,
        message,
        isGroup: true,
        timestamp: new Date().toISOString()
      };
    } catch (error) {
      console.error('Error sending group message:', error);
      throw error;
    }
  }

  // Send media message (image, video, document, audio)
  async sendMedia(jid, mediaBuffer, mediaType, options = {}) {
    if (!this.connected) {
      throw new Error('Not connected to WhatsApp');
    }

    try {
      let formattedJid = jid;
      if (!jid.includes('@')) {
        formattedJid = `${jid}@s.whatsapp.net`;
      }
      if (jid.endsWith('@g.us')) {
        formattedJid = jid;
      }

      let messageContent = {};
      
      switch (mediaType) {
        case 'image':
          messageContent = {
            image: mediaBuffer,
            caption: options.caption || '',
            mimetype: options.mimetype || 'image/jpeg'
          };
          break;
        case 'video':
          messageContent = {
            video: mediaBuffer,
            caption: options.caption || '',
            mimetype: options.mimetype || 'video/mp4'
          };
          break;
        case 'audio':
          messageContent = {
            audio: mediaBuffer,
            mimetype: options.mimetype || 'audio/mpeg',
            ptt: options.ptt || false // voice note
          };
          break;
        case 'document':
          messageContent = {
            document: mediaBuffer,
            fileName: options.fileName || 'file',
            mimetype: options.mimetype || 'application/octet-stream'
          };
          break;
        default:
          throw new Error('Invalid media type');
      }

      await this.sock.sendMessage(formattedJid, messageContent);
      
      return {
        success: true,
        to: formattedJid,
        mediaType,
        timestamp: new Date().toISOString()
      };
    } catch (error) {
      console.error('Error sending media:', error);
      throw error;
    }
  }

  // Download media from a message
  async downloadMedia(messageId) {
    try {
      // Find the message with this ID
      const msg = this.messages.find(m => m.id === messageId);
      if (!msg || !msg.rawMessage) {
        throw new Error('Message not found or no media');
      }

      const buffer = await downloadMediaMessage(
        msg.rawMessage,
        'buffer',
        {},
        {
          logger: pino({ level: 'silent' }),
          reuploadRequest: this.sock.updateMediaMessage
        }
      );

      // Generate filename
      const ext = this.getExtensionFromMimetype(msg.media?.mimetype);
      const filename = msg.media?.filename || `${messageId}.${ext}`;
      const filepath = path.join(this.mediaFolder, filename);

      // Save to file
      fs.writeFileSync(filepath, buffer);

      return {
        success: true,
        filename,
        filepath,
        size: buffer.length,
        mimetype: msg.media?.mimetype
      };
    } catch (error) {
      console.error('Error downloading media:', error);
      throw error;
    }
  }

  getExtensionFromMimetype(mimetype) {
    if (!mimetype) return 'bin';
    const mimeMap = {
      'image/jpeg': 'jpg',
      'image/png': 'png',
      'image/gif': 'gif',
      'image/webp': 'webp',
      'video/mp4': 'mp4',
      'video/3gpp': '3gp',
      'audio/mpeg': 'mp3',
      'audio/ogg': 'ogg',
      'audio/wav': 'wav',
      'application/pdf': 'pdf',
      'application/msword': 'doc',
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document': 'docx'
    };
    return mimeMap[mimetype] || mimetype.split('/')[1] || 'bin';
  }

  async sendBulkMessages(recipients, message, delay = 2000) {
    const results = [];
    
    for (const recipient of recipients) {
      try {
        const result = await this.sendMessage(recipient, message);
        results.push({ ...result, status: 'sent' });
      } catch (error) {
        results.push({ 
          to: recipient, 
          status: 'failed', 
          error: error.message 
        });
      }
      
      // Delay between messages
      await new Promise(resolve => setTimeout(resolve, delay));
    }
    
    return results;
  }

  async getGroupInfo(groupId) {
    try {
      const metadata = await this.sock.groupMetadata(groupId);
      return {
        id: metadata.id,
        name: metadata.subject,
        description: metadata.desc,
        participants: metadata.participants,
        creation: metadata.creation
      };
    } catch (error) {
      console.error('Error getting group info:', error);
      throw error;
    }
  }

  async logout() {
    if (this.sock) {
      await this.sock.logout();
      this.connected = false;
      this.qrCode = null;
      this.io.emit('status', { connected: false });
    }
  }
}

module.exports = WhatsAppService;
