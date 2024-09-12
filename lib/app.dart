import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  bool _speechEnabled = false;
  String _lastWords = '';
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  /// This has to happen only once per app
  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize();

    setState(() {});
  }

  /// Each time to start a speech recognition session
  void _startListening() async {
    if (_speechEnabled && !_isListening) {
      // Set the listening state to true
      setState(() {
        _isListening = true;
      });
      await _speechToText.listen(
        onResult: _onSpeechResult,
        listenFor: const Duration(seconds: 60), // Increase duration

        onSoundLevelChange: (level) {
          log("voice level is : $level");
        },
      );
    }
  }

 
  /// listen method.
  void _stopListening() async {
    await _speechToText.stop();
    setState(() {
      _isListening = false; // Update the listening state
    });
  }

  
  void _onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      _lastWords = result.recognizedWords;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Speech Demo'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(16),
                child: const Text(
                  'Recognized words:',
                  style: TextStyle(fontSize: 20.0),
                ),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    // If listening is active show the recognized words
                    _isListening
                        ? _lastWords
                       
                        : _speechEnabled
                            ? 'Tap the microphone to start listening...'
                            : 'Speech not available',
                  ),
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed:
              // If not yet listening for speech start, otherwise stop
              _isListening ? _stopListening : _startListening,
          tooltip: 'Listen',
          child: Icon(_isListening ? Icons.mic : Icons.mic_off),
        ),
      ),
    );
  }
}
