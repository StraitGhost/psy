// lib/features/streak/streak_shop_screen.dart
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_colors.dart';
import '../../services/profile_data_service.dart';
import '../../services/streak_service.dart';

// ─────────────────────────────────────────────────────────────
// Duplicador de XP: helper público para usar en el resto de la app
// `userData` es el documento usuarios/{uid}/perfiles/{profileId}
// ─────────────────────────────────────────────────────────────
class XpBoost {
  static const int multiplier = 2;

  static DateTime? activeUntil(Map<String, dynamic> userData) {
    final v = userData['xpBoostUntil'];
    if (v is Timestamp) {
      final dt = v.toDate();
      if (dt.isAfter(DateTime.now())) return dt;
    }
    return null;
  }

  static int multiplierFor(Map<String, dynamic> userData) {
    if (activeUntil(userData) == null) return 1;
    final m = userData['xpBoostMultiplier'];
    return m is num ? m.toInt() : multiplier;
  }
}

TextStyle _t(double size, FontWeight w, Color c, {double? height}) =>
    TextStyle(fontSize: size, fontWeight: w, color: c, height: height);

int _safeInt(dynamic v, {int defaultValue = 0}) {
  if (v == null) return defaultValue;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? defaultValue;
  return defaultValue;
}

String _mmss(Duration d) {
  final s = d.inSeconds.clamp(0, 359999);
  return '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
}

// ─────────────────────────────────────────────────────────────
// Catálogo
// ─────────────────────────────────────────────────────────────
enum _Kind { shield, freeze, xpBoost }

class _Item {
  final String id;
  final _Kind kind;
  final IconData icon;
  final String title;
  final String description;
  final String chip;
  final String? badge;
  final int price;
  final int boostMinutes;

  const _Item({
    required this.id,
    required this.kind,
    required this.icon,
    required this.title,
    required this.description,
    required this.chip,
    required this.price,
    this.badge,
    this.boostMinutes = 0,
  });
}

const _items = <_Item>[
  _Item(
    id: 'shield',
    kind: _Kind.shield,
    icon: Icons.shield_rounded,
    title: 'Escudo de Racha',
    description: 'Protege tu racha si pasas un día sin jugar.',
    chip: '1 vez por compra',
    price: 50,
  ),
  _Item(
    id: 'freeze',
    kind: _Kind.freeze,
    icon: Icons.ac_unit_rounded,
    title: 'Congelador de Racha',
    description: 'Congela tu racha si dejas de jugar varios días.',
    chip: '1 vez por compra',
    price: 100,
  ),
  _Item(
    id: 'xp5',
    kind: _Kind.xpBoost,
    icon: Icons.bolt_rounded,
    title: 'Duplicador de XP · 5 min',
    description: 'Duplica las XP que ganes durante 5 minutos.',
    chip: 'Dura 5 minutos',
    price: 40,
    boostMinutes: 5,
  ),
  _Item(
    id: 'xp10',
    kind: _Kind.xpBoost,
    icon: Icons.bolt_rounded,
    title: 'Duplicador de XP · 10 min',
    description: 'Duplica las XP que ganes durante 10 minutos.',
    chip: 'Dura 10 minutos',
    badge: 'Mejor valor',
    price: 75,
    boostMinutes: 10,
  ),
];

class _ShopException implements Exception {
  final String message;
  _ShopException(this.message);
}

// ─────────────────────────────────────────────────────────────
// Pantalla
// ─────────────────────────────────────────────────────────────
class StreakShopScreen extends StatefulWidget {
  final VoidCallback? onHistory;

  const StreakShopScreen({super.key, this.onHistory});

  @override
  State<StreakShopScreen> createState() => _StreakShopScreenState();
}

class _StreakShopScreenState extends State<StreakShopScreen> {
  Timer? _timer;
  DateTime? _boostUntil;
  String? _busyId;

