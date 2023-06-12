import 'dart:io';

import 'package:bg_launcher/bg_launcher.dart';
import 'package:chatter/plugins/flutter_chat_ui/src/chat_theme.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import '/plugins/flutter_firebase_chat_core/flutter_firebase_chat_core.dart';
import 'package:fluttericon/font_awesome_icons.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import '/routes/routes.dart';

import '../../plugins/flutter_chat_ui/src/widgets/chat.dart';

class ChatOverlayScreen extends StatefulWidget {
  const ChatOverlayScreen(this.room, {super.key});
  final types.Room? room;
  @override
  State<ChatOverlayScreen> createState() => _ChatOverlayScreenState();
}

class _ChatOverlayScreenState extends State<ChatOverlayScreen> {
  final selectedMessage = <Map<String, Function>>[];
  final selectedMessageList = <types.Message>[];
  bool _isAttachmentUploading = false;
  var room;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    room = widget.room ?? Get.arguments as types.Room;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color.fromARGB(1, 33, 37, 41),
        appBar: AppBar(
          leading: null,
          backgroundColor: const Color.fromARGB(255, 31, 30, 30),
          systemOverlayStyle: SystemUiOverlayStyle.light,
          title: Text(
            '${room.name} APP',
            style: Get.textTheme.titleLarge!.copyWith(color: Colors.white),
          ),
          actions: [
            IconButton(
                onPressed: () {
                  BgLauncher.bringAppToForeground();
                },
                icon: Icon(Icons.fullscreen)),
            IconButton(
                onPressed: () {
                  exit(0);
                },
                icon: Icon(Icons.close)),
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
                color: Colors.grey,
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
                        final date = DateTime.fromMillisecondsSinceEpoch(
                            user['updatedAt'] == null ? 0 : user['updatedAt']!);
                        return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 5),
                            decoration: const BoxDecoration(
                                color: Colors.amber,
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
                                            color: Colors.white, fontSize: 15),
                                      ),
                                      const Text(
                                        '500\$',
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                        style: TextStyle(
                                            color: Colors.white, fontSize: 15),
                                        textAlign: TextAlign.end,
                                      ),
                                    ],
                                  ),
                                )
                              ],
                            ));
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
                        isAttachmentUploading: _isAttachmentUploading,
                        messages: snapshot.data ?? [],
                        onAttachmentPressed: _handleAtachmentPressed,
                        onMessageTap: _handleMessageTap,
                        onPreviewDataFetched: _handlePreviewDataFetched,
                        onSendPressed: _handleSendPressed,
                        user: types.User(
                          id: FirebaseChatCore.instance.firebaseUser?.uid ?? '',
                        ),
                        onMessageLongPress: (context, p1, isSelected) {
                          if (!selectedMessageList.contains(p1)) {
                            isSelected(true);
                            selectedMessageList.add(p1);
                            selectedMessage.add({p1.id: isSelected});
                          } else {
                            print('Log Press Else');

                            setState(() {
                              selectedMessageList
                                  .removeWhere((element) => element == p1);
                            });
                            for (var map in selectedMessage) {
                              if (p1.id == map.keys.first) {
                                map.values.first(true);
                                selectedMessage
                                    .removeWhere((element) => element == map);
                              }
                            }
                          }

                          print('Message Count =' +
                              selectedMessageList.length.toString());
                          print('Log Press');
                          setState(() {});
                        },
                        onAvatarTap: (p0) {
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
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(const SnackBar(
                                                  content: Text(
                                                      'This user has been blocked.')));
                                          final fbcc =
                                              FirebaseChatCore.instance;
                                          fbcc
                                              .blockUser(
                                                  fbcc.firebaseUser!.uid, p0.id)
                                              .then(
                                                (value) => ScaffoldMessenger.of(
                                                        context)
                                                    .showSnackBar(
                                                  const SnackBar(
                                                      content:
                                                          Text('Report send')),
                                                ),
                                              );
                                          Navigator.pop(context);
                                        },
                                        child: const Text(
                                            'Block User (Permanent)'),
                                      ),
                                      OutlinedButton(
                                        onPressed: () {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(const SnackBar(
                                                  content: Text(
                                                      'Thank you for reporting.')));
                                          final fbcc =
                                              FirebaseChatCore.instance;
                                          fbcc.reportContent([], room.id).then(
                                            (value) =>
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                              const SnackBar(
                                                  content: Text('Report send')),
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
        //     final bool status =
        //         await FlutterOverlayWindow.isPermissionGranted();
        //     if (!status) {
        //       await FlutterOverlayWindow.requestPermission();
        //     }

        //     Get.toNamed(Routes.homepage);

        //     await Future.delayed(Duration(seconds: 5));
        //     await FlutterOverlayWindow.shareData("Hello from the other side");
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
}
