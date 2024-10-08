
import 'package:flutter/material.dart';
import 'package:speech_to_text_ultra/speech_to_text_ultra.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool mIsListening = false;
  String mEntireResponse = '';
  String mLiveResponse = '';


 

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.teal,
          centerTitle: true,
          title: const Text(
            'Speech To Text Ultra',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
          ),
        ),
        body: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                mIsListening
                    ? Text('$mEntireResponse $mLiveResponse')
                    : Text(mEntireResponse),
                const SizedBox(height: 20),
                SpeechToTextUltra(
                  ultraCallback:
                      (String liveText, String finalText, bool isListening) {
                    setState(() {
                      mLiveResponse = liveText;
                      mEntireResponse = finalText;
                      mIsListening = isListening;
                    });
                  },
                  toPauseIcon: const Icon(Icons.pause),
                  toStartIcon: const Icon(Icons.mic),
                  pauseIconColor: Colors.black,
                  startIconColor: Colors.black,
                ),
                const SizedBox(
                  height: 10,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
