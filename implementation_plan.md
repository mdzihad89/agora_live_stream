# Implementation Plan: Audience Stream Access Request Feature

## Goal
Implement a system where audience members must request and receive permission from the broadcaster to view a live stream. Audience members will always remain in the `ClientRoleType.clientRoleAudience` role.

## Current Architecture Overview
The application is a Flutter project utilizing Firebase (Firestore, Authentication) for backend services and Agora RTC Engine for live video streaming. Key components include:
- **Authentication:** Handled by `AuthMethods` and Firebase Authentication.
- **Livestream Management:** `FirestoreMethods` interacts with Firestore to manage livestream data (starting, ending, joining, leaving).
- **UI:** Screens for onboarding, login, signup, home, feed, go-live, and broadcast.
- **State Management:** `UserProvider` manages user data.
- **Agora Integration:** `BroadcastScreen` uses `agora_rtc_engine` for video/audio.

## Affected Files & Components

1.  `lib/screens/broadcast_screen.dart`: Major modifications for both broadcaster and audience UI and logic.
2.  `lib/resources/firestore_methods.dart`: New methods for handling access requests (sending, updating status, streaming).
3.  `lib/models/livestream.dart`: Potentially a new data structure or subcollection for access requests.
4.  `lib/utils/utils.dart`: For displaying `SnackBar` messages.

## Proposed Changes

### 1. Firestore Schema Update

*   **New Subcollection:** Under each existing `livestream` document in the `livestream` collection, create a new subcollection named `accessRequests`.
*   **Access Request Document Structure:** Each document within `accessRequests` will represent a single request and contain the following fields:
    *   `uid` (String): The unique ID of the requesting user.
    *   `username` (String): The username of the requesting user.
    *   `status` (String): Current status of the request (`pending`, `accepted`, `denied`).
    *   `timestamp` (Timestamp): Server timestamp when the request was made.

### 2. `lib/resources/firestore_methods.dart` Modifications

*   **`sendAccessRequest(BuildContext context, String channelId, String requesterUid, String requesterUsername)`:**
    *   **Purpose:** To send a new access request from an audience member to the broadcaster.
    *   **Action:** Adds a new document to the `livestream/{channelId}/accessRequests` subcollection with `status: 'pending'`.
*   **`updateAccessRequestStatus(String channelId, String requesterUid, String status)`:**
    *   **Purpose:** To update the status of a specific access request (e.g., from `pending` to `accepted` or `denied`).
    *   **Action:** Updates the `status` field of the corresponding document in `livestream/{channelId}/accessRequests`.
*   **`streamAccessRequests(String channelId)`:**
    *   **Purpose:** To provide a real-time stream of pending access requests for a given channel.
    *   **Action:** Returns a `Stream<QuerySnapshot>` from the `livestream/{channelId}/accessRequests` subcollection, filtered by `status: 'pending'`.
*   **`streamMyAccessRequest(String channelId, String requesterUid)`:**
    *   **Purpose:** To provide a real-time stream of the status of a specific user's access request.
    *   **Action:** Returns a `Stream<DocumentSnapshot>` for the specific document in `livestream/{channelId}/accessRequests/{requesterUid}`.

### 3. `lib/screens/broadcast_screen.dart` (Audience Side)

*   **Initial State:** When an audience member navigates to `BroadcastScreen`, they should *not* automatically join the Agora channel. Instead, they should see a UI indicating they need to request access.
*   **UI:**
    *   Add a `CustomButton` (e.g., "Request to Watch") to the audience view. This button should only be visible if `isBroadcaster` is `false` and no request has been sent or is pending.
    *   Display a `LoadingIndicator` or a message like "Requesting access..." when a request is pending.
    *   If access is denied, display a message like "Access Denied" and potentially re-enable the "Request to Watch" button.
*   **Logic (`_BroadcastScreenState`):**
    *   **`_sendAccessRequest()` method:**
        *   Call `FirestoreMethods().sendAccessRequest()` with the current user's details.
        *   Set a local state variable (e.g., `_isRequestPending = true`).
        *   Start listening to the specific access request document in Firestore using `FirestoreMethods().streamMyAccessRequest()`.
    *   **Handling Response:**
        *   If the request `status` changes to `accepted` (from the `streamMyAccessRequest` listener):
            *   Call `_engine.setClientRole(role: ClientRoleType.clientRoleAudience)` (if not already set).
            *   Call `_joinChannel()` to start receiving the stream.
            *   Hide the "Request to Watch" button and display the stream.
            *   Display a success `SnackBar` using `showSnackBar`.
        *   If the request `status` changes to `denied` (from the `streamMyAccessRequest` listener):
            *   Display a "Request Denied" `SnackBar`.
            *   Reset `_isRequestPending = false` and re-enable the "Request to Watch" button.
    *   **Error Handling:** Implement `try-catch` for Firestore operations and show error `SnackBar` messages.

### 4. `lib/screens/broadcast_screen.dart` (Broadcaster Side)

*   **UI:**
    *   Implement a `StreamBuilder` that listens to `FirestoreMethods().streamAccessRequests(widget.channelId)`.
    *   When new `pending` requests are received:
        *   Display a clear notification to the broadcaster (e.g., a small overlay, a dedicated section in the UI, or a dialog).
        *   The notification should show the `username` of the requester.
        *   Provide two `CustomButton`s: "Allow" and "Deny".
*   **Logic (`_BroadcastScreenState`):**
    *   **`_handleAccessRequest(String requesterUid, String status)` method:**
        *   When "Allow" is tapped: Call `FirestoreMethods().updateAccessRequestStatus(widget.channelId, requesterUid, 'accepted')`.
        *   When "Deny" is tapped: Call `FirestoreMethods().updateAccessRequestStatus(widget.channelId, requesterUid, 'denied')`.
        *   Dismiss the notification/dialog after action.
    *   **Managing Multiple Requests:** Initially, focus on handling one request at a time. Consider a queue or a list for multiple pending requests in future iterations if needed.

### 5. Agora Role
*   Audience members will always remain in the `ClientRoleType.clientRoleAudience` role. The `_engine.setClientRole` method will be used to set this role *only after* their access request has been accepted by the broadcaster.
