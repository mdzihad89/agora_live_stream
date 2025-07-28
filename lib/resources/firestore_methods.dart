
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/livestream.dart';
import '../providers/user_provider.dart';
import '../utils/utils.dart';

class FirestoreMethods {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> startLiveStream(BuildContext context, String title) async {
    final user = Provider.of<UserProvider>(context, listen: false);
    String channelId = '';
    try {
      if (title.isNotEmpty) {
        if (!((await _firestore
                .collection('livestream')
                .doc('${user.user.uid}${user.user.username}')
                .get())
            .exists)) {
          channelId = '${user.user.uid}${user.user.username}';

          LiveStream liveStream = LiveStream(
            title: title,
            uid: user.user.uid,
            username: user.user.username,
            viewers: 0,
            channelId: channelId,
            startedAt: DateTime.now(),
          );

          _firestore
              .collection('livestream')
              .doc(channelId)
              .set(liveStream.toMap());
        } else {
          showSnackBar(
              context, 'Two Livestreams cannot start at the same time.');
        }
      } else {
        showSnackBar(context, 'Please enter all the fields');
      }
    } on FirebaseException catch (e) {
      showSnackBar(context, e.message!);
    }
    return channelId;
  }


  Future<void> joinChannel(BuildContext context, String channelId) async {
    final user = Provider.of<UserProvider>(context, listen: false);
    try {
      await updateViewCount(channelId, true);
      await _firestore
          .collection('livestream')
          .doc(channelId)
          .collection('viewers')
          .doc(user.user.uid)
          .set({
        'username': user.user.username,
        'uid': user.user.uid,
        'joinedAt': DateTime.now(),
      });
    } on FirebaseException catch (e) {
      showSnackBar(context, e.message!);
    }
  }

  Future<void> leaveChannel(BuildContext context, String channelId) async {
    final user = Provider.of<UserProvider>(context, listen: false);
    try {
      await updateViewCount(channelId, false);
      await _firestore
          .collection('livestream')
          .doc(channelId)
          .collection('viewers')
          .doc(user.user.uid)
          .delete();
    } on FirebaseException catch (e) {
      showSnackBar(context, e.message!);
    }
  }

  Stream<dynamic> getLiveStream(String channelId) {
    return _firestore.collection('livestream').doc(channelId).snapshots();
  }

  Stream<dynamic> getViewers(String channelId) {
    return _firestore
        .collection('livestream')
        .doc(channelId)
        .collection('viewers')
        .snapshots();
  }

  Future<void> updateViewCount(String id, bool isIncrease) async {
    try {
      await _firestore.collection('livestream').doc(id).update({
        'viewers': FieldValue.increment(isIncrease ? 1 : -1),
      });
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> endLiveStream(String channelId) async {
    try {
      QuerySnapshot snap = await _firestore
          .collection('livestream')
          .doc(channelId)
          .collection('comments')
          .get();

      for (int i = 0; i < snap.docs.length; i++) {
        await _firestore
            .collection('livestream')
            .doc(channelId)
            .collection('comments')
            .doc(
              ((snap.docs[i].data()! as dynamic)['commentId']),
            )
            .delete();
      }

      QuerySnapshot viewersSnap = await _firestore
          .collection('livestream')
          .doc(channelId)
          .collection('viewers')
          .get();

      for (int i = 0; i < viewersSnap.docs.length; i++) {
        await _firestore
            .collection('livestream')
            .doc(channelId)
            .collection('viewers')
            .doc(viewersSnap.docs[i].id)
            .delete();
      }

      // Delete access requests when stream ends
      QuerySnapshot accessRequestsSnap = await _firestore
          .collection('livestream')
          .doc(channelId)
          .collection('accessRequests')
          .get();

      for (int i = 0; i < accessRequestsSnap.docs.length; i++) {
        await _firestore
            .collection('livestream')
            .doc(channelId)
            .collection('accessRequests')
            .doc(accessRequestsSnap.docs[i].id)
            .delete();
      }

      await _firestore.collection('livestream').doc(channelId).delete();
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> sendAccessRequest(
      BuildContext context, String channelId, String requesterUid, String requesterUsername) async {
    try {
      await _firestore
          .collection('livestream')
          .doc(channelId)
          .collection('accessRequests')
          .doc(requesterUid)
          .set({
        'uid': requesterUid,
        'username': requesterUsername,
        'status': 'pending',
        'timestamp': DateTime.now(),
      });
    } on FirebaseException catch (e) {
      showSnackBar(context, e.message!);
    }
  }

  Future<void> updateAccessRequestStatus(
      String channelId, String requesterUid, String status) async {
    try {
      await _firestore
          .collection('livestream')
          .doc(channelId)
          .collection('accessRequests')
          .doc(requesterUid)
          .update({
        'status': status,
      });
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Stream<QuerySnapshot> streamAccessRequests(String channelId) {
    return _firestore
        .collection('livestream')
        .doc(channelId)
        .collection('accessRequests')
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  Stream<DocumentSnapshot> streamMyAccessRequest(String channelId, String requesterUid) {
    return _firestore
        .collection('livestream')
        .doc(channelId)
        .collection('accessRequests')
        .doc(requesterUid)
        .snapshots();
  }
}
