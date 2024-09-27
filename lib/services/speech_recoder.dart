import 'dart:async';

import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
// Required for directory operations
import 'dart:developer';


class SpeechRecorderService {
  late FlutterSoundRecorder _mRecorder;
  bool _isRecorderInitialized = false;

  bool isVoiceDetected = false;
  Timer? timer;
  StreamSubscription? recorderSubscription;
  double decibel = 0;

  SpeechRecorderService() {
    _mRecorder = FlutterSoundRecorder();
  }

  Future<void> initRecorder() async {
    // Requesting microphone permission
    final micStatus = await Permission.microphone.request();
    if (micStatus != PermissionStatus.granted) {
      throw RecordingPermissionException('Microphone permission not granted');
    }

    // Open the recorder
    await _mRecorder.openRecorder();

    _isRecorderInitialized = true;
  }

  Future<void> dispose() async {
    if (_isRecorderInitialized) {
      await _mRecorder.closeRecorder();
    }
  }

  Future<String> getFilePath(String extension) async {
    final directory =
        await getApplicationDocumentsDirectory(); // Internal storage
    return '${directory.path}/audio.$extension'; // e.g., audio.wav or audio.mp4
  }

  Future<void> startRecording() async {
    // or 'mp4', 'aac'
    final filePath = await getFilePath('mp4');
    await _mRecorder.startRecorder(
      toFile: filePath,
      codec: Codec.aacMP4,
    );
    log("Strat from : $filePath");
   
  }

  Future<String?> stopRecording() async {
    try {
      final path = await _mRecorder.stopRecorder();
      if (path == null || path.isEmpty) {
        throw Exception('Error: File path is invalid or recording not saved.');
      }
      print('File saved at: $path');
      return path;
    } catch (e) {
      print('Error stopping recorder: $e');
      return null;
    }
  }
}
