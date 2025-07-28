# Agora Live Streaming Flutter App

A live streaming mobile application built with Flutter and Agora SDK, featuring broadcaster and audience roles with admission control.

## 🎯 Features

- **Broadcaster Role**: Start live streams, control camera/mic, manage audience admission
- **Audience Role**: Request to join streams, watch live content
- **Admission Control**: Broadcasters can allow/deny audience join requests
- **Real-time Video**: Powered by Agora RTC Engine
- **Clean Architecture**: Built with BLoC pattern and domain-driven design

## 🏗 Architecture

The app follows Clean Architecture principles with BLoC for state management:

```
lib/
├── data/
│   ├── services/
│   │   ├── agora_service.dart      # Agora RTC integration
│   │   └── permission_service.dart # Camera/mic permissions
│   └── repositories/
│       └── streaming_repository.dart # Data layer abstraction
├── domain/
│   ├── entities/
│   │   ├── channel.dart            # Channel entity
│   │   └── admission_request.dart  # Admission request entity
│   └── usecases/
│       ├── start_broadcast.dart    # Start streaming use case
│       ├── send_join_request.dart  # Join request use case
│       └── handle_admission.dart   # Admission control use case
├── presentation/
│   ├── blocs/
│   │   ├── home_bloc.dart          # Home screen state management
│   │   ├── broadcast_bloc.dart     # Broadcaster state management
│   │   └── watch_bloc.dart         # Audience state management
│   ├── screens/
│   │   ├── home_screen.dart        # Main entry screen
│   │   ├── broadcast_screen.dart   # Broadcaster interface
│   │   └── watch_screen.dart       # Audience interface
│   └── widgets/
│       ├── video_controls.dart     # Reusable video controls
│       ├── request_dialog.dart     # Admission request dialog
│       └── agora_video_view.dart   # Video display widget
└── main.dart                       # App entry point
```

## 🚀 Setup Instructions

### Prerequisites

- Flutter SDK (latest stable version)
- Agora account and project
- Android Studio / VS Code
- Physical device for testing (recommended)

### 1. Clone and Install Dependencies

```bash
git clone <repository-url>
cd agora_live_stream
flutter pub get
```

### 2. Agora Setup

1. Create an account at [Agora Console](https://console.agora.io/)
2. Create a new project
3. Set the project to **Live Broadcast** mode
4. Copy your App ID
5. Update `lib/data/services/agora_service.dart`:

```dart
static const String appId = 'YOUR_AGORA_APP_ID'; // Replace with your App ID
```

### 3. Platform Configuration

#### Android
Add permissions to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS" />
```

#### iOS
Add permissions to `ios/Runner/Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>Camera access is required for video streaming</string>
<key>NSMicrophoneUsageDescription</key>
<string>Microphone access is required for audio streaming</string>
```

### 4. Run the App

```bash
flutter run
```

## 📱 Usage

### For Broadcasters

1. Enter a channel name on the home screen
2. Tap "Start Broadcasting"
3. Grant camera and microphone permissions
4. Use controls to:
   - Switch camera (front/back)
   - Mute/unmute audio
   - End stream
5. When audience requests to join, choose Allow/Deny

### For Audience

1. Enter the same channel name as the broadcaster
2. Tap "Join"
3. Wait for broadcaster approval
4. If allowed, watch the live stream
5. If denied, see access denied message

## 🔧 Development

### Adding Real Video Support

The current implementation uses placeholder video widgets. To add real Agora video:

1. Update `AgoraVideoView` to use actual Agora video rendering
2. Configure video rendering in `AgoraService`
3. Handle video stream events in the BLoCs

### Implementing Signaling

For production admission control:

1. Implement Agora signaling or data streams
2. Update `HandleAdmission` use case
3. Add real-time communication between broadcaster and audience

### Testing

Test the app on multiple devices:

1. Run broadcaster on one device
2. Run audience on another device
3. Use the same channel name
4. Test admission flow

## 📦 Dependencies

- `flutter_bloc: ^8.1.0` - State management
- `agora_rtc_engine: ^6.2.6` - Video streaming
- `permission_handler: ^11.0.0` - Permissions
- `equatable: ^2.0.5` - Value equality

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License.

## 🆘 Support

For issues and questions:
- Check the [Agora Documentation](https://docs.agora.io/)
- Review Flutter and BLoC documentation
- Open an issue in this repository
