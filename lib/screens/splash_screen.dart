import 'dart:developer';

import 'package:chatter/controller/firebase_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';

import '../plugins/flutter_firebase_chat_core/src/firebase_chat_core.dart';
import '../routes/routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with WidgetsBindingObserver {
  final fbController = Get.find<FirebaseController>();
  late AppLifecycleState _appLifecycleState;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user == null) {
        Get.offAndToNamed(Routes.loginScreen);
      } else {
        login(user);
      }
    });
  }

  Future<void> login(User? user) async {
    print('User is signed in!');

    fbController.fbUser.insert(0, user!);
    log(fbController.fbUser.toString());
    final room = await FirebaseChatCore.instance
        .roomSingle("ZOqUYykZmNUAYUKF2dwz", fbuser: user);

    Navigator.of(Get.context!)
        .pushReplacementNamed(Routes.chatScreen, arguments: room);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(1, 33, 37, 41),
      body: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 20),
              child: Image.asset('assets/images/chatter_logo.png'),
            ),
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
          ],
        ),
      ),
    );
  }
}
