# Morphed Backend

Backend API server for the Morphed AI photo editor iOS app. This server proxies image editing requests to Google Gemini AI.

## Setup

1. **Install dependencies:**
```bash
npm install
```

2. **Create `.env` file:**
```bash
cp .env.example .env
```

3. **Add your Gemini API key:**
Edit `.env` and replace `<<<EDIT_THIS>>>` with your actual Gemini API key:
```
GEMINI_API_KEY=your_actual_api_key_here
PORT=3000
NODE_ENV=development
```

You can get a Gemini API key from: https://makersuite.google.com/app/apikey

## Running

**Start the server:**
```bash
npm start
```

**Development mode (with auto-reload):**
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
  "imageBase64": "<base64 encoded jpeg>",
  "mimeType": "image/jpeg"
}
```

**Response (Success):**
```json
{
  "editedImageBase64": "<base64 encoded jpeg>",
  "mimeType": "image/jpeg"
}
```

**Response (Error):**
```json
{
  "error": {
    "code": "BAD_REQUEST" | "MODEL_ERROR" | "INTERNAL",
    "message": "Error description",
    "details": "Additional error details"
  }
}
```

### GET /health

Health check endpoint.

**Response:**
```json
{
  "status": "ok",
  "timestamp": "2024-01-01T00:00:00.000Z"
}
```

## Testing with curl

```bash
# First, encode an image to base64
IMAGE_BASE64=$(base64 -i path/to/your/image.jpg)

# Send edit request
curl -X POST http://localhost:3000/edit \
  -H "Content-Type: application/json" \
  -d "{
    \"mode\": \"max\",
    \"imageBase64\": \"$IMAGE_BASE64\",
    \"mimeType\": \"image/jpeg\"
  }"
```

## iOS App Configuration

- **For iOS Simulator:** The app uses `http://localhost:3000` by default
- **For Physical Device:** 
  1. Find your computer's LAN IP address (e.g., `192.168.1.100`)
  2. Open the app's Settings screen
  3. Update the Base URL to `http://YOUR_IP:3000`
  4. Save

## Error Codes

- `BAD_REQUEST`: Invalid request parameters or validation failure
- `MODEL_ERROR`: The AI model did not return a valid image
- `INTERNAL`: Server error or configuration issue

## Notes

- Maximum image size: 6MB (decoded)
- Request timeout: 120 seconds
- The backend uses Google Gemini 1.5 Flash model
- CORS is enabled for all origins (adjust for production)
- All requests are logged with a unique request ID
