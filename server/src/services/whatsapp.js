const makeWASocket = require('@whiskeysockets/baileys').default;
const { 
  useMultiFileAuthState, 
  DisconnectReason,
  fetchLatestBaileysVersion,
  makeCacheableSignalKeyStore
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
    this.usePairingCode = false;
    this.phoneNumber = null;
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
    
    return {
      id: msg.key.id,
      from: jid,
      sender: msg.pushName || jid.split('@')[0],
      isGroup,
      content: msg.message?.conversation || 
               msg.message?.extendedTextMessage?.text ||
               msg.message?.imageMessage?.caption ||
               '[Media]',
      timestamp: new Date(msg.messageTimestamp * 1000).toISOString(),
      type: this.getMessageType(msg.message)
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
        formattedJid = `${jid}@s.whatsapp.net`;
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
