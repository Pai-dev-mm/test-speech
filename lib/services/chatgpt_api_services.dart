import 'dart:convert';

import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;

import 'dart:developer';

class ChatgptApiService {
  final String _apiKey = "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";
  final String _baseUrl =
      'https://asia-southeast1-aimedicalapp.cloudfunctions.net';
  Future<String> postMessage(String content,
      {String language = 'en-US',
      List<Message>? messages,
      String? chatGptPrompt}) async {
    final url = Uri.parse('$_baseUrl/completions');
    const int maxRetries = 3;
    int retryCount = 0;
    while (retryCount < maxRetries) {
      try {
        List<Message> messageList = (messages != null && messages.length > 10)
            ? messages.sublist(messages.length - 10)
            : List.from(messages ?? []);
        String responseFormat = chatGptPrompt ?? getResponseFormat;

        messageList.insert(0, Message(role: 'system', content: responseFormat));
        messageList.add(Message(role: 'user', content: content));
        // log(generateResponseFormat(messageList).toString());
        var tempList = generateResponseFormat(messageList);
        log('Sending request to OpenAI: $tempList');
        print('URL: $url');
        final response = await http
            .post(
              url,
              headers: <String, String>{
                'Content-Type': 'application/json; charset=utf-8',
                'Authorization': 'Bearer $_apiKey',
              },
              body: json.encode({
                'model': 'gpt-4',
                'messages': [
                  {
                    'role': 'system',
                    'content':
                        'you are ai chat bot. try to respond to the message'
                  },
                  {'role': 'user', 'content': content}
                ],
              }),
            )
            .timeout(const Duration(seconds: 30));

        if (response.statusCode == 200) {
          final responseBody = json.decode(response.body);
          final apiResponse =
              responseBody['choices'][0]['message']['content'].trim();
          return apiResponse;
        } else {
          final responseBody = json.decode(response.body);
          print("Request failed with status: ${response.statusCode}");
          print("Response body: ${response.body}");
          final errorMessage =
              responseBody['error']?['message'] ?? 'Unknown error';
          throw Exception('Failed to fetch response: $errorMessage');
        }
      } catch (error) {
        log("that is error response : $error");
        retryCount++;
        if (retryCount >= maxRetries) {
          Fluttertoast.showToast(
            msg: 'An error occurred: $error',
          );
          throw Exception(
              'An error occurred after $retryCount retries: $error');
        }
        // Optionally, add a delay between retries
        await Future.delayed(const Duration(seconds: 1));
      }
    }

    // This should not be reached
    throw Exception('Unexpected error: Exceeded max retries');
  }

  List<Map<String, String>> generateResponseFormat(List<Message> messages) {
    List<Map<String, String>> formattedMessages = [];

    for (var message in messages) {
      if (message.role == 'assistant') {
        formattedMessages.add({
          'role': 'assistant',
          'content': message.content,
        });
      } else if (message.role == 'patient' || message.role == 'user') {
        formattedMessages.add({
          'role': 'user',
          'content': message.content,
        });
      } else if (message.role == 'system') {
        formattedMessages.add({
          'role': 'system',
          'content': message.content,
        });
      }
    }

    return formattedMessages;
  }

  String get getResponseFormat {
    return '''
    You are a virtual medical assistant integrated into a doctor consultation app. Your role is to assist users by analyzing their symptoms, medical records, and providing a preliminary diagnosis along with an explanation and suggested treatment options.
    
    Introduction:
    - Greet the user.
    - Briefly explain the purpose of the consultation and how it works.
    - Ensure the user understands that this is a preliminary diagnosis and they should consult a healthcare professional for a final diagnosis and treatment.
    
    Gather Information:
    - Ask the user for their current symptoms.
    - Request any relevant medical history or records they can provide.
    - Inquire about any allergies, current medications, and other health conditions.
    
    Analysis:
    - Analyze the provided symptoms and medical history.
    - Consider potential conditions or diseases that match the symptoms.
    
    Response:
    - Provide a preliminary diagnosis based on the analysis.
    - Offer a detailed explanation of the potential condition.
    - Suggest possible treatments or medications that might be appropriate.
    - Remind the user to consult with a healthcare professional to confirm the diagnosis and treatment.
    
    Disclaimer:
    - Emphasize that the provided information is for educational purposes and not a substitute for professional medical advice.
  ''';
  }
}

class Message {
  final String role;
  final String content;

  Message({
    required this.role,
    required this.content,
  });

  factory Message.fromJson(Map<String, dynamic> json) => Message(
        role: json["role"] ?? json["sender_type"],
        content: json["content"],
      );

  Map<String, dynamic> toJson() => {
        "role": role,
        "content": content,
      };
}
