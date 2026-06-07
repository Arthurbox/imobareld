import 'dart:io';

void main() async {
  var process = await Process.start('flutter', ['build', 'web', '--release']);
  var outFile = File('build_stderr.txt').openWrite();
  var sub1 = process.stderr.listen((data) {
    outFile.add(data);
  });
  // Ignore stdout
  var sub2 = process.stdout.listen((_) {}); 
  await process.exitCode;
  await sub1.cancel();
  await sub2.cancel();
  await outFile.close();
}
