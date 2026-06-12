import 'dart:convert';
import 'dart:io';
import 'package:cloud_functions/cloud_functions.dart';

class RecognizedItem {
  String name;
  String type;
  String genre;

  RecognizedItem({required this.name, required this.type, required this.genre});
}

class ReceiptRecognitionService {
  static final _functions =
      FirebaseFunctions.instanceFor(region: 'asia-northeast1');

  static Future<List<RecognizedItem>> recognizeReceipt(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);

    final ext = imageFile.path.toLowerCase().split('.').last;
    final mediaType = switch (ext) {
      'png' => 'image/png',
      'gif' => 'image/gif',
      'webp' => 'image/webp',
      _ => 'image/jpeg',
    };

    final callable = _functions.httpsCallable(
      'analyzeReceipt',
      options: HttpsCallableOptions(timeout: const Duration(seconds: 120)),
    );
    final result = await callable.call<Map<Object?, Object?>>({
      'imageBase64': base64Image,
      'mediaType': mediaType,
    });

    final data = Map<String, dynamic>.from(result.data);
    final itemsJson = data['items'] as List<dynamic>? ?? [];

    return itemsJson.map((e) {
      final item = Map<String, dynamic>.from(e as Map);
      return RecognizedItem(
        name: (item['name'] as String?) ?? '',
        type: '',
        genre: (item['genre'] as String?) ?? 'その他',
      );
    }).toList();
  }
}
