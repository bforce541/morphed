# Morphed MVP - Complete Runbook

## Directory Structure

```
morphed-ios/
  Morphed/
    App/
      MorphedApp.swift
    Features/
      Editor/
        EditorView.swift
        EditorViewModel.swift
        ImagePicker.swift
      Settings/
        SettingsView.swift
      Paywall/
        PaywallView.swift
    Core/
      Networking/
        APIClient.swift
      Models/
        EditRequest.swift
        EditResponse.swift
        APIError.swift
      Utils/
        ImageUtils.swift
        PhotoSaver.swift
        Haptics.swift
        ToastView.swift
    Resources/
      Info.plist
    Assets.xcassets/
  Morphed.xcodeproj/

morphed-backend/
  src/
    server.js
    geminiClient.js
    prompts.js
    validate.js
  package.json
  .env.example
  README.md
```

## 1. Backend Setup & Run

### Prerequisites
- Node.js 18+ installed
- Gemini API key from https://makersuite.google.com/app/apikey

### Setup Steps

```bash
# Navigate to backend directory
cd morphed-backend

# Install dependencies
npm install

# Create .env file from example
cp .env.example .env

# Edit .env and add your Gemini API key
# Replace <<<EDIT_THIS>>> with your actual API key
nano .env  # or use your preferred editor
```

### Running the Backend

```bash
# Development mode (with auto-reload)
npm run dev

# Production mode
npm start
```

**Expected Output:**
```
Morphed backend server running on http://localhost:3000
Environment: development
```

### Verify Backend is Running

```bash
# Test health endpoint
curl http://localhost:3000/health

# Expected response:
# {"status":"ok","timestamp":"2024-01-01T00:00:00.000Z"}
```

## 2. iOS App Setup

### Prerequisites
- Xcode 15+ installed
- iOS 16+ deployment target
- macOS with Apple Developer account (for simulator)

### Xcode Project Setup

If the project doesn't exist, create it:

1. Open Xcode
2. File → New → Project
3. Select "iOS" → "App"
4. Product Name: `Morphed`
5. Interface: `SwiftUI`
6. Language: `Swift`
7. Storage: `None`
8. Minimum Deployment: `iOS 16.0`
9. Click "Next" and save

### Add Files to Xcode Project

1. In Xcode, right-click on the `Morphed` folder in Project Navigator
2. Select "Add Files to Morphed..."
3. Navigate to the `Morphed` directory
4. Select all folders: `App`, `Features`, `Core`, `Resources`
5. Check "Create groups" (not folder references)
6. Check "Copy items if needed" (if files are outside project)
7. Click "Add"

### Verify Target Membership

1. Select each file in Project Navigator
2. In File Inspector (right panel), verify "Target Membership" has "Morphed" checked

### Build Settings Verification

1. Select project in Navigator
2. Select "Morphed" target
3. Go to "Build Settings"
4. Verify:
   - `iOS Deployment Target` = `16.0`
   - `Info.plist File` = `Morphed/Resources/Info.plist`
   - `Generate Info.plist File` = `NO`

## 3. Running the iOS App

### Simulator Setup

```bash
# List available simulators
xcrun simctl list devices available

# Boot a simulator (e.g., iPhone 15)
xcrun simctl boot "iPhone 15"

# Or open Xcode and select a simulator from the device menu
```

### Build & Run in Xcode

1. Open `Morphed.xcodeproj` in Xcode
2. Select a simulator (e.g., iPhone 15 Pro)
3. Press `Cmd + R` or click the Play button
4. Wait for build to complete
5. App launches in simulator

### Command Line Build & Run

```bash
# Build for simulator
xcodebuild -project Morphed.xcodeproj \
  -scheme Morphed \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  build

# Run on simulator
xcodebuild -project Morphed.xcodeproj \
  -scheme Morphed \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  test-without-building
```

## 4. End-to-End Morph Test

### Steps to Morph Successfully

1. **Start Backend:**
   ```bash
   cd morphed-backend
   npm run dev
   ```

2. **Launch iOS App:**
   - Open Xcode
   - Run on simulator
   - App opens with "Morphed" title

