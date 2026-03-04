# تريفيا مصر (Egypt Trivia)

A beautiful Egyptian-themed trivia game in Arabic.

## Prerequisites

- Flutter SDK 3.x or later
- Android Studio / Xcode (for mobile builds)
- Chrome (for web)

## Setup

1. **Install Flutter** (if not already installed):
   ```bash
   # macOS
   brew install flutter

   # Or download from https://flutter.dev
   ```

2. **Navigate to project directory**:
   ```bash
   cd "/Users/essam/ai-product-studio/projects/Egypt Trivia/egypt_trivia"
   ```

3. **Install dependencies**:
   ```bash
   flutter pub get
   ```

## Running the App

### Android
```bash
flutter run -d android
```

### iOS
```bash
flutter run -d ios
```

### Web
```bash
flutter run -d chrome
```

## Building for Release

### Android APK
```bash
flutter build apk --release
```

### Android App Bundle (for Play Store)
```bash
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

### Web
```bash
flutter build web --release
```

## Project Structure

```
lib/
├── main.dart              # App entry point
├── app.dart               # MaterialApp configuration
├── core/
│   ├── theme/            # Egyptian theme colors & styles
│   └── constants/        # Game config & categories
├── data/
│   ├── models/           # Question, GameResult, ScoreEntry
│   └── datasources/      # Questions loader
├── domain/
│   └── services/         # Game logic & scoring
├── presentation/
│   ├── providers/        # Riverpod state management
│   └── screens/          # Home, Game, Score screens
└── routing/              # GoRouter configuration

assets/
└── data/
    └── questions.json    # 50 Egyptian history questions
```

## Features (Slice 0)

- ✅ Egyptian-themed UI with RTL Arabic
- ✅ 50 questions in تاريخ مصر category
- ✅ 10 questions per round
- ✅ 15-second timer per question
- ✅ Streak multiplier scoring
- ✅ 3 lives system
- ✅ 50/50 lifeline
- ✅ Score summary screen
- ✅ Play again functionality

## Tech Stack

- **Flutter 3.x** - Cross-platform framework
- **Riverpod** - State management
- **Hive** - Local storage
- **GoRouter** - Navigation
- **Google Fonts** - Cairo Arabic font

## Color Palette

| Color | Hex | Usage |
|-------|-----|-------|
| Gold | `#D4AF37` | Primary, buttons, accents |
| Sand | `#F5E6C8` | Background |
| Papyrus | `#E8D4A8` | Cards |
| Success | `#2E8B57` | Correct answers |
| Error | `#C04000` | Wrong answers |

## Next Steps (Future Slices)

- [ ] AdMob integration
- [ ] All 7 categories
- [ ] 300+ questions
- [ ] Daily challenge
- [ ] iOS build
- [ ] Web PWA
- [ ] Sound effects

## License

MIT License
