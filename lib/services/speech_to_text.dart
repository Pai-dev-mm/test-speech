import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:test_ai/network_api.dart';

const loginToken =
    "cvqT2bwtTUWFWb_QsPvXEG:APA91bGeGd9IOLF6UPljWwAKMsdWo9aaXqvcomH8yA9llfwG-MVGoyGG7sYSrK_kH9a1vEh9JEmXSs5NkpYOdu9s-vvwLdhbOIPN_f62F30wfIWxRecGqzwhRUTLfnY0UfHH0M1Vo1GO";

class SpeechToTextService {
  final _api = NetworkApi();

  Future<SpeechToTextResponse> recognize(List<int> file,
      {String language = 'en-US', String fileFormat = 'mp4'}) async {
    try {
      final response = await _api.speechToTextWisper(loginToken, file, language,
          fileFormat: fileFormat);
      return SpeechToTextResponse(
          text: response['text'] ?? '', isSuccess: true);
    } catch (e) {
      return SpeechToTextResponse(text: e.toString());
    }
  }
}

class SpeechToTextResponse {
  final bool isSuccess;
  final String text;
  SpeechToTextResponse({
    this.isSuccess = false,
    required this.text,
  });
}






/* final String apiKey;

  SpeechToTextService(this.apiKey);

  Future<String> transcribeAudio(String audioFilePath) async {
   final audioFile = File(audioFilePath);
    final audioBytes = await audioFile.readAsBytes();
    final base64Audio = base64Encode(audioBytes);

    final url = "https://speech.googleapis.com/v1/speech:recognize?key=$apiKey";

    final requestPayload = {
      "config": {
        "encoding": "LINEAR16", // WAV uses LINEAR16 encoding
        "sampleRateHertz": 16000, // Adjust based on recording settings
        "languageCode": "en-US"
      },
      "audio": {
        "content": base64Audio
      }
    };

    final response = await http.post(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
      body: json.encode(requestPayload),
    );

     if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      if (jsonResponse['results'] != null) {
        return jsonResponse['results'][0]['alternatives'][0]['transcript']
            as String;
      } else {
        return 'No transcription available';
      }
    } else {
      throw Exception('Failed to transcribe audio: ${response.body}');
    }
  } */ 