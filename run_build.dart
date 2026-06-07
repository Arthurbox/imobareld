import 'dart:io';

void main() async {
  print("Starting build...");
  var result = await Process.run('flutter', ['build', 'web', '--release']);
  File('build_out.txt').writeAsStringSync("STDOUT:\n${result.stdout}\n\nSTDERR:\n${result.stderr}");
  print("Build complete. Log written to build_out.txt");
}
