import 'package:get/get.dart';

import '../controller/firebase_controller.dart';

class FirebaseBinding implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut<FirebaseController>(() => FirebaseController(), fenix: true);
  }
}
