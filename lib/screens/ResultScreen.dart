import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:musicognizer/manager/CacheManager.dart';
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
  String openUrl = '';
  late List<dynamic> artists;
  late String artist;
  String albumName = '';
  String trackName = '';
  dynamic previewUrl = '';

  Duration sliderValue = Duration.zero;
  Duration sliderPosition = Duration.zero;
  bool isLoaded = false;

  final player = AudioPlayer();

  Future<void> getMusicInfo() async {
    // Your Spotify client ID and client secret
    String clientId = '85f3b1cb78c74ddc90d9c5cd99aaf8d6';
    String clientSecret = 'c96641335bd5460c8a26c778bca10f4c';
    String authUrl = 'https://accounts.spotify.com/api/token';
    String grantType = 'client_credentials';
    String body =
        'grant_type=$grantType&client_id=$clientId&client_secret=$clientSecret';
    var header = {'Content-Type': 'application/x-www-form-urlencoded'};
    http.Response res =
        await http.post(Uri.parse(authUrl), body: body, headers: header);
    print(res.body);
    Map<String, dynamic> json = convert.jsonDecode(res.body);
    String accessToken = json['access_token'];

    var headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $accessToken'
    };
    String query = removeSymbolsAndEncodeSpaces(
        '${widget.musicItem.musicianName} ${widget.musicItem.trackName}');
    print(query);

    body.replaceAll('', ' ');
    var request = http.Request(
        'GET',
        Uri.parse(
            'https://api.spotify.com/v1/search?q=$query&type=track&limit=1'));

    request.headers.addAll(headers);

    http.StreamedResponse streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      print(response.body);
    } else {
      print(response.reasonPhrase);
    }

    if (response.statusCode == 200) {
      Map<String, dynamic> baseUrl = convert.jsonDecode(response.body);
      //print(baseUrl);

      Map<String, dynamic> content = baseUrl['tracks']['items'].elementAt(0);
      openUrl = content['external_urls']['spotify'];
      setState(() {
        url = content['album']['images'].first['url'];
        artists = content['artists'];
        trackName = content['name'];
        albumName = content['album']['name'];
        previewUrl = content['preview_url'];
      });

      setState(() {
        String localArtist = '';
        for (var i = 0; i < artists.length; i++) {
          if (i + 1 != artists.length && artists.length != 1) {
            localArtist = '$localArtist ${artists.elementAt(i)['name']} x';
          } else {
            localArtist = '$localArtist ${artists.elementAt(i)['name']}';
          }
        }
        artist = localArtist;
      });

      setState(() {
        isLoaded = true;
      });

      print(previewUrl);
      print(artists);
      print(openUrl);
      print(url.toString());
    }
  }

  String removeSymbolsAndEncodeSpaces(String input) {
    return input
        .replaceAll(RegExp(r"[^A-Za-z0-9\s]"), "")
        .replaceAll(RegExp(r"\s"), "%20");
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
          child: CachedNetworkImage(
            height: 400,
            width: 400,
            imageUrl: url!,
            progressIndicatorBuilder: (context, url, downloadProgress) =>
                Container(height: 250, width: 250,child: CircularProgressIndicator(value: downloadProgress.progress, strokeWidth: 2.5,)),
            errorWidget: (context, url, error) => const Icon(Icons.error),
          ));
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    print(widget.musicItem.spotifyTackId);
    getMusicInfo();

    player.onDurationChanged.listen((event) {
      setState(() {
        sliderValue = event;
      });
    });

    player.onPositionChanged.listen((event) {
      setState(() {
        sliderPosition = event;
      });
    });
  }

  void setUpPlayer() async {
    await player.setSourceUrl(previewUrl);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoaded) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Colors.deepPurple,
          appBar: AppBar(
            title: Column(
              children: [
                const Text(
                  'Gotten from',
                  style: TextStyle(fontFamily: 'ManropeBold'),
                ),
                Text(
                  '$albumName Album',
                  style: const TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                      fontFamily: 'ManropeBold'),
                )
              ],
            ),
            titleTextStyle:
                const TextStyle(fontSize: 16, overflow: TextOverflow.clip),
            centerTitle: true,
            backgroundColor: Colors.deepPurple,
            elevation: 0,
          ),
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Center(
              child: Column(
                children: [
                  const SizedBox(
                    height: 20,
                  ),
                  AlbumArtImage(),
                  const SizedBox(
                    height: 30,
                  ),
                  Text(
                    trackName,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontFamily: 'ManropeBold'),
                  ),
                  Text(
                    artist,
                    style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                        fontFamily: 'ManropeBold'),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      children: [
                        Slider(
                          value: sliderPosition.inSeconds.toDouble(),
                          onChanged: (value) async {
                            final position = Duration(seconds: value.toInt());
                            await player.seek(position);
                          },
                          max: sliderValue.inSeconds.toDouble(),
                          activeColor: Colors.white,
                          inactiveColor: Colors.grey,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '00:${sliderPosition.inSeconds.toString()}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontFamily: 'ManropeBold'),
                              ),
                              Text(
                                '00:${sliderValue.inSeconds.toString()}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontFamily: 'ManropeBold'),
                              )
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              player.play(UrlSource(previewUrl));
            },
            label: const Text(
              "Play Preview",
              style: TextStyle(fontFamily: 'ManropeBold'),
            ),
            backgroundColor: Colors.deepPurpleAccent,
            icon: const Icon(Icons.play_arrow_rounded),
          ),
        ),
      );
    } else {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Colors.deepPurple,
          body: Center(
            child: AnimatedTextKit(
                repeatForever: true,
                pause: const Duration(seconds: 1),
                animatedTexts: [
                  RotateAnimatedText('Fetching Music Data',
                      textStyle:
                          const TextStyle(fontSize: 20, color: Colors.white)),
                  RotateAnimatedText('Almost Done',
                      textStyle:
                          const TextStyle(fontSize: 20, color: Colors.white)),
                  RotateAnimatedText('Slow Internet Connection',
                      textStyle:
                          const TextStyle(fontSize: 20, color: Colors.white)),
                ]),
          ),
        ),
      );
    }
  }
}
