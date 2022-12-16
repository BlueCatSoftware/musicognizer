import 'dart:collection';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';


class MusicognitionsManager {
  late String trackName;
  late String musicianName;
  late String imageUrl;
  late String albumName;
  late String previewUrl;

  MusicognitionsManager(Builder builder){
    trackName = builder.trackName;
    musicianName = builder.musicianName;
    imageUrl = builder.imageUrl;
    albumName = builder.albumName;
    previewUrl = builder.previewUrl;
  }
  static Future<List<Map>> getCachedMusicInfo() async {
    List<Map> list = [];
    final prefs = await SharedPreferences.getInstance();
    List<String> keys = prefs.getStringList('key')!;
    for(var key in keys){
      final pref = await SharedPreferences.getInstance();
      Map<String, String> map = jsonDecode(pref.getString(key)!);
      list.add(map);
    }
    return list;
  }
}

class Builder {
  late String trackName;
  late String musicianName;
  late String imageUrl;
  late String albumName;
  late String previewUrl;

  Builder addTrackName(String trackName){
    this.trackName = trackName;
    return this;
  }

  Builder addMusicianName(String musicianName){
    this.musicianName = musicianName;
    return this;
  }

  Builder addImageUrl(String imageUrl){
    this.imageUrl = imageUrl;
    return this;
  }

  Builder addAlbumName(String albumName){
    this.albumName = albumName;
    return this;
  }

  Builder addPreviewUrl(String previewUrl){
    this.previewUrl = previewUrl;
    return this;
  }

  Future<Builder> cacheMusic(String key) async {
    Map<String, String> map = HashMap();
    map['trackName'] = trackName;
    map['musicianName'] = musicianName;
    map['imageUrl'] = imageUrl;
    map['albumName'] = albumName;
    map['previewUrl'] = previewUrl;

    // Obtain shared preferences.
    final prefs = await SharedPreferences.getInstance();
    List<String> keys = prefs.getStringList('keys')!;
    keys.add(key);
    prefs.setString(key, map.toString());
    return this;
  }
}
