import 'dart:async';

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:avatar_glow/avatar_glow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_acrcloud/flutter_acrcloud.dart';
import 'package:musicognizer/ResultScreen.dart';
import 'package:musicognizer/model/music_item.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with SingleTickerProviderStateMixin {
  String tap_string = "Tap to Musicognize";

  ACRCloudResponseMusicItem? music;
  String apiKey = "87910d133768f752caba06ae030f7424";
  String apiSecret = "Yp6VwXNMQaj6gP5X2xYZcICNBZKIClSFhRTgQeCZ";
  String host = "identify-eu-west-1.acrcloud.com";

  var height = 220.0;
  var width = 220.0;

  bool isListening = false;

  late ACRCloudSession session;

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
    _animation();
    ACRCloud.setUp(ACRCloudConfig(apiKey, apiSecret, host));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.deepPurple,
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        appBar: AppBar(
          title: const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              'Musicognizer',
              style: TextStyle(fontSize: 25),
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.deepPurple,
          elevation: 0,
          actions: const [
            Icon(Icons.history),
            SizedBox(width: 16),
          ],
          leading: const Icon(Icons.library_music),
        ),
        body: Column(
          children: [
            const SizedBox(height: 60),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return ScaleTransition(
                  scale: animation,
                  child: child,
                );
              },
              child: Text(
                tap_string,
                key: ValueKey<String>(tap_string),
                style: const TextStyle(fontSize: 28, color: Colors.white),
              ),
            ),
            Expanded(
              flex: 1,
              child: Center(
                  child: AvatarGlow(
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
                            Timer.periodic(const Duration(seconds: 3), (timer) {
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
                                MusicItem(music!.title, music!.album.name,
                                    music!.artists.first.name, music!.artists.last.name ));
                            setState(() {
                              isListening = false;
                            });
                          }
                        },
                        child: const CircleAvatar(
                          backgroundColor: Colors.deepPurpleAccent,
                          child: Icon(
                            Icons.music_note,
                            size: 100,
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              )),
            ),
            const SizedBox(
              height: 70,
            ),
            Expanded(
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
                    ]))),
            if (music != null) ...[
              // Text('Track: ${music!.title}\n'),
              // Text('Album: ${music!.album.name}\n'),
              // Text('Artist: ${music!.artists.first.name}\n'),
            ]
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {},
          backgroundColor: Colors.deepPurpleAccent,
          label: const Text("Search Music"),
          icon: const Icon(Icons.queue_music_rounded),
        ),
      ),
    );
  }
}
