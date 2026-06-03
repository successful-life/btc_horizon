import 'package:btc_horizon/models/funding_rate_model.dart';
import 'package:btc_horizon/services/funding_rate_service.dart';
import 'package:btc_horizon/widgets/crypto_card.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class FundingRateCard extends StatefulWidget {
  const FundingRateCard({super.key});

  @override
  State<FundingRateCard> createState() => _FundingRateCardState();
}

class _FundingRateCardState extends State<FundingRateCard> {
  FundingRateModel? fundingRate;
  final FundingRateService service = FundingRateService();
  String? errorMessage;

  @override
  void initState() {
    super.initState();

    fetchData();
  }

  Future<void> fetchData() async {
    try {
      final result = await service.fetchFundingRate();

      if (!mounted) return;

      setState(() {
        fundingRate = result;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = "데이터를 불러올 수 없습니다.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (errorMessage != null) {
      return CryptoCard(
        title: 'Funding Rate',
        value: '$errorMessage',
        subtitle: '바이낸스 선물',
        icon: Icons.error,
        bgColor: Colors.red,
      );
    }

    if (fundingRate == null) {
      return CryptoCard(
        title: 'Funding Rate',
        value: 'Loading …',
        subtitle: '바이낸스 선물',
        icon: Icons.hourglass_top,
        bgColor: Colors.grey,
      );
    }

    return CryptoCard(
      title: 'Funding Rate',
      value: '${(fundingRate!.fundingRate * 100).toStringAsFixed(4)}%',
      subtitle: '바이낸스 선물',
      icon: Icons.attach_money,
      bgColor: Colors.purple,
    );
  }
}
