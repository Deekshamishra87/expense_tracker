import 'dart:convert';
import 'package:http/http.dart' as http;
import '../app_config.dart';
// import yeh karo

class GeminiBridgeService {
  static Future<String> getSuggestion(String prompt) async {
    try {
      final response = await http.post(
        Uri.parse(AppConfig.aiServerUrl), // ← yahan use ho rha
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'prompt': prompt}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['reply'] ?? "❌ No suggestion.";
      } else {
        return "⚠️ Error: ${response.statusCode}\n${response.body}";
      }
    } catch (e) {
      return "❌ Failed to connect to local server: $e";
    }
  }
}
