import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:musicognizer/manager/CacheManager.dart';

class History extends StatefulWidget {
  const History({Key? key}) : super(key: key);

  @override
  State<History> createState() => _HistoryState();
}

class _HistoryState extends State<History> {

  late InterstitialAd ad;
  late BannerAd bannerAd;
  List<dynamic> cacheList = [];
  String txt = "History";

  Future<void> initList() async {
    ItemStorage.init();
    cacheList = await ItemStorage.getItems();
    updateText();
  }

  void updateText() {
    setState(() {
      txt = 'History ${cacheList.length}';
    });
  }


  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    initList();
    MobileAds.instance.initialize();
    loadBanner();
    loadAd();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    bannerAd.dispose();
    ad.dispose();
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
        size: const AdSize(width:300, height: 50),
        adUnitId: 'ca-app-pub-3940256099942544/6300978111',
        listener: listener,
        request: const AdRequest());
    bannerAd.load();
  }

  void loadAd(){
    InterstitialAd.load(
        adUnitId: 'ca-app-pub-3940256099942544/8691691433',
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (InterstitialAd ad) {
            // Keep a reference to the ad so you can show it later.
            this.ad = ad;
            initAd();
          },
          onAdFailedToLoad: (LoadAdError error) {
            print('InterstitialAd failed to load: $error');
          },
        ));
  }

  void initAd(){
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (InterstitialAd ad) {
        print('%ad onAdShowedFullScreenContent.');
      },
      onAdDismissedFullScreenContent: (InterstitialAd ad) {
        loadAd();
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
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.deepPurple,
        appBar: AppBar(
          title: Text(txt),
          centerTitle: true,
          backgroundColor: Colors.deepPurple,
          elevation: 0,
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: ListView.builder(
              itemCount: cacheList.length,
              itemBuilder: (context, index) {
                return Row(
                  children: [
                    Card(
                      shape: const  RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(15))),
                      clipBehavior: Clip.antiAlias,
                      child: Image(image: MemoryImage(cacheList.elementAt(index)['url'])),
                    ),
                    const SizedBox(width: 10,),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(cacheList.elementAt(index)['trackName']),
                        Text(cacheList.elementAt(index)['musicianName']),
                        Image.asset('images/spotify.png', height: 30, width: 30,color: Colors.white,)
                      ],
                    ),
                  ],
                );
              }),
        ),
        bottomNavigationBar: SizedBox(height:50, child: AdWidget(ad: bannerAd)),
      ),
    );
  }
}
