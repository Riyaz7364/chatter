import 'package:chatter/screens/chat_screen.dart';
import 'package:chatter/screens/home_page.dart';
import 'package:chatter/screens/login_screen.dart';
import 'package:chatter/screens/messanger_chathead.dart';
import 'package:chatter/screens/splash_screen.dart';
import 'package:get/get.dart';

import '../bindings/app_bindings.dart';
import '../screens/chatoverlay_screen.dart';

class Routes {
  static const splashScreem = '/';
  static const loginScreen = '/loginScreen';
  static const chatScreen = '/chatScreen';
  static const chatOverScreen = '/chatOverScreen';
  static const chatOverlayScreen = '/chatOverlayScreen';
  static const homepage = '/homepage';
  static const messagePop = '/messagePop';
  static List<GetPage> routes = [
    GetPage(
      name: messagePop,
      page: () => MessangerChatHead(),
    ),
    GetPage(
      name: chatScreen,
      page: () => const ChatScreen(null),
    ),
    GetPage(
      name: chatOverlayScreen,
      binding: FirebaseBinding(),
      page: () => const ChatOverlayScreen(null),
    ),
    GetPage(
      name: homepage,
      page: () => HomePage(),
    ),
    GetPage(
      name: chatOverlayScreen,
      page: () => MessangerChatHead(),
    ),
    GetPage(
      name: loginScreen,
      // bindings: [
      //   FirebaseBinding(),
      // ],
      page: () => LoginScreen(),
    ),
    GetPage(
      name: splashScreem,
      bindings: [
        FirebaseBinding(),
      ],
      page: () => SplashScreen(),
    ),
  ];
}
