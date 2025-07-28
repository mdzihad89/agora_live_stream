# Setup Guide: Agora Live Streaming Flutter App

This guide will walk you through setting up and testing the Agora Live Streaming Flutter app.

## 🚀 Quick Start

### 1. Prerequisites

- Flutter SDK (latest stable version)
- Agora account (free at https://console.agora.io/)
- Physical device for testing (recommended over emulator)
- Android Studio or VS Code

### 2. Agora Project Setup

1. **Create Agora Account**
   - Go to https://console.agora.io/
   - Sign up for a free account

2. **Create Project**
   - Click "Create Project"
   - Enter project name (e.g., "Live Streaming App")
   - Select "Live Broadcast" as the project type
   - Click "Create"

3. **Get App ID**
   - In your project dashboard, find the "App ID"
   - Copy the App ID (it looks like: `1234567890abcdef1234567890abcdef`)

### 3. Configure the App

1. **Update App ID**
   - Open `lib/config/agora_config.dart`
   - Replace `'YOUR_AGORA_APP_ID'` with your actual App ID:
   ```dart
   static const String appId = '1234567890abcdef1234567890abcdef';
   ```

2. **Install Dependencies**
   ```bash
   flutter pub get
   ```

### 4. Platform Setup

#### Android
The Android permissions are already configured in `android/app/src/main/AndroidManifest.xml`.

#### iOS
The iOS permissions are already configured in `ios/Runner/Info.plist`.

### 5. Run the App

```bash
flutter run
```

## 📱 Testing the App

### Test on Multiple Devices

1. **Device 1 (Broadcaster)**
   - Run the app
   - Enter channel name (e.g., "test123")
   - Tap "Start Broadcasting"
   - Grant permissions when prompted
   - You should see the broadcast screen

2. **Device 2 (Audience)**
   - Run the app
   - Enter the same channel name ("test123")
   - Tap "Join"
   - You should see "Waiting for broadcaster to admit you..."

3. **Test Admission Flow**
   - On Device 1, tap "Simulate Join Request"
   - Choose "Allow" or "Deny"
   - On Device 2, you should see the result

### Expected Behavior

- **Broadcaster**: Can see local video placeholder, control buttons work
- **Audience**: Can request to join, see waiting state, then allowed/denied
- **Permissions**: App should request camera and microphone access
- **Navigation**: Should be able to navigate between screens

## 🔧 Troubleshooting

### Common Issues

1. **"Failed to start broadcast"**
   - Check your App ID is correct
   - Ensure internet connection
   - Verify Agora project is in "Live Broadcast" mode

2. **Permissions denied**
   - Go to device settings
   - Find the app and enable camera/microphone permissions

3. **App crashes on startup**
   - Check Flutter version compatibility
   - Run `flutter doctor` to verify setup
   - Try `flutter clean && flutter pub get`

4. **Video not showing**
   - Current implementation uses placeholder video
   - Real video integration requires additional setup (see next steps)

### Debug Information

Check the console output for:
- "Agora engine initialized successfully"
- "Joined channel successfully"
- Any error messages

## 🎯 Next Steps

### 1. Real Video Integration

To add actual video streaming:

1. **Update AgoraVideoView**
   - Replace placeholder with real Agora video widget
   - Configure video rendering

2. **Test Real Streaming**
   - Use two physical devices
   - Verify video and audio transmission

### 2. Production Setup

1. **Token Authentication**
   - Enable token authentication in Agora console
   - Implement token generation
   - Update `AgoraConfig.useToken = true`

2. **Error Handling**
   - Add proper error handling for network issues
   - Implement retry mechanisms

3. **UI Polish**
   - Add loading indicators
   - Improve error messages
   - Add network status indicators

### 3. Advanced Features

1. **Signaling Implementation**
   - Add real-time admission control
   - Implement chat functionality
   - Add user management

2. **Video Quality**
   - Configure video resolution
   - Add quality selection
   - Implement bandwidth adaptation

## 📞 Support

- **Agora Documentation**: https://docs.agora.io/
- **Flutter Documentation**: https://docs.flutter.dev/
- **BLoC Documentation**: https://bloclibrary.dev/

## 🔄 Updates

Keep your dependencies updated:
```bash
flutter pub upgrade
```

Check for Agora SDK updates and migrate as needed. 