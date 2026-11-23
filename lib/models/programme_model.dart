class ProgrammeModel {
  final String id;
  final String code;
  final String name;
  final int years;

  ProgrammeModel({
    required this.id,
    required this.code,
    required this.name,
    required this.years,
  });

  factory ProgrammeModel.fromJson(Map<String, dynamic> json) {
    int parsedYears = 3;
    final y = json['years'];
    if (y is num) {
      parsedYears = y.toInt();
    } else if (y is String) {
      parsedYears = int.tryParse(y) ?? 3;
    }

    return ProgrammeModel(
      id: json['id'] ?? '',
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      years: parsedYears > 0 ? parsedYears : 3,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'name': name,
        'years': years,
      };
}
