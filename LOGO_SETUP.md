# Logo Setup Instructions

## Adding the App Logo

1. Open Xcode and select the `Morphed` project
2. Navigate to `Morphed/Assets.xcassets`
3. Right-click in the Assets catalog and select "New Image Set"
4. Name it `AppLogo`
5. Drag your logo image (the squareish app icon from the center of the provided image) into the 1x, 2x, and 3x slots
6. The logo should be square (recommended: 1024x1024px for best quality)

## Logo Usage

The logo is referenced in:
- `LoginView.swift` - Main login screen
- `PaywallView.swift` - Premium subscription screen

If the logo image is not found, the app will show a placeholder. Make sure to add the image asset before building.

