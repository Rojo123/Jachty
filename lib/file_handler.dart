import "dart:io";
import "dart:async";
import "package:path_provider/path_provider.dart";

Future handleFile(bool write, [String value = ""]) async {
  Future<File> getFile() async {
    final path = await getApplicationDocumentsDirectory();
    return File("${path.path}/token");
  }

  if(write){
    final file = await getFile();
    await file.writeAsString(value);
    return 1;

  } else {
    try {
      final file = await getFile();
      final stringForm = await file.readAsString();
      return stringForm != "" ? stringForm.split(";") : ["0", "0", "0"];

    } catch(e) {
      return ["0", "0", "0"];
    }

  }
}