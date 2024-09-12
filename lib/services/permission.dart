import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

Future<bool> requestMicrophonePermission(BuildContext context) async {
  var status = await Permission.microphone.status;
  if (!status.isGranted) {
    if (await Permission.microphone.request().isGranted) {
      return true;
    } else {
      log("Permission is not allowed");
      return false;
    }
  }
  return true;
}