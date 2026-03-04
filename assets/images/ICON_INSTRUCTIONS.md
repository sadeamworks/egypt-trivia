# Icon Creation Guide for Egypt Trivia

## Option 1: Use Figma/Canva (Recommended)

### App Icon Design
1. Create a 1024x1024px canvas
2. Background color: #1a1a2e (dark blue)
3. Add a gold (#FFD700) pyramid shape in the center
4. Add the text "تريفيا" or "EG" below the pyramid
5. Export as PNG

### Splash Logo Design
1. Create a 500x500px canvas with transparent background
2. Add app name "تريفيا مصر" in gold (#FFD700)
3. Add small pyramid icon above text
4. Export as PNG

## Option 2: Quick Placeholder Icons

If you have ImageMagick installed, run these commands:

```bash
cd /Users/essam/ai-product-studio/projects/Egypt\ Trivia/egypt_trivia/assets/images

# Create app icon (1024x1024)
convert -size 1024x1024 xc:'#1a1a2e' \
  -fill '#FFD700' \
  -draw "polygon 512,200 256,700 768,700" \
  -font Arial -pointsize 80 -gravity center -annotate +0+200 'تريفيا' \
  app_icon.png

# Create foreground icon for adaptive (1024x1024 with icon centered)
convert -size 1024x1024 xc:transparent \
  -fill '#FFD700' \
  -draw "polygon 512,300 312,624 712,624" \
  app_icon_foreground.png

# Create splash logo (500x500 with transparency)
convert -size 500x500 xc:transparent \
  -fill '#FFD700' \
  -font Arial -pointsize 48 -gravity center -annotate +0+0 'تريفيا مصر' \
  splash_logo.png
```

## Option 3: Use Online Tools

1. **App Icon Generator**: https://appicon.co/
   - Upload your 1024x1024 icon
   - Download all required sizes

2. **Launcher Icons**: https://romannurik.github.io/AndroidAssetStudio/icons-launcher.html
   - Create adaptive icons for Android

3. **Splash Screen**: https://ao.gl/create-flutter-splash-screen/
   - Generate splash screens for both platforms

## After Creating Icons

1. Place files in `assets/images/`:
   - app_icon.png (1024x1024)
   - app_icon_foreground.png (1024x1024, transparent background)
   - splash_logo.png (~500x500, transparent background)

2. Generate icons:
```bash
cd /Users/essam/ai-product-studio/projects/Egypt\ Trivia/egypt_trivia
flutter pub get
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

## Required Icon Sizes (Auto-generated)

### Android
- mipmap-mdpi: 48x48
- mipmap-hdpi: 72x72
- mipmap-xhdpi: 96x96
- mipmap-xxhdpi: 144x144
- mipmap-xxxhdpi: 192x192

### iOS
- AppIcon.appiconset: 20x20 to 1024x1024 (all required sizes)
