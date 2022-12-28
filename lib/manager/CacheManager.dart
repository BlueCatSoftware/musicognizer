import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

import 'package:shared_preferences/shared_preferences.dart';

class ItemStorage {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static Future<void> addItem(String title, String subtitle, Uint8List imageBytes) async {
    if (_prefs == null) {
      throw Exception('SharedPreferences not initialized');
    }

    var item = {
      'trackName': title,
      'musicianName': subtitle,
      'url': imageBytes,
    };
    List<dynamic> items = await getItems();
    items.add(item);
    String itemsJson = jsonEncode(items);
    _prefs?.setString('items', itemsJson);
  }

  static Future<List<dynamic>> getItems() async {
    if (_prefs == null) {
      init();
    }

    List<dynamic> itemsJson = _prefs?.getString('items') as List;
    if (itemsJson == null) {
      return [];
    }
    return itemsJson;
  }

  static Future<Uint8List> getImageBytesFromUrl(String url) async {
    http.Response response = await http.get(Uri.parse(url));
    return response.bodyBytes;
  }
}
