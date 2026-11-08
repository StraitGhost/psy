// lib/features/profile_selection/profile_data.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';

class Topic {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  const Topic(this.id, this.name, this.icon, this.color);
}

const List<Topic> topics = [
  Topic('conciencia', 'Conciencia', Icons.wb_sunny_rounded, Color(0xFF1EA7FD)),
  Topic('orientacion', 'Orientación', Icons.explore_rounded, Color(0xFF1FB5A0)),
  Topic('atencion', 'Atención', Icons.center_focus_strong_rounded, Color(0xFFFF5A3C)),
  Topic('memoria', 'Memoria', Icons.memory_rounded, Color(0xFF9B51E0)),
  Topic('percepcion', 'Percepción', Icons.visibility_rounded, Color(0xFF00B8FF)),
  Topic('pensamiento', 'Pensamiento', Icons.psychology_rounded, Color(0xFFE040FB)),
  Topic('sueno', 'Sueño', Icons.nightlight_round, Color(0xFF1C9AB0)),
  Topic('apetito', 'Apetito', Icons.restaurant_rounded, Color(0xFF4CAF50)),
  Topic('sexualidad', 'Sexualidad', Icons.favorite_rounded, Color(0xFFFF8A9B)),
  Topic('sindromes', 'Síndromes', Icons.medical_services_rounded, Color(0xFF78909C)),
];

class UserStats {
  /// Porcentaje 0-100 por id de tema
  final Map<String, double> mastery;

  const UserStats({required this.mastery});

  double get masteryAvg => mastery.isEmpty
      ? 0
      : mastery.values.reduce((a, b) => a + b) / mastery.length;
  double get masteryMax =>
      mastery.isEmpty ? 0 : mastery.values.reduce(math.max);

  factory UserStats.from(Map<String, dynamic> d) {
    final raw = d['topicMastery'];

    // Mapa normalizado: "orientacion" -> valor
    // (acepta "Orientación", "orientacion", etc.)
    final normalized = <String, dynamic>{};
    if (raw is Map) {
      raw.forEach((k, v) => normalized[_norm(k.toString())] = v);
    }

    final mastery = <String, double>{
      for (final t in topics)
        t.id: _topicPercent(
            normalized[_norm(t.id)] ?? normalized[_norm(t.name)]),
    };
    return UserStats(mastery: mastery);
  }
}

/// Minúsculas y sin tildes para comparar claves.
String _norm(String s) {
  const from = 'áàäâéèëêíìïîóòöôúùüûñ';
  const to = 'aaaaeeeeiiiioooouuuun';
  var out = s.trim().toLowerCase();
  for (var i = 0; i < from.length; i++) {
    out = out.replaceAll(from[i], to[i]);
  }
  return out;
}

/// Devuelve porcentaje 0-100.
/// Si el valor es <= 1 se interpreta como fracción (0.15 -> 15%).
double _topicPercent(dynamic v) {
  if (v is num) {
    final d = v.toDouble();
    final pct = d <= 1.0 ? d * 100 : d;
    return pct.clamp(0.0, 100.0);
  }
  if (v is Map) {
    final c = (v['correct'] is num) ? (v['correct'] as num).toInt() : 0;
    final t = (v['total'] is num) ? (v['total'] as num).toInt() : 0;
    return t <= 0 ? 0.0 : (c * 100 / t).clamp(0.0, 100.0);
  }
  return 0.0;
}