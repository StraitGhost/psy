// lib/features/pet/pet_screen.dart
import 'dart:async';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'pet_catalog.dart';
import 'pet_perks.dart';
import 'pet_stage.dart';

TextStyle _t(double size, FontWeight w, Color c, {double? height}) =>
    TextStyle(fontSize: size, fontWeight: w, color: c, height: height);

class _PetException implements Exception {
  final String message;
  _PetException(this.message);
}

// ─────────────────────────────────────────────────────────────
// Vista de los datos del usuario
// ─────────────────────────────────────────────────────────────
class _UserView {
  final int gems;
  final int streak; // racha actual
  final int unlockStreak; // max(racha actual, mejor racha): para desbloqueos
  final String? activeId;
  final Map<String, PetState> pets;
  final Set<String> cosmetics;
  final String? claimedDate; // último regalo diario reclamado
  final DateTime? weeklyAt;
  final DateTime? monthlyAt;

  _UserView({
    required this.gems,
    required this.streak,
    required this.unlockStreak,
    required this.activeId,
    required this.pets,
    required this.cosmetics,
    required this.claimedDate,
    required this.weeklyAt,
    required this.monthlyAt,
  });

  PetState? get active =>
      pets[activeId] ?? (pets.isNotEmpty ? pets.values.first : null);

  factory _UserView.from(Map<String, dynamic> d) {
    final now = DateTime.now();
    final pets = <String, PetState>{};
    final raw = d['pets'];
    if (raw is Map) {
      raw.forEach((k, v) {
        if (v is Map) {
          pets[k.toString()] = PetState.fromMap(
            k.toString(),
            Map<String, dynamic>.from(v),
          ).decayed(now); // se muestra con el desgaste ya aplicado
        }
      });
    }
    final owned = <String>{};
    final rc = d['ownedCosmetics'];
    if (rc is List) owned.addAll(rc.map((e) => e.toString()));

    DateTime? ts(dynamic v) => v is Timestamp ? v.toDate() : null;

    final streak = asInt(d['dayStreak']);
    return _UserView(
      gems: asInt(d['gems']),
      streak: streak,
      unlockStreak: math.max(streak, asInt(d['bestStreak'])),
      activeId: d['activePet'] as String?,
      pets: pets,
      cosmetics: owned,
      claimedDate: d['petDailyClaimDate'] as String?,
      weeklyAt: ts(d['petWeeklyClaimAt']),
      monthlyAt: ts(d['petMonthlyClaimAt']),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Pantalla
// ─────────────────────────────────────────────────────────────
class PetScreen extends StatefulWidget {
  const PetScreen({super.key});

  @override
  State<PetScreen> createState() => _PetScreenState();
}

class _PetScreenState extends State<PetScreen> with TickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 3, vsync: this);
  final GlobalKey<PetStageState> _stageKey = GlobalKey<PetStageState>();

  Timer? _msgTimer;
  Timer? _tick;
  String? _msg;
  bool _busy = false;
  String _slotFilter = 'all';

  final _db = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> get _ref =>
      _db.collection('usuarios').doc(FirebaseAuth.instance.currentUser!.uid);

  @override
  void initState() {
    super.initState();
    // refresca las barras de estado cada 30 s
    _tick = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    _msgTimer?.cancel();
    _tick?.cancel();
    super.dispose();
  }

  // ───────── utilidades UI ─────────
  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: error ? AppColors.error.withValues(alpha: 0.9) : AppColors.success.withValues(alpha: 0.9),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Text(msg, style: _t(14, FontWeight.w600, AppColors.textOnPrimary)),
        ),
      );
  }

  void _say(String msg) {
    setState(() => _msg = msg);
    _msgTimer?.cancel();
    _msgTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _msg = null);
    });
  }

  Future<bool> _confirm(String title, String body, Color accent) async {
    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColors.border),
        ),
        title: Text(title, style: _t(18, FontWeight.w800, AppColors.textPrimary)),
        content: Text(body, style: _t(14, FontWeight.w400, AppColors.textMuted, height: 1.4)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar', style: _t(14, FontWeight.w600, AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Confirmar', style: _t(14, FontWeight.w800, accent)),
          ),
        ],
      ),
    );
    return res == true;
  }

  /// Ejecuta una operación con control de "ocupado" y manejo de errores.
  Future<void> _run(Future<void> Function() job, {String? okMsg}) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await job();
      if (okMsg != null) _snack(okMsg);
    } on _PetException catch (e) {
      _snack(e.message, error: true);
    } catch (_) {
      _snack('No se pudo completar la acción. Inténtalo de nuevo.', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ───────── interacciones con la mascota ─────────
  static const int _feedCost = 5;
  static const int _levelUpGems = 10;

  Future<void> _act(String action, _UserView u) async {
    final pet = u.active;
    if (pet == null || _busy) return;

    // Validación rápida para animar al instante (la transacción revalida)
    switch (action) {
      case 'alimentar':
        if (pet.hunger >= 95) {
          _snack('${pet.name} no tiene hambre ahora.', error: true);
          return;
        }
        if (u.gems < _feedCost) {
          _snack('Necesitas $_feedCost gemas para alimentar.', error: true);
          return;
        }
        break;
      case 'jugar':
        if (pet.energy < 15) {
          _snack('${pet.name} está muy cansado. Déjalo dormir.', error: true);
          return;
        }
        break;
      case 'dormir':
        if (pet.energy >= 95) {
          _snack('${pet.name} no tiene sueño.', error: true);
          return;
        }
        break;
    }

    const msgs = {
      'acariciar': '¡Me encanta! 😊💕',
      'alimentar': '¡Qué rico! 🍖✨',
      'jugar': '¡A jugar! 🎾',
      'dormir': 'Zzz... 😴💤',
    };
    _stageKey.currentState?.play(action);
    _say(msgs[action] ?? '🐾');

    int levelsGained = 0;

    await _run(() async {
      await _db.runTransaction((tx) async {
        final snap = await tx.get(_ref);
        final data = snap.data() ?? <String, dynamic>{};
        var gems = asInt(data['gems']);
        final rawPets = data['pets'];
        final raw = rawPets is Map ? rawPets[pet.id] : null;
        if (raw is! Map) throw _PetException('No tienes esta mascota.');

        var p = PetState.fromMap(pet.id, Map<String, dynamic>.from(raw))
            .decayed(DateTime.now());
        final oldLevel = levelFromXp(p.xp).level;

        switch (action) {
          case 'acariciar':
            p = p.copyWith(happiness: p.happiness + 8, xp: p.xp + 2);
            break;
          case 'alimentar':
            if (p.hunger >= 95) throw _PetException('${p.name} no tiene hambre ahora.');
            if (gems < _feedCost) throw _PetException('Necesitas $_feedCost gemas para alimentar.');
            gems -= _feedCost;
            p = p.copyWith(
              hunger: p.hunger + 30,
              happiness: p.happiness + 3,
              xp: p.xp + 5,
            );
            break;
          case 'jugar':
            if (p.energy < 15) throw _PetException('${p.name} está muy cansado. Déjalo dormir.');
            p = p.copyWith(
              energy: p.energy - 15,
              hunger: p.hunger - 8,
              happiness: p.happiness + 20,
              xp: p.xp + 8,
            );
            break;
          case 'dormir':
            if (p.energy >= 95) throw _PetException('${p.name} no tiene sueño.');
            p = p.copyWith(
              energy: p.energy + 40,
              hunger: p.hunger - 5,
              xp: p.xp + 1,
            );
            break;
        }

        final newLevel = levelFromXp(p.xp).level;
        levelsGained = newLevel - oldLevel;
        if (levelsGained > 0) gems += _levelUpGems * levelsGained;

        tx.update(_ref, {'pets.${p.id}': p.toMap(), 'gems': gems});
        if (action == 'alimentar') {
          tx.set(_ref.collection('purchases').doc(), {
            'itemId': 'pet_food',
            'title': 'Comida para ${p.name}',
            'price': _feedCost,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      });

      if (levelsGained > 0) {
        _snack('🎉 ¡Tu mascota subió de nivel! +${_levelUpGems * levelsGained} gemas');
      }
    });
  }

  Future<void> _buyPet(PetSpecies s, _UserView u) async {
    if (!await _confirm(
      'Adoptar ${s.name} ${s.emoji}',
      s.price == 0
          ? '¡Es gratis! Se unirá a tu colección.'
          : 'Se descontarán ${s.price} gemas.',
      s.color,
    )) return;

    await _run(() async {
      await _db.runTransaction((tx) async {
        final snap = await tx.get(_ref);
        final data = snap.data() ?? <String, dynamic>{};
        final gems = asInt(data['gems']);
        final streak = math.max(asInt(data['dayStreak']), asInt(data['bestStreak']));
        final pets = data['pets'];

        if (pets is Map && pets.containsKey(s.id)) {
          throw _PetException('Ya tienes a ${s.name}.');
        }
        if (streak < s.requiredStreak) {
          throw _PetException('Necesitas una racha de ${s.requiredStreak} días.');
        }
        if (gems < s.price) throw _PetException('No tienes suficientes gemas.');

        final updates = <String, dynamic>{
          'gems': gems - s.price,
          'pets.${s.id}': PetState.newborn(s.id).toMap(),
        };
        if (data['activePet'] == null) updates['activePet'] = s.id;
        tx.update(_ref, updates);

        if (s.price > 0) {
          tx.set(_ref.collection('purchases').doc(), {
            'itemId': 'pet_${s.id}',
            'title': 'Mascota: ${s.name}',
            'price': s.price,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      });
      _tabs.animateTo(0);
    }, okMsg: '${s.emoji} ¡${s.name} se unió a tu familia!');
  }

  Future<void> _setActive(String id) async {
    await _run(() => _ref.update({'activePet': id}));
  }

  Future<void> _buyCosmetic(Cosmetic c, _UserView u) async {
    if (!await _confirm(
      '${c.name} ${c.emoji}',
      'Se descontarán ${c.price} gemas.',
      c.rarity.color,
    )) return;

    await _run(() async {
      await _db.runTransaction((tx) async {
        final snap = await tx.get(_ref);
        final data = snap.data() ?? <String, dynamic>{};
        final gems = asInt(data['gems']);
        final streak = math.max(asInt(data['dayStreak']), asInt(data['bestStreak']));
        final owned = data['ownedCosmetics'];

        if (owned is List && owned.contains(c.id)) {
          throw _PetException('Ya tienes este cosmético.');
        }
        if (streak < c.requiredStreak) {
          throw _PetException('Necesitas una racha de ${c.requiredStreak} días.');
        }
        if (gems < c.price) throw _PetException('No tienes suficientes gemas.');

        tx.update(_ref, {
          'gems': gems - c.price,
          'ownedCosmetics': FieldValue.arrayUnion([c.id]),
        });
        tx.set(_ref.collection('purchases').doc(), {
          'itemId': c.id,
          'title': 'Cosmético: ${c.name}',
          'price': c.price,
          'createdAt': FieldValue.serverTimestamp(),
        });
      });
    }, okMsg: '${c.emoji} ¡${c.name} comprado!');
  }

  Future<void> _toggleEquip(Cosmetic c, _UserView u) async {
    final pet = u.active;
    if (pet == null) {
      _snack('Primero adopta una mascota.', error: true);
      return;
    }
    final isOn = pet.equipped[c.slot] == c.id;
    await _run(() => _ref.update({
          'pets.${pet.id}.equipped.${c.slot}':
              isOn ? FieldValue.delete() : c.id,
        }));
  }

  Future<void> _rename(PetState pet) async {
    final ctrl = TextEditingController(text: pet.name);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColors.border),
        ),
        title: Text('Nombre de tu mascota', style: _t(18, FontWeight.w800, AppColors.textPrimary)),
        content: TextField(
          controller: ctrl,
          maxLength: 14,
          autofocus: true,
          style: _t(16, FontWeight.w600, AppColors.textPrimary),
          decoration: InputDecoration(
            counterStyle: _t(11, FontWeight.w400, AppColors.textMuted),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.border)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primary)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar', style: _t(14, FontWeight.w600, AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: Text('Guardar', style: _t(14, FontWeight.w800, AppColors.primary)),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (name == null || name.isEmpty) return;
    await _run(() => _ref.update({'pets.${pet.id}.name': name}));
  }

  // ───────── regalos y beneficios ─────────
  Future<void> _claim(String kind) async {
    await _run(() async {
      var msg = '';
      await _db.runTransaction((tx) async {
        final snap = await tx.get(_ref);
        final data = snap.data() ?? <String, dynamic>{};
        final pets = data['pets'];
        final id = (data['activePet'] as String?) ??
            (pets is Map && pets.isNotEmpty ? pets.keys.first.toString() : null);
        final raw = (pets is Map && id != null) ? pets[id] : null;
        if (raw is! Map) throw _PetException('Primero adopta una mascota.');

        final pet = PetState.fromMap(id!, Map<String, dynamic>.from(raw))
            .decayed(DateTime.now());
        final species = speciesById(id)!;
        if (!PetPerks.isActive(pet)) {
          throw _PetException('${pet.name} está descuidado. Aliméntalo y juega con él primero.');
        }
        final perks = speciesPerks[id] ?? const <Perk>[];
        final now = DateTime.now();

        if (kind == 'daily') {
          if (data['petDailyClaimDate'] == PetPerks.todayKey()) {
            throw _PetException('Ya reclamaste el regalo de hoy.');
          }
          final gift = PetPerks.dailyGift(pet, species);
          tx.update(_ref, {
            'gems': asInt(data['gems']) + gift,
            'petDailyClaimDate': PetPerks.todayKey(),
          });
          msg = '🎁 ${pet.name} te trajo $gift gemas';
        } else if (kind == 'weekly') {
          if (!perks.any((p) => p.type == PerkType.weeklyShield)) {
            throw _PetException('Esta mascota no da escudos.');
          }
          final last = data['petWeeklyClaimAt'];
          if (last is Timestamp && now.difference(last.toDate()).inDays < 7) {
            throw _PetException('Aún no está disponible.');
          }
          tx.update(_ref, {
            'streakShields': FieldValue.increment(1),
            'petWeeklyClaimAt': Timestamp.fromDate(now),
          });
          msg = '🛡️ ¡${pet.name} te regaló un escudo de racha!';
        } else {
          if (!perks.any((p) => p.type == PerkType.monthlyFreeze)) {
            throw _PetException('Esta mascota no da congeladores.');
          }
          final last = data['petMonthlyClaimAt'];
          if (last is Timestamp && now.difference(last.toDate()).inDays < 30) {
            throw _PetException('Aún no está disponible.');
          }
          tx.update(_ref, {
            'streakFreezes': FieldValue.increment(1),
            'petMonthlyClaimAt': Timestamp.fromDate(now),
          });
          msg = '❄️ ¡${pet.name} te regaló un congelador de racha!';
        }
      });
      _snack(msg);
    });
  }

  void _showInfo() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, sc) => Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: AppColors.border),
          ),
          child: ListView(
            controller: sc,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('¿Para qué sirven las mascotas?', style: _t(20, FontWeight.w800, AppColors.textPrimary)),
              const SizedBox(height: 10),
              Text(
                'Cuídalas (alimentar, jugar y dormir) y te ayudarán mientras estudias:',
                style: _t(14, FontWeight.w400, AppColors.textMuted, height: 1.4),
              ),
              const SizedBox(height: 12),
              _infoLine('🎁', 'Regalo diario', 'Una vez al día te traen gemas. Mientras más rara y de más nivel, más gemas.'),
              _infoLine('⚡', 'Poder de su especie', 'Más XP, más gemas, escudos y más, según la mascota.'),
              _infoLine('📈', 'Suben de nivel', 'Con cada nivel su poder y su regalo crecen (hasta el nivel 20) y ganas +10 💎.'),
              _infoLine('❤️', 'Hay que cuidarlas', 'Si tienen mucha hambre o están tristes, pierden sus poderes hasta que las cuides.'),
              const SizedBox(height: 18),
              Text('Rangos', style: _t(18, FontWeight.w800, AppColors.primary)),
              const SizedBox(height: 4),
              Text(
                'Mientras mayor es la rareza, más fuerte es el regalo y el poder.',
                style: _t(13, FontWeight.w400, AppColors.textMuted, height: 1.4),
              ),
              const SizedBox(height: 12),
              for (final r in Rarity.values) _rarityBlock(r),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoLine(String emoji, String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: _t(14, FontWeight.w800, AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(body, style: _t(13, FontWeight.w400, AppColors.textMuted, height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _rarityBlock(Rarity r) {
    final list = petSpecies.where((s) => s.rarity == r).toList();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: r.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: r.color.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(r.label, style: _t(16, FontWeight.w800, r.color)),
              const SizedBox(width: 8),
              Text(r.stars, style: const TextStyle(fontSize: 12)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${r.powerText} · Regalo diario desde ${r.dailyBase} 💎 (+1 por nivel)',
            style: _t(12, FontWeight.w500, AppColors.textMuted, height: 1.35),
          ),
          const SizedBox(height: 10),
          for (final s in list)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.emoji, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.requiredStreak > 0
                              ? '${s.name} · racha ${s.requiredStreak} días'
                              : s.name,
                          style: _t(13, FontWeight.w800, AppColors.textPrimary),
                        ),
                        for (final pk in speciesPerks[s.id] ?? const <Perk>[])
                          Text('${pk.emoji} ${pk.rangeText}',
                              style: _t(12, FontWeight.w500, AppColors.textMuted, height: 1.35)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _perksCard(_UserView u, PetState pet, PetSpecies s) {
    final active = PetPerks.isActive(pet);
    final lvl = levelFromXp(pet.xp).level;
    final perks = speciesPerks[s.id] ?? const <Perk>[];
    final gift = PetPerks.dailyGift(pet, s);
    final now = DateTime.now();
    final claimedToday = u.claimedDate == PetPerks.todayKey();

    Duration left(DateTime? at, int days) => at == null
        ? Duration.zero
        : Duration(days: days) - now.difference(at);
    final weeklyLeft = left(u.weeklyAt, 7);
    final monthlyLeft = left(u.monthlyAt, 30);
    final hasWeekly = perks.any((p) => p.type == PerkType.weeklyShield);
    final hasMonthly = perks.any((p) => p.type == PerkType.monthlyFreeze);

    String wait(Duration d) => 'Disponible en ${(d.inHours / 24).ceil()} d';

    Widget btn(String label, bool enabled, bool outlined, VoidCallback onTap) =>
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: SizedBox(
            width: double.infinity,
            child: _BuyButton(
              label: label,
              color: s.color,
              enabled: enabled,
              outlined: outlined,
              compact: true,
              onTap: onTap,
            ),
          ),
        );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: (active ? AppColors.success : AppColors.error).withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Beneficios de ${pet.name}',
                    style: _t(16, FontWeight.w800, AppColors.textPrimary)),
              ),
              _Pill(
                text: active ? '✓ Activos' : '✗ Inactivos',
                color: active ? AppColors.success : AppColors.error,
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (!active)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                'Está descuidado: dale de comer y juega con él para recuperar sus poderes.',
                style: _t(12.5, FontWeight.w600, AppColors.error, height: 1.35),
              ),
            ),
          for (final pk in perks)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Text(pk.emoji, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(pk.label(pk.at(lvl)),
                        style: _t(13.5, FontWeight.w700, active ? AppColors.textPrimary : AppColors.textMuted)),
                  ),
                ],
              ),
            ),
          Text(
            'Nivel $lvl · mejoran al subir de nivel (hasta el 20).',
            style: _t(11.5, FontWeight.w500, AppColors.textMuted),
          ),
          btn(
            claimedToday ? 'Regalo de hoy reclamado ✓' : '🎁 Reclamar regalo diario +$gift 💎',
            active && !claimedToday && !_busy,
            claimedToday,
            () => _claim('daily'),
          ),
          if (hasWeekly)
            btn(
              weeklyLeft <= Duration.zero ? '🛡️ Reclamar escudo gratis' : '🛡️ ${wait(weeklyLeft)}',
              active && weeklyLeft <= Duration.zero && !_busy,
              weeklyLeft > Duration.zero,
              () => _claim('weekly'),
            ),
          if (hasMonthly)
            btn(
              monthlyLeft <= Duration.zero ? '❄️ Reclamar congelador gratis' : '❄️ ${wait(monthlyLeft)}',
              active && monthlyLeft <= Duration.zero && !_busy,
              monthlyLeft > Duration.zero,
              () => _claim('monthly'),
            ),
        ],
      ),
    );
  }

  // ───────── build ─────────
  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.surface, AppColors.background],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: uid == null
              ? Center(child: Text('No hay usuario', style: _t(15, FontWeight.w600, AppColors.textPrimary)))
              : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  stream: _db.collection('usuarios').doc(uid).snapshots(),
                  builder: (context, snap) {
                    if (snap.hasError) {
                      return Center(
                        child: Text('No pudimos cargar tus mascotas.',
                            style: _t(15, FontWeight.w600, AppColors.textPrimary)),
                      );
                    }
                    if (!snap.hasData) {
                      return Center(child: CircularProgressIndicator(color: AppColors.primary));
                    }
                    final u = _UserView.from(snap.data!.data() ?? {});
                    return Column(
                      children: [
                        _topBar(u),
                        _tabBar(),
                        Expanded(
                          child: TabBarView(
                            controller: _tabs,
                            children: [
                              _petTab(u),
                              _adoptTab(u),
                              _cosmeticsTab(u),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
        ),
      ),
    );
  }

  Widget _topBar(_UserView u) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 4),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary, size: 26),
            onPressed: () => Navigator.pop(context),
          ),
          Text('Mis Mascotas', style: _t(20, FontWeight.w800, AppColors.textPrimary)),
          const SizedBox(width: 8),
          _InfoDot(onTap: _showInfo),
          const Spacer(),
          _Chip(
            icon: Icons.local_fire_department_rounded,
            text: '${u.streak}',
            color: AppColors.warning,
          ),
          const SizedBox(width: 8),
          _Chip(icon: Icons.diamond_rounded, text: '${u.gems}', color: AppColors.primary),
        ],
      ),
    );
  }

  Widget _tabBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: TabBar(
        controller: _tabs,
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: AppColors.textOnPrimary,
        unselectedLabelColor: AppColors.textMuted,
        labelStyle: _t(13, FontWeight.w800, AppColors.textOnPrimary),
        unselectedLabelStyle: _t(13, FontWeight.w600, AppColors.textMuted),
        tabs: const [
          Tab(height: 40, text: '🐾 Mascota'),
          Tab(height: 40, text: '🥚 Adoptar'),
          Tab(height: 40, text: '👑 Estilo'),
        ],
      ),
    );
  }

  Widget _centered(Widget child) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: child,
        ),
      );

  // ───────── Pestaña 1: mascota ─────────
  Widget _petTab(_UserView u) {
    final pet = u.active;
    if (pet == null) {
      return _centered(
        Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🥚', style: TextStyle(fontSize: 72)),
              const SizedBox(height: 16),
              Text('Aún no tienes mascota',
                  style: _t(20, FontWeight.w800, AppColors.textPrimary)),
              const SizedBox(height: 8),
              Text(
                'Adopta un perro o un gato gratis y empieza a cuidarlo.',
                textAlign: TextAlign.center,
                style: _t(14, FontWeight.w400, AppColors.textMuted, height: 1.4),
              ),
              const SizedBox(height: 20),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  shape: const StadiumBorder(),
                ),
                onPressed: () => _tabs.animateTo(1),
                child: Text('Adoptar mascota', style: _t(15, FontWeight.w800, AppColors.textOnPrimary)),
              ),
            ],
          ),
        ),
      );
    }

    final species = speciesById(pet.id)!;
    final lvl = levelFromXp(pet.xp);

    return _centered(
      ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        physics: const BouncingScrollPhysics(),
        children: [
          // selector de mascotas
          if (u.pets.length > 1)
            SizedBox(
              height: 52,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final p in u.pets.values)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => _setActive(p.id),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: p.id == pet.id
                                ? speciesById(p.id)!.color.withValues(alpha: 0.25)
                                : AppColors.surfaceCard,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: p.id == pet.id
                                  ? speciesById(p.id)!.color
                                  : AppColors.border,
                              width: p.id == pet.id ? 1.6 : 1,
                            ),
                          ),
                          child: Text(
                            '${speciesById(p.id)!.emoji} ${p.name}',
                            style: _t(14, FontWeight.w700, AppColors.textPrimary),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          if (u.pets.length > 1) const SizedBox(height: 12),

          // tarjeta de info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: species.color.withValues(alpha: 0.4)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _rename(pet),
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(pet.name,
                                  overflow: TextOverflow.ellipsis,
                                  style: _t(20, FontWeight.w800, AppColors.textPrimary)),
                            ),
                            const SizedBox(width: 6),
                            Icon(Icons.edit_rounded, size: 15, color: AppColors.textMuted),
                          ],
                        ),
                      ),
                    ),
                    _Pill(text: species.rarity.label, color: species.rarity.color),
                    const SizedBox(width: 8),
                    _Pill(text: '${pet.moodEmoji} ${pet.moodLabel}', color: AppColors.success),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text('Nivel ${lvl.level}', style: _t(13, FontWeight.w800, AppColors.warning)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: lvl.progress,
                          minHeight: 8,
                          backgroundColor: AppColors.surface.withValues(alpha: 0.1),
                          valueColor: AlwaysStoppedAnimation(AppColors.warning),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text('${lvl.into}/${lvl.need} XP', style: _t(11, FontWeight.w600, AppColors.textMuted)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // mascota animada e interactiva
          PetStage(
            key: _stageKey,
            species: species,
            equipped: pet.equipped,
            message: _msg,
            onPet: () => _act('acariciar', u),
          ),
          Text(
            'Toca o desliza el dedo sobre tu mascota para acariciarla',
            textAlign: TextAlign.center,
            style: _t(12, FontWeight.w500, AppColors.textMuted),
          ),
          const SizedBox(height: 12),

          // stats
          _StatBar(label: 'Hambre', icon: Icons.restaurant_rounded, value: pet.hunger, color: AppColors.warning),
          const SizedBox(height: 10),
          _StatBar(label: 'Felicidad', icon: Icons.favorite_rounded, value: pet.happiness, color: const Color(0xFFFF5C8A)),
          const SizedBox(height: 10),
          _StatBar(label: 'Energía', icon: Icons.bolt_rounded, value: pet.energy, color: AppColors.info),
          const SizedBox(height: 20),

          _perksCard(u, pet, species),
          const SizedBox(height: 20),

          // acciones
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  icon: Icons.touch_app_rounded,
                  label: 'Acariciar',
                  color: Colors.pink,
                  onTap: _busy ? null : () => _act('acariciar', u),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionButton(
                  icon: Icons.restaurant_rounded,
                  label: 'Alimentar',
                  sub: '$_feedCost 💎',
                  color: AppColors.warning,
                  onTap: _busy ? null : () => _act('alimentar', u),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionButton(
                  icon: Icons.sports_esports_rounded,
                  label: 'Jugar',
                  color: AppColors.info,
                  onTap: _busy ? null : () => _act('jugar', u),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionButton(
                  icon: Icons.bedtime_rounded,
                  label: 'Dormir',
                  color: AppColors.secondary,
                  onTap: _busy ? null : () => _act('dormir', u),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Sube de nivel cuidando a tu mascota: ganas +$_levelUpGems 💎 por cada nivel.',
            textAlign: TextAlign.center,
            style: _t(12, FontWeight.w400, AppColors.textMuted, height: 1.35),
          ),
        ],
      ),
    );
  }

  // ───────── Pestaña 2: adoptar ─────────
  Widget _adoptTab(_UserView u) {
    return _centered(
      ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        physics: const BouncingScrollPhysics(),
        itemCount: petSpecies.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) {
          final s = petSpecies[i];
          final owned = u.pets.containsKey(s.id);
          final lockedByStreak = u.unlockStreak < s.requiredStreak;
          final canAfford = u.gems >= s.price;
          final isActive = u.active?.id == s.id;

          String label;
          bool enabled;
          bool outlined = false;
          VoidCallback? onTap;

          if (owned) {
            label = isActive ? 'Activa' : 'Elegir';
            enabled = !isActive && !_busy;
            outlined = isActive;
            onTap = () => _setActive(s.id);
          } else if (lockedByStreak) {
            label = '🔒 ${s.requiredStreak} días';
            enabled = false;
            outlined = true;
          } else {
            label = s.price == 0 ? 'Gratis' : 'Adoptar';
            enabled = canAfford && !_busy;
            onTap = () => _buyPet(s, u);
          }

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: LinearGradient(
                colors: [s.color.withValues(alpha: lockedByStreak ? 0.06 : 0.18), AppColors.surfaceCard],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: (isActive ? s.color : s.rarity.color)
                    .withValues(alpha: isActive ? 0.9 : 0.35),
                width: isActive ? 1.6 : 1,
              ),
            ),
            child: Row(
              children: [
                Opacity(
                  opacity: lockedByStreak ? 0.35 : 1,
                  child: Container(
                    width: 76,
                    height: 76,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: s.color.withValues(alpha: 0.2),
                    ),
                    child: Text(s.emoji, style: const TextStyle(fontSize: 42)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(s.name, style: _t(17, FontWeight.w800, AppColors.textPrimary)),
                          const SizedBox(width: 8),
                          _Pill(text: s.rarity.label, color: s.rarity.color),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(s.description,
                          style: _t(12.5, FontWeight.w400, AppColors.textMuted, height: 1.35)),
                      const SizedBox(height: 6),
                      for (final pk in speciesPerks[s.id] ?? const <Perk>[])
                        Text('${pk.emoji} ${pk.rangeText}',
                            style: _t(11.5, FontWeight.w700, s.color, height: 1.35)),
                      Text('🎁 Regalo diario: ${s.rarity.dailyBase}+ 💎',
                          style: _t(11.5, FontWeight.w600, AppColors.textMuted, height: 1.35)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          if (!owned && s.price > 0) ...[
                            Icon(Icons.diamond_rounded, color: AppColors.primary, size: 16),
                            const SizedBox(width: 4),
                            Text('${s.price}', style: _t(15, FontWeight.w800, AppColors.textPrimary)),
                            if (!canAfford && !lockedByStreak) ...[
                              const SizedBox(width: 8),
                              Text('Te faltan ${s.price - u.gems}',
                                  style: _t(10, FontWeight.w600, AppColors.error)),
                            ],
                          ],
                          if (lockedByStreak && !owned)
                            Flexible(
                              child: Text(
                                'Tu racha: ${u.unlockStreak}/${s.requiredStreak}',
                                style: _t(11, FontWeight.w600, AppColors.warning),
                              ),
                            ),
                          const Spacer(),
                          _BuyButton(
                            label: label,
                            color: s.color,
                            enabled: enabled,
                            outlined: outlined,
                            onTap: onTap ?? () {},
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ───────── Pestaña 3: cosméticos ─────────
  Widget _cosmeticsTab(_UserView u) {
    final pet = u.active;
    final filters = ['all', ...CosmeticSlot.all];
    final list = cosmetics
        .where((c) => _slotFilter == 'all' || c.slot == _slotFilter)
        .toList();

    return _centered(
      Column(
        children: [
          if (pet != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: PetAvatar(
                species: speciesById(pet.id)!,
                equipped: pet.equipped,
                size: 130,
              ),
            ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                for (final f in filters)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(CosmeticSlot.label(f)),
                      selected: _slotFilter == f,
                      onSelected: (_) => setState(() => _slotFilter = f),
                      backgroundColor: AppColors.surfaceCard,
                      selectedColor: AppColors.primary,
                      side: BorderSide(color: AppColors.border),
                      labelStyle: _t(13, FontWeight.w700,
                          _slotFilter == f ? AppColors.textOnPrimary : AppColors.textMuted),
                      showCheckmark: false,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              physics: const BouncingScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 220,
                mainAxisExtent: 215,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: list.length,
              itemBuilder: (_, i) {
                final c = list[i];
                final owned = u.cosmetics.contains(c.id);
                final equipped = pet?.equipped[c.slot] == c.id;
                final locked = u.unlockStreak < c.requiredStreak;
                final canAfford = u.gems >= c.price;

                String label;
                bool enabled;
                bool outlined = false;
                VoidCallback onTap;

                if (owned) {
                  label = equipped ? 'Quitar' : 'Equipar';
                  enabled = !_busy;
                  outlined = equipped;
                  onTap = () => _toggleEquip(c, u);
                } else if (locked) {
                  label = '🔒 ${c.requiredStreak} días';
                  enabled = false;
                  outlined = true;
                  onTap = () {};
                } else {
                  label = '${c.price} 💎';
                  enabled = canAfford && !_busy;
                  onTap = () => _buyCosmetic(c, u);
                }

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: AppColors.surfaceCard,
                    border: Border.all(
                      color: c.rarity.color.withValues(alpha: equipped ? 0.95 : 0.35),
                      width: equipped ? 1.6 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: Opacity(
                          opacity: locked && !owned ? 0.3 : 1,
                          child: Center(
                            child: Text(c.emoji, style: const TextStyle(fontSize: 44)),
                          ),
                        ),
                      ),
                      Text(c.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _t(14, FontWeight.w800, AppColors.textPrimary)),
                      const SizedBox(height: 4),
                      _Pill(text: c.rarity.label, color: c.rarity.color),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: _BuyButton(
                          label: label,
                          color: c.rarity.color,
                          enabled: enabled,
                          outlined: outlined,
                          compact: true,
                          onTap: onTap,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Widgets pequeños
// ─────────────────────────────────────────────────────────────
class _Chip extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  const _Chip({required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 6),
          Text(text, style: _t(14, FontWeight.w800, color)),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final Color color;
  const _Pill({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text, style: _t(11, FontWeight.w700, color)),
    );
  }
}

class _StatBar extends StatelessWidget {
  final String label;
  final IconData icon;
  final double value;
  final Color color;
  const _StatBar({
    required this.label,
    required this.icon,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final low = value < 25;
    final c = low ? AppColors.error : color;
    return Row(
      children: [
        Icon(icon, color: c, size: 20),
        const SizedBox(width: 10),
        SizedBox(width: 76, child: Text(label, style: _t(13, FontWeight.w700, AppColors.textPrimary))),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (value / 100).clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor: AppColors.surface.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation(c),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 34,
          child: Text('${value.round()}',
              textAlign: TextAlign.right, style: _t(13, FontWeight.w800, c)),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? sub;
  final Color color;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap == null ? 0.5 : 1,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.5)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 26),
              const SizedBox(height: 4),
              Text(label, style: _t(11, FontWeight.w800, color)),
              if (sub != null)
                Text(sub!, style: _t(10, FontWeight.w600, AppColors.textMuted)),
            ],
          ),
        ),
      ),
    );
  }
}

class _BuyButton extends StatelessWidget {
  final String label;
  final Color color;
  final bool enabled;
  final bool outlined;
  final bool compact;
  final VoidCallback onTap;

  const _BuyButton({
    required this.label,
    required this.color,
    required this.enabled,
    required this.outlined,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color bg = outlined
        ? Colors.transparent
        : (enabled ? color : AppColors.surface.withValues(alpha: 0.1));
    final Color fg = outlined ? color : (enabled ? AppColors.textOnPrimary : AppColors.textMuted);

    return Material(
      color: bg,
      shape: StadiumBorder(
        side: outlined
            ? BorderSide(color: color.withValues(alpha: 0.7), width: 1.5)
            : BorderSide.none,
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: enabled ? onTap : null,
        child: Container(
          constraints: BoxConstraints(minWidth: compact ? 0 : 100, minHeight: 40),
          padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 18, vertical: 8),
          alignment: Alignment.center,
          child: Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _t(compact ? 13 : 14, FontWeight.w800, fg)),
        ),
      ),
    );
  }
}

// Círculo pequeño con "?" que abre la guía de mascotas y rangos
class _InfoDot extends StatelessWidget {
  final VoidCallback onTap;
  const _InfoDot({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.primary.withValues(alpha: 0.15),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.7)),
        ),
        child: Text('?', style: _t(15, FontWeight.w800, AppColors.primary)),
      ),
    );
  }
}