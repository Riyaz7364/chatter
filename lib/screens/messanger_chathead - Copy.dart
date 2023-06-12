// import 'dart:developer';
// import 'dart:isolate';
// import 'dart:ui';

// import 'package:bg_launcher/bg_launcher.dart';
// import 'package:chatter/controller/firebase_controller.dart';
// import 'package:chatter/routes/routes.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_overlay_window/flutter_overlay_window.dart';
// import 'package:get/get.dart';

// import '../plugins/flutter_firebase_chat_core/src/firebase_chat_core.dart';

// class MessangerChatHead extends StatefulWidget {
//   const MessangerChatHead({Key? key}) : super(key: key);

//   @override
//   State<MessangerChatHead> createState() => _MessangerChatHeadState();
// }

// class _MessangerChatHeadState extends State<MessangerChatHead> {
//   Color color = const Color(0xFFFFFFFF);
//   BoxShape _currentShape = BoxShape.circle;
//   static const String _kPortNameOverlay = 'OVERLAY';
//   static const String _kPortNameHome = 'UI';
//   final _receivePort = ReceivePort();
//   SendPort? homePort;
//   String? messageFromOverlay;

//   final fbController = Get.put(FirebaseController());

//   @override
//   void initState() {
//     super.initState();
//     if (homePort != null) return;
//     final res = IsolateNameServer.registerPortWithName(
//       _receivePort.sendPort,
//       _kPortNameOverlay,
//     );
//     log("$res : HOME");
//     _receivePort.listen((message) {
//       log("message from UI: $message");
//       log(fbController.fbUser.toString());
//       setState(() {
//         messageFromOverlay = 'message from UI: $message';
//       });
//     });
//   }

//   init() async {
//     // final room = await FirebaseChatCore.instance
//     //     .roomSingle("ZOqUYykZmNUAYUKF2dwz", fbuser: fbController.fbUser.first);
//     // Get.offAndToNamed(Routes.chatOverlayScreen, arguments: room);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Stack(
//       clipBehavior: Clip.none,
//       children: [
//         Material(
//           color: Colors.transparent,
//           elevation: 0.0,
//           child: GestureDetector(
//             onTap: () async {
//               if (_currentShape == BoxShape.rectangle) {
//                 await FlutterOverlayWindow.resizeOverlay(100, 100);
//                 setState(() {
//                   _currentShape = BoxShape.circle;
//                 });
//               } else {
//                 BgLauncher.bringAppToForeground();
//                 // await FlutterOverlayWindow.resizeOverlay(
//                 //   WindowSize.matchParent,
//                 //   WindowSize.matchParent,
//                 // );
//                 // setState(() {
//                 //   _currentShape = BoxShape.rectangle;
//                 // });
//               }
//             },
//             child: Container(
//               // margin: EdgeInsets.only(top: MediaQuery.of(context).size.height),
//               height: MediaQuery.of(context).size.height * 0.1,
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 shape: _currentShape,
//               ),
//               child: Center(
//                 child: _currentShape == BoxShape.rectangle
//                     ? ElevatedButton(
//                         onPressed: () {
//                           init();
//                           print(fbController.fbUser);
//                         },
//                         child: Text('Check'))
//                     : const SizedBox.shrink(),
//               ),
//             ),
//           ),
//         ),
//         if (_currentShape == BoxShape.circle)
//           Material(
//             color: Colors.transparent,
//             child: InkWell(
//               onTap: () {
//                 BgLauncher.bringAppToForeground();
//               },
//               child: const CircleAvatar(
//                 backgroundColor: Colors.amberAccent,
//                 radius: 30,
//                 child: FlutterLogo(),
//               ),
//             ),
//           )

//         // SizedBox(
//         //   width: 500,
//         //   child: Container(
//         //     child: Card(
//         //       child: Text('New message show'),
//         //     ),
//         //   ),
//         // )
//       ],
//     );
//   }
// }
