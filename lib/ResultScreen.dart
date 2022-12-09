import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:musicognizer/model/music_item.dart';
import 'dart:convert' as convert;
import 'package:http/http.dart' as http;

class ResultScreen extends StatefulWidget {
  final MusicItem musicItem;

  const ResultScreen({super.key, required this.musicItem});

  @override
  State<StatefulWidget> createState() => ResultScreenState();
}

class ResultScreenState extends State<ResultScreen> {
  String url = '';
  late String trackUrl;

  Future<void> getMusicInfo() async {
    Map<String, String> headers = <String, String>{
      'X-RapidAPI-Key': '04c7b090d0msh7b5acc88ac42a51p15f0e0jsn8e717c2eab1e',
      'X-RapidAPI-Host': 'spotify-scraper.p.rapidapi.com'
    };
    late Response<String> response;
    var dio = Dio();
// Optionally the request above could also be done as
    response = await dio.get(
        'https://spotify-scraper.p.rapidapi.com/v1/search?term=${widget.musicItem.musicianName}%20${widget.musicItem.trackName}&type=track&offset=1&limit=1',
        options: Options(headers: headers));

    if (response.statusCode == 200) {
      List<dynamic> list =
          convert.jsonDecode(response.data.toString())['tracks']['items'];
      setState(() {
        url = list.last['album']['cover'].first['url'].toString();
        //url = list.elementAt(3);
      });
      print(url.toString());
    }
  }

  Widget AlbumArtImage() {
    if (url.isEmpty) {
      return Card(
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(15))),
        clipBehavior: Clip.antiAlias,
        child: Image.asset(
          "images/img.png",
          width: 400,
          height: 400,
        ),
      );
    } else {
      return Card(
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(15))),
        clipBehavior: Clip.antiAlias,
        child: Image.network(
          url!,
          width: 400,
          height: 400,
        ),
      );
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getMusicInfo();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.deepPurple,
        appBar: AppBar(
          title: const Text('Recognition Result'),
          centerTitle: true,
          backgroundColor: Colors.deepPurple,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            children: [
              const SizedBox(
                height: 20,
              ),
              AlbumArtImage(),
              const SizedBox(
                height: 40,
              ),
              Text(
                widget.musicItem.trackName,
                style: const TextStyle(color: Colors.white, fontSize: 20),
              ),
              Text(
                widget.musicItem.albumName,
                style: const TextStyle(color: Colors.white, fontSize: 20),
              ),
              Text(
                '${widget.musicItem.musicianName} ${widget.musicItem.musicianName2}.',
                style: TextStyle(color: Colors.grey[300], fontSize: 20),
              ),
            ],
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
          },
          label: const Text("Play on Spotify"),
          backgroundColor: Colors.deepPurpleAccent,
          icon: Icon(Icons.library_music),
        ),
      ),
    );
  }
}
