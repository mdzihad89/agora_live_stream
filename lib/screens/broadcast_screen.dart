import 'dart:convert';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../config/appId.dart' as config;
import '../providers/user_provider.dart';
import '../resources/firestore_methods.dart';
import '../responsive/resonsive_layout.dart';
import '../widgets/chat.dart';
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
  late final RtcEngine _engine;
  List<int> remoteUid = [];
  bool switchCamera = true;
  bool isMuted = false;
   bool isScreenSharing = false;
  final ChannelProfileType _channelProfileType = ChannelProfileType.channelProfileLiveBroadcasting;

  @override
  void initState() {
    super.initState();
    _initEngine();
  }

  void _initEngine() async {
    _engine = createAgoraRtcEngine();
    await _engine.initialize(RtcEngineContext(
      appId: config.appId,
    ));
    _addListeners();
    await _engine.enableVideo();
    await _engine.startPreview();

    if (widget.isBroadcaster) {
      await _engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
    } else {
      await _engine.setClientRole(role: ClientRoleType.clientRoleAudience);
    }

    _joinChannel();
  }

  String baseUrl = "https://token-server-hrve.onrender.com";

  String? token;

  Future<void> getToken() async {
    final res = await http.get(
      Uri.parse('$baseUrl/rtc/${widget.channelId}/publisher/userAccount/${Provider.of<UserProvider>(context, listen: false).user.uid}/'),
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
    _engine.registerEventHandler(
     RtcEngineEventHandler(
    onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
      debugPrint('joinChannelSuccess $connection $elapsed');
    },


   onUserJoined: ( connection, uid, elapsed) {
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

         onLeaveChannel: (connection,stats) {
      debugPrint('leaveChannel $stats');
      setState(() {
        remoteUid.clear();
      });
    },
         onTokenPrivilegeWillExpire: (connection,token) async {
      await getToken();
      await _engine.renewToken(token);
    }));
  }

  void _joinChannel() async {
    await getToken();
    if (token != null) {
      if (defaultTargetPlatform == TargetPlatform.android) {
        await [Permission.microphone, Permission.camera].request();
      }
      await _engine.joinChannelWithUserAccount(
        token: token!, channelId:     widget.channelId, userAccount:  Provider.of<UserProvider>(context, listen: false).user.uid
      );
    }
  }

  void _switchCamera() {
    _engine.switchCamera().then((value) {
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
    await _engine.muteLocalAudioStream(isMuted);
  }

  // _startScreenShare() async {
  //   final helper = await _engine.getScreenShareHelper(
  //       appGroup: kIsWeb || Platform.isWindows ? null : 'io.agora');
  //   await helper.disableAudio();
  //   await helper.enableVideo();
  //   await helper.setChannelProfile(ChannelProfile.LiveBroadcasting);
  //   await helper.setClientRole(ClientRole.Broadcaster);
  //   var windowId = 0;
  //   var random = Random();
  //   if (!kIsWeb &&
  //       (Platform.isWindows || Platform.isMacOS || Platform.isAndroid)) {
  //     final windows = _engine.enumerateWindows();
  //     if (windows.isNotEmpty) {
  //       final index = random.nextInt(windows.length - 1);
  //       debugPrint('Screensharing window with index $index');
  //       windowId = windows[index].id;
  //     }
  //   }
  //   await helper.startScreenCaptureByWindowId(windowId);
  //   setState(() {
  //     isScreenSharing = true;
  //   });
  //   await helper.joinChannelWithUserAccount(
  //     token,
  //     widget.channelId,
  //     Provider.of<UserProvider>(context, listen: false).user.uid,
  //   );
  // }

  // _stopScreenShare() async {
  //   final helper = await _engine.getScreenShareHelper();
  //   await helper.destroy().then((value) {
  //     setState(() {
  //       isScreenSharing = false;
  //     });
  //   }).catchError((err) {
  //     debugPrint('StopScreenShare $err');
  //   });
  // }

  _leaveChannel() async {
    await _engine.leaveChannel();
    if ('${Provider.of<UserProvider>(context, listen: false).user.uid}${Provider.of<UserProvider>(context, listen: false).user.username}' == widget.channelId) {
      await FirestoreMethods().endLiveStream(widget.channelId);
    } else {
      await FirestoreMethods().updateViewCount(widget.channelId, false);
    }
    Navigator.pushReplacementNamed(context, HomeScreen.routeName);
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).user;

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
        body: Padding(
          padding: const EdgeInsets.all(8),
          child: ResponsiveLatout(
            desktopBody: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      _renderVideo(user),
                      if ("${user.uid}${user.username}" == widget.channelId)
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            InkWell(
                              onTap: _switchCamera,
                              child: const Text('Switch Camera'),
                            ),
                            InkWell(
                              onTap: onToggleMute,
                              child: Text(isMuted ? 'Unmute' : 'Mute'),
                            ),
                            // InkWell(
                            //   onTap: isScreenSharing
                            //       ? _stopScreenShare
                            //       : _startScreenShare,
                            //   child: Text(
                            //     isScreenSharing
                            //         ? 'Stop ScreenSharing'
                            //         : 'Start Screensharing',
                            //   ),
                            // ),
                          ],
                        ),
                    ],
                  ),
                ),
                Chat(channelId: widget.channelId),
              ],
            ),
            mobileBody: Column(
              children: [
                _renderVideo(user),
                if ("${user.uid}${user.username}" == widget.channelId)
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
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
                Expanded(
                  child: Chat(
                    channelId: widget.channelId,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _renderVideo(user) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: "${user.uid}${user.username}" == widget.channelId
          ? AgoraVideoView(
        controller: VideoViewController(
          rtcEngine: _engine,
          canvas: const VideoCanvas(uid: 0), // local user
        ),
      )
          : remoteUid.isNotEmpty
          ? AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: _engine,
          canvas: VideoCanvas(uid: remoteUid[0]),
          connection: RtcConnection(channelId: widget.channelId),
        ),
      )
          : Container(),
    );
  }

}
