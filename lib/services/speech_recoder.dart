import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io'; // Required for directory operations
import 'dart:developer';

class SpeechRecorderService {
  late FlutterSoundRecorder _mRecorder;
  bool _isRecorderInitialized = false;

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

  Future<String> getFilePath() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/temp.wav';

    // Ensure the directory exists
    if (!await Directory(directory.path).exists()) {
      await Directory(directory.path).create(recursive: true);
    }

    log('Path from recorder: $path');
    return path;
  }

  Future<void> startRecording() async {
    if (!_isRecorderInitialized) {
      await initRecorder();
    }

    final filePath = await getFilePath();
    await _mRecorder.startRecorder(toFile: filePath);
    log('Recording started at $filePath');
  }

  Future<String?> stopRecording() async {
    if (!_isRecorderInitialized) {
      log('Recorder is not initialized');
      return null;
    }

    final filePath = await _mRecorder.stopRecorder();
    log('Recording stopped. File saved at: $filePath');
    return filePath;
  }
}
