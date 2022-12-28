import 'dart:async';

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:avatar_glow/avatar_glow.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:musicognizer/model/music_item.dart';
import 'package:musicognizer/screens/About.dart';
import 'package:musicognizer/screens/HistoryScreen.dart';
import 'package:musicognizer/screens/ResultScreen.dart';
import 'package:flutter_acrcloud/flutter_acrcloud.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  HomeState createState() => HomeState();
}

class HomeState extends State<Home> with SingleTickerProviderStateMixin {
  String tap_string = "Tap to Musicognize";

  ACRCloudResponseMusicItem? music;
  String apiKey = "87910d133768f752caba06ae030f7424";
  String apiSecret = "Yp6VwXNMQaj6gP5X2xYZcICNBZKIClSFhRTgQeCZ";
  String host = "identify-eu-west-1.acrcloud.com";
  late BannerAd bannerAd;

  var height = 220.0;
  var width = 220.0;

  bool isListening = false;

  late ACRCloudSession session;

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    session.dispose();
    bannerAd.dispose();
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

  void _animation() {
    Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        height = height == 220.0 ? 190.0 : 220.0;
        width = width == 220.0 ? 190.0 : 220.0;
      });
    });
  }

  startListening() async {}

  Future<void> navigate(BuildContext buildContext, MusicItem item) async {
    music = null;
    isListening = false;
    Navigator.push(
        buildContext,
        MaterialPageRoute(
            builder: (buildContext) => ResultScreen(musicItem: item)));
  }

  @override
  void initState() {
    super.initState();
    MobileAds.instance.initialize();
    _animation();
    ACRCloud.setUp(ACRCloudConfig(apiKey, apiSecret, host));
  }

  @override
  Widget build(BuildContext context) {
    loadBanner();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.deepPurple,
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        appBar: AppBar(
          centerTitle: true,
          backgroundColor: Colors.deepPurple,
          elevation: 0,
          actions: [
            Builder(
              builder: (BuildContext context) {
                return GestureDetector(
                    onTap: () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (context) => About()));
                    },
                    child: const Icon(Icons.info_rounded));
              },
            ),
            const SizedBox(width: 16),
          ],
          // leading: Builder(builder: (context) {
          //   return GestureDetector(
          //     child: const Icon(Icons.library_music_rounded),
          //     onTap: () {
          //       Navigator.push(context,
          //           MaterialPageRoute(builder: (builder) => const History()));
          //     },
          //   );
          // }),
        ),
        body: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 50),
              alignment: Alignment.topCenter,
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    transitionBuilder:
                        (Widget child, Animation<double> animation) {
                      return ScaleTransition(
                        scale: animation,
                        child: child,
                      );
                    },
                    child: Text(
                      tap_string,
                      key: ValueKey<String>(tap_string),
                      style: const TextStyle(
                          fontSize: 25,
                          color: Colors.white,
                          fontFamily: 'ManropeBold'),
                    ),
                  ),
                  AvatarGlow(
                    endRadius: 200,
                    animate: isListening,
                    child: AnimatedContainer(
                      height: height,
                      width: width,
                      duration: const Duration(milliseconds: 1000),
                      child: Container(
                        decoration: BoxDecoration(boxShadow: [
                          BoxShadow(
                            color: Colors.purple.withOpacity(0.2),
                            spreadRadius: 1,
                            blurRadius: 100,
                            offset: const Offset(0, 1),
                          )
                        ]),
                        child: Builder(builder: (context) {
                          return GestureDetector(
                            onTap: () async {
                              setState(() {
                                if (isListening) {
                                  isListening = false;
                                  session.cancel();
                                  session.dispose();
                                } else {
                                  isListening = true;
                                  session = ACRCloud.startSession();
                                }
                              });
                              _animation();
                              final result = await session.result;
                              if (result == null) {
                                setState(() {
                                  isListening = false;
                                });
                                return;
                              } else if (result.metadata == null) {
                                setState(() {
                                  tap_string = "No match found";
                                  isListening = false;
                                });
                                Timer.periodic(const Duration(seconds: 3),
                                    (timer) {
                                  setState(() {
                                    tap_string = "Tap to Musicognize";
                                  });
                                });
                                return;
                              }
                              setState(() {
                                music = result.metadata?.music.first;
                              });
                              if (music != null) {
                                if (!mounted) return;
                                navigate(
                                    context,
                                    MusicItem(
                                        music!.title,
                                        music!.album.name,
                                        music!.artists.first.name,
                                        music!.artists.last.name,
                                        music!.spotifyId));
                                setState(() {
                                  isListening = false;
                                });
                              }
                            },
                            child: const CircleAvatar(
                              backgroundColor: Colors.deepPurpleAccent,
                              child: Icon(
                                Icons.music_note_rounded,
                                size: 100,
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 350,
                    child: Visibility(
                        visible: isListening,
                        child: Wrap(children: [
                          AnimatedTextKit(repeatForever: true, animatedTexts: [
                            RotateAnimatedText('Listening...',
                                textStyle: const TextStyle(
                                    fontSize: 20, color: Colors.white)),
                            RotateAnimatedText('Searching...',
                                textStyle: const TextStyle(
                                    fontSize: 20, color: Colors.white)),
                            RotateAnimatedText('Fetching...',
                                textStyle: const TextStyle(
                                    fontSize: 20, color: Colors.white)),
                          ]),
                        ])),
                  )
                ],
              ),
            ),
            const SizedBox(
              height: 100,
            ),
          ],
        ),
        bottomNavigationBar:
            SizedBox(height: 50, child: AdWidget(ad: bannerAd)),
        floatingActionButton: const Padding(
          padding: EdgeInsets.all(8.0),
          child: Text(
            "Recognize Music in One Tap",
            style: TextStyle(fontFamily: 'ManropeBold', color: Colors.white),
          ),
        ),
      ),
    );
  }
}