3. **Select Photo:**
   - Tap "Tap to select photo" on Original card
   - Photos picker opens
   - Select a photo from library
   - Photo appears in Original card

4. **Choose Mode:**
   - MAX or CLEAN buttons appear
   - Tap either mode (button highlights)
   - Haptic feedback occurs

5. **Morph Image:**
   - Tap "Morph" button
   - Loading overlay appears with spinner
   - Wait 10-30 seconds (depends on image size)
   - Morphed image appears in "Morphed" card
   - Success toast appears
   - Haptic feedback occurs

6. **Save to Photos:**
   - Tap "Save to Photos" button
   - Permission prompt may appear (first time)
   - Grant permission
   - Success alert appears
   - Image saved to Photos app

### Expected UI Behavior Checklist

- [ ] Dark background with gradient
- [ ] "Morphed" title at top with mode pill on right
- [ ] Original card shows placeholder when empty
- [ ] Original card shows image after selection
- [ ] Mode selector appears after image selection
- [ ] Selected mode button has gradient background
- [ ] Morph button disabled until image and mode selected
- [ ] Loading overlay appears during morph
- [ ] Morphed card appears with result
- [ ] Save button appears after morph completes
- [ ] Toast notifications appear for success/errors
- [ ] Haptic feedback on mode switch and success
- [ ] Settings button opens settings sheet
- [ ] Paywall button opens paywall sheet (stub)

## 5. Physical Device Setup

### Find Your Computer's LAN IP

**macOS:**
```bash
ifconfig | grep "inet " | grep -v 127.0.0.1
# Look for something like: 192.168.1.100
```

**Alternative:**
```bash
ipconfig getifaddr en0  # For Wi-Fi
ipconfig getifaddr en1  # For Ethernet
```

### Update Base URL in App

1. Launch app on physical device
2. Tap Settings (gear icon) in top right
3. Update "Base URL" field to: `http://YOUR_IP:3000`
   - Example: `http://192.168.1.100:3000`
4. Tap "Save"
5. Close settings
6. Try morphing an image

### Ensure Device and Computer on Same Network

- Both must be on the same Wi-Fi network
- Firewall may block connections - temporarily disable or allow port 3000

## 6. Troubleshooting

### Backend Not Reachable

**Symptoms:**
- "Network error" in app
- Loading spinner never completes
- Timeout errors

**Solutions:**

1. **Verify backend is running:**
   ```bash
   curl http://localhost:3000/health
   ```

2. **Check port is not in use:**
   ```bash
   lsof -i :3000
   ```

3. **For physical device:**
   - Verify LAN IP is correct in Settings
   - Verify device and computer on same network
   - Check firewall settings

4. **Check backend logs:**
   - Look for request IDs in console
   - Verify GEMINI_API_KEY is set correctly

### ATS (App Transport Security) Errors

**Symptoms:**
- "App Transport Security has blocked a connection"
- Network errors on simulator/device

**Solutions:**

1. **Verify Info.plist has ATS settings:**
   - Open `Morphed/Resources/Info.plist`
   - Verify `NSAppTransportSecurity` → `NSAllowsLocalNetworking` = `true`

2. **For production:**
   - Remove ATS exception
   - Use HTTPS backend
   - Or use `NSExceptionDomains` for specific domains only

### Invalid Base64 Errors

**Symptoms:**
- "Invalid base64 encoding" error
- "Failed to decode image" error

**Solutions:**

1. **Check image compression:**
   - App compresses to JPEG at 0.85 quality
   - Max dimension: 1536px
   - Verify image is valid JPEG

2. **Check backend validation:**
   - Backend rejects > 6MB images
   - Verify base64 string is not corrupted

### Gemini API Errors

**Symptoms:**
- "MODEL_ERROR" in response
- "Gemini did not return an image"

**Solutions:**

1. **Verify API key:**
   ```bash
   # In .env file
   GEMINI_API_KEY=your_actual_key_here
   ```

2. **Check API quota:**
   - Visit Google Cloud Console
   - Verify API is enabled
   - Check usage limits

3. **Test API directly:**
   ```bash
   # Use curl to test Gemini API
   # (See backend README for example)
   ```

### Build Errors

**Symptoms:**
- Xcode shows compilation errors
- Missing imports
- Type errors

