import 'dart:convert';
import 'dart:io';

void main() {
  final file = File('analyze.json');
  if (!file.existsSync()) return;
  final json = jsonDecode(file.readAsStringSync());
  for (var error in json['diagnostics']) {
    print('${error['problemMessage']} at line ${error['location']['startLine']}');
  }
}
