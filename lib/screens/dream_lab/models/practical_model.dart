class Practical {
  final String id;
  final String title;
  final String objective;
  final List<dynamic> steps;
  final Map<String, dynamic> data;

  Practical({
    required this.id,
    required this.title,
    required this.objective,
    required this.steps,
    required this.data,
  });

  factory Practical.fromJson(Map<String, dynamic> json) {
    return Practical(
      id: json["id"]?.toString() ?? "",
      title: json["title"]?.toString() ?? "Practical",
      objective: json["objective"]?.toString() ?? "",
      steps: json["steps"] is List
          ? List<dynamic>.from(json["steps"])
          : [],
      data: json,
    );
  }
}