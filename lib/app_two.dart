import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
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
  final SpeechToTextService _speechToText = SpeechToTextService();

  FlutterSoundRecorder? _mRecorder;
  bool isActive = false;
  String? _filePath;
  Timer? inactivityTimer;
  List<Message> transcriptions = [];
  bool isRecording = false;
  String transcribedText = '';
  
  bool type = false;
  Timer? restartTimer;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    Permission.microphone.request();
    _mRecorder = FlutterSoundRecorder();
    initRecorder();
  }

  Future<void> initRecorder() async {
    await _mRecorder!.openRecorder();

    await _mRecorder!.setSubscriptionDuration(const Duration(milliseconds: 50));
    // Set up decibel monitoring
    _mRecorder!.onProgress!.listen((event) {
      double amplitude = event.decibels ?? 0.0;
      if (amplitude > 40) {
        setState(() {
          isActive = true;
        });
        resetInactivityTimer();

        print('Voice detected! , decibel : $amplitude');
      } else {
        setState(() {
          isActive = false;
        });

        if (!isActive) {
          startInactivityTimer();
        }
      }
    });
  }

  Future<void> startListening() async {
    try {
      Directory tempDir = await getTemporaryDirectory();
      _filePath = '${tempDir.path}/temp_audio.mp4';

      if (!_mRecorder!.isRecording) {
        await _mRecorder!.startRecorder(
          toFile: _filePath,
          codec: Codec.aacMP4,
        );

        setState(() {
          isRecording = true;
          transcribedText = 'Listening...';
        });
      }

      log("active or not : $isActive");
    } catch (e) {
      print('Error starting recording: $e');
    }
  }

  Future<void> stopListening() async {
    try {
      final filePath = await _mRecorder!.stopRecorder();
      setState(() {
        isRecording = false;
      });
      if (filePath != null) {
        final fileBytes = await _readAudioFile(filePath);
        final response = await _speechToText.recognize(fileBytes);
        if (response.isSuccess) {
          setState(() {
            transcriptions.add(Message(
                text: response.text,
                isUser: true)); // Display the transcribed text
          });
        } else {
          setState(() {
            transcriptions
                .add(Message(text: "failed to recognized", isUser: true));
          });
        }
      }

      Timer(const Duration(seconds: 6), () {
        setState(() {
          transcriptions
              .add(Message(text: "How can I help you today?", isUser: false));
        });
      });

      restartListeningAfterDelay();
    } catch (e) {
      print('Error stopping recording or recognizing speech: $e');
      setState(() {
        transcribedText = 'Error: $e';
      });
    }
  }

  Future<void> stop() async {
    await _mRecorder!.stopRecorder();

    setState(() {
      isRecording = false;
    });
  }

  Future<List<int>> _readAudioFile(String filePath) async {
    final file = File(filePath);
    return await file.readAsBytes();
  }

  void startInactivityTimer() {
    inactivityTimer?.cancel();
    inactivityTimer = Timer(const Duration(seconds: 6), () {
      stopListening(); 
    });
  }

  
  void resetInactivityTimer() {
    if (inactivityTimer != null && inactivityTimer!.isActive) {
      inactivityTimer?.cancel();
    }
  }

  
  void restartListeningAfterDelay() {
    restartTimer?.cancel();
    restartTimer = Timer(const Duration(seconds: 2), () {
      startListening(); // Auto start recording if voice is detected again
    });
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
                Expanded(
                  child: ListView.builder(
                    itemCount: transcriptions.length,
                    itemBuilder: (context, index) {
                      final message = transcriptions[index];
                      return ChatBubble(
                        text: message.text,
                        isUser: message.isUser,
                      );
                    },
                  ),
                ),
                Text(
                  isActive ? 'Voice Detected!' : 'No Voice Detected',
                  style: TextStyle(
                    color: isActive ? Colors.green : Colors.red,
                    fontSize: 24,
                  ),
                ),
                ElevatedButton(
                  onPressed: isRecording ? stop : startListening,
                  child:
                      Text(isRecording ? "Stop Recording" : "Start Recording"),
                ),
              ],
            ),
          )),
    );
  }
}

class ChatBubble extends StatelessWidget {
  final String text;
  final bool isUser;

  const ChatBubble({
    super.key,
    required this.text,
    required this.isUser,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 260,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isUser ? Colors.blueAccent : Colors.grey[300],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            text,
            style: TextStyle(
              color: isUser ? Colors.white : Colors.black,
            ),
          ),
        ),
      ),
    );
  }
}

class Message {
  final String text;
  final bool isUser;

  Message({required this.text, required this.isUser});
}
