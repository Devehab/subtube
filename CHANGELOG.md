# Changelog

## v1.1.1 (2025-03-22)

### 🐛 Bug Fixes

- **Mobile Copy Functionality**: Fixed an issue where the "Copy Arabic Text" and "Copy English Text" buttons weren't working on mobile browsers, particularly Google Chrome
- **Cross-Browser Compatibility**: Enhanced clipboard operations to work consistently across different browsers and platforms

### 🔧 Technical Changes

- Implemented a special modal popup for mobile devices with a dedicated copy button
- Added fallback mechanisms when the standard Clipboard API isn't available
- Applied cross-browser detection to provide the best copy experience based on the device and browser
- Maintained backward compatibility with existing functionality

### 📱 User Experience Improvements

- Improved copy experience on mobile devices with clear instructions
- Added success messages to confirm when text has been copied
- Provided graceful fallbacks with manual copy instructions when automatic copying fails

## v1.1.0 (Previous Release)

- Added "Copy English Text" and "Copy Arabic Text" buttons for instant subtitle access
- Enhanced display of subtitle availability with language indicators
- Added auto-detection for original vs. auto-generated subtitles
