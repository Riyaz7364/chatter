import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:get/get.dart';

import 'firebase_chat_core_config.dart';
import 'util.dart';

/// Provides access to Firebase chat data. Singleton, use
/// FirebaseChatCore.instance to aceess methods.
class FirebaseChatCore {
  FirebaseChatCore._privateConstructor() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      firebaseUser = user;
    });
  }

  /// Config to set custom names for rooms and users collections. Also
  /// see [FirebaseChatCoreConfig].
  FirebaseChatCoreConfig config = const FirebaseChatCoreConfig(
    null,
    'room',
    'users',
    'reports',
  );

  /// Current logged in user in Firebase. Does not update automatically.
  /// Use [FirebaseAuth.authStateChanges] to listen to the state changes.
  User? firebaseUser = FirebaseAuth.instance.currentUser;

  /// Singleton instance.
  static final FirebaseChatCore instance =
      FirebaseChatCore._privateConstructor();

  /// Gets proper [FirebaseFirestore] instance.
  FirebaseFirestore getFirebaseFirestore() => config.firebaseAppName != null
      ? FirebaseFirestore.instanceFor(
          app: Firebase.app(config.firebaseAppName!),
        )
      : FirebaseFirestore.instance;

  /// Sets custom config to change default names for rooms
  /// and users collections. Also see [FirebaseChatCoreConfig].
  void setConfig(FirebaseChatCoreConfig firebaseChatCoreConfig) {
    config = firebaseChatCoreConfig;
  }

  /// Creates [types.User] in Firebase to store name and avatar used on
  /// rooms list
  Future<void> createUserInFirestore(types.User user) async {
    await getFirebaseFirestore()
        .collection(config.usersCollectionName)
        .doc(user.id)
        .set({
      'createdAt': FieldValue.serverTimestamp(),
      'firstName': user.firstName,
      'imageUrl': user.imageUrl,
      'lastName': user.lastName,
      'lastSeen': FieldValue.serverTimestamp(),
      'metadata': user.metadata,
      'role': user.role?.toShortString(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Removes message document.
  Future<void> deleteMessage(String roomId, String messageId) async {
    await getFirebaseFirestore()
        .collection('${config.roomsCollectionName}/$roomId/messages')
        .doc(messageId)
        .delete();
  }

  /// Removes [types.User] from `users` collection in Firebase.
  Future<void> deleteUserFromFirestore(String userId) async {
    await getFirebaseFirestore()
        .collection(config.usersCollectionName)
        .doc(userId)
        .delete();
  }

  /// Returns a stream of messages from Firebase for a given room.
  Stream<List<types.Message>> messages(
    types.User meUser,
    types.Room room, {
    List<Object?>? endAt,
    List<Object?>? endBefore,
    int? limit,
    List<Object?>? startAfter,
    List<Object?>? startAt,
  }) async* {
    final userDoc = await fetchUser(
        FirebaseFirestore.instance, meUser.id, config.usersCollectionName);

    final blockUserList = userDoc['blockID'];
    var query = getFirebaseFirestore()
        .collection(config.roomsCollectionName)
        .doc(room.id)
        .collection('messages')
        .orderBy('createdAt', descending: true);

    if (endAt != null) {
      query = query.endAt(endAt);
    }

    if (endBefore != null) {
      query = query.endBefore(endBefore);
    }

    if (limit != null) {
      query = query.limit(limit);
    }

    if (startAfter != null) {
      query = query.startAfter(startAfter);
    }

    if (startAt != null) {
      query = query.startAt(startAt);
    }

    await for (final snapshot in query.snapshots()) {
      final messages = snapshot.docs.fold<List<types.Message>>(
        [],
        (previousValue, doc) {
          final data = doc.data();
          final author = room.users.firstWhere(
            (u) => u.id == data['authorId'],
            orElse: () => types.User(id: data['authorId'] as String),
          );

          data['author'] = author.toJson();
          data['createdAt'] = data['createdAt']?.millisecondsSinceEpoch;
          data['id'] = doc.id;
          data['updatedAt'] = data['updatedAt']?.millisecondsSinceEpoch;
          final message = types.Message.fromJson(data);

          if (blockUserList != null &&
              blockUserList!.contains(message.author.id)) {
            // If the author is blocked, skip this message
            print('Author is blocked, skipping message');
            return previousValue;
          }

          // If the author is not blocked, add the message to the list of previous messages
          print('Adding message to list');
          return [...previousValue, message];
        },
      );
      yield messages;
    }
  }

  Future<void> blockUser(String userId, String otherUserId) async {
    final userDoc = await fetchUser(
        FirebaseFirestore.instance, userId, config.usersCollectionName);

    final blockUserList = userDoc['blockID'];
    blockUserList!.add(otherUserId);
    getFirebaseFirestore()
        .collection(config.usersCollectionName)
        .doc(userId)
        .update({'blockID': blockUserList});
  }

  Future<bool> reportContent(
      List<types.Message> messages, String roomId) async {
    final fu = FirebaseAuth.instance.currentUser;
    var messageList = [];
    for (var element in messages) {
      messageList.add({
        'userId': element.author.id,
        'id': element.id,
      });
    }

    final Map<String, dynamic> reportMap = {};

    reportMap['authorId'] = fu!.uid;
    reportMap['messageList'] = messageList;
    reportMap['roomId'] = roomId;
    reportMap['createdAt'] = FieldValue.serverTimestamp();

    await getFirebaseFirestore()
        .collection(config.reportCollectionName)
        .add(reportMap);
    return true;
  }

  Future<types.Room> roomSingle(String roomId, {User? fbuser}) async {
    final fu = fbuser ?? FirebaseAuth.instance.currentUser;
    final doc = await getFirebaseFirestore()
        .collection(config.roomsCollectionName)
        .doc(roomId)
        .get();
    final room = processRoomDocument(
      doc,
      fu!,
      getFirebaseFirestore(),
      config.usersCollectionName,
    );
    return room;
    // return getFirebaseFirestore()
    //     .collection(config.roomsCollectionName)
    //     .doc(roomId)
    //     .snapshots()
    //     .asyncMap(
    //       (doc) =>
    //     );
  }

  Stream<types.Room> room(String roomId) {
    final fu = firebaseUser;

    if (fu == null) return const Stream.empty();

    return getFirebaseFirestore()
        .collection(config.roomsCollectionName)
        .doc(roomId)
        .snapshots()
        .asyncMap(
          (doc) => processRoomDocument(
            doc,
            fu,
            getFirebaseFirestore(),
            config.usersCollectionName,
          ),
        );
  }

  void updateMessage(types.Message message, String roomId) async {
    if (firebaseUser == null) return;
    if (message.author.id != firebaseUser!.uid) return;

    final messageMap = message.toJson();
    messageMap.removeWhere(
      (key, value) => key == 'author' || key == 'createdAt' || key == 'id',
    );
    messageMap['authorId'] = message.author.id;
    messageMap['updatedAt'] = FieldValue.serverTimestamp();

    await getFirebaseFirestore()
        .collection('${config.roomsCollectionName}/$roomId/messages')
        .doc(message.id)
        .update(messageMap);
  }

  void sendMessage(
    dynamic partialMessage,
    String roomId, {
    bool superChat = false,
    String amount = "",
  }) async {
    print('partialMessage');
    if (firebaseUser == null) return;
    types.Message? message;

    if (partialMessage is types.PartialCustom) {
      message = types.CustomMessage.fromPartial(
        author: types.User(id: firebaseUser!.uid),
        id: '',
        partialCustom: partialMessage,
      );
    } else if (partialMessage is types.PartialFile) {
      message = types.FileMessage.fromPartial(
        author: types.User(id: firebaseUser!.uid),
        id: '',
        partialFile: partialMessage,
      );
    } else if (partialMessage is types.PartialImage) {
      message = types.ImageMessage.fromPartial(
        author: types.User(id: firebaseUser!.uid),
        id: '',
        partialImage: partialMessage,
      );
    } else if (partialMessage is types.PartialText) {
      message = types.TextMessage.fromPartial(
        author: types.User(id: firebaseUser!.uid),
        id: '',
        partialText: partialMessage,
      );
    }

    if (message != null) {
      final messageMap = message.toJson();
      messageMap.removeWhere((key, value) => key == 'author' || key == 'id');
      messageMap['authorId'] = firebaseUser!.uid;
      messageMap['createdAt'] = FieldValue.serverTimestamp();
      messageMap['updatedAt'] = FieldValue.serverTimestamp();

      if (superChat) {
        messageMap['metadata'] = {
          'color': 'FE0000',
          'amount': amount,
          'paid': 'true'
        };
      }

      await getFirebaseFirestore()
          .collection('${config.roomsCollectionName}/$roomId/messages')
          .add(messageMap);

      print((partialMessage as types.PartialText).text);
      await getFirebaseFirestore()
          .collection(config.roomsCollectionName)
          .doc(roomId)
          .update({
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await getFirebaseFirestore()
          .collection(config.usersCollectionName)
          .doc(firebaseUser!.uid)
          .update({
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Stream<List<dynamic>> users() {
    if (firebaseUser == null) return const Stream.empty();
    return getFirebaseFirestore().collection("superchat").snapshots().map(
          (snapshot) => snapshot.docs.fold<List<dynamic>>(
            [],
            (previousValue, doc) {
              if (firebaseUser!.uid == doc.id) return previousValue;

              final data = doc.data();

              data['createdAt'] = data['createdAt']?.millisecondsSinceEpoch;
              data['id'] = doc.id;
              data['lastSeen'] = data['lastSeen']?.millisecondsSinceEpoch;
              data['updatedAt'] = data['updatedAt']?.millisecondsSinceEpoch;

              return [...previousValue, data];
            },
          ),
        );
  }

  void updateRoom(types.Room room) async {
    if (firebaseUser == null) return;

    final roomMap = room.toJson();
    roomMap.removeWhere((key, value) =>
        key == 'createdAt' ||
        key == 'id' ||
        key == 'lastMessages' ||
        key == 'users');

    if (room.type == types.RoomType.direct) {
      roomMap['imageUrl'] = null;
      roomMap['name'] = null;
    }

    roomMap['lastMessages'] = room.lastMessages?.map((m) {
      final messageMap = m.toJson();

      messageMap.removeWhere((key, value) =>
          key == 'author' ||
          key == 'createdAt' ||
          key == 'id' ||
          key == 'updatedAt');

      messageMap['authorId'] = m.author.id;

      return messageMap;
    }).toList();
    roomMap['updatedAt'] = FieldValue.serverTimestamp();
    roomMap['userIds'] = room.users.map((u) => u.id).toList();

    await getFirebaseFirestore()
        .collection(config.roomsCollectionName)
        .doc(room.id)
        .update(roomMap);
  }

  Future<bool> checkUserExist() async {
    final fu = firebaseUser;

    final snapshot = await getFirebaseFirestore()
        .collection(config.roomsCollectionName)
        .where("userIds", arrayContains: fu!.uid)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return Future.value(true);
    } else {
      return Future.value(false);
    }

    // log(data.toString());
  }

  Future<void> UpdateSuperChat(String message, String amount) async {
    final fu = firebaseUser;

    final body = {
      'uid': fu!.uid,
      'firstName': fu.displayName,
      'lastName': '',
      'imageUrl': fu.photoURL,
      'metadata': null,
      'message': message,
      'amount': amount,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'lastSeen': FieldValue.serverTimestamp(),
    };

    await getFirebaseFirestore()
        .collection('superchat')
        .doc(DateTime.now().toIso8601String())
        .set(body);
  }
}