**Solutions:**

1. **Clean build folder:**
   - Xcode → Product → Clean Build Folder (Shift+Cmd+K)

2. **Verify all files added to target:**
   - Select file in Navigator
   - Check File Inspector → Target Membership

3. **Verify imports:**
   - All Swift files have correct imports
   - Combine imported where @Published is used

4. **Check deployment target:**
   - Project → Target → General → Minimum Deployments = iOS 16.0

### Photo Library Permission Denied

**Symptoms:**
- "Photo library access was denied" error
- Save button doesn't work

**Solutions:**

1. **Grant permission:**
   - iOS Settings → Morphed → Photos → "Add Photos Only" or "Full Access"

2. **Verify Info.plist:**
   - `NSPhotoLibraryAddUsageDescription` is present
   - `NSPhotoLibraryUsageDescription` is present

## 7. Testing Checklist

### Backend Tests

- [ ] Server starts without errors
- [ ] Health endpoint returns 200 OK
- [ ] POST /edit accepts valid request
- [ ] POST /edit rejects invalid mode
- [ ] POST /edit rejects missing imageBase64
- [ ] POST /edit rejects oversized image
- [ ] POST /edit returns edited image
- [ ] Error responses have correct structure
- [ ] Request IDs are logged

### iOS App Tests

- [ ] App launches without crashes
- [ ] Photo picker opens and selects image
- [ ] Image displays in Original card
- [ ] Mode selector appears after image selection
- [ ] Mode selection updates UI
- [ ] Morph button enables after mode selection
- [ ] Loading overlay appears during morph
- [ ] Morphed image displays correctly
- [ ] Save button saves to Photos
- [ ] Toast notifications appear
- [ ] Error alerts display correctly
- [ ] Settings screen updates baseURL
- [ ] Paywall screen displays (stub)
- [ ] Haptic feedback works

### Integration Tests

- [ ] Simulator connects to localhost backend
- [ ] Physical device connects to LAN IP backend
- [ ] MAX mode produces enhanced image
- [ ] CLEAN mode produces subtle enhancement
- [ ] Large images are resized correctly
- [ ] Network errors are handled gracefully
- [ ] Timeout errors are handled
- [ ] Invalid responses are handled

## 8. Production Considerations

### Security

- [ ] Never commit `.env` file
- [ ] Use HTTPS in production
- [ ] Remove ATS exceptions for production
- [ ] Implement API rate limiting
- [ ] Add authentication for backend
- [ ] Validate and sanitize all inputs

### Performance

- [ ] Image compression optimizes file size
- [ ] Request timeout is appropriate (120s)
- [ ] Backend handles concurrent requests
- [ ] Error responses are fast
- [ ] UI remains responsive during processing

### User Experience

- [ ] Loading states are clear
- [ ] Error messages are helpful
- [ ] Success feedback is immediate
- [ ] Animations are smooth
- [ ] Haptics enhance interactions

## 9. Next Steps

### Immediate Improvements

1. Add real payment integration for paywall
2. Add image history/cache
3. Add share functionality
4. Add before/after comparison view
5. Add more edit modes

### Backend Enhancements

1. Add request rate limiting
2. Add user authentication
3. Add image caching
4. Add analytics/logging
5. Add webhook support

### iOS Enhancements

1. Add Core Data for local storage
2. Add image filters/preview
3. Add batch processing
4. Add social sharing
5. Add tutorial/onboarding

---

## Quick Reference

### Backend Commands
```bash
cd morphed-backend
npm install          # Install dependencies
npm start            # Run server
npm run dev          # Run with auto-reload
```

### iOS Commands
```bash
# Build
xcodebuild -project Morphed.xcodeproj -scheme Morphed -sdk iphonesimulator build

# Run
open Morphed.xcodeproj  # Then press Cmd+R in Xcode
```

### Test Endpoints
```bash
# Health check
curl http://localhost:3000/health

# Edit request (requires base64 image)
curl -X POST http://localhost:3000/edit \
  -H "Content-Type: application/json" \
  -d '{"mode":"max","imageBase64":"...","mimeType":"image/jpeg"}'
```

---

**Last Updated:** 2024-01-01
**Version:** 1.0.0

