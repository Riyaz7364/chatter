import 'package:chatter/plugins/flutter_firebase_chat_core/flutter_firebase_chat_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;

class SuperChatController extends GetxController {
  final amountTextController = TextEditingController();
  final messageTextController = TextEditingController();
  final isLoading = false.obs;
  Future<bool> makePayment() async {
    if (messageTextController.text.isEmpty) {
      showGetSnackBar('Please enter your Message');
      return false;
    }
    if (amountTextController.text.isEmpty) {
      showGetSnackBar('Please enter your Amount');
      return false;
    }

    isLoading.value = true;

    final partialText = types.PartialText(text: messageTextController.text);
    await Future.delayed(const Duration(seconds: 2));
    FirebaseChatCore.instance.sendMessage(
      partialText,
      "ZOqUYykZmNUAYUKF2dwz",
      amount: amountTextController.text,
      superChat: true,
    );
    isLoading.value = false;
    FirebaseChatCore.instance
        .UpdateSuperChat(messageTextController.text, amountTextController.text);
    return true;
  }

  void showGetSnackBar(String message) {
    Get.showSnackbar(
      GetSnackBar(
        duration: const Duration(seconds: 2),
        title: 'Error',
        message: message,
      ),
    );
  }

  bool isKeyboardOpen(BuildContext context) {
    return MediaQuery.of(context).viewInsets.bottom > 0;
  }
}