  /// Documento del perfil activo: usuarios/{uid}/perfiles/{profileId}
  DocumentReference<Map<String, dynamic>>? _ref;
  bool _refReady = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _boostUntil != null) setState(() {});
    });
    ProfileDataService.activeRef().then((r) {
      if (!mounted) return;
      setState(() {
        _ref = r;
        _refReady = true;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<bool> _confirm(_Item item) async {
    final extra = item.kind == _Kind.xpBoost
        ? 'Ganarás el doble de XP durante ${item.boostMinutes} minutos y no podrás comprar otro duplicador hasta que termine.'
        : 'Se guardará en tu inventario y se usa una sola vez.';

    final itemColor = _getItemColor(item);

    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColors.border),
        ),
        title: Text(item.title,
            style: _t(18, FontWeight.w800, AppColors.textPrimary)),
        content: Text(
          '$extra\n\nSe descontarán ${item.price} gemas.',
          style: _t(14, FontWeight.w400, AppColors.textMuted, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar',
                style: _t(14, FontWeight.w600, AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Comprar', style: _t(14, FontWeight.w800, itemColor)),
          ),
        ],
      ),
    );
    return res == true;
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: error
              ? AppColors.error.withValues(alpha: 0.9)
              : AppColors.success.withValues(alpha: 0.9),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Text(msg,
              style: _t(14, FontWeight.w600, AppColors.textOnPrimary)),
        ),
      );
  }

  // `profileId` = id del perfil activo (se pasa desde _body como `uid`)
  Future<void> _buy(_Item item, String profileId) async {
    if (_busyId != null) return;
    final ref = ProfileDataService.refFor(profileId);
    if (ref == null) {
      _snack('No hay un perfil activo.', error: true);
      return;
    }
    if (!await _confirm(item)) return;

    setState(() => _busyId = item.id);
    final db = FirebaseFirestore.instance;

    try {
      await db.runTransaction((tx) async {
        final snap = await tx.get(ref);
        final data = snap.data() ?? <String, dynamic>{};
        final gems = _safeInt(data['gems']);

        if (gems < item.price) {
          throw _ShopException('No tienes suficientes gemas.');
        }

        final updates = <String, dynamic>{'gems': gems - item.price};

        if (item.kind == _Kind.shield) {
          updates['streakShields'] = FieldValue.increment(1);
        } else if (item.kind == _Kind.freeze) {
          updates['streakFreezes'] = FieldValue.increment(1);
        } else {
          final active = XpBoost.activeUntil(data);
          if (active != null) {
            throw _ShopException(
              'Ya tienes un duplicador activo. Espera ${_mmss(active.difference(DateTime.now()))} para comprar otro.',
            );
          }
          updates['xpBoostUntil'] = Timestamp.fromDate(
              DateTime.now().add(Duration(minutes: item.boostMinutes)));
          updates['xpBoostMultiplier'] = XpBoost.multiplier;
          updates['xpBoostMinutes'] = item.boostMinutes;
        }

        tx.set(ref, updates, SetOptions(merge: true));
        tx.set(ref.collection('purchases').doc(), {
          'itemId': item.id,
          'title': item.title,
          'price': item.price,
          'createdAt': FieldValue.serverTimestamp(),
        });
      });

      _snack(
        item.kind == _Kind.xpBoost
            ? '⚡ ¡Duplicador de XP activado! x2 durante ${item.boostMinutes} minutos.'
            : item.kind == _Kind.shield
                ? '🛡️ ¡Escudo comprado! Ya está en tu inventario.'
                : '❄️ ¡Congelador comprado! Ya está en tu inventario.',
      );
    } on _ShopException catch (e) {
      _snack(e.message, error: true);
    } catch (_) {
      _snack('No se pudo completar la compra. Inténtalo de nuevo.',
          error: true);
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Color _getItemColor(_Item item) {
    switch (item.kind) {
      case _Kind.shield:
        return AppColors.info;
      case _Kind.freeze:
        return AppColors.primary;
      case _Kind.xpBoost:
        return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ref = _ref;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.background, AppColors.surface],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: !_refReady
              ? Center(
                  child: CircularProgressIndicator(color: AppColors.primary))
              : ref == null
                  ? Center(
                      child: Text('No hay perfil activo',
                          style: _t(15, FontWeight.w600,
                              AppColors.textPrimary)))
                  : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                      stream: ref.snapshots(),
                      builder: (context, snap) {
                        if (snap.hasError) {
                          return Center(
                            child: Text('No pudimos cargar la tienda.',
                                style: _t(15, FontWeight.w600,
                                    AppColors.textPrimary)),
                          );
                        }
                        final data = (snap.hasData && snap.data!.exists)
                            ? (snap.data!.data() ?? <String, dynamic>{})
                            : <String, dynamic>{};

                        final gems = _safeInt(data['gems']);
                        final streak = StreakService.displayStreak(data);
                        final boostUntil = XpBoost.activeUntil(data);
                        final boostMinutes = _safeInt(data['xpBoostMinutes']);
                        _boostUntil = boostUntil;

                        final owned = {
                          'shield': _safeInt(data['streakShields']),
                          'freeze': _safeInt(data['streakFreezes']),
                        };

                        return Column(
                          children: [
                            _topBar(context, gems),
                            Expanded(
                              child: LayoutBuilder(
                                builder: (_, c) => _body(
                                  c.maxWidth,
                                  uid: ref.id, // id del perfil
                                  gems: gems,
                                  streak: streak,
                                  owned: owned,
                                  boostUntil: boostUntil,
                                  boostMinutes: boostMinutes,
                                ),
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

  Widget _topBar(BuildContext context, int gems) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_rounded,
                color: AppColors.textPrimary, size: 26),
            onPressed: () => Navigator.pop(context),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.diamond_rounded, color: AppColors.primary, size: 18),
                const SizedBox(width: 8),
                Text('$gems',
                    style: _t(15, FontWeight.w800, AppColors.primary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _body(
    double width, {
    required String uid,
    required int gems,
    required int streak,
    required Map<String, int> owned,
    required DateTime? boostUntil,
    required int boostMinutes,
  }) {
    final wide = width >= 900;
    final cols = width >= 1100 ? 4 : (width >= 640 ? 2 : 1);

    final header = _Header(streak: streak, wide: wide);
    final gemsCard = _GemsCard(gems: gems, onHistory: widget.onHistory);
    const info = _InfoCard();

    final rows = <Widget>[];
    for (var i = 0; i < _items.length; i += cols) {
      final chunk = _items.skip(i).take(cols).toList();
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var j = 0; j < cols; j++) ...[
                if (j > 0) const SizedBox(width: 16),
                Expanded(
                  child: j < chunk.length
                      ? _ShopCard(
                          item: chunk[j],
                          gems: gems,
                          owned: owned[chunk[j].id] ?? 0,
                          busy: _busyId == chunk[j].id,
                          anyBusy: _busyId != null,
                          boostUntil: boostUntil,
                          boostMinutes: boostMinutes,
                          onBuy: () => _buy(chunk[j], uid),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ],
          ),
        ),
      );
      if (i + cols < _items.length) rows.add(const SizedBox(height: 16));
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(wide ? 28 : 16, 8, wide ? 28 : 16, 40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1400),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              header,
              const SizedBox(height: 16),
              if (wide)
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(flex: 3, child: gemsCard),
                      const SizedBox(width: 16),
                      const Expanded(flex: 2, child: info),
                    ],
                  ),
                )
              else ...[
                gemsCard,
                const SizedBox(height: 12),
                info,
              ],
              if (boostUntil != null) ...[
                const SizedBox(height: 16),
                _ActiveBoostBanner(
                  until: boostUntil,
                  totalMinutes: boostMinutes,
                ),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  Icon(Icons.auto_awesome_rounded,
                      color: AppColors.primary, size: 22),
                  const SizedBox(width: 10),
                  Text('Potenciadores disponibles',
                      style: _t(20, FontWeight.w800, AppColors.textPrimary)),
                ],
              ),
              const SizedBox(height: 16),
              ...rows,
              const SizedBox(height: 24),
              const _HowItWorks(),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Secciones
// ─────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final int streak;
  final bool wide;
  const _Header({required this.streak, required this.wide});

  @override
  Widget build(BuildContext context) {
    final title = Row(
      children: [
        Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.45),
                blurRadius: 24,
              ),
            ],
          ),
          child: Icon(Icons.storefront_rounded,
              color: AppColors.textOnPrimary, size: 38),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tienda de Racha',
                  style: _t(wide ? 32 : 26, FontWeight.w800,
                      AppColors.textPrimary)),
              const SizedBox(height: 4),
              Text(
                'Canjea tus gemas por potenciadores y mantén viva tu racha.',
                style: _t(14, FontWeight.w400, AppColors.textMuted,
                    height: 1.35),
              ),
            ],
          ),
        ),
      ],
    );

    final streakCard = Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [AppColors.surface, AppColors.surfaceCard],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border:
            Border.all(color: AppColors.borderAccent.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: wide ? MainAxisSize.min : MainAxisSize.max,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.warning.withValues(alpha: 0.5),
                  blurRadius: 28,
                ),
              ],
            ),
            child: Icon(Icons.local_fire_department_rounded,
                color: AppColors.warning, size: 56),
          ),
          const SizedBox(width: 14),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tu racha actual',
                    style: _t(13, FontWeight.w700, AppColors.warning)),
                Text('$streak ${streak == 1 ? 'día' : 'días'}',
                    style: _t(26, FontWeight.w800, AppColors.textPrimary)),
                Text('¡Sigue así y desbloquea más recompensas!',
                    style: _t(11, FontWeight.w400, AppColors.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: [AppColors.surface, AppColors.background],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: AppColors.border),
      ),
      child: wide
          ? Row(
              children: [
                Expanded(child: title),
                const SizedBox(width: 24),
                streakCard,
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [title, const SizedBox(height: 16), streakCard],
            ),
    );
  }
}

class _GemsCard extends StatelessWidget {
  final int gems;
  final VoidCallback? onHistory;
  const _GemsCard({required this.gems, this.onHistory});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 24,
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.diamond_rounded, color: AppColors.primary, size: 52),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tus gemas',
                    style: _t(14, FontWeight.w600, AppColors.primary)),
                TweenAnimationBuilder<int>(
                  tween: IntTween(begin: 0, end: gems),
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.easeOutCubic,
                  builder: (_, v, __) => Text('$v',
                      style: _t(32, FontWeight.w800, AppColors.primary)),
                ),
              ],
            ),
          ),
          if (onHistory != null)
            OutlinedButton.icon(
              onPressed: onHistory,
              icon: Icon(Icons.history_rounded,
                  size: 18, color: AppColors.textPrimary),
              label: Text('Historial',
                  style: _t(14, FontWeight.w700, AppColors.textPrimary)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                side: BorderSide(color: AppColors.border),
                backgroundColor: AppColors.surface,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              ),
            ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(Icons.info_rounded, color: AppColors.info, size: 26),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'Las gemas las obtienes al completar preguntas, lograr rachas y alcanzar nuevos niveles.',
              style: _t(13, FontWeight.w400, AppColors.textSecondary,
                  height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveBoostBanner extends StatelessWidget {
  final DateTime until;
  final int totalMinutes;
  const _ActiveBoostBanner({required this.until, required this.totalMinutes});

  @override
  Widget build(BuildContext context) {
    final remaining = until.difference(DateTime.now());
    final total = Duration(minutes: totalMinutes <= 0 ? 10 : totalMinutes);
    final progress =
        (remaining.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [
            AppColors.warning.withValues(alpha: 0.22),
            AppColors.warning.withValues(alpha: 0.10),
          ],
        ),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bolt_rounded, color: AppColors.warning, size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Duplicador de XP activo · x2',
                    style: _t(15, FontWeight.w800, AppColors.textPrimary)),
              ),
              Text(_mmss(remaining),
                  style: _t(20, FontWeight.w800, AppColors.warning)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: AppColors.textMuted.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.warning),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Todo lo que respondas ahora te da el doble de XP. Podrás comprar otro cuando termine.',
            style: _t(12, FontWeight.w400, AppColors.textMuted, height: 1.35),
          ),
        ],
      ),
    );
  }
}

class _HowItWorks extends StatelessWidget {
  const _HowItWorks();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [AppColors.surface, AppColors.surfaceCard],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border:
            Border.all(color: AppColors.borderAccent.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.card_giftcard_rounded,
                color: AppColors.primary, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('¿Cómo funciona?',
                    style: _t(16, FontWeight.w800, AppColors.textPrimary)),
                const SizedBox(height: 6),
                Text(
                  'El escudo y el congelador se guardan en tu inventario. Si pasas más de un día sin practicar, '
                  'se gasta uno automáticamente al completar tu próxima lección y tu racha continúa. '
                  'El duplicador de XP se activa al comprarlo, dura 5 o 10 minutos y no puedes comprar otro hasta que termine.',
                  style: _t(13, FontWeight.w400, AppColors.textSecondary,
                      height: 1.45),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Tarjeta de producto
// ─────────────────────────────────────────────────────────────
class _ShopCard extends StatelessWidget {
  final _Item item;
  final int gems;
  final int owned;
  final bool busy;
  final bool anyBusy;
  final DateTime? boostUntil;
  final int boostMinutes;
  final VoidCallback onBuy;

  const _ShopCard({
    required this.item,
    required this.gems,
    required this.owned,
    required this.busy,
    required this.anyBusy,
    required this.boostUntil,
    required this.boostMinutes,
    required this.onBuy,
  });

  Color get _itemColor {
    switch (item.kind) {
      case _Kind.shield:
        return AppColors.info;
      case _Kind.freeze:
        return AppColors.primary;
      case _Kind.xpBoost:
        return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _itemColor;
    final isBoost = item.kind == _Kind.xpBoost;
    final boostActive = isBoost && boostUntil != null;
    final isThisBoost = boostActive && boostMinutes == item.boostMinutes;
    final canAfford = gems >= item.price;

    String label = 'Comprar';
    bool enabled = canAfford && !anyBusy;
    bool outlined = false;

    if (boostActive) {
      enabled = false;
      outlined = true;
      label = isThisBoost
          ? '⚡ ${_mmss(boostUntil!.difference(DateTime.now()))}'
          : 'No disponible';
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: [c.withValues(alpha: 0.18), AppColors.surfaceCard],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: c.withValues(alpha: isThisBoost ? 0.9 : 0.4),
          width: isThisBoost ? 1.6 : 1,
        ),
        boxShadow: [
          BoxShadow(color: c.withValues(alpha: 0.10), blurRadius: 26)
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HexBadge(icon: item.icon, color: c, size: 84),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.title,
                              style: _t(16, FontWeight.w800,
                                  AppColors.textPrimary,
                                  height: 1.2)),
                          const SizedBox(height: 6),
                          Text(item.description,
                              style: _t(13, FontWeight.w400,
                                  AppColors.textMuted,
                                  height: 1.4)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _Pill(
                      icon: Icons.info_outline_rounded,
                      text: item.chip,
                      color: AppColors.textMuted),
                  if (item.badge != null)
                    _Pill(
                        icon: Icons.star_rounded,
                        text: item.badge!,
                        color: c,
                        filled: true),
                  if (!isBoost && owned > 0)
                    _Pill(
                        icon: Icons.inventory_2_rounded,
                        text: 'Tienes: $owned',
                        color: AppColors.success,
                        filled: true),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Icon(Icons.diamond_rounded, color: AppColors.primary, size: 22),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${item.price}',
                      style: _t(20, FontWeight.w800, AppColors.textPrimary)),
                  if (!canAfford && !boostActive)
                    Text('Te faltan ${item.price - gems}',
                        style: _t(10, FontWeight.w600, AppColors.error)),
                ],
              ),
              const Spacer(),
              _BuyButton(
                  label: label,
                  color: c,
                  enabled: enabled,
                  outlined: outlined,
                  loading: busy,
                  onTap: onBuy),
            ],
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  final bool filled;

  const _Pill(
      {required this.icon,
      required this.text,
      required this.color,
      this.filled = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: filled ? color.withValues(alpha: 0.16) : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(text, style: _t(11, FontWeight.w600, color)),
        ],
      ),
    );
  }
}

