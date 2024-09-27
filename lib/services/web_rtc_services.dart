/* import 'dart:async';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class WebRTCService {
  MediaStream? _localStream;
  RTCPeerConnection? _peerConnection;
  bool _isVoiceActive = false;
  final double _voiceThreshold = 10.0; // Adjust threshold as needed

  Future<void> initWebRTC() async {
    // Get user media (audio)
    final mediaConstraints = {
      'audio': true,
      'video': false,
    };

    try {
      // Request access to audio stream
      _localStream =
          await navigator.mediaDevices.getUserMedia(mediaConstraints);

      // Set up peer connection (this is used for WebRTC, even if you're not doing calls)
      _peerConnection = await createPeerConnection({});
      _peerConnection?.addStream(_localStream!);

      // Listen to audio levels
      _localStream?.getAudioTracks().forEach((audioTrack) {
        audioTrack.onEnded = () => print('Audio track ended');
      });

      // Set up voice activity detection
      _startVoiceActivityDetection();
    } catch (e) {
      print("Error accessing microphone: $e");
    }
  }

  void _startVoiceActivityDetection() {
    Timer.periodic(const Duration(milliseconds: 500), (timer) {
      _monitorAudioLevels();
    });
  }

  void _monitorAudioLevels() {
    // This is a placeholder for monitoring audio levels from the stream.
    // We can analyze the stream here for voice activity detection.
    // For now, we'll just mock this by randomizing whether the voice is active.
    final randomDecibels =
        _mockDecibels(); // Replace this with real decibel calculation.
    print("Current Decibels: $randomDecibels");

    // Determine if voice is active based on decibels
    if (randomDecibels > _voiceThreshold) {
      _isVoiceActive = true;
      print("Voice is Active");
    } else {
      _isVoiceActive = false;
      print("No Voice Activity");
    }
  }

  // Simulate decibel levels (you can replace this with actual WebRTC audio level analysis)
  double _mockDecibels() {
    return (5 + (15 * (DateTime.now().second % 5)))
        .toDouble(); // Mock decibels range 5-20
  }

  bool get isVoiceActive => _isVoiceActive;

  Future<void> dispose() async {
    await _localStream?.dispose();
    await _peerConnection?.close();
  }
}
 */