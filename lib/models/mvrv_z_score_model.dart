class MvrvZScoreModel {
  final DateTime timestamp;
  final double mvrvZScore;

  MvrvZScoreModel({required this.timestamp, required this.mvrvZScore});

  factory MvrvZScoreModel.fromJson(Map<String, dynamic> json) {
    print(json['unixTs'].runtimeType);
    return MvrvZScoreModel(
      timestamp: DateTime.fromMillisecondsSinceEpoch((json['unixTs']) * 1000),
      mvrvZScore: (json['mvrvZscore'] as num).toDouble(),
    );
  }
}
