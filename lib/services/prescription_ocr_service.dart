import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrMedicineSuggestion {
  final String name;
  final String dosage;
  final String rawText;

  const OcrMedicineSuggestion({
    required this.name,
    required this.dosage,
    required this.rawText,
  });
}

class PrescriptionOcrService {
  PrescriptionOcrService._();

  static final RegExp _dosePattern = RegExp(
    r'(\d+\s*(mg|mcg|g|ml)|\d+\s*\+\s*\d+\s*\+\s*\d+|tab|tablet|cap|capsule|syrup|drop|inj|injection|cream)',
    caseSensitive: false,
  );

  static final List<String> _ignoredWords = [
    'doctor',
    'dr.',
    'patient',
    'name',
    'age',
    'date',
    'phone',
    'address',
    'rx',
    'advice',
    'follow',
    'test',
    'report',
    'diagnosis',
    'hospital',
    'clinic',
  ];

  static Future<List<OcrMedicineSuggestion>> scanImages(
    List<String> imagePaths,
  ) async {
    final recognizer = TextRecognizer();
    final lines = <String>[];

    try {
      for (final path in imagePaths) {
        if (path.trim().isEmpty || !File(path).existsSync()) continue;
        final inputImage = InputImage.fromFilePath(path);
        final recognizedText = await recognizer.processImage(inputImage);
        lines.addAll(recognizedText.text.split('\n'));
      }
    } finally {
      await recognizer.close();
    }

    return parseLines(lines);
  }

  static List<OcrMedicineSuggestion> parseLines(List<String> lines) {
    final suggestions = <OcrMedicineSuggestion>[];
    final seen = <String>{};

    for (final line in lines) {
      final cleaned = _cleanLine(line);
      if (!_looksLikeMedicine(cleaned)) continue;

      final suggestion = _toSuggestion(cleaned);
      final key = suggestion.name.toLowerCase();
      if (key.isEmpty || seen.contains(key)) continue;

      seen.add(key);
      suggestions.add(suggestion);
    }

    return suggestions;
  }

  static String _cleanLine(String line) {
    return line
        .replaceAll(RegExp(r'^[\s\-\*\d\.\)\(]+'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static bool _looksLikeMedicine(String line) {
    if (line.length < 3 || line.length > 90) return false;

    final lower = line.toLowerCase();
    if (_ignoredWords.any(lower.contains)) return false;

    return _dosePattern.hasMatch(line) ||
        RegExp(r'^[A-Za-z][A-Za-z0-9\-\s]{2,}$').hasMatch(line);
  }

  static OcrMedicineSuggestion _toSuggestion(String line) {
    final doseMatch = _dosePattern.firstMatch(line);
    var name = line;
    var dosage = '';

    if (doseMatch != null) {
      dosage = doseMatch.group(0)?.replaceAll(RegExp(r'\s+'), '') ?? '';
      name = line.substring(0, doseMatch.start).trim();
    }

    name = name
        .replaceAll(RegExp(r'\b(tab|tablet|cap|capsule|syrup|drop|inj)\b',
            caseSensitive: false), '')
        .replaceAll(RegExp(r'[:\-]+$'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (name.isEmpty) name = line;

    return OcrMedicineSuggestion(
      name: name,
      dosage: dosage.isEmpty ? 'As prescribed' : dosage,
      rawText: line,
    );
  }
}
