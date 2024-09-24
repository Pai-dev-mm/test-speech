import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:test_ai/services/speech_to_text.dart';

class NetworkApi {
  static const String _baseUrl = "https://dev.api.lango.ai";
  static const String _apiVersion = "/v1";
  static String get _apiBaseUrl => _baseUrl + _apiVersion;
  static String get apiBaseUrl => _apiBaseUrl;

  Future<Map> speechToTextWisper(
    String loginToken,
    List<int> file,
    String language, {
    String fileFormat = 'mp4',
  }) async {
    try {
      final request = http.MultipartRequest(
          'POST', Uri.parse("$_apiBaseUrl/temp/sttWhisper"))
        ..headers.addAll({
          "content-Type": 'multipart/form-data',
          "authorization": "Bearer $loginToken"
        })
        ..fields.addAll({
          // 'recognitionMode': ({})['recognitionMode'],
          'language': language,
        })
        ..files.add(
          http.MultipartFile.fromBytes('audioFile', file,
              filename: "audio.$fileFormat",
              contentType: MediaType("audio", fileFormat)

              // "application/octet-stream"
              ),
        );

      final response =
          jsonDecode(await (await request.send()).stream.bytesToString());
      if (response['success'] == true) {
        return response;
      } else {
        throw Exception('Fail to send request');
      }
    } catch (e) {
      rethrow;
    }
  }
}
