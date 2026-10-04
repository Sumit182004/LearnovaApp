import 'package:flutter/material.dart';

double toDouble(dynamic value) {
  if (value == null) return 0;

  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(value.toString()) ?? 0;
}

int toInt(dynamic value) {
  if (value == null) return 0;

  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value.toString()) ?? 0;
}

String capitalize(String value) {
  if (value.isEmpty) return value;

  return value[0].toUpperCase() +
      value.substring(1).toLowerCase();
}

String formatTopic(String topic) {
  return topic
      .replaceAll("_", " ")
      .replaceAll("-", " ")
      .split(" ")
      .map((word) {
    if (word.isEmpty) return word;

    return word[0].toUpperCase() +
        word.substring(1).toLowerCase();
  })
      .join(" ");
}

String formatChapter(String chapter) {
  return chapter
      .replaceAll(".json", "")
      .replaceAll("_", " ")
      .replaceAll("-", " ")
      .split(" ")
      .map((word) {
    if (word.isEmpty) return word;

    return word[0].toUpperCase() +
        word.substring(1).toLowerCase();
  })
      .join(" ");
}

Color scoreColor(double score) {
  if (score >= 75) {
    return Colors.cyanAccent;
  }

  if (score >= 40) {
    return Colors.orangeAccent;
  }

  return Colors.redAccent;
}

IconData subjectIcon(String subject) {
  final normalized = subject.toLowerCase();

  if (normalized.contains("math")) {
    return Icons.calculate_rounded;
  }

  if (normalized.contains("science")) {
    return Icons.science_rounded;
  }

  if (normalized.contains("physics")) {
    return Icons.bolt_rounded;
  }

  if (normalized.contains("chemistry")) {
    return Icons.science_outlined;
  }

  if (normalized.contains("english")) {
    return Icons.translate_rounded;
  }

  if (normalized.contains("biology")) {
    return Icons.biotech_rounded;
  }

  return Icons.menu_book_rounded;
}

BoxDecoration cardDecoration() {
  return BoxDecoration(
    color: const Color(0xff1A173B).withOpacity(0.72),
    borderRadius: BorderRadius.circular(17),
    border: Border.all(
      color: Colors.white.withOpacity(0.07),
    ),
  );
}