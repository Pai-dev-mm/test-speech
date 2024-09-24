/* import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_sound/flutter_sound.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:test_ai/network_api.dart';
import 'package:test_ai/services/permission.dart';
import 'package:test_ai/services/speech_recoder.dart';
import 'package:test_ai/services/speech_to_text.dart';

class AppThree extends StatefulWidget {
  const AppThree({super.key});

  @override
  State<AppThree> createState() => _AppThreeState();
}

class _AppThreeState extends State<AppThree> {
  final FlutterSoundRecorder _audioRecorder = FlutterSoundRecorder();
  final SpeechToTextService _speechToText = SpeechToTextService();
  final SpeechRecorderService _recorderService = SpeechRecorderService();

  String transcribedText = '';
  MediaStream? _localStream;
  // List<int> audioBytes = [];
  bool _isRecording = false;
  // String? filePath = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await requestMicrophonePermission(context);
      await Permission.storage.request();
    });
    _initializeWebRTC();
    _initializeRecorder();
  }

  Future<void> _initializeWebRTC() async {
    // Initialize WebRTC to capture the audio stream
    final Map<String, dynamic> mediaConstraints = {
      'audio': true,
      'video': false, // Video is not needed for audio recording
    };

    _localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);

    // Now you can process audio track or save the data
    _localStream?.getAudioTracks().forEach((track) {
      track.onEnded = () => log('Audio track ended');
    });
  }

  Future<void> _initializeRecorder() async {
    await _audioRecorder.openRecorder();
  }

  Future<void> _startRecording() async {
    if (!_audioRecorder.isRecording) {
      setState(() {
        _isRecording = true;
        transcribedText = "Listening...";
      });

      await _recorderService.startRecording();

      /* Timer(const Duration(seconds: 10), () {
        _stopRecordingAndSend();
      }); */
    }
  }

  Future<void> _stopRecordingAndSend() async {
    final filePath = await _recorderService.stopRecording();

    /* final pcmFilePath =
        '${filePath!.substring(0, filePath.lastIndexOf('.'))}.wav';
    log("PCM_____________$pcmFilePath"); */

    setState(() {
      _isRecording = false;
    });
    if (filePath != null) {
      File audioFile = File(filePath);
      Uint8List audioBytes = await audioFile.readAsBytes();

      print('Total audio bytes: ${audioBytes.buffer.lengthInBytes}');

      final response = await _speechToText.recognize(audioBytes);
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
  }

  Future<Uint8List> _readFileAsBytes(String filePath) async {
    final file = File(filePath);
    return await file.readAsBytes();
  }

  /* Future<void> convertMp4ToPcm(String inputPath, String outputPath) async {
    await _flutterFFmpeg
        .execute(
      '-i $inputPath -acodec pcm_s16le -ar 44100 -ac 1 $outputPath',
    )
        .then((returnCode) {
      if (returnCode == 0) {
        log('Conversion successful: $outputPath');
      } else {
        log('Conversion failed with return code $returnCode');
      }
    });
  } */

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Voice to Text')),
        body: Column(
          children: [
            Expanded(
              child: Text(
                transcribedText,
                style: const TextStyle(fontSize: 18),
              ),
            ),
            ElevatedButton(
              onPressed: _isRecording ? _stopRecordingAndSend : _startRecording,
              child:
                  Text(_isRecording ? 'Stop & Send Audio' : 'Start Recording'),
            ),
          ],
        ),
      ),
    );
  }
}

class VoiceToTextRecorder {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool _isRecording = false;
  String _transcription = ''; // This will hold the real-time transcription text

  Future<void> startRecording(String loginToken, String language) async {
    // Start the recorder and capture audio in WAV format
    await _recorder.startRecorder(
      codec: Codec.pcm16WAV, // Record in WAV format for better accuracy
    );

    _isRecording = true;

    // Start transcription in real-time
    while (_isRecording) {
      // Capture a small chunk of audio (for example, every 1 second)
      await Future.delayed(const Duration(seconds: 1));

      // Get the path to the recorded file
      String? filePath = await _recorder.getRecordURL(path: 'audio.wav');
      File file = File(filePath!);
      List<int> audioBytes = await file.readAsBytes();

      // Send the audio chunk to the speech-to-text API
      Map response = await NetworkApi().speechToTextWisper(
        loginToken,
        audioBytes,
        language,
        fileFormat: 'wav', // Make sure the API is expecting WAV format
      );

      // Update the UI with the transcribed text
      if (response.containsKey('text')) {
        _transcription += response['text']; // Append the new chunk of text
        // You can now update the UI with the transcription
        print("Transcription so far: $_transcription");
      }
    }
  }

  Future<void> stopRecording() async {
    // Stop the recorder
    await _recorder.stopRecorder();
    _isRecording = false;

    // Final transcription
    print("Final Transcription: $_transcription");
    // Update the UI with the final transcription
  }
}
 */