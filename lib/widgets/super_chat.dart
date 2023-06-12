import 'package:chatter/controller/superchat_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:get/get.dart';

import '../plugins/flutter_firebase_chat_core/src/firebase_chat_core.dart';

class SuperChat extends StatelessWidget {
  SuperChat({super.key});
  final superChatController = Get.put(SuperChatController());
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: superChatController.isKeyboardOpen(Get.context!) ? 650 : 250,
      child: Scaffold(
        backgroundColor: const Color(0xff292929),
        appBar: AppBar(
          backgroundColor: const Color(0xff121211),
          leading: const Icon(Icons.arrow_back_ios),
          title: const Text('Send a Super Chat'),
        ),
        body: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Column(
                      children: [
                        const SizedBox(
                          height: 20,
                        ),
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          decoration: const BoxDecoration(
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(5),
                              topRight: Radius.circular(5),
                            ),
                            color: Color(0xffFE0000),
                          ),
                          child: Container(
                            margin: const EdgeInsets.only(left: 15),
                            width: MediaQuery.of(context).size.width * 0.4,
                            height: 50,
                            child: SizedBox(
                                width: MediaQuery.of(context).size.width,
                                height: 55,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          foregroundImage: NetworkImage(
                                              '${FirebaseChatCore.instance.firebaseUser!.photoURL}'),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text(
                                            '${FirebaseChatCore.instance.firebaseUser!.displayName}',
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.currency_rupee,
                                          color: Colors.white,
                                        ),
                                        Container(
                                          margin: const EdgeInsets.all(8),
                                          padding: const EdgeInsets.only(
                                              top: 15, left: 5),
                                          width: 120,
                                          child: TextField(
                                            controller: superChatController
                                                .amountTextController,
                                            style: const TextStyle(
                                                color: Colors.white),
                                            keyboardType: TextInputType.number,
                                            maxLines: 1,
                                            maxLength: 6,
                                            decoration: const InputDecoration(
                                                hintStyle: TextStyle(
                                                    color: Colors.white60,
                                                    fontSize: 14),
                                                border: InputBorder.none,
                                                hintText: 'Enter Amount',
                                                counterText: ""),
                                            onChanged: (value) {
                                              if (value.length > 5) {}
                                            },
                                          ),
                                        ),
                                      ],
                                    )
                                  ],
                                )),
                          ),
                        ),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 0),
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          decoration: const BoxDecoration(
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(5),
                              bottomRight: Radius.circular(5),
                            ),
                            color: Color(0xff5CE1E6),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: TextField(
                              controller:
                                  superChatController.messageTextController,
                              decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  hintText: 'Enter your message here'),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            shape: const RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(20))),
                            fixedSize: Size.fromWidth(
                                MediaQuery.of(context).size.width)),
                        onPressed: () async {
                          superChatController.makePayment().then((value) =>
                              value == true ? showSuccessMessage(context) : '');
                        },
                        child: const Text(
                          'Buy and Send',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w600,
                          ),
                        ))
                  ],
                ),
              ),
            ),
            Obx(
              () => superChatController.isLoading.isTrue
                  ? Container(
                      color: Colors.black45,
                      height: double.infinity,
                      width: double.infinity,
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : const Center(),
            ),
          ],
        ),
      ),
    );
  }

  void showSuccessMessage(BuildContext context) {
    Get.back();
    showModalBottomSheet(
      constraints: const BoxConstraints(maxHeight: 300),
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 20),
        color: const Color(0xff121211),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Chatter',
                  style: Get.textTheme.titleLarge!
                      .copyWith(fontSize: 35, color: Colors.white),
                ),
                IconButton(
                    onPressed: () {
                      Get.back();
                    },
                    icon: const Icon(
                      Icons.cancel,
                      color: Colors.grey,
                      size: 40,
                    )),
              ],
            ),
            Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: Color(0xff292929),
                borderRadius: BorderRadius.all(
                  Radius.circular(10),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: const BoxDecoration(
                        border: Border(
                            bottom: BorderSide(width: 2, color: Colors.grey))),
                    child: ListTile(
                      leading: FlutterLogo(),
                      title: Text(
                        'Super Chat',
                        style: Get.textTheme.titleLarge!
                            .copyWith(color: Colors.white),
                      ),
                      subtitle: Text('Thank you for Your Super Chat',
                          style: Get.textTheme.bodySmall!
                              .copyWith(color: Colors.white)),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: const BoxDecoration(
                        border: Border(
                            bottom: BorderSide(width: 2, color: Colors.grey))),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.currency_rupee,
                              color: Colors.white,
                            ),
                            Text(
                              superChatController.amountTextController.text,
                              style: Get.textTheme.titleLarge!
                                  .copyWith(color: Colors.white),
                            )
                          ],
                        ),
                        Row(
                          children: const [
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 5),
                              child: Text(
                                'One Time Charge',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        'Account: ${FirebaseChatCore.instance.firebaseUser!.email}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
