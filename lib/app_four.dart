import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:vosk_flutter/vosk_flutter.dart';

class AppFour extends StatefulWidget {
  const AppFour({super.key});

  @override
  State<AppFour> createState() => _AppFourState();
}

class _AppFourState extends State<AppFour> {
  static const _modelName = 'vosk-model-small-en-us-0.15';
  static const _sampleRate = 16000;

  final _vosk = VoskFlutterPlugin.instance();
  final _modelLoader = ModelLoader();
  StreamController<Uint8List> audioStreamController =
      StreamController<Uint8List>();

  Model? _model;
  Recognizer? _recognizer;
  SpeechService? _speechService;
  bool isRecording = false;

  String status = "Waiting for voice...";
  bool _isVoiceActive = false;
  bool start = false;
  FlutterSoundRecorder? _recorder;
  String? _filePath;
  double decibelLevel = 0.0;
  bool isVoiceDetected = false;

  @override
  void initState() {
    super.initState();
    Permission.microphone.request();

    _recorder = FlutterSoundRecorder();
    initRecorder();
  }

  /*  @override
  void initState() {
    super.initState();
    _recorder = FlutterSoundRecorder();
    requestMicPermission();
    _initRecorder();
  } */

  Future<void> initRecorder() async {
    await _recorder!.openRecorder();

    // Set up decibel monitoring
  }

  Future<void> startRecording() async {
    Directory tempDir = await getTemporaryDirectory();
    _filePath = '${tempDir.path}/temp_audio.mp4';
    await _recorder!.setSubscriptionDuration(const Duration(milliseconds: 50));

    if (!_recorder!.isRecording) {
      await _recorder!.startRecorder(
        toFile: _filePath,
        codec: Codec.aacMP4,
      );
// aacMP4   pcm16WAV    wav
      setState(() {
        isRecording = true;
      });

      _recorder!.onProgress!.listen((event) {
        double db = event.decibels ?? 0.0; // Get decibel level
        setState(() {
          decibelLevel = db;
          isVoiceDetected =
              db > 50.0; // Simple VAD: if decibels > 40, voice is detected
        });
      });

      // Listen to the stream and process audio chunks
      /*  audioStreamController.stream.listen((audioChunk) async {
        await checkVoiceActivity(audioChunk);
      }); */

      log("Recording started");
    }
  }

  Future<void> stopRecording() async {
    if (_recorder!.isRecording) {
      await _recorder!.stopRecorder();
      setState(() {
        isRecording = false;
      });
      log("Recording stopped");
    }
  }

  /* Future<void> _loadModel() async {
    final modelPath =
        await _modelLoader.loadFromAssets('assets/models/$_modelName.zip');
    _model = await _vosk.createModel(modelPath);
    _recognizer =
        await _vosk.createRecognizer(model: _model!, sampleRate: _sampleRate);
    if (Platform.isAndroid) {
      _speechService = await _vosk.initSpeechService(_recognizer!);
      // Handle results here

      await _speechService!.start();

      setState(() {
        start = true;
      });
      log("Speech service started.");
    }
  } */

  Future<void> checkVoiceActivity(Uint8List audioBytes) async {
    List<String> results = [];
    int chunkSize = 8192; // Process in chunks of 8192 bytes
    int pos = 0;

    bool resultReady = await _recognizer!.acceptWaveformBytes(audioBytes);

    if (resultReady) {
      // If VAD detects voice activity, mark voice as active
      _isVoiceActive = true;
      log("Voice detected.");
      if (!_recorder!.isRecording) {
        await startRecording();
      }
    } else {
      // No voice activity detected
      _isVoiceActive = false;
      log("No voice detected.");
      if (_recorder!.isRecording) {
        await stopRecording();
      }
    }
  }

  @override
  void dispose() {
    // Properly stop the SpeechService when the widget is disposed
    _recorder!.closeRecorder();
    audioStreamController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vosk Flutter Demo')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(isRecording ? 'Recording...' : 'Press to Start Recording'),
            ElevatedButton(
              onPressed: isRecording ? stopRecording : startRecording,
              child: Text(isRecording ? 'Stop Recording' : 'Start Recording'),
            ),
            const SizedBox(height: 20),
            Text('Decibel Level: ${decibelLevel.toStringAsFixed(2)} dB'),
            const SizedBox(height: 20),
            Text(
              isVoiceDetected ? 'Voice Detected!' : 'No Voice Detected',
              style: TextStyle(
                color: isVoiceDetected ? Colors.green : Colors.red,
                fontSize: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
