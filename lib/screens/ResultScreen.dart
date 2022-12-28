import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:musicognizer/manager/CacheManager.dart';
import 'package:musicognizer/model/music_item.dart';
import 'dart:convert' as convert;
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher_string.dart';

class ResultScreen extends StatefulWidget {
  final MusicItem musicItem;

  const ResultScreen({super.key, required this.musicItem});

  @override
  State<StatefulWidget> createState() => ResultScreenState();
}

class ResultScreenState extends State<ResultScreen>
    with WidgetsBindingObserver {
  String url = '';
  late String trackUrl;
  String openUrl = '';
  late List<dynamic> artists;
  late String artist;
  String albumName = '';
  String trackName = '';
  String previewUrl = '';
  List<Map<String, dynamic>> recommendedList = [];

  Duration sliderValue = Duration.zero;
  Duration sliderPosition = Duration.zero;
  bool isLoaded = false;
  bool adLoaded = false;

  final player = AudioPlayer();

  late InterstitialAd ad;
  late BannerAd bannerAd;

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
            'https://api.spotify.com/v1/search?q=$query&type=track&limit=10'));

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

      List<dynamic> totalItems = baseUrl['tracks']['items'];

      Map<String, dynamic> content = baseUrl['tracks']['items'].elementAt(0);
      openUrl = content['uri'];

      for (var i = 0; i < totalItems.length; i++) {
        Map<String, dynamic> content = baseUrl['tracks']['items'].elementAt(i);
        Map<String, dynamic> map = HashMap();
        map['albumPic'] = content['album']['images'].elementAt(1)['url'];
        map['artists'] = content['artists'];
        map['trackName'] = content['name'];
        map['previewUrl'] = content['preview_url'];
        map['openUrl'] = content['uri'];
        map['albumName'] = content['album']['name'];
        recommendedList.add(map);
      }

      setState(() {
        url = content['album']['images'].elementAt(1)['url'];
        artists = content['artists'];
        trackName = content['name'];
        albumName = content['album']['name'];
        previewUrl = content['preview_url'];
      });

      setState(() {
        artist = calculateArtists(artists);
      });

      setState(() {
        isLoaded = true;
      });

      cacheMusic();

      print(previewUrl);
      print(artists);
      print(openUrl);
      print(url.toString());
    }
  }

  String calculateArtists(List<dynamic> list) {
    String localArtist = '';
    for (var i = 0; i < list.length; i++) {
      if (i + 1 != list.length && list.length != 1) {
        localArtist = '$localArtist ${list.elementAt(i)['name']} x';
      } else {
        if (i == 0) {
          localArtist = list.elementAt(i)['name'];
        } else {
          localArtist = '$localArtist ${list.elementAt(i)['name']}';
        }
      }
    }
    return localArtist.trim();
  }

  String removeSymbolsAndEncodeSpaces(String input) {
    return input
        .replaceAll(RegExp(r"[^A-Za-z0-9\s]"), "")
        .replaceAll(RegExp(r"\s"), "%20");
  }

  Widget albumCoverImage() {
    if (url.isEmpty) {
      return Card(
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(15))),
        clipBehavior: Clip.antiAlias,
        child: Image.asset(
          "images/img.png",
          width: 400,
          height: 300,
        ),
      );
    } else {
      return Card(
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(15))),
          clipBehavior: Clip.antiAlias,
          child: CachedNetworkImage(
            height: 150,
            width: 150,
            imageUrl: url,
            errorWidget: (context, url, error) => const Icon(Icons.error),
          ));
    }
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    ad.dispose();
    bannerAd.dispose();
    WidgetsBinding.instance.removeObserver(this);
  }

  void loadBanner() {
    final BannerAdListener listener = BannerAdListener(
      // Called when an ad is successfully received.
      onAdLoaded: (Ad ad) => print('Ad loaded.'),
      // Called when an ad request failed.
      onAdFailedToLoad: (Ad ad, LoadAdError error) {
        // Dispose the ad here to free resources.
        ad.dispose();
        print('Ad failed to load: $error');
      },
      // Called when an ad opens an overlay that covers the screen.
      onAdOpened: (Ad ad) => print('Ad opened.'),
      // Called when an ad removes an overlay that covers the screen.
      onAdClosed: (Ad ad) => print('Ad closed.'),
      // Called when an impression occurs on the ad.
      onAdImpression: (Ad ad) => print('Ad impression.'),
    );
    bannerAd = BannerAd(
        size: const AdSize(width: 300, height: 50),
        adUnitId: 'ca-app-pub-6314399559271167/3279067787',
        listener: listener,
        request: const AdRequest());
    bannerAd.load();
  }

  void loadAd() {
    InterstitialAd.load(
        adUnitId: 'ca-app-pub-6314399559271167/7785590324',
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (InterstitialAd ad) {
            // Keep a reference to the ad so you can show it later.
            print("execustion of interstitial ad");
            this.ad = ad;
            setState(() {
              adLoaded = true;
            });
          },
          onAdFailedToLoad: (LoadAdError error) {
            print('InterstitialAd failed to load: $error');
          },
        )).then((value) => ad.show());
  }

  void initAd() {
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (InterstitialAd ad) {
        loadAd();
        print('%ad onAdShowedFullScreenContent.');
      },
      onAdDismissedFullScreenContent: (InterstitialAd ad) {
        print('$ad onAdDismissedFullScreenContent.');
      },
      onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
        print('$ad onAdFailedToShowFullScreenContent: $error');
        ad.dispose();
      },
      onAdImpression: (InterstitialAd ad) => print('$ad impression occurred.'),
    );
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    MobileAds.instance.initialize();
    player.onPositionChanged.listen((value) {
      setState(() {
        sliderValue = value;
      });
    });
    loadAd();
    loadBanner();
    WidgetsBinding.instance.addObserver(this);
    print(widget.musicItem.spotifyTackId);
    getMusicInfo();

    player.onDurationChanged.listen((event) {
      setState(() {
        sliderValue = event;
      });
    });
  }

  Future<void> cacheMusic() async {
    ItemStorage.init();
    Uint8List imageBytes = await ItemStorage.getImageBytesFromUrl(url);
    ItemStorage.addItem(trackName, artist, imageBytes);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoaded) {
      if (adLoaded) {
        Timer(const Duration(seconds: 3), () {
          ad.show();
        });
      }
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Colors.deepPurpleAccent,
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
            backgroundColor: Colors.deepPurpleAccent,
            elevation: 0,
          ),
          body: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  children: [
                    Row(
                      // crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(
                          height: 10,
                        ),
                        albumCoverImage(),
                        const SizedBox(
                          width: 10,
                        ),
                        SizedBox(
                          width: MediaQuery.of(context).size.width - 200,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                trackName,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontFamily: 'ManropeBold'),
                              ),
                              const SizedBox(
                                height: 5,
                              ),
                              Text(
                                artist,
                                style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                    fontFamily: 'ManropeBold'),
                              ),
                              const SizedBox(
                                height: 10,
                              ),
                              Row(
                                children: [
                                  MaterialButton(
                                    shape: const RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadiusDirectional.all(
                                                Radius.circular(20))),
                                    onPressed: () async {
                                      await launchUrlString(openUrl);
                                    },
                                    color: Colors.green,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 8),
                                      child: Row(
                                        children: const [
                                          Icon(
                                            Icons.play_arrow_rounded,
                                            color: Colors.white,
                                          ),
                                          SizedBox(
                                            width: 2,
                                          ),
                                          Text(
                                            "Play on Spotify",
                                            style: TextStyle(
                                                fontFamily: 'ManropeBold',
                                                fontSize: 14,
                                                color: Colors.white),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 5,
                                  ),
                                  MaterialButton(
                                    minWidth: 50,
                                    onPressed: () {
                                      if (player.state == PlayerState.playing) {
                                        player.pause();
                                      } else {
                                        if (player.state ==
                                            PlayerState.paused) {
                                          player.resume();
                                        } else {
                                          player.stop();
                                          player.release();
                                          player.play(UrlSource(previewUrl));
                                        }
                                      }
                                    },
                                    shape: const RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadiusDirectional.all(
                                                Radius.circular(20))),
                                    color: Colors.deepPurple,
                                    child: player.state == PlayerState.playing
                                        ? const Icon(
                                            Icons.pause_rounded,
                                            color: Colors.white,
                                          )
                                        : const Icon(
                                            Icons.play_arrow_rounded,
                                            color: Colors.white,
                                          ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              DraggableScrollableSheet(
                initialChildSize: .75,
                minChildSize: .75,
                maxChildSize: .85,
                builder:
                    (BuildContext context, ScrollController scrollController) {
                  return Container(
                    decoration: BoxDecoration(
                        color: Colors.deepPurple[500],
                        borderRadius: const BorderRadiusDirectional.only(
                            topEnd: Radius.circular(20),
                            topStart: Radius.circular(20))),
                    child: ListView.builder(
                        controller: scrollController,
                        itemCount: recommendedList.length,
                        itemBuilder: (buildContext, position) {
                          if (position != 0) {
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  trackName = recommendedList
                                      .elementAt(position)['trackName'];
                                  artist = calculateArtists(recommendedList
                                      .elementAt(position)['artists']);
                                  url = recommendedList
                                      .elementAt(position)['albumPic'];
                                  albumName = recommendedList
                                      .elementAt(position)['albumName'];
                                  previewUrl = recommendedList
                                      .elementAt(position)['previewUrl'];
                                  openUrl = recommendedList
                                      .elementAt(position)['openUrl'];
                                  player.stop();
                                });
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                    color: Colors.purple[100],
                                    borderRadius:
                                        const BorderRadiusDirectional.all(
                                      Radius.circular(20),
                                    )),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 12),
                                margin: const EdgeInsets.symmetric(
                                    vertical: 8, horizontal: 16),
                                child: Row(children: [
                                  Card(
                                      clipBehavior: Clip.antiAlias,
                                      shape: const RoundedRectangleBorder(
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(20))),
                                      child: CachedNetworkImage(
                                        imageUrl: recommendedList
                                            .elementAt(position)['albumPic'],
                                        placeholder: (context, url) =>
                                            Image.asset('images/img.png'),
                                        errorWidget: (context, url, dyn) =>
                                            Image.asset('images/img.png'),
                                        height: 70,
                                        width: 70,
                                      )),
                                  const SizedBox(
                                    width: 6,
                                  ),
                                  Column(
                                    children: [
                                      SizedBox(
                                        width:
                                            MediaQuery.of(context).size.width -
                                                200,
                                        child: Text(
                                          recommendedList
                                              .elementAt(position)['trackName'],
                                        ),
                                      ),
                                      SizedBox(
                                        width:
                                            MediaQuery.of(context).size.width -
                                                200,
                                        child: Text(
                                          calculateArtists(recommendedList
                                              .elementAt(position)['artists']),
                                        ),
                                      )
                                    ],
                                  )
                                ]),
                              ),
                            );
                          } else {
                            return const Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 10),
                              child: Text(
                                "Suggestions",
                                style: TextStyle(
                                    fontSize: 16, color: Colors.white),
                              ),
                            );
                          }
                        }),
                  );
                },
              ),
            ],
          ),
          bottomNavigationBar: Container(
            color: Colors.deepPurple[500],
            child: SizedBox(height: 50, child: AdWidget(ad: bannerAd)),
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
