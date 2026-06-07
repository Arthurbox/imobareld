import 'dart:io';

void main() async {
  var process = await Process.start('flutter', ['build', 'web', '--release']);
  var outFile = File('build_errors.txt').openWrite();
  process.stdout.transform(SystemEncoding().decoder).listen((data) {
    if (data.toLowerCase().contains("error")) {
      outFile.write(data);
    }
  });
  process.stderr.transform(SystemEncoding().decoder).listen((data) {
    outFile.write(data);
  });
  await process.exitCode;
  outFile.close();
}
