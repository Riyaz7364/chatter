import 'dart:developer';

import 'package:chatter/controller/firebase_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:fluttericon/font_awesome_icons.dart';
import 'package:get/get.dart';

class LoginScreen extends StatefulWidget {
  LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with WidgetsBindingObserver {
  final fbController = Get.find<FirebaseController>();
  late AppLifecycleState _appLifecycleState;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(1, 33, 37, 41),
      body: Obx(
        () => fbController.isLoading.isTrue
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : Padding(
                padding: const EdgeInsets.all(25),
                child: Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 20),
                      child: Image.asset('assets/images/chatter_logo.png'),
                    ),
                    const Expanded(child: SizedBox()),
                    Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      child: const Text(
                        'By clicking Log in, you agree with our Terms. Learn how we process your data in our Privacy and Cookies policy',
                        style: TextStyle(color: Colors.white60),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        shape: const RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(30))),
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        fixedSize: Size(Get.size.width, 50),
                        padding: const EdgeInsets.all(10),
                      ),
                      onPressed: () {
                        fbController.signInGoogle();
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Icon(
                            FontAwesome.google,
                            size: 30,
                          ),
                          Text(
                            'Sign in with Google'.toUpperCase(),
                          ),
                          const SizedBox()
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: 200,
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
