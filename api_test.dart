
import 'dart:convert';
import 'package:http/http.dart' as http;

// Script to test the live API response for a specific anime slug.
void main() async {
  const String baseUrl = "apimy.ldtp.com";
  const String apiKey = "habib123";
  const String animeSlug = "sakamoto-days-part-2"; // Using a slug from the screenshots

  final url = Uri.https(baseUrl, '/anime/$animeSlug');

  print('Fetching data from: $url');

  try {
    final response = await http.get(
      url,
      headers: {
        'X-API-KEY': apiKey,
      },
    );

    if (response.statusCode == 200) {
      print('\n--- API Response (Status 200) ---');
      // Pretty print the JSON response
      var decodedJson = json.decode(response.body);
      var prettyString = JsonEncoder.withIndent('  ').convert(decodedJson);
      print(prettyString);
    } else {
      print('\n--- API Error ---');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');
    }
  } catch (e) {
    print('\n--- Script Error ---');
    print('An error occurred: $e');
  }
}
