import 'dart:developer';
import 'dart:io';

import 'package:chatter/plugins/flutter_chat_ui/flutter_chat_ui.dart';
import 'package:chatter/plugins/flutter_chat_ui/src/chat_theme.dart';
import 'package:chatter/routes/routes.dart';
import 'package:chatter/widgets/super_chat.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:fluttericon/font_awesome_icons.dart';
import 'package:fluttericon/web_symbols_icons.dart';
import 'package:permission_handler/permission_handler.dart';
import '../controller/firebase_controller.dart';
import '/plugins/flutter_firebase_chat_core/flutter_firebase_chat_core.dart';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';

import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../../plugins/flutter_chat_ui/src/widgets/chat.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen(this.room, {super.key});
  final types.Room? room;
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final fbController = Get.find<FirebaseController>();
  final selectedMessage = <Map<String, Function>>[];
  final selectedMessageList = <types.Message>[];
  bool _isAttachmentUploading = false;
  var room;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    room = widget.room ?? Get.arguments as types.Room;
    showPermissionDialog();
  }

  void showPermissionDialog() async {
    var status = await Permission.systemAlertWindow.status;

    log(status.toString());
    if (status.isDenied) {
      await Permission.systemAlertWindow.request();
    }
    // showDialog(
    //   context: context,
    //   builder: (context) => AlertDialog(
    //     title: Text('Allow Overlay Permission'),
    //     content: Text('Allow app to run over other apps'),
    //     actions: [
    //       TextButton(
    //           onPressed: () {
    //             FlutterOverlayWindow.isPermissionGranted().then((value) {
    //               if (!value) {
    //                 FlutterOverlayWindow.requestPermission().then((value) {});
    //               }
    //             });
    //           },
    //           child: Text('Allow'))
    //     ],
    //   ),
    // );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xff292929),
        appBar: AppBar(
          leading: null,
          backgroundColor: const Color(0xff121211),
          systemOverlayStyle: SystemUiOverlayStyle.light,
          title: Text(
            '${room.name} APP',
            style: Get.textTheme.titleLarge!.copyWith(color: Colors.white),
          ),
          actions: [
            if (selectedMessageList.isNotEmpty)
              IconButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Report Content'),
                        content: const Text(
                            'Report/Flag potential violating content.'),
                        actions: [
                          ElevatedButton(
                              onPressed: () {
                                final fbcc = FirebaseChatCore.instance;
                                fbcc
                                    .reportContent(selectedMessageList, room.id)
                                    .then(
                                      (value) => ScaffoldMessenger.of(context)
                                          .showSnackBar(const SnackBar(
                                              content: Text('Report send'))),
                                    );
                                for (var element in selectedMessage) {
                                  element.values.first(true);
                                }
                                selectedMessage.clear();
                                selectedMessageList.clear();
                                Navigator.of(context).pop();
                                setState(() {});
                              },
                              child: const Text('Send Report')),
                          ElevatedButton(
                              onPressed: () {
                                for (var element in selectedMessage) {
                                  element.values.first(true);
                                }
                                selectedMessage.clear();
                                selectedMessageList.clear();
                                Navigator.of(context).pop();
                                setState(() {});
                              },
                              child: const Text('Cancel'))
                        ],
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.report_problem,
                    size: 30,
                  ))
          ],
        ),
        body: SizedBox(
          height: Get.size.height,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                height: 55,
                color: const Color(0xff444442),
                padding: const EdgeInsets.all(5),
                child: StreamBuilder<List<dynamic>>(
                  stream: FirebaseChatCore.instance.users(),
                  initialData: const [],
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Container(
                        alignment: Alignment.center,
                        margin: const EdgeInsets.only(
                          bottom: 200,
                        ),
                        child: const Text('No users'),
                      );
                    }

                    return ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        final user = snapshot.data![index];
                        log(user.toString());
                        final date = DateTime.fromMillisecondsSinceEpoch(
                            user['updatedAt'] == null ? 0 : user['updatedAt']!);
                        return InkWell(
                          child: Container(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 3),
                              decoration: const BoxDecoration(
                                  color: Color(0xffD4C0B6),
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(20))),
                              width: 140,
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    foregroundImage:
                                        NetworkImage('${user['imageUrl']}'),
                                  ),
                                  Container(
                                    margin:
                                        const EdgeInsets.only(top: 5, left: 2),
                                    width: 90,
                                    child: Column(
                                      children: [
                                        Text(
                                          '${user['firstName']}',
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black,
                                              fontSize: 14),
                                        ),
                                        Row(
                                          children: [
                                            const SizedBox(
                                              width: 5,
                                            ),
                                            Text(
                                              ' ₹${user['amount']}',
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                              style: const TextStyle(
                                                  color: Colors.green,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14),
                                              textAlign: TextAlign.start,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  )
                                ],
                              )),
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                titlePadding: EdgeInsets.zero,
                                title: Card(
                                  color: const Color(0xffFE0000),
                                  elevation: 3,
                                  child: ListTile(
                                    //     contentPadding: EdgeInsets.zero,
                                    leading: CircleAvatar(
                                      foregroundImage:
                                          NetworkImage('${user['imageUrl']}'),
                                    ),
                                    title: Text(
                                      '${user['firstName']}',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14),
                                    ),
                                    trailing: Text(
                                      ' ₹${user['amount']}',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20),
                                    ),
                                  ),
                                ),
                                backgroundColor: const Color(0xff5CE1E6),
                                content: Text(
                                  '${user['message']}',
                                  style: const TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14),
                                ),
                                actions: [
                                  IconButton(
                                      onPressed: () {
                                        Get.back();
                                      },
                                      icon: const Icon(Icons.cancel))
                                ],
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
              Expanded(
                child: StreamBuilder<types.Room>(
                  initialData: room,
                  stream: FirebaseChatCore.instance.room(room.id),
                  builder: (context, snapshot) =>
                      StreamBuilder<List<types.Message>>(
                    initialData: const [],
                    stream: FirebaseChatCore.instance.messages(
                        types.User(
                          id: FirebaseChatCore.instance.firebaseUser?.uid ?? '',
                        ),
                        snapshot.data!),
                    builder: (context, snapshot) {
                      return Chat(
                        theme: const DefaultChatTheme(
                            sentMessageBodyTextStyle:
                                TextStyle(color: Colors.black),
                            receivedMessageBodyTextStyle:
                                TextStyle(color: Colors.white),
                            primaryColor: Colors.white,
                            secondaryColor: Colors.transparent),
                        messages: snapshot.data ?? [],
                        superChat: () {
                          showSuperChatMenu();
                        },
                        onMessageTap: _handleMessageTap,
                        onPreviewDataFetched: _handlePreviewDataFetched,
                        onSendPressed: _handleSendPressed,
                        bubbleRtlAlignment: BubbleRtlAlignment.left,
                        user: types.User(
                            id: FirebaseChatCore.instance.firebaseUser?.uid ??
                                '',
                            firstName: FirebaseChatCore
                                    .instance.firebaseUser?.displayName ??
                                ''),
                        onMessageLongPress: (context, p1, isSelected) {
                          longMessagePress(context, p1, isSelected);
                        },
                        onAvatarTap: (p0) {
                          onAvatarTab(p0);
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        // floatingActionButton: FloatingActionButton(
        //   onPressed: () async {
        //     log(fbController.fbUser.toString());
        //   },
        // ),
      );

  void _handleAtachmentPressed() {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) => SafeArea(
        child: SizedBox(
          height: 144,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _handleImageSelection();
                },
                child: const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Photo'),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _handleFileSelection();
                },
                child: const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('File'),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Cancel'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // void enableWindowMode() async {
  //   // Check if the platform supports multi-window mode
  //   final supported = await WindowManager.isSupported();

  //   if (supported) {
  //     // Enable multi-window mode
  //     await WindowManager.enable();
  //   }
  // }

  void _onMessageLongPress() {}

  void _handleFileSelection() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
    );

    if (result != null && result.files.single.path != null) {
      _setAttachmentUploading(true);
      final name = result.files.single.name;
      final filePath = result.files.single.path!;
      final file = File(filePath);

      try {
        final reference = FirebaseStorage.instance.ref(name);
        await reference.putFile(file);
        final uri = await reference.getDownloadURL();

        final message = types.PartialFile(
          mimeType: lookupMimeType(filePath),
          name: name,
          size: result.files.single.size,
          uri: uri,
        );

        FirebaseChatCore.instance.sendMessage(message, room.id);
        _setAttachmentUploading(false);
      } finally {
        _setAttachmentUploading(false);
      }
    }
  }

  void _handleImageSelection() async {
    final result = await ImagePicker().pickImage(
      imageQuality: 70,
      maxWidth: 1440,
      source: ImageSource.gallery,
    );

    if (result != null) {
      _setAttachmentUploading(true);
      final file = File(result.path);
      final size = file.lengthSync();
      final bytes = await result.readAsBytes();
      final image = await decodeImageFromList(bytes);
      final name = result.name;

      try {
        final reference = FirebaseStorage.instance.ref(name);
        await reference.putFile(file);
        final uri = await reference.getDownloadURL();

        final message = types.PartialImage(
          height: image.height.toDouble(),
          name: name,
          size: size,
          uri: uri,
          width: image.width.toDouble(),
        );

        FirebaseChatCore.instance.sendMessage(
          message,
          room.id,
        );
        _setAttachmentUploading(false);
      } finally {
        _setAttachmentUploading(false);
      }
    }
  }

  void _handleMessageTap(BuildContext _, types.Message message) async {
    if (message is types.FileMessage) {
      var localPath = message.uri;

      if (message.uri.startsWith('http')) {
        try {
          final client = http.Client();
          final request = await client.get(Uri.parse(message.uri));
          final bytes = request.bodyBytes;
          final documentsDir = (await getApplicationDocumentsDirectory()).path;
          localPath = '$documentsDir/${message.name}';

          if (!File(localPath).existsSync()) {
            final file = File(localPath);
            await file.writeAsBytes(bytes);
          }
        } finally {
          final updatedMessage = message.copyWith(isLoading: false);
          FirebaseChatCore.instance.updateMessage(
            updatedMessage,
            room.id,
          );
        }
      }

      await OpenFilex.open(localPath);
    }
  }

  void _handlePreviewDataFetched(
    types.TextMessage message,
    types.PreviewData previewData,
  ) {
    final updatedMessage = message.copyWith(previewData: previewData);

    FirebaseChatCore.instance.updateMessage(updatedMessage, room.id);
  }

  void _handleSendPressed(types.PartialText message) {
    FirebaseChatCore.instance.sendMessage(
      message,
      room.id,
    );
  }

  void _setAttachmentUploading(bool uploading) {
    setState(() {
      _isAttachmentUploading = uploading;
    });
  }

  void longMessagePress(
      BuildContext context, types.Message p1, Function isSelected) {
    if (!selectedMessageList.contains(p1)) {
      isSelected(true);
      selectedMessageList.add(p1);
      selectedMessage.add({p1.id: isSelected});
    } else {
      print('Log Press Else');

      setState(() {
        selectedMessageList.removeWhere((element) => element == p1);
      });
      for (var map in selectedMessage) {
        if (p1.id == map.keys.first) {
          map.values.first(true);
          selectedMessage.removeWhere((element) => element == map);
        }
      }
    }

    print('Message Count =' + selectedMessageList.length.toString());
    print('Log Press');
    setState(() {});
  }

  void onAvatarTab(types.User p0) {
    if (room.type == types.RoomType.group) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(p0.firstName.toString()),
          content: SizedBox(
            height: 150,
            width: 200,
            child: ListView(
              children: [
                OutlinedButton(
                  onPressed: () {},
                  child: const Text('Message'),
                ),
                OutlinedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('This user has been blocked.')));
                    final fbcc = FirebaseChatCore.instance;
                    fbcc.blockUser(fbcc.firebaseUser!.uid, p0.id).then(
                          (value) => ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Report send')),
                          ),
                        );
                    Navigator.pop(context);
                  },
                  child: const Text('Block User (Permanent)'),
                ),
                OutlinedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Thank you for reporting.')));
                    final fbcc = FirebaseChatCore.instance;
                    fbcc.reportContent([], room.id).then(
                      (value) => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Report send')),
                      ),
                    );
                    Navigator.pop(context);
                  },
                  child: Column(
                    children: const [
                      Text('Report User'),
                      Text(
                        'report/flag for potential violations',
                        textAlign: TextAlign.center,
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
                onPressed: () {
                  Get.back();
                },
                child: const Text('Close'))
          ],
        ),
      );
    }
  }

  void showSuperChatMenu() {
    showModalBottomSheet(
      constraints: const BoxConstraints(maxHeight: 200),
      context: context,
      builder: (context) {
        return Container(
          color: Color.fromARGB(255, 54, 53, 53),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: const [
                      Text(
                        'Show Your Support',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
                ListTile(
                  leading: Stack(
                    children: const [
                      Icon(
                        Icons.chat_bubble_outline_outlined,
                        size: 40,
                        color: Colors.white54,
                      ),
                      Positioned(
                        left: 17,
                        bottom: 20,
                        child: Icon(
                          FontAwesome.star,
                          size: 10,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  title: Text(
                    'Super Chat',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium!
                        .copyWith(color: Colors.white),
                  ),
                  subtitle: Text(
                    'Send a highlighted message',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall!
                        .copyWith(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    showModalBottomSheet(
                      isScrollControlled: true,
                      context: context,
                      builder: (context) {
                        return SuperChat();
                      },
                    );
                  },
                ),
                ListTile(
                  onTap: () => Navigator.of(context).pop(),
                  leading: const Icon(
                    WebSymbols.cancel,
                    size: 25,
                    color: Colors.white54,
                  ),
                  title: Text(
                    'Close',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge!
                        .copyWith(color: Colors.white),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }
}
