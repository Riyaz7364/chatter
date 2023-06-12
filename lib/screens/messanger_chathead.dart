import 'dart:developer';
import 'dart:isolate';
import 'dart:ui';
import 'package:chatter/screens/chatoverlay_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:get/get.dart';

import '../plugins/flutter_firebase_chat_core/src/firebase_chat_core.dart';

class MessangerChatHead extends StatefulWidget {
  const MessangerChatHead({Key? key}) : super(key: key);

  @override
  State<MessangerChatHead> createState() => _MessangerChatHeadState();
}

class _MessangerChatHeadState extends State<MessangerChatHead> {
  Color color = const Color(0xFFFFFFFF);
  BoxShape _currentShape = BoxShape.circle;
  static const String _kPortNameOverlay = 'OVERLAY';
  static const String _kPortNameHome = 'UI';
  final _receivePort = ReceivePort();
  SendPort? homePort;
  String? messageFromOverlay;

  @override
  void initState() {
    super.initState();
    if (homePort != null) return;
    final res = IsolateNameServer.registerPortWithName(
      _receivePort.sendPort,
      _kPortNameOverlay,
    );
    log("$res : HOME");
    _receivePort.listen((message) {
      log("message from UI: $message");

      setState(() {
        messageFromOverlay = 'message from UI: $message';
      });
    });
  }

  var room;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: Colors.transparent,
          elevation: 0.0,
          child: GestureDetector(
            onTap: () async {
              log('Tap');
              if (_currentShape == BoxShape.rectangle) {
                await FlutterOverlayWindow.resizeOverlay(100, 100);
                setState(() {
                  _currentShape = BoxShape.circle;
                });
              } else {
                await FlutterOverlayWindow.closeOverlay();
                // BgLauncher.bringAppToForeground();
                // await FlutterOverlayWindow.resizeOverlay(
                //   WindowSize.matchParent,
                //   WindowSize.matchParent,
                // );
                // setState(() {
                //   _currentShape = BoxShape.rectangle;
                // });
              }
            },
          ),
        ),
        // Align(
        //   alignment: Alignment.bottomCenter,
        //   child: Container(
        //     margin: EdgeInsets.only(bottom: 100),
        //     height: MediaQuery.of(context).size.height * 0.07,
        //     decoration: BoxDecoration(
        //       color: Colors.white,
        //       shape: _currentShape,
        //     ),
        //     child: Center(
        //       child: _currentShape == BoxShape.rectangle
        //           ? Material(
        //               color: Colors.transparent,
        //               child: IconButton(
        //                   onPressed: () {},
        //                   icon: Icon(
        //                     Icons.cancel_rounded,
        //                     size: 30,
        //                   )))
        //           : const SizedBox.shrink(),
        //     ),
        //   ),
        // ),
        if (_currentShape == BoxShape.circle)
          Material(
            color: Colors.transparent,
            child: Align(
              alignment: Alignment.centerRight,
              child: InkWell(
                onTap: () async {
                  // BgLauncher.bringAppToForeground();
                  // await FlutterOverlayWindow.closeOverlay();
                  final user = FirebaseAuth.instance.currentUser;
                  log(user.toString());
                  room = await FirebaseChatCore.instance
                      .roomSingle("ZOqUYykZmNUAYUKF2dwz", fbuser: user);
                  log(room.toString());

                  _currentShape = BoxShape.rectangle;
                  setState(() {});
                },
                child: const CircleAvatar(
                  backgroundColor: Colors.amberAccent,
                  radius: 30,
                  child: FlutterLogo(),
                ),
              ),
            ),
          ),
        if (_currentShape == BoxShape.rectangle)
          Wrap(
            alignment: WrapAlignment.end,
            runAlignment: WrapAlignment.end,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 100,
            children: [
              SafeArea(
                  child: SizedBox(
                height: (Get.size.height * 0.33).toDouble(),
              )),
              Material(
                child: InkWell(
                    onTap: () {
                      // setState(() async {
                      //   await FlutterOverlayWindow.resizeOverlay(500, 200);
                      //   _currentShape = BoxShape.rectangle;
                      // });
                      print('TAb');
                    },
                    child:
                        Container(height: 500, child: ChatOverlayScreen(room))),
              ),
            ],
          )
      ],
    );
  }
}
