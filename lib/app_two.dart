import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_silero_vad/flutter_silero_vad.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:test_ai/services/chatgpt_api_services.dart';

import 'package:test_ai/services/speech_to_text.dart';

class AppTwo extends StatefulWidget {
  const AppTwo({super.key});

  @override
  State<AppTwo> createState() => _AppTwoState();
}

class _AppTwoState extends State<AppTwo> {
  final SpeechToTextService _speechToText = SpeechToTextService();
  final ChatgptApiService chatgptApiService = ChatgptApiService();

  FlutterSoundRecorder? _mRecorder;
  bool isActive = false;
  String? _filePath;
  Timer? inactivityTimer;
  List<Message> transcriptions = [];
  bool isRecording = false;
  String transcribedText = '';
  DateTime? lastSpeechTime;
  bool type = false;
  Timer? restartTimer;
  int chunk = 0;
  final int silenceThreshold = 2000; // time wait for no voice detected
  StreamSubscription? _recorderSubscription;
  double? ambientNoiseLevel;
  double dynamicThreshold = 46;

  final ScrollController _scrollController = ScrollController();

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

    /* await _mRecorder!.setSubscriptionDuration(const Duration(milliseconds: 50));
    // Set up decibel monitoring
    _mRecorder!.onProgress!.listen((event) {
      double amplitude = event.decibels ?? 0.0;

      if (amplitude > 46) {
        setState(() {
          isActive = true;
        });
        resetInactivityTimer();

        log('Voice detected! , decibel : $amplitude');
      } else {
        setState(() {
          isActive = false;
        });
        log("Is active  : $isActive");
        if (!isActive) {
          startInactivityTimer();
        }
      }
    }); */
  }

  // Method to scroll to the bottom of the ListView
  void scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 100),
            curve: Curves.bounceIn);
      }
    });
  }

  Future<void> measureAmbientNoise() async {
    try {
      await _mRecorder!.openRecorder();
      _filePath = await getRecordedFilePath();

      await _mRecorder!.startRecorder(
        toFile: _filePath,
        codec: Codec.aacMP4,
        enableVoiceProcessing: true,
      );

      // Measure for 2 seconds to capture ambient noise
      int sampleCount = 0;
      double totalDecibels = 0;

      _recorderSubscription = _mRecorder!.onProgress!.listen((event) {
        double decibels = event.decibels ?? 0.0;
        sampleCount++;
        totalDecibels += decibels;

        // After 2 seconds, stop measuring
        if (sampleCount >= 3) {
          ambientNoiseLevel = totalDecibels / sampleCount;
          dynamicThreshold = ambientNoiseLevel! +
              6; // Add a buffer of 6 dB to filter out ambient noise
          log('Ambient noise level: $ambientNoiseLevel dB, Dynamic threshold: $dynamicThreshold dB');

          stopListening(); // Stop ambient noise recording
        }
      });

      await Future.delayed(const Duration(seconds: 2));
    } catch (e) {
      print('Error measuring ambient noise: $e');
    }
  }

  Future<void> startListening() async {
    try {
      /* Directory tempDir = await getTemporaryDirectory();
      _filePath = '${tempDir.path}/temp_audio.mp4'; */

      await _mRecorder!.openRecorder();

      chunk++;

      _filePath = await getRecordedFilePath();

      await _mRecorder!.startRecorder(
          toFile: _filePath, codec: Codec.aacMP4, enableVoiceProcessing: true);

      log("start file at $chunk:  $_filePath");

      setState(() {
        isRecording = true;
        transcribedText = 'Listening...';
      });

      //old voice part to cancel
      _recorderSubscription?.cancel();

      int sampleCount = 0;
      double totalDecibels = 0;

      await _mRecorder!
          .setSubscriptionDuration(const Duration(milliseconds: 600));
      _recorderSubscription = _mRecorder!.onProgress!.listen((event) {
        double decibels = event.decibels ?? 0.0;

        sampleCount++;
        totalDecibels += decibels;

        if (sampleCount >= 3) {
          ambientNoiseLevel = totalDecibels / sampleCount;
          dynamicThreshold = ambientNoiseLevel! +
              6; // Add a buffer of 6 dB to filter out ambient noise
          log('Ambient noise level: $ambientNoiseLevel dB, Dynamic threshold: $dynamicThreshold dB');

          // Stop ambient noise recording
        }

        if (decibels > dynamicThreshold) {
          // Update last speech time if speech is detected
          lastSpeechTime = DateTime.now();
          setState(() {
            isActive = true;
          });
        } else {
          setState(() {
            isActive = false;
          });
          if (lastSpeechTime != null &&
              DateTime.now().difference(lastSpeechTime!).inMilliseconds >
                  silenceThreshold) {
            stopListening();
            // If silence is detected for longer than the threshold, stop recording
          }
        }

        // Check for silence
      });

      log("active or not : $isActive");
    } catch (e) {
      print('Error starting recording: $e');
    }
  }

  Future<void> stopListening() async {
    try {
      final filePath = await _mRecorder!.stopRecorder();

      lastSpeechTime = null;
      // Optionally, close the session if you're done

      if (filePath!.isNotEmpty) {
        log('Audio saved at: $filePath');
        final fileBytes = await _readAudioFile(filePath);
        final response = await _speechToText.recognize(fileBytes);
        if (response.isSuccess) {
          setState(() {
            transcriptions.add(Message(text: response.text, isUser: true));
          });
          scrollToBottom();
          final String sendToAi = await chatgptApiService
              .postMessage(response.text, language: "en-US");
          log("That is come from ai : $sendToAi");
          setState(() {
            transcriptions.add(Message(text: sendToAi, isUser: false));
          });
          scrollToBottom();

          // Display the transcribed text
        } else {
          setState(() {
            transcriptions
                .add(Message(text: "failed to recognized", isUser: true));
          });
        }
      }
      startListening();
      /* Timer(const Duration(seconds: 2), () async {
      }); */
    } catch (e) {
      print('Error stopping recording or recognizing speech: $e');
      setState(() {
        transcribedText = 'Error: $e';
      });
    }
  }

  Future<String> getRecordedFilePath() async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    // Create a unique file path for the recorded audio
    String filePath = 'audio_conversation_part$chunk-$timestamp.mp4';

    return filePath; // Return the path of the saved file
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

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
                    controller: _scrollController,
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



/* Future<void> saveAudioChunk() async {
    // Record a short segment (e.g., for a few seconds)
    await stopListening(); // Stop current recording
    await Future.delayed(
        const Duration(seconds: 2)); // Adjust duration as needed

    // Start a new recording for the next chunk

    await startListening();
    // print('Saved audio chunk at: $filePath');
  }

void resetInactivityTimer() {
    if (inactivityTimer != null && inactivityTimer!.isActive) {
      inactivityTimer?.cancel();
    }
  }

  void restartListeningAfterDelay() {
    restartTimer?.cancel();
    restartTimer = Timer(const Duration(seconds: 2), () {
      if (!isRecording) {
        print("Restarting listening after delay...");
        startListening(); // Restart recording
      } // Auto start recording if voice is detected again
    });
    
    void startInactivityTimer() {
    inactivityTimer?.cancel();
    inactivityTimer = Timer(const Duration(seconds: 6), () {
      log("Voice inactive for 6 seconds, stopping recording...");

      stopListening();
      // Stop recording after 6 seconds of no voice
    });

    //
  }
  } */