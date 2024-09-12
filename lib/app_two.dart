import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:test_ai/network_api.dart';

import 'package:test_ai/services/permission.dart';
import 'package:test_ai/services/speech_recoder.dart';
import 'package:test_ai/services/speech_to_text.dart';

class AppTwo extends StatefulWidget {
  const AppTwo({super.key});

  @override
  State<AppTwo> createState() => _AppTwoState();
}

class _AppTwoState extends State<AppTwo> {
  final SpeechRecorderService speechRecorderService = SpeechRecorderService();

  final SpeechToTextService _speechToText = SpeechToTextService();
  final SpeechRecorderService _recorderService = SpeechRecorderService();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await requestMicrophonePermission(context);
    });
  }

  bool isRecording = false;
  String transcribedText = '';

  Future<void> startListening() async {
    try {
      await _recorderService.startRecording();
      setState(() {
        isRecording = true;
        transcribedText = 'Listening...';
      });
    } catch (e) {
      print('Error starting recording: $e');
    }
  }

  Future<void> stopListening() async {
    try {
      final filePath = await _recorderService.stopRecording();
      setState(() {
        isRecording = false;
      });

      if (filePath != null) {
        final fileBytes = await _readFileAsBytes(filePath);
        final response = await _speechToText.recognize(fileBytes);
        if (response.isSuccess) {
          setState(() {
            transcribedText = response.text; // Display the transcribed text
          });
        } else {
          setState(() {
            transcribedText = 'Failed to recognize speech';
          });
        }
      }
    } catch (e) {
      print('Error stopping recording or recognizing speech: $e');
      setState(() {
        transcribedText = 'Error: $e';
      });
    }
  }

  Future<Uint8List> _readFileAsBytes(String filePath) async {
    final file = File(filePath);
    return await file.readAsBytes();
    /* try {
    final byteData = await rootBundle.load(filePath);
    return byteData.buffer.asUint8List();
    } catch (e) {
      throw Exception('Error reading audio file: $e');
    } */
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
          appBar: AppBar(
            title: const Text("Test Ai"),
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(transcribedText, style: const TextStyle(fontSize: 24)),
                ElevatedButton(
                  onPressed: isRecording ? stopListening : startListening,
                  child:
                      Text(isRecording ? "Stop Recording" : "Start Recording"),
                ),
              ],
            ),
          )),
    );
  }
}
