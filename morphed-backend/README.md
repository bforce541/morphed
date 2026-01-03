# Morphed Backend

Backend API server for the Morphed AI photo editor iOS app.

## Setup

1. Install dependencies:
```bash
npm install
```

2. Create a `.env` file from the example:
```bash
cp .env.example .env
```

3. Add your Gemini API key to `.env`:
```
GEMINI_API_KEY=your_actual_api_key_here
PORT=3000
```

## Running

Start the server:
```bash
npm start
```

For development with auto-reload:
```bash
npm run dev
```

The server will run on `http://localhost:3000` by default.

## API Endpoints

### POST /edit

Processes an image with AI editing based on the selected mode.

**Request:**
```json
{
  "mode": "max" | "clean",
  "imageBase64": "<base64 encoded image>",
  "mimeType": "image/jpeg"
}
```

**Response:**
```json
{
  "editedImageBase64": "<base64 encoded edited image>",
  "mimeType": "image/jpeg"
}
```

**Error Response:**
```json
{
  "error": "Error message"
}
```

## iOS App Configuration

- For iOS Simulator: Use `http://localhost:3000`
- For physical device: Use your computer's LAN IP address (e.g., `http://192.168.1.100:3000`)
  - You may need to configure App Transport Security (ATS) exceptions in Info.plist for HTTP connections

## Notes

- Maximum image size: 10MB
- The backend uses Google Gemini 1.5 Flash model for image editing
- CORS is enabled for all origins (adjust for production)

