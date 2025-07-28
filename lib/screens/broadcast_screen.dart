import 'dart:convert';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../config/appId.dart' as config;
import '../providers/user_provider.dart';
import '../resources/firestore_methods.dart';
import '../responsive/resonsive_layout.dart';
import '../utils/utils.dart';
import '../widgets/custom_button.dart';
import 'home_screen.dart';

class BroadcastScreen extends StatefulWidget {
  final bool isBroadcaster;
  final String channelId;
  const BroadcastScreen({
    Key? key,
    required this.isBroadcaster,
    required this.channelId,
  }) : super(key: key);

  @override
  State<BroadcastScreen> createState() => _BroadcastScreenState();
}

class _BroadcastScreenState extends State<BroadcastScreen> {
  RtcEngine? _engine; // Made nullable
  List<int> remoteUid = [];
  bool switchCamera = true;
  bool isMuted = false;
  bool _isRequestPending = false;
  bool _hasAccess = false;
  bool _isLoading = true; // Added loading state

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      if (widget.isBroadcaster) {
        await _initializeBroadcaster();
      }
      if (!widget.isBroadcaster) {
        _listenForAccessRequestStatus();
      }
      setState(() {
        _isLoading = false; // Set loading to false after initialization attempts
      });
    });
  }

  Future<void> _initializeBroadcaster() async {
    debugPrint('Initializing Broadcaster...');
    await _initEngine();
    await _engine?.setClientRole(role: ClientRoleType.clientRoleBroadcaster); // Null-aware
    debugPrint('Broadcaster role set. Joining channel...');
    await _joinChannel();
    debugPrint('Broadcaster joined channel.');
  }

  @override
  void dispose() {
    _engine?.leaveChannel(); // Null-aware
    _engine?.release(); // Null-aware
    super.dispose();
  }

  Future<void> _initEngine() async {
    _engine = createAgoraRtcEngine();
    await _engine!.initialize(RtcEngineContext( // Use ! for non-null assertion after assignment
      appId: config.appId,
    ));
    _addListeners();
    await _engine!.enableVideo(); // Use !
    await _engine!.startPreview(); // Use !
  }

  String baseUrl = "https://token-server-hrve.onrender.com";

  String? token;

  Future<void> getToken() async {
    final res = await http.get(
      Uri.parse(
          '$baseUrl/rtc/${widget.channelId}/publisher/userAccount/${Provider
              .of<UserProvider>(context, listen: false)
              .user
              .uid}/'),
    );

    if (res.statusCode == 200) {
      setState(() {
        token = res.body;
        token = jsonDecode(token!)['rtcToken'];
      });
    } else {
      debugPrint('Failed to fetch the token');
    }
  }

  void _addListeners() {
    _engine!.registerEventHandler(RtcEngineEventHandler(
      onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
        debugPrint('joinChannelSuccess $connection $elapsed');
      },
      onUserJoined: (connection, uid, elapsed) {
        debugPrint('userJoined $uid $elapsed');
        setState(() {
          remoteUid.add(uid);
        });
      },
      onUserOffline: (connection, uid, reason) {
        debugPrint('userOffline $uid $reason');
        setState(() {
          remoteUid.removeWhere((element) => element == uid);
        });
      },
      onLeaveChannel: (connection, stats) {
        debugPrint('leaveChannel $stats');
        setState(() {
          remoteUid.clear();
        });
      },
      onTokenPrivilegeWillExpire: (connection, token) async {
        await getToken();
        await _engine!.renewToken(token);
      },
    ));
  }

  Future _joinChannel() async {
    await getToken();
    if (token != null) {
      if (defaultTargetPlatform == TargetPlatform.android) {
        await [Permission.microphone, Permission.camera].request();
      }
      await _engine!.joinChannelWithUserAccount(
        token: token!,
        channelId: widget.channelId,
        userAccount: Provider
            .of<UserProvider>(context, listen: false)
            .user
            .uid,
      );
      if (!widget.isBroadcaster) {
        await FirestoreMethods().joinChannel(context, widget.channelId);
      }
    }
  }


  void _sendAccessRequest() async {
    final user = Provider
        .of<UserProvider>(context, listen: false)
        .user;
    setState(() {
      _isRequestPending = true;
    });
    await FirestoreMethods().sendAccessRequest(
        context, widget.channelId, user.uid, user.username);
  }

  void _listenForAccessRequestStatus() {
    final user = Provider
        .of<UserProvider>(context, listen: false)
        .user;
    FirestoreMethods()
        .streamMyAccessRequest(widget.channelId, user.uid)
        .listen((snapshot) async {
      if (snapshot.exists) {
        final Map<String, dynamic>? data = snapshot.data() as Map<String, dynamic>?;
        final status = data?['status'] ?? '';
        if (status == 'accepted' && !_hasAccess) {
          setState(() {
            _hasAccess = true;
            _isRequestPending = false;
          });
          await _initEngine(); // Initialize Agora
          await _engine!.setClientRole(role: ClientRoleType.clientRoleAudience);
          await _joinChannel(); // Join channel after engine is initialized
          Future.delayed(const Duration(seconds: 5), () {
            debugPrint('Delayed check: remoteUid after 5 seconds: $remoteUid');
          });
          showSnackBar(
              context, 'Access granted! You can now watch the stream.');
        } else if (status == 'denied' && _isRequestPending) {
          setState(() {
            _isRequestPending = false;
          });
          showSnackBar(context, 'Your request to watch the stream was denied.');
        }
      }
    });
  }

  void _switchCamera() {
    _engine!.switchCamera().then((value) {
      setState(() {
        switchCamera = !switchCamera;
      });
    }).catchError((err) {
      debugPrint('switchCamera $err');
    });
  }

  void onToggleMute() async {
    setState(() {
      isMuted = !isMuted;
    });
    await _engine!.muteLocalAudioStream(isMuted);
  }

  _leaveChannel() async {
    await _engine!.leaveChannel();
    if ('${Provider
        .of<UserProvider>(context, listen: false)
        .user
        .uid}${Provider
        .of<UserProvider>(context, listen: false)
        .user
        .username}' ==
        widget.channelId) {
      await FirestoreMethods().endLiveStream(widget.channelId);
    } else {
      await FirestoreMethods().leaveChannel(context, widget.channelId);
    }
    Navigator.pushReplacementNamed(context, HomeScreen.routeName);
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider
        .of<UserProvider>(context)
        .user;

    return WillPopScope(
      onWillPop: () async {
        await _leaveChannel();
        return Future.value(true);
      },
      child: Scaffold(
        bottomNavigationBar: widget.isBroadcaster
            ? Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18.0),
          child: CustomButton(
            text: 'End Stream',
            onTap: _leaveChannel,
          ),
        )
            : null,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: _isLoading || _engine == null
                ? const Center(
              child: CircularProgressIndicator(),
            )
                : ResponsiveLatout(
              desktopBody: Row(
                children: [
                  // keep it empty i don't need for desktop
                ],
              ),
              mobileBody: Column(
                children: [
                  if (widget.isBroadcaster || _hasAccess)
                    _renderVideo(user)
                  else
                    if (_isRequestPending)
                      const Center(
                        child: Text('Requesting access...'),
                      )
                    else
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('You need permission to watch this stream.'),
                          CustomButton(
                            text: 'Request to Watch',
                            onTap: _sendAccessRequest,
                          ),
                        ],
                      ),
                  if (widget.isBroadcaster)
                    Column(
                      children: [
                        InkWell(
                          onTap: _switchCamera,
                          child: const Text('Switch Camera'),
                        ),
                        InkWell(
                          onTap: onToggleMute,
                          child: Text(isMuted ? 'Unmute' : 'Mute'),
                        ),
                      ],
                    ),
                  if (widget.isBroadcaster) _viewerList(),
                  if (widget.isBroadcaster) _accessRequestList(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  _renderVideo(user) {
    debugPrint('Inside _renderVideo. isBroadcaster: ${widget.isBroadcaster}, _hasAccess: $_hasAccess, remoteUid: $remoteUid');
    if (_engine == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: widget.isBroadcaster
          ? AgoraVideoView(
        controller: VideoViewController(
          rtcEngine: _engine!,
          canvas: const VideoCanvas(uid: 0), // local user
        ),
      )
          : _hasAccess && remoteUid.isNotEmpty
          ? Builder(
              builder: (context) {
                debugPrint('Attempting to render remote video. _hasAccess: $_hasAccess, remoteUid.isNotEmpty: ${remoteUid.isNotEmpty}, remoteUid: $remoteUid');
                return AgoraVideoView(
                  controller: VideoViewController.remote(
                    rtcEngine: _engine!,
                    canvas: VideoCanvas(uid: remoteUid[0]),
                    connection: RtcConnection(channelId: widget.channelId),
                  ),
                );
              }
            )
          : Container(),
    );
  }

  Widget _viewerList() {
    return StreamBuilder<dynamic>(
      stream: FirestoreMethods().getViewers(widget.channelId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting ||
            !snapshot.hasData) {
          return const CircularProgressIndicator();
        }

        final viewers = snapshot.data.docs;

        return Expanded(
          child: ListView.builder(
            itemCount: viewers.length,
            itemBuilder: (context, index) {
              final viewer = viewers[index];
              return ListTile(
                title: Text("${viewer['username']} is watching ",
                    style: TextStyle(color: Colors.black)),
              );
            },
          ),
        );
      },
    );
  }

  Widget _accessRequestList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirestoreMethods().streamAccessRequests(widget.channelId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting ||
            !snapshot.hasData) {
          return const SizedBox.shrink(); // Don't show anything if no requests
        }

        final requests = snapshot.data!.docs;

        if (requests.isEmpty) {
          return const SizedBox.shrink();
        }

        return Expanded(
          child: Column(
            children: [
              const Text(
                'Pending Access Requests',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    final request = requests[index];
                    return ListTile(
                      title: Text(request['username']),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.check, color: Colors.green),
                            onPressed: () =>
                                FirestoreMethods()
                                    .updateAccessRequestStatus(
                                    widget.channelId, request['uid'],
                                    'accepted'),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: () =>
                                FirestoreMethods()
                                    .updateAccessRequestStatus(
                                    widget.channelId, request['uid'], 'denied'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}