// lib/features/pet/pet_catalog.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────
int asInt(dynamic v, {int def = 0}) {
  if (v == null) return def;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? def;
  return def;
}

double asDouble(dynamic v, {double def = 0}) {
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? def;
  return def;
}

// ─────────────────────────────────────────────────────────────
// Rareza
// ─────────────────────────────────────────────────────────────
enum Rarity { common, rare, epic, legendary }

extension RarityX on Rarity {
  String get label => switch (this) {
        Rarity.common => 'Común',
        Rarity.rare => 'Raro',
        Rarity.epic => 'Épico',
        Rarity.legendary => 'Legendario',
      };

  Color get color => switch (this) {
        Rarity.common => const Color(0xFF8C9BC7),
        Rarity.rare => const Color(0xFF4DA3FF),
        Rarity.epic => const Color(0xFFB36BFF),
        Rarity.legendary => const Color(0xFFFFC93C),
      };
}

// ─────────────────────────────────────────────────────────────
// Especies
// Para usar imágenes/Lottie reales más adelante, agrega un campo
// `asset` aquí y cámbialo en PetAvatar (pet_screen.dart).
// ─────────────────────────────────────────────────────────────
class PetSpecies {
  final String id;
  final String emoji;
  final String name;
  final String description;
  final int price;
  final int requiredStreak; // racha necesaria para desbloquear
  final Rarity rarity;
  final Color color;

  const PetSpecies({
    required this.id,
    required this.emoji,
    required this.name,
    required this.description,
    required this.price,
    required this.requiredStreak,
    required this.rarity,
    required this.color,
  });
}

const petSpecies = <PetSpecies>[
  PetSpecies(
    id: 'dog', emoji: '🐶', name: 'Perro',
    description: 'Leal y juguetón. Tu compañero de estudio ideal.',
    price: 0, requiredStreak: 0, rarity: Rarity.common, color: Color(0xFFC68642),
  ),
  PetSpecies(
    id: 'cat', emoji: '🐱', name: 'Gato',
    description: 'Independiente, curioso y muy mimoso.',
    price: 0, requiredStreak: 0, rarity: Rarity.common, color: Color(0xFFFFA94D),
  ),
  PetSpecies(
    id: 'rabbit', emoji: '🐰', name: 'Conejo',
    description: 'Tierno y rápido. Adora las zanahorias.',
    price: 80, requiredStreak: 0, rarity: Rarity.common, color: Color(0xFFFF8FB1),
  ),
  PetSpecies(
    id: 'panda', emoji: '🐼', name: 'Panda',
    description: 'Tranquilo y adorable. Duerme mucho.',
    price: 150, requiredStreak: 3, rarity: Rarity.rare, color: Color(0xFF9CA3AF),
  ),
  PetSpecies(
    id: 'fox', emoji: '🦊', name: 'Zorro',
    description: 'Astuto y veloz. Aprende todo al instante.',
    price: 200, requiredStreak: 5, rarity: Rarity.rare, color: Color(0xFFFF7A33),
  ),
  PetSpecies(
    id: 'wolf', emoji: '🐺', name: 'Lobo',
    description: 'Salvaje y protector. Aúlla cuando alcanzas tus metas.',
    price: 300, requiredStreak: 7, rarity: Rarity.rare, color: Color(0xFF7C93B8),
  ),
  PetSpecies(
    id: 'owl', emoji: '🦉', name: 'Búho',
    description: 'Sabio nocturno. Le encanta la psicología.',
    price: 400, requiredStreak: 14, rarity: Rarity.epic, color: Color(0xFF8D6E63),
  ),
  PetSpecies(
    id: 'unicorn', emoji: '🦄', name: 'Unicornio',
    description: 'Mágico y brillante. Deja destellos a su paso.',
    price: 700, requiredStreak: 30, rarity: Rarity.epic, color: Color(0xFFD58CFF),
  ),
  PetSpecies(
    id: 'dragon', emoji: '🐲', name: 'Dragón',
    description: 'Poderoso y ancestral. Solo para verdaderos constantes.',
    price: 1000, requiredStreak: 60, rarity: Rarity.legendary, color: Color(0xFF2ECC71),
  ),
  PetSpecies(
    id: 'phoenix', emoji: '🦅', name: 'Ave Fénix',
    description: 'Renace de las cenizas. La mascota definitiva.',
    price: 1500, requiredStreak: 100, rarity: Rarity.legendary, color: Color(0xFFFF5722),
  ),
];

PetSpecies? speciesById(String? id) {
  for (final s in petSpecies) {
    if (s.id == id) return s;
  }
  return null;
}

// ─────────────────────────────────────────────────────────────
// Cosméticos
// ─────────────────────────────────────────────────────────────
class CosmeticSlot {
  static const hat = 'hat';
  static const face = 'face';
  static const neck = 'neck';
  static const aura = 'aura';

  static const all = [hat, face, neck, aura];

  static String label(String slot) => switch (slot) {
        hat => 'Sombreros',
        face => 'Gafas',
        neck => 'Cuello',
        aura => 'Auras',
        _ => 'Todos',
      };
}

class Cosmetic {
  final String id;
  final String slot;
  final String emoji;
  final String name;
  final int price;
  final int requiredStreak;
  final Rarity rarity;
  final Color color; // se usa en las auras

  const Cosmetic({
    required this.id,
    required this.slot,
    required this.emoji,
    required this.name,
    required this.price,
    required this.rarity,
    this.requiredStreak = 0,
    this.color = const Color(0xFF7657FF),
  });
}

const cosmetics = <Cosmetic>[
  // Sombreros
  Cosmetic(id: 'hat_cap', slot: CosmeticSlot.hat, emoji: '🧢', name: 'Gorra', price: 30, rarity: Rarity.common),
  Cosmetic(id: 'hat_top', slot: CosmeticSlot.hat, emoji: '🎩', name: 'Sombrero de copa', price: 40, rarity: Rarity.common),
  Cosmetic(id: 'hat_grad', slot: CosmeticSlot.hat, emoji: '🎓', name: 'Birrete', price: 60, rarity: Rarity.rare, requiredStreak: 3),
  Cosmetic(id: 'hat_cowboy', slot: CosmeticSlot.hat, emoji: '🤠', name: 'Vaquero', price: 90, rarity: Rarity.rare, requiredStreak: 5),
  Cosmetic(id: 'hat_crown', slot: CosmeticSlot.hat, emoji: '👑', name: 'Corona real', price: 300, rarity: Rarity.legendary, requiredStreak: 30),
  // Gafas
  Cosmetic(id: 'face_glasses', slot: CosmeticSlot.face, emoji: '👓', name: 'Gafas de estudio', price: 35, rarity: Rarity.common),
  Cosmetic(id: 'face_sun', slot: CosmeticSlot.face, emoji: '🕶️', name: 'Gafas de sol', price: 50, rarity: Rarity.common),
  Cosmetic(id: 'face_goggles', slot: CosmeticSlot.face, emoji: '🥽', name: 'Gafas aviador', price: 120, rarity: Rarity.rare, requiredStreak: 10),
  // Cuello
  Cosmetic(id: 'neck_bow', slot: CosmeticSlot.neck, emoji: '🎀', name: 'Moño', price: 35, rarity: Rarity.common),
  Cosmetic(id: 'neck_scarf', slot: CosmeticSlot.neck, emoji: '🧣', name: 'Bufanda', price: 45, rarity: Rarity.common),
  Cosmetic(id: 'neck_necklace', slot: CosmeticSlot.neck, emoji: '📿', name: 'Collar místico', price: 100, rarity: Rarity.rare, requiredStreak: 7),
  Cosmetic(id: 'neck_medal', slot: CosmeticSlot.neck, emoji: '🏅', name: 'Medalla de oro', price: 200, rarity: Rarity.epic, requiredStreak: 21),
  // Auras
  Cosmetic(id: 'aura_sparkle', slot: CosmeticSlot.aura, emoji: '✨', name: 'Destellos', price: 120, rarity: Rarity.rare, requiredStreak: 7, color: Color(0xFF3FE0FF)),
  Cosmetic(id: 'aura_fire', slot: CosmeticSlot.aura, emoji: '🔥', name: 'Llamas', price: 250, rarity: Rarity.epic, requiredStreak: 21, color: Color(0xFFFF6B35)),
  Cosmetic(id: 'aura_ice', slot: CosmeticSlot.aura, emoji: '❄️', name: 'Escarcha', price: 250, rarity: Rarity.epic, requiredStreak: 21, color: Color(0xFF8FD8FF)),
  Cosmetic(id: 'aura_storm', slot: CosmeticSlot.aura, emoji: '⚡', name: 'Tormenta', price: 400, rarity: Rarity.epic, requiredStreak: 30, color: Color(0xFFFFD93C)),
  Cosmetic(id: 'aura_rainbow', slot: CosmeticSlot.aura, emoji: '🌈', name: 'Arcoíris', price: 500, rarity: Rarity.legendary, requiredStreak: 45, color: Color(0xFFB36BFF)),
];

Cosmetic? cosmeticById(String? id) {
  for (final c in cosmetics) {
    if (c.id == id) return c;
  }
  return null;
}

// ─────────────────────────────────────────────────────────────
// Nivel
// ─────────────────────────────────────────────────────────────
class LevelInfo {
  final int level;
  final int into;
  final int need;
  const LevelInfo(this.level, this.into, this.need);
  double get progress => need == 0 ? 0 : (into / need).clamp(0.0, 1.0);
}

LevelInfo levelFromXp(int xp) {
  var lvl = 1;
  var rem = xp < 0 ? 0 : xp;
  var need = 50;
  while (rem >= need) {
    rem -= need;
    lvl++;
    need = 50 + (lvl - 1) * 25;
  }
  return LevelInfo(lvl, rem, need);
}

// ─────────────────────────────────────────────────────────────
// Estado de una mascota (guardado en usuarios/{uid}.pets.{id})
// ─────────────────────────────────────────────────────────────
class PetState {
  final String id;
  final String name;
  final int xp;
  final double hunger; // 100 = lleno
  final double happiness;
  final double energy;
  final DateTime lastTick;
  final Map<String, String> equipped;

  const PetState({
    required this.id,
    required this.name,
    required this.xp,
    required this.hunger,
    required this.happiness,
    required this.energy,
    required this.lastTick,
    required this.equipped,
  });

  factory PetState.newborn(String id, {String? name}) => PetState(
        id: id,
        name: name ?? speciesById(id)?.name ?? 'Mascota',
        xp: 0,
        hunger: 80,
        happiness: 80,
        energy: 100,
        lastTick: DateTime.now(),
        equipped: const {},
      );

  factory PetState.fromMap(String id, Map<String, dynamic> m) {
    final ts = m['lastTick'];
    final eq = <String, String>{};
    final rawEq = m['equipped'];
    if (rawEq is Map) {
      rawEq.forEach((k, v) {
        if (v is String) eq[k.toString()] = v;
      });
    }
    return PetState(
      id: id,
      name: (m['name'] as String?) ?? speciesById(id)?.name ?? 'Mascota',
      xp: asInt(m['xp']),
      hunger: asDouble(m['hunger'], def: 80).clamp(0, 100),
      happiness: asDouble(m['happiness'], def: 80).clamp(0, 100),
      energy: asDouble(m['energy'], def: 100).clamp(0, 100),
      lastTick: ts is Timestamp ? ts.toDate() : DateTime.now(),
      equipped: eq,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'xp': xp,
        'hunger': hunger,
        'happiness': happiness,
        'energy': energy,
        'lastTick': Timestamp.fromDate(lastTick),
        'equipped': equipped,
      };

  PetState copyWith({
    String? name,
    int? xp,
    double? hunger,
    double? happiness,
    double? energy,
    DateTime? lastTick,
  }) =>
      PetState(
        id: id,
        name: name ?? this.name,
        xp: xp ?? this.xp,
        hunger: (hunger ?? this.hunger).clamp(0, 100).toDouble(),
        happiness: (happiness ?? this.happiness).clamp(0, 100).toDouble(),
        energy: (energy ?? this.energy).clamp(0, 100).toDouble(),
        lastTick: lastTick ?? this.lastTick,
        equipped: equipped,
      );

  /// Las stats bajan con el tiempo: hambre -4/h, felicidad -3/h, energía -2/h.
  /// Si tiene mucha hambre, la felicidad baja más rápido.
  PetState decayed(DateTime now) {
    final hours = now.difference(lastTick).inSeconds / 3600.0;
    if (hours <= 0) return this;
    final newHunger = hunger - 4 * hours;
    final hungerPenalty = newHunger < 25 ? 1.5 : 1.0;
    return copyWith(
      hunger: newHunger,
      happiness: happiness - 3 * hours * hungerPenalty,
      energy: energy - 2 * hours,
      lastTick: now,
    );
  }

  double get average => (hunger + happiness + energy) / 3;

  String get moodLabel {
    if (hunger < 25) return 'Tiene hambre';
    if (energy < 25) return 'Muy cansado';
    if (happiness < 25) return 'Está triste';
    if (average >= 80) return 'Feliz';
    if (average >= 55) return 'Contento';
    return 'Regular';
  }

  String get moodEmoji {
    if (hunger < 25) return '🍖';
    if (energy < 25) return '😴';
    if (happiness < 25) return '😢';
    if (average >= 80) return '😄';
    if (average >= 55) return '🙂';
    return '😐';
  }
}