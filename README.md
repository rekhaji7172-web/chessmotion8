# ChessMotion 🎬♟️

Professional Chess Video Editor — Alight Motion level editing for chess content creators.

## Features
- 🎬 **Multi-layer timeline** with keyframe animation (like Alight Motion)
- ♟️ **Interactive chess board** — drag & drop pieces, setup positions
- 💎 **Keyframe system** — Opacity, Scale, Rotation, Position, Effects, Skew
- 📐 **7 Easing curves** — Linear, Ease In/Out, Bounce, Elastic, Cubic
- 🎨 **Effects panel** — Brightness, Contrast, Saturation, Blur, Hue
- 🎞️ **Layer types** — Chess Board, Piece, Text, Image, Shape, Effect, Audio, Video
- 📱 **Dark theme** — Deep navy + gold chess color palette
- 💾 **Auto-save** — Projects saved with SharedPreferences
- 📤 **Export dialog** — 480p to 4K, MP4/MOV/GIF/WebM, 24/30/60fps

## Build Steps

### 1. Prerequisites
```bash
flutter --version   # Needs Flutter 3.16+
java -version       # Needs Java 17+
```

### 2. Install dependencies
```bash
cd chessmotion
flutter pub get
```

### 3. Build Debug APK
```bash
flutter build apk --debug
# APK: build/app/outputs/flutter-apk/app-debug.apk
```

### 4. Build Release APK
```bash
flutter build apk --release
# APK: build/app/outputs/flutter-apk/app-release.apk
```

### 5. Build Split APKs (smaller size)
```bash
flutter build apk --split-per-abi
```

### 6. Install on device
```bash
flutter install
# or
adb install build/app/outputs/flutter-apk/app-debug.apk
```

## Project Structure
```
lib/
├── main.dart                          # Entry point
├── theme/
│   └── app_theme.dart                 # Colors, gradients, theme
├── models/
│   ├── keyframe_model.dart            # Keyframe + EasingType
│   ├── layer_model.dart               # EditorLayer, LayerTransform, LayerEffect
│   └── project_model.dart             # ChessProject, ProjectSettings
├── providers/
│   ├── editor_provider.dart           # Editor state (ChangeNotifier)
│   └── project_provider.dart          # Projects list (SharedPreferences)
├── screens/
│   ├── splash_screen.dart             # Animated splash
│   ├── home_screen.dart               # Projects list
│   └── editor_screen.dart             # Main editor (Alight Motion style)
├── widgets/
│   ├── timeline_widget.dart           # Timeline + Playhead + Ruler
│   ├── properties_panel.dart          # Transform, Effects, Keyframes tabs
│   ├── chess_board_editor.dart        # Drag & drop chess board
│   ├── layer_panel_sheet.dart         # Layer-specific options bottom sheet
│   └── animation_curves_widget.dart   # Easing curve visualizer
└── utils/
    └── chess_painter.dart             # Custom chess board & piece painters
```

## Minimum Requirements
- Android 5.0+ (API 21)
- ~80MB storage
- 2GB RAM recommended
