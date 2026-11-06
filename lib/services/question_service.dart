import 'dart:convert'; // <--- ESTA LÍNEA FALTABA
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class QuestionService {
  
  static Future<List<Map<String, dynamic>>> _loadQuestions(String path) async {
    try {
      final jsonString = await rootBundle.loadString(path);
      final List<dynamic> jsonData = jsonDecode(jsonString);
      return jsonData.map((item) => Map<String, dynamic>.from(item)).toList();
    } catch (e) {
      debugPrint('Error cargando preguntas desde $path: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getRandomQuestions({
    required String gameType,
    required String moduleName,
    required int questionCount,
  }) async {
    String path;
    switch (gameType) {
      case 'opcion_multiple':
        path = 'assets/questions/opcion_multiple.json';
        break;
      case 'verdadero_falso':
        path = 'assets/questions/verdadero_falso.json';
        break;
      case 'completar':
        path = 'assets/questions/completar.json';
        break;
      case 'relacionar':
        path = 'assets/questions/relacionar.json';
        break;
      case 'ordenar':
        path = 'assets/questions/ordenar.json';
        break;
      default:
        path = 'assets/questions/opcion_multiple.json';
    }

    List<Map<String, dynamic>> questions = await _loadQuestions(path);
    
    questions.shuffle();

    if (questions.length <= questionCount) {
      return questions;
    }
    return questions.sublist(0, questionCount);
  }
}