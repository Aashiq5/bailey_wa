# Bailey WA - WhatsApp Automation

A complete WhatsApp automation solution using **Baileys** (Node.js WhatsApp Web API) with a Flutter Android WebView wrapper.

## Features

- ✅ **List Contacts** - View all WhatsApp contacts
- ✅ **List Groups** - View all groups and participants
- ✅ **Send Messages** - Send to individuals or bulk send
- ✅ **Receive Messages** - Real-time message notifications
- ✅ **Hourly Message Check** - Automatic hourly polling
- ✅ **QR Code Login** - Scan to connect WhatsApp

## Architecture

```
bailey_wa/
├── server/                 # Node.js Baileys server
│   ├── src/
│   │   ├── index.js       # Express + Socket.IO server
│   │   ├── services/
│   │   │   └── whatsapp.js # Baileys WhatsApp service
│   │   └── routes/
│   │       └── api.js     # REST API endpoints
│   └── public/
│       └── index.html     # Web UI
│
└── lib/                    # Flutter Android app
    └── main.dart          # WebView wrapper
```

## Quick Start

### 1. Start the Node.js Server

```bash
cd server
npm install
npm start
```

The server will start at `http://localhost:3000`

### 2. Connect WhatsApp

1. Open `http://localhost:3000` in your browser
2. Scan the QR code with WhatsApp (Settings > Linked Devices)
3. Wait for connection

### 3. Use the Android App (Optional)

1. Get your computer's IP address
2. Run Flutter app:
   ```bash
   cd ..
   flutter pub get
   flutter run
   ```
3. Enter server URL (e.g., `http://192.168.1.100:3000`)

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/status` | Connection status |
| GET | `/api/contacts` | List all contacts |
| GET | `/api/groups` | List all groups |
| GET | `/api/groups/:id` | Get group info |
| GET | `/api/messages` | Get recent messages |
| POST | `/api/send` | Send single message |
| POST | `/api/send-bulk` | Send to multiple recipients |
| POST | `/api/check-messages` | Manual message check |
| POST | `/api/logout` | Disconnect WhatsApp |

### Send Message Example

```bash
curl -X POST http://localhost:3000/api/send \
  -H "Content-Type: application/json" \
  -d '{"to": "+1234567890", "message": "Hello!"}'
```

### Bulk Send Example

```bash
curl -X POST http://localhost:3000/api/send-bulk \
  -H "Content-Type: application/json" \
  -d '{
    "recipients": ["+1234567890", "+0987654321"],
    "message": "Hello everyone!",
    "delay": 2000
  }'
```

## Socket.IO Events

The server emits real-time events via Socket.IO:

| Event | Description |
|-------|-------------|
| `status` | Connection status update |
| `qr` | New QR code for scanning |
| `new-message` | Incoming message |
| `contacts-updated` | Contacts list updated |
| `groups-loaded` | Groups list loaded |
| `hourly-check` | Hourly check results |

## Configuration

### Hourly Check Schedule

The server automatically checks for new messages every hour. To modify, edit `server/src/index.js`:

```javascript
// Current: Every hour at minute 0
cron.schedule('0 * * * *', async () => { ... });

// Every 30 minutes
cron.schedule('*/30 * * * *', async () => { ... });
```

## Disclaimer

⚠️ **Important**: This project uses Baileys which is not affiliated with WhatsApp. Use responsibly and respect WhatsApp's Terms of Service. Do not use for spam or automated bulk messaging.

## License

MIT
