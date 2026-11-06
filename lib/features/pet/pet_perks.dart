// lib/features/pet/pet_perks.dart
import 'package:cloud_firestore/cloud_firestore.dart';

import 'pet_catalog.dart';

// ─────────────────────────────────────────────────────────────
// Tipos de beneficio
// ─────────────────────────────────────────────────────────────
enum PerkType { xpPercent, gemPercent, dailyGems, hints, weeklyShield, monthlyFreeze }

String _fmt(num v) {
  final d = v.toDouble();
  return d == d.roundToDouble() ? d.round().toString() : d.toStringAsFixed(1);
}

class Perk {
  final PerkType type;
  final double base; // valor a nivel 1
  final double max; // valor a nivel 20

  const Perk(this.type, this.base, [double? maxValue]) : max = maxValue ?? base;

  /// Valor según el nivel de la mascota (sube hasta el nivel 20).
  double at(int level) {
    final l = level.clamp(1, 20);
    return base + (max - base) * (l - 1) / 19;
  }

  String get emoji => switch (type) {
        PerkType.xpPercent => '⚡',
        PerkType.gemPercent => '💎',
        PerkType.dailyGems => '🎁',
        PerkType.hints => '💡',
        PerkType.weeklyShield => '🛡️',
        PerkType.monthlyFreeze => '❄️',
      };

  String label(num v) => switch (type) {
        PerkType.xpPercent => '+${_fmt(v)}% de XP',
        PerkType.gemPercent => '+${_fmt(v)}% de gemas',
        PerkType.dailyGems => '+${_fmt(v)} 💎 en el regalo diario',
        PerkType.hints => '${v.round()} pista${v.round() == 1 ? '' : 's'} gratis al día',
        PerkType.weeklyShield => '1 escudo de racha gratis por semana',
        PerkType.monthlyFreeze => '1 congelador de racha gratis al mes',
      };

  /// "+3% de XP · máx +8% de XP"
  String get rangeText =>
      base == max ? label(base) : '${label(base)} · máx ${label(max)}';
}

/// Poderes de cada especie. Mientras más rara, más poderes y más fuertes.
const speciesPerks = <String, List<Perk>>{
  // Comunes
  'dog': [Perk(PerkType.xpPercent, 3, 8)],
  'cat': [Perk(PerkType.gemPercent, 3, 8)],
  'rabbit': [Perk(PerkType.dailyGems, 2, 6)],
  // Raras
  'panda': [Perk(PerkType.xpPercent, 5, 12)],
  'fox': [Perk(PerkType.gemPercent, 5, 12)],
  'wolf': [Perk(PerkType.xpPercent, 8, 18)],
  // Épicas
  'owl': [Perk(PerkType.hints, 1, 3), Perk(PerkType.xpPercent, 6, 12)],
  'unicorn': [Perk(PerkType.xpPercent, 12, 25), Perk(PerkType.dailyGems, 5, 15)],
  // Legendarias
  'dragon': [Perk(PerkType.xpPercent, 15, 30), Perk(PerkType.weeklyShield, 1)],
  'phoenix': [
    Perk(PerkType.xpPercent, 20, 40),
    Perk(PerkType.gemPercent, 10, 20),
    Perk(PerkType.monthlyFreeze, 1),
  ],
};

// ─────────────────────────────────────────────────────────────
// Rareza → regalo diario base
// ─────────────────────────────────────────────────────────────
extension RarityPerksX on Rarity {
  int get dailyBase => switch (this) {
        Rarity.common => 5,
        Rarity.rare => 10,
        Rarity.epic => 20,
        Rarity.legendary => 40,
      };

  String get stars => '⭐' * (index + 1);

  String get powerText => switch (this) {
        Rarity.common => 'Un poder pequeño',
        Rarity.rare => 'Un poder mediano',
        Rarity.epic => 'Dos poderes fuertes',
        Rarity.legendary => 'Poderes máximos y regalos especiales',
      };
}

// ─────────────────────────────────────────────────────────────
// Helper público para usar en el resto de la app
//
// Ejemplo al dar XP por una respuesta correcta:
//   final xp = (base * XpBoost.multiplierFor(d) * (1 + PetPerks.xpPercent(d) / 100)).round();
// o simplemente:
//   final xp = PetPerks.applyXp(d, base * XpBoost.multiplierFor(d));
//
// `d` es el Map del documento usuarios/{uid}.
// ─────────────────────────────────────────────────────────────
class PetPerks {
  /// Los poderes solo funcionan si la mascota está bien cuidada.
  static bool isActive(PetState p) => p.hunger >= 25 && p.average >= 50;

  static String todayKey() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  static PetState? activePet(Map<String, dynamic> d) {
    final raw = d['pets'];
    if (raw is! Map || raw.isEmpty) return null;
    final id = (d['activePet'] as String?) ?? raw.keys.first.toString();
    final v = raw[id] ?? raw.values.first;
    if (v is! Map) return null;
    return PetState.fromMap(id, Map<String, dynamic>.from(v)).decayed(DateTime.now());
  }

  static double total(Map<String, dynamic> d, PerkType type) {
    final pet = activePet(d);
    if (pet == null || !isActive(pet)) return 0;
    final lvl = levelFromXp(pet.xp).level;
    var sum = 0.0;
    for (final p in speciesPerks[pet.id] ?? const <Perk>[]) {
      if (p.type == type) sum += p.at(lvl);
    }
    return sum;
  }

  static double xpPercent(Map<String, dynamic> d) => total(d, PerkType.xpPercent);
  static double gemPercent(Map<String, dynamic> d) => total(d, PerkType.gemPercent);

  static int applyXp(Map<String, dynamic> d, num baseXp) =>
      (baseXp * (1 + xpPercent(d) / 100)).round();

  static int applyGems(Map<String, dynamic> d, num baseGems) =>
      (baseGems * (1 + gemPercent(d) / 100)).round();

  /// Regalo diario = base por rareza + 1 por nivel (máx +20) + poder de la especie.
  static int dailyGift(PetState pet, PetSpecies s) {
    final lvl = levelFromXp(pet.xp).level;
    var bonus = 0.0;
    for (final p in speciesPerks[s.id] ?? const <Perk>[]) {
      if (p.type == PerkType.dailyGems) bonus += p.at(lvl);
    }
    return s.rarity.dailyBase + (lvl - 1).clamp(0, 20) + bonus.round();
  }

  // ── Pistas gratis (Búho) ──
  static int hintsPerDay(Map<String, dynamic> d) => total(d, PerkType.hints).round();

  static int hintsLeft(Map<String, dynamic> d) {
    final perDay = hintsPerDay(d);
    final used = d['petHintDate'] == todayKey() ? asInt(d['petHintsUsed']) : 0;
    return (perDay - used).clamp(0, 99);
  }

  /// Gasta una pista gratis. Devuelve true si había disponible.
  static Future<bool> useHint(DocumentReference<Map<String, dynamic>> ref) {
    return FirebaseFirestore.instance.runTransaction<bool>((tx) async {
      final snap = await tx.get(ref);
      final d = snap.data() ?? <String, dynamic>{};
      if (hintsLeft(d) <= 0) return false;
      final today = todayKey();
      final used = d['petHintDate'] == today ? asInt(d['petHintsUsed']) : 0;
      tx.update(ref, {'petHintDate': today, 'petHintsUsed': used + 1});
      return true;
    });
  }
}