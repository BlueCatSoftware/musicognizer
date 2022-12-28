// ignore_for_file: public_member_api_docs

import 'package:about/about.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:musicognizer/screens/HomeScreen.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';

class About extends StatefulWidget {
  About({super.key});

  @override
  State<About> createState() => _AboutState();
}

class _AboutState extends State<About> {
  late PackageInfo packageInfo;

  Future<void> loadPackage() async {
    packageInfo = await PackageInfo.fromPlatform();
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    loadPackage();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isIos = theme.platform == TargetPlatform.iOS ||
        theme.platform == TargetPlatform.macOS;

    String description =
        'An app that recognize music with a matter of seconds, very powerful and fast with high accuracy';

    final aboutPage = AboutPage(
        scaffoldBuilder: (context, title, body) {
          return Scaffold(
            backgroundColor: Colors.deepPurple,
            appBar: AppBar(
              leading: InkWell(
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const Home()),
                  );
                },
                child: const Icon(Icons.arrow_back_rounded),
              ),
              title: title,
              elevation: 0,
              backgroundColor: Colors.deepPurple,
            ),
            body: body,
          );
        },
        values: {
          'version': '1.0',
          'year': DateTime.now().year.toString(),
          'author': 'Ameen',
        },
        title: const Text('About'),
        applicationVersion: 'Version 1.0',
        applicationDescription: Text(
          description,
          textAlign: TextAlign.center,
        ),
        applicationIcon: const FlutterLogo(size: 100),
        applicationLegalese: 'Copyright © {{ author }}, {{ year }}',
        children: <Widget>[
          items(
              title: const Text('Rate Us'),
              subtitle: const Text('Please rate us on google play store'),
              click: () async {
                await launchUrlString('market://details?id=com.ameen.musicognizer.musicognizer');
              },
              icon: const Icon(Icons.star_rate)),
          items(
            subtitle: const Text('Check out dev on Github'),
            click: () async {
              await launchUrlString('https://github.com/BlueCatSoftware');
            },
            title: const Text('Github'),
            icon: const Icon(Icons.link_rounded),
          ),
          items(
            subtitle: const Text('You can help by donating on paypal'),
            click: () {
              Clipboard.setData(
                  const ClipboardData(text: 'reinvent650@gmail.com'));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('reinvent650@gmail.com has been copied'),
                  duration: Duration(seconds: 3),
                ),
              );
            },
            title: const Text('Donate'),
            icon: const Icon(Icons.monetization_on_rounded),
          )
        ]);

    if (isIos) {
      return CupertinoApp(
        title: 'About Demo (Cupertino)',
        home: aboutPage,
        theme: CupertinoThemeData(
          brightness: theme.brightness,
        ),
      );
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Musicognizer',
      home: aboutPage,
      theme: ThemeData(),
      darkTheme: ThemeData(brightness: Brightness.dark),
    );
  }
}

Widget items(
    {required Text title,
    required Text subtitle,
    required Function() click,
    required Widget icon}) {
  return ListTile(
    contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
    title: title,
    subtitle: subtitle,
    leading: icon,
    onTap: click,
  );
}
