import 'dart:io';
import 'package:flutter/material.dart';
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
    r'(\d+\s*(mg|mcg|g|ml)(\s*\+\s*\d+\s*(mg|mcg|g|ml))*'
    r'|\d+\s*\+\s*\d+\s*\+\s*\d+'
    r'|tab\.?|tablet\.?|cap\.?|capsule|syrup|drop|inj\.?|injection|cream|ointment)',
    caseSensitive: false,
  );

  static final RegExp _medicineRequiredPattern = RegExp(
    r'(\d+\s*(mg|mcg|g|ml)(\s*\+\s*\d+\s*(mg|mcg|g|ml))*'
    r'|\d+\s*\+\s*\d+\s*\+\s*\d+'
    r'|\btab\.?\b|\btablet\.?\b|\bcap\.?\b|\bcapsule\b|\bsyrup\b'
    r'|\bdrop\b|\binj\.?\b|\binjection\b|\bcream\b|\bointment\b'
    r'|\binhaler\b|\bpuff\b|\brespule\b)',
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
    'cbc',
    'blood',
    'urine',
    'x-ray',
    'xray',
    'ecg',
    'eeg',
    'ultrasound',
    'usg',
    'mri',
    'ct',
    'scan',
    'culture',
    'fbs',
    'ppbs',
    'hba1c',
    'lipid',
    'profile',
    'tsh',
    'serum',
    'creatinine',
    'bilirubin',
    'sgpt',
    'sgot',
    'cholesterol',
    'triglyceride',
    'wbc',
    'rbc',
    'platelet',
    'hemoglobin',
    'hb',
    'esr',
    'crp',
    'stool',
    'sputum',
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

        // ✅ Image size বের করি
        final imageSize = await _getImageSize(path);
        final imgWidth = imageSize.width;
        final imgHeight = imageSize.height;

        // ✅ Top 20% এবং Bottom 10% বাদ দেব (doctor info / footer)
        final topCutoff = imgHeight * 0.20;
        final bottomCutoff = imgHeight * 0.90;

        // ✅ Left 20% এবং Right 20% বাদ দেব (tests / instructions)
        final leftCutoff = imgWidth * 0.20;
        final rightCutoff = imgWidth * 0.80;

        for (final block in recognizedText.blocks) {
          for (final line in block.lines) {
            final rect = line.boundingBox;

            // Center zone এর বাইরে হলে skip
            if (rect.top < topCutoff) continue;
            if (rect.bottom > bottomCutoff) continue;
            if (rect.left < leftCutoff) continue;
            if (rect.right > rightCutoff) continue;

            lines.add(line.text);
          }
        }
      }
    } finally {
      await recognizer.close();
    }

    return parseLines(lines);
  }

  // ✅ Image dimensions বের করার helper
  static Future<Size> _getImageSize(String imagePath) async {
    final bytes = await File(imagePath).readAsBytes();
    final decoded = await decodeImageFromList(bytes);
    return Size(decoded.width.toDouble(), decoded.height.toDouble());
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
    if (_ignoredWords.any((w) => lower.contains(w))) return false;
    if (RegExp(r'^[\d\s\-\/\+\.\,\(\)]+$').hasMatch(line)) return false;

    final wordCount = line.trim().split(RegExp(r'\s+')).length;
    if (wordCount > 7) return false;

    return _medicineRequiredPattern.hasMatch(line);
  }

  static OcrMedicineSuggestion _toSuggestion(String line) {
    final combinedDoseMatch = RegExp(
      r'\d+\s*(mg|mcg|g|ml)(\s*\+\s*\d+\s*(mg|mcg|g|ml))+',
      caseSensitive: false,
    ).firstMatch(line);

    final doseMatch = combinedDoseMatch ?? _dosePattern.firstMatch(line);

    var name = line;
    var dosage = '';

    if (doseMatch != null) {
      dosage = doseMatch.group(0)?.replaceAll(RegExp(r'\s+'), '') ?? '';
      name = line.substring(0, doseMatch.start).trim();
    }

    name = name
        .replaceAll(
          RegExp(
            r'\b(tab\.?|tablet\.?|cap\.?|capsule|syrup|drop|inj\.?|injection|ointment|cream)\b',
            caseSensitive: false,
          ),
          '',
        )
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
