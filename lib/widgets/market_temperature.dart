import 'package:flutter/material.dart';

class MarketTemperature extends StatelessWidget {
  //final double _currentTemperature;

  const MarketTemperature({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.blue),
      child: Column(children: [Text('시장 온도'), Text('72/100'), Text('과열')]),
    );
  }
}
