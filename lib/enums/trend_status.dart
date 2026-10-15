enum TrendStatus {
  veryBullish(score: 90.0, description: '현재가가 장기 추세 기준선을 상회하고 중·단기 추세선 이상에 위치한 상태'),
  bullish(score: 75.0, description: '현재가가 장기 추세 기준선을 상회하지만 중·단기 추세선은 하회한 상태'),
  transition(score: 50.0, description: '현재가가 장기 추세 기준선의 ±1.5% 범위에 위치한 상태'),
  bearish(score: 30.0, description: '현재가가 장기 추세 기준선 아래, 하락 심화 참고선 이상에 위치한 상태'),
  deepBearish(score: 20.0, description: '현재가가 하락 심화 참고선 아래, 장기 저점 참고선 이상에 위치한 상태'),
  bottomRange(score: 10.0, description: '현재가가 장기 저점 참고선도 하회한 상태');

  final double score;
  final String description;
  const TrendStatus({required this.score, required this.description});
}
