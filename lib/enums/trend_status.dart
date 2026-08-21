enum TrendStatus {
  /// 장기 추세 기준선 위에 위치하면서
  /// 상단 추세 기준선까지 상회하는 강한 상승 상태
  veryBullish(score: 90.0, description: '장기 상승 추세가 유지되는 가운데 단기 추세까지 강하게 정렬된 상태'),

  /// 장기 추세 기준선 위에 위치하지만
  /// 상단 추세 기준선은 하회하는 상태
  bullish(score: 75.0, description: '장기 추세 기준선 위에서 상승 추세가 유지되는 상태'),

  /// 장기 추세 기준선 부근에 위치하여
  /// 상승과 하락 추세의 전환 가능성이 높은 상태
  transition(score: 50.0, description: '장기 추세 기준선 부근에서 상승과 하락 추세의 전환 가능성이 나타나는 상태'),

  /// 장기 추세 기준선 아래에 위치하지만
  /// 하락 깊이 기준선에는 아직 도달하지 않은 상태
  bearish(score: 30.0, description: '장기 추세 기준선 아래에서 하락 추세가 진행되는 상태'),

  /// 하락 깊이 기준선을 하회하여
  /// 장기 하락이 더욱 심화된 상태
  deepBearish(score: 20.0, description: '장기 하락 추세가 심화되어 깊은 하락 구간에 진입한 상태'),

  /// 바닥권 기준선을 하회하여
  /// 역사적으로 낮은 가격 영역에 진입한 상태
  bottomRange(score: 10.0, description: '장기 하락이 충분히 진행된 이후 역사적으로 낮은 가격 영역에 진입한 상태');

  final double score;
  final String description;

  const TrendStatus({required this.score, required this.description});
}