class _BuyButton extends StatelessWidget {
  final String label;
  final Color color;
  final bool enabled;
  final bool outlined;
  final bool loading;
  final VoidCallback onTap;

  const _BuyButton(
      {required this.label,
      required this.color,
      required this.enabled,
      required this.outlined,
      required this.loading,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final Color bg =
        outlined ? Colors.transparent : (enabled ? color : AppColors.surface);
    final Color fg = outlined
        ? color
        : (enabled ? AppColors.textOnPrimary : AppColors.textMuted);

    return Material(
      color: bg,
      shape: StadiumBorder(
        side: outlined
            ? BorderSide(color: color.withValues(alpha: 0.7), width: 1.5)
            : BorderSide.none,
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: enabled && !loading ? onTap : null,
        child: Container(
          constraints: const BoxConstraints(minWidth: 112, minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
          alignment: Alignment.center,
          child: loading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: fg))
              : Text(label, style: _t(15, FontWeight.w800, fg)),
        ),
      ),
    );
  }
}

class _HexBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  const _HexBadge(
      {required this.icon, required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(child: CustomPaint(painter: _HexPainter(color))),
          Icon(icon, color: color, size: size * 0.46),
        ],
      ),
    );
  }
}

class _HexPainter extends CustomPainter {
  final Color color;
  _HexPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2 - 8;
    final path = Path();
    for (var i = 0; i < 6; i++) {
      final a = -math.pi / 2 + i * math.pi / 3;
      final p = c + Offset(math.cos(a), math.sin(a)) * r;
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    path.close();

    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..color = color.withValues(alpha: 0.55)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9),
    );
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          colors: [
            color.withValues(alpha: 0.38),
            color.withValues(alpha: 0.10)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeJoin = StrokeJoin.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant _HexPainter old) => old.color != color;
}