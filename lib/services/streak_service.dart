// lib/services/streak_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StreakService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final String? _uid = FirebaseAuth.instance.currentUser?.uid;

  /// Llama a este método cuando el usuario completa una lección exitosamente
  static Future<void> updateStreakOnLessonCompleted() async {
    if (_uid == null) return;

    final userRef = _firestore.collection('usuarios').doc(_uid);
    final userDoc = await userRef.get();
    
    if (!userDoc.exists) return;

    final userData = userDoc.data() as Map<String, dynamic>;
    final int currentStreak = (userData['currentStreak'] ?? 0) as int;
    
    // 1. Fecha de hoy (solo año, mes, día, sin horas)
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // 2. Fecha de la última lección
    DateTime? lastLessonDate;
    if (userData['lastLessonDate'] != null && userData['lastLessonDate'] is Timestamp) {
      final date = (userData['lastLessonDate'] as Timestamp).toDate();
      lastLessonDate = DateTime(date.year, date.month, date.day);
    }

    int newStreak = currentStreak;

    // 3. Lógica de la racha
    if (lastLessonDate == null) {
      newStreak = 1; // Primera vez
    } else {
      final differenceInDays = today.difference(lastLessonDate).inDays;
      
      if (differenceInDays == 0) {
        newStreak = currentStreak; // Ya jugó hoy, se mantiene
      } else if (differenceInDays == 1) {
        newStreak = currentStreak + 1; // Jugó ayer, ¡racha consecutiva!
      } else {
        newStreak = 1; // Pasó más de un día, se reinicia (pero a 1, no a 0)
      }
    }

    // 4. Guardar en Firestore
    await userRef.update({
      'currentStreak': newStreak,
      'lastLessonDate': Timestamp.fromDate(today),
    });
  }
}