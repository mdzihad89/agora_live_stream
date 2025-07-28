# Product Requirements Document: Agora Live Stream

## 1. Overview

This document outlines the product requirements for a Flutter-based live streaming application that uses Agora for video streaming and Firebase for user authentication and database management.

## 2. User Personas

- **Broadcaster:** A user who can start and end a live stream.
- **Audience:** A user who can view a live stream.

## 3. Functional Requirements

### 3.1. User Authentication

- Users can sign up for a new account using their email, a unique username, and a password.
- Users can log in to their existing account using their email and password.
- The application persists user sessions, allowing users to remain logged in.

### 3.2. Live Streaming

- Authenticated users can initiate a live stream.
- To start a stream, a user must provide a title.
- The application uses the Agora RTC (Real-Time Communication) engine for video streaming.
- Broadcasters can:
  - Switch between their device's front and back cameras.
  - Mute and unmute their microphone.
  - End the live stream.
- Audience members can:
  - View a list of active live streams.
  - Join a live stream to watch.
  - Leave a live stream.

### 3.3. Real-Time Updates

- The application displays the number of viewers for each live stream in real-time.
- When a user joins a stream, the viewer count increases.
- When a user leaves a stream, the viewer count decreases.

### 3.4. Viewer List (Live Watchers List for Broadcaster)

- When a live stream is active, the broadcaster can view a real-time list of current audience members (e.g., "Rahim is watching", "Karim is watching").
- The list updates in real-time as viewers join or leave.
- The viewer list is displayed below the video player using a ListView\.builder.

## 4. Technical Stack

- **Frontend:** Flutter
- **Video Streaming:** Agora RTC Engine
- **Authentication:** Firebase Authentication
- **Database:** Cloud Firestore
- **State Management:** Provider

## 5. Data Models

### 5.1. User

- `uid`: Unique user ID (from Firebase Auth)
- `username`: User's chosen username
- `email`: User's email address

### 5.2. LiveStream

- `title`: Title of the live stream
- `uid`: UID of the broadcaster
- `username`: Username of the broadcaster
- `viewers`: Number of current viewers
- `channelId`: Unique ID for the Agora channel
- `startedAt`: Timestamp of when the stream started

#### Subcollection: `liveStreams/{channelId}/viewers`

Each document represents a viewer currently in the stream:

```json
{
  "uid": "user123",
  "username": "Rahim",
  "joinedAt": "timestamp"
}
```

## 6. Screen Flow

1. **Onboarding Screen:** The initial screen for new users, with options to log in or sign up.
2. **Login Screen:** Allows existing users to sign in.
3. **Signup Screen:** Allows new users to create an account.
4. **Home Screen:** Displays a list of active live streams. Authenticated users can also access the "Go Live" screen from here.
5. **Go Live Screen:** A form where a user can enter a title for their live stream.
6. **Broadcast Screen:**
   - The main screen for both broadcasters and audience members.
   - Displays the live video stream and provides relevant controls based on the user's role.
   - Broadcasters see a real-time list of viewers below the video stream using a ListView\.builder.