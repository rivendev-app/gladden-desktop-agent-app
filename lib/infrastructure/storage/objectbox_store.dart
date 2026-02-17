import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../objectbox.g.dart'; // generated code

class ObjectBoxStore {
  late final Store store;

  ObjectBoxStore._create(this.store);

  static Future<ObjectBoxStore> create() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final storeDir = p.join(docsDir.path, 'gladden_data');
    print('Opening ObjectBox at: $storeDir');
    
    final dir = Directory(storeDir);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    try {
      final store = await openStore(directory: storeDir);
      return ObjectBoxStore._create(store);
    } catch (e) {
      print('ObjectBox initialization failed: $e');
      rethrow;
    }
  }
}
