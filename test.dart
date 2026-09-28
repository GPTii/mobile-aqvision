import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final url = Uri.parse('https://dev1.aqvision.net/api/media/index/api/webrtc?app=live&stream=cam1&type=play');
  print('Requesting: $url');
  
  final res = await http.post(
    url,
    headers: {
      'Content-Type': 'text/plain',
      'Authorization': 'Bearer test',
    },
    body: utf8.encode('test'),
  );
  
  print('Status: ${res.statusCode}');
  print('Body: ${res.body}');
  print('Headers: ${res.headers}');
}
