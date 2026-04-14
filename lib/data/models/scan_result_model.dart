class ScanResultModel {
  final int? id;
  final String title;
  final String score;
  final String imagePath;
  final DateTime timestamp;

  ScanResultModel({
    this.id,
    required this.title,
    required this.score,
    required this.imagePath,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'score': score,
      'imagePath': imagePath,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory ScanResultModel.fromMap(Map<String, dynamic> map) {
    return ScanResultModel(
      id: map['id'],
      title: map['title'],
      score: map['score'],
      imagePath: map['imagePath'],
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
}
