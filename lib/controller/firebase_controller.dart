import 'dart:convert';
import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../routes/routes.dart';
import '/plugins/flutter_firebase_chat_core/flutter_firebase_chat_core.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';

class FirebaseController extends GetxController {
  final fbUser = <User>[].obs;
  final textPopSize = 20.0.obs;
  final chatRoom = <types.Room>[].obs;
  final isLoading = false.obs;
  late User _firebaseUser;

  Future<void> signInGoogle() async {
    final googleSignIn = GoogleSignIn();
    final signInUser = await googleSignIn.signIn();

    log(signInUser.toString());
    if (signInUser != null) {
      final firebaseAuth = FirebaseAuth.instance;
      final googleAuth = await signInUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      isLoading.value = true;
      final userCredential =
          await firebaseAuth.signInWithCredential(credential);
      log('User userCredential created');
      fbUser.insert(0, userCredential.user!);
      addGroupMembers(userCredential.user!);
    }
  }

  void signOutFirebase() async {
    await FirebaseAuth.instance.signOut();
    await GoogleSignIn().signOut();
    Get.offAndToNamed(Routes.loginScreen);
  }

  void addGroupMembers(User user) async {
    final isUserExists = await FirebaseChatCore.instance.checkUserExist();
    _saveFirebaseUser(user);
    log(user.toString());
    final tUser = types.User(
      firstName: user.displayName,
      id: user.uid,
      imageUrl: user.photoURL ?? 'https://i.pravatar.cc/300?u=${user.email}',
      lastName: '',
    );
    await FirebaseChatCore.instance.createUserInFirestore(tUser);

    final room = await FirebaseChatCore.instance
        .roomSingle("ZOqUYykZmNUAYUKF2dwz", fbuser: user);
    chatRoom.insert(0, room);
    log('Room Users = ${room.users.length}');
    if (isUserExists) {
      Get.toNamed(Routes.chatScreen, arguments: room);
      return;
    }

    final newList = room.users..add(tUser);
    final newRoom = types.Room(
      id: room.id,
      type: room.type,
      users: newList,
      createdAt: room.updatedAt,
      imageUrl: room.imageUrl,
      name: room.name,
      metadata: room.metadata,
      lastMessages: room.lastMessages,
      updatedAt: room.updatedAt,
    );
    FirebaseChatCore.instance.updateRoom(newRoom);

    Get.toNamed(Routes.chatScreen, arguments: room);
    return;
  }

  void _saveFirebaseUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    final idtoken = await user.getIdToken();
    final firebaseUserData = jsonEncode(idtoken);
    prefs.setString('fbidToken', firebaseUserData);
  }

  late AppLifecycleReactor _appLifecycleReactor;
  @override
  void onInit() {
    // TODO: implement onInit
    super.onInit();
    _appLifecycleReactor = AppLifecycleReactor();
    _appLifecycleReactor.listenToAppStateChanges();
  }
}

class AppLifecycleReactor {
  AppLifecycleReactor();

  void showOverlay() async {
    await FlutterOverlayWindow.showOverlay(
      enableDrag: false,
      flag: OverlayFlag.focusPointer,
      alignment: OverlayAlignment.centerLeft,
      visibility: NotificationVisibility.visibilityPublic,
      positionGravity: PositionGravity.auto,
      height: WindowSize.matchParent,
      width: WindowSize.matchParent,
    );
  }

  void listenToAppStateChanges() {
    AppStateEventNotifier.startListening();
    AppStateEventNotifier.appStateStream
        .forEach((state) => _onAppStateChanged(state));
  }

  void _onAppStateChanged(AppState appState) async {
    // Try to show an app open ad if the app is being resumed and
    // we're not already showing an app open ad.
    if (appState == AppState.background) {
      log('App Is in Background');
      if (await FlutterOverlayWindow.isActive()) return;
      showOverlay();
    } else if (appState == AppState.foreground) {
      log('App Is in Forground');
      await FlutterOverlayWindow.closeOverlay();
    }

    print(appState);
  }
}
