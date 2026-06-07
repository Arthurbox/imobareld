import 'dart:convert';
import 'dart:io';

void main() async {
  final url = Uri.parse('https://scmljymzyzirvaveatxh.supabase.co/rest/v1/?apikey=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNjbWxqeW16eXppcnZhdmVhdHhoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ3ODc3OTcsImV4cCI6MjA5MDM2Mzc5N30.knhhmwZJlA_9zxckX6OW6joSqTC9WA4LANd6t5oZs2k');
  final key = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNjbWxqeW16eXppcnZhdmVhdHhoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ3ODc3OTcsImV4cCI6MjA5MDM2Mzc5N30.knhhmwZJlA_9zxckX6OW6joSqTC9WA4LANd6t5oZs2k';

  final request = await HttpClient().getUrl(url);
  request.headers.add('apikey', key);
  request.headers.add('Authorization', 'Bearer $key');
  final response = await request.close();
  
  final stringData = await response.transform(utf8.decoder).join();
  final file = File('profiles_schema.txt');
  
  if (response.statusCode == 200) {
    file.writeAsStringSync('SUCCESS\n');
    final data = json.decode(stringData) as Map<String, dynamic>;
    final definitions = data['definitions'] as Map<String, dynamic>?;
    if (definitions != null && definitions.containsKey('profiles')) {
      final profiles = definitions['profiles'] as Map<String, dynamic>;
      final properties = profiles['properties'] as Map<String, dynamic>;
      file.writeAsStringSync('Profiles Schema Columns:\n${properties.keys.join('\n')}', mode: FileMode.append);
    } else {
      file.writeAsStringSync('Profiles table not found in schema.', mode: FileMode.append);
    }
  } else {
    file.writeAsStringSync('ERROR: ${response.statusCode}\n$stringData');
  }
}
