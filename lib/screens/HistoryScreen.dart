import 'package:flutter/material.dart';

class History extends StatefulWidget {
  const History({Key? key}) : super(key: key);

  @override
  State<History> createState() => _HistoryState();
}

class _HistoryState extends State<History> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.deepPurple,
        appBar: AppBar(
          title: const Text('Recently Musicognized'),
          centerTitle: true,
          backgroundColor: Colors.deepPurple,
          elevation: 0,
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: ListView.builder(
              itemCount: 10,
              itemBuilder: (context, index) {
                return Row(
                  children: [
                    Card(
                      shape: const  RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(15))),
                      clipBehavior: Clip.antiAlias,
                      child: Image.asset(
                        'images/img.png',
                        height: 80,
                        width: 80,
                      ),
                    ),
                    const SizedBox(width: 10,),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Title Me'),
                        const Text('By Ameen'),
                        Image.asset('images/spotify.png', height: 30, width: 30,color: Colors.white,)
                      ],
                    ),
                  ],
                );
              }),
        ),
      ),
    );
  }
}
