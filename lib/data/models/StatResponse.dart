class StatResponse {
  final String label;
  final double value;
  final int count;

  StatResponse({required this.label, required this.value, required this.count});
  factory StatResponse.fromJson(Map<String, dynamic> json) =>
      StatResponse(label: json['label'], value: (json['value'] as num).toDouble(), count: (json['count'] as num).toInt());
}