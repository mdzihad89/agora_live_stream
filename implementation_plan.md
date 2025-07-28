# Implementation Plan for Missing Features

This document outlines the steps to implement the missing features in the Agora Live Stream application, based on the PRD.

## 1. Real-Time Viewer Count

### Objective

Ensure the viewer count for each live stream updates in real-time as users join and leave.

### Steps

1.  **Update Firestore Methods:**
    *   In `lib/resources/firestore_methods.dart`, create a new function `updateViewers` that:
        *   Takes `channelId` and `uid` as arguments.
        *   Adds a document to the `viewers` subcollection for the specified `channelId`.
        *   Removes the document when the user leaves the stream.
    *   Modify the `updateViewCount` function to increment or decrement the `viewers` field in the `liveStreams` collection.

2.  **Integrate with Broadcast Screen:**
    *   In `lib/screens/broadcast_screen.dart`, call the `updateViewers` function when a user joins or leaves the stream.
    *   Use a `StreamBuilder` to listen for changes in the `viewers` subcollection and update the UI in real-time.

## 2. Viewer List for Broadcaster

### Objective

Display a real-time list of viewers to the broadcaster during a live stream.

### Steps

1.  **Create a Viewer List Widget:**
    *   Create a new widget in `lib/widgets/viewer_list.dart`.
    *   This widget will use a `StreamBuilder` to listen for changes in the `viewers` subcollection.
    *   Display the list of viewers using a `ListView.builder`.

2.  **Integrate with Broadcast Screen:**
    *   In `lib/screens/broadcast_screen.dart`, add the `ViewerList` widget below the video player.
    *   Use a conditional statement to ensure the list is only visible to the broadcaster.

## 3. Testing and Validation

### Objective

Ensure the new features are working correctly and are free of bugs.

### Steps

1.  **Manual Testing:**
    *   Start a live stream and have multiple users join and leave.
    *   Verify that the viewer count updates correctly in real-time.
    *   Confirm that the broadcaster can see the list of viewers and that it updates as expected.

2.  **Automated Testing (Optional):**
    *   Write unit tests for the `firestore_methods.dart` functions.
    *   Write widget tests for the `ViewerList` widget.
