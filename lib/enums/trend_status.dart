enum TrendStatus {
  veryBullish(score: 90.0, description: '장기 상승 추세가 유지되는 가운데 단기 추세까지 강하게 정렬된 상태'),

  bullish(score: 75.0, description: '1년 이평선 위에 위치하며 장기 상승 추세가 유지되는 상태'),

  transition(score: 50.0, description: '1년 이평선 부근에 위치하여 장기 추세의 방향성이 뚜렷하지 않은 상태'),

  bearish(score: 25.0, description: '1년 이평선 아래에 위치하며 장기 상승 추세가 훼손된 상태'),

  bottomRange(score: 10.0, description: '장기 하락 추세가 진행된 이후 역사적인 바닥권 영역에 진입한 상태');

  final double score;
  final String description;

  const TrendStatus({required this.score, required this.description});
}
