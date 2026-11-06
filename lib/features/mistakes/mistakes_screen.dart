// lib/features/mistakes/mistakes_screen.dart
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/theme/app_colors.dart';
import '../../models/profile.dart';
import '../../services/learning_progress_service.dart';
import '../game/game_screen.dart';

// ─────────────────────────────────────────────────────────────────────────
// Nombres de campo ULTRA-FLEXIBLES (Sin tildes en los nombres de variables)
// ─────────────────────────────────────────────────────────────────────────
class _K {
  static const pregunta = 'pregunta';
  static const text = 'text';
  static const question = 'question';
  static const prompt = 'prompt';

  static const opciones = 'opciones';
  static const options = 'options';
  static const choices = 'choices';
  static const alternativas = 'alternativas';

  static const respuestaCorrecta = 'respuesta_correcta';
  static const respuestaCorrectaCamel = 'respuestaCorrecta';
  static const correctIndex = 'correctIndex';
  static const correctIndexSnake = 'correct_index';
  static const answerIndex = 'answerIndex';
  static const correcta = 'correcta';

  static const afirmacion = 'afirmacion';
  static const afirmacionTilde = 'afirmación';
  static const esVerdadero = 'esVerdadero';
  static const esVerdaderoSnake = 'es_verdadero';
  static const isTrue = 'isTrue';
  static const isTrueSnake = 'is_true';
  static const verdadero = 'verdadero';

  static const oracion = 'oracion';
  static const oracionTilde = 'oración';
  static const sentence = 'sentence';
  static const frase = 'frase';
  static const texto = 'texto';
  static const respuesta = 'respuesta';
  static const answer = 'answer';
  static const answers = 'answers';
  static const respuestas = 'respuestas';
  static const solucion = 'solucion';
  static const solution = 'solution';

  static const instruccion = 'instruccion';
  static const instruccionTilde = 'instrucción';
  static const instruction = 'instruction';
  static const elementos = 'elementos';
  static const items = 'items';
  static const item = 'item';
  static const lista = 'lista';
  static const list = 'list';
  static const ordenCorrecto = 'orden_correcto';
  static const correctOrder = 'correctOrder';
  static const correctOrderSnake = 'correct_order';

  static const explicacion = 'explicacion';
  static const explicacionTilde = 'explicación';
  static const justificacion = 'justificacion';
  static const justificacionTilde = 'justificación';
  static const explanation = 'explanation';
  static const tipo = 'tipo';
  static const type = 'type';
  static const questionType = 'questionType';
  static const questionTypeSnake = 'question_type';
}

enum _MType { multipleChoice, trueFalse, fillBlank, ordering, unsupported }

_MType _detectType(Map<String, dynamic> q) {
  final tipoField = q[_K.tipo] ?? q[_K.type] ?? q[_K.questionType] ?? q[_K.questionTypeSnake];
  if (tipoField != null) {
    final tipoStr = tipoField.toString().toLowerCase();
    if (tipoStr.contains('multiple') || tipoStr.contains('opcion') || tipoStr.contains('option')) return _MType.multipleChoice;
    if (tipoStr.contains('true') || tipoStr.contains('false') || tipoStr.contains('verdadero') || tipoStr.contains('falso')) return _MType.trueFalse;
    if (tipoStr.contains('fill') || tipoStr.contains('completar') || tipoStr.contains('blank')) return _MType.fillBlank;
    if (tipoStr.contains('order') || tipoStr.contains('ordenar') || tipoStr.contains('secuencia')) return _MType.ordering;
  }

  final hasOptions = q.containsKey(_K.opciones) || q.containsKey(_K.options) || q.containsKey(_K.choices) || q.containsKey(_K.alternativas);
  if (hasOptions && (q[_K.opciones] is List || q[_K.options] is List || q[_K.choices] is List)) {
    return _MType.multipleChoice;
  }

  final hasTrueFalse = q.containsKey(_K.afirmacion) || q.containsKey(_K.afirmacionTilde) || q.containsKey(_K.esVerdadero) || q.containsKey(_K.esVerdaderoSnake) || q.containsKey(_K.isTrue) || q.containsKey(_K.isTrueSnake) || q.containsKey(_K.verdadero);
  if (hasTrueFalse) return _MType.trueFalse;

  final sentenceField = q[_K.oracion] ?? q[_K.oracionTilde] ?? q[_K.sentence] ?? q[_K.frase] ?? q[_K.texto] ?? q[_K.pregunta] ?? '';
  final hasFillBlank = q.containsKey(_K.oracion) || q.containsKey(_K.oracionTilde) || q.containsKey(_K.sentence) || (sentenceField.toString().contains('___'));
  if (hasFillBlank) return _MType.fillBlank;

  final hasItems = q.containsKey(_K.elementos) || q.containsKey(_K.items) || q.containsKey(_K.item) || q.containsKey(_K.lista) || q.containsKey(_K.list);
  final hasOrder = q.containsKey(_K.ordenCorrecto) || q.containsKey(_K.correctOrder) || q.containsKey(_K.correctOrderSnake) || q.containsKey(_K.instruccion) || q.containsKey(_K.instruccionTilde) || q.containsKey(_K.instruction);
  if (hasItems && hasOrder) return _MType.ordering;

  final hasQuestion = q.containsKey(_K.pregunta) || q.containsKey(_K.text) || q.containsKey(_K.question) || q.containsKey(_K.prompt);
  if (hasQuestion) {
    if (hasOptions) return _MType.multipleChoice;
    final questionText = (q[_K.pregunta] ?? q[_K.text] ?? q[_K.question] ?? '').toString();
    if (questionText.contains('___')) return _MType.fillBlank;
    return _MType.trueFalse;
  }

  return _MType.unsupported;
}

class MistakesScreen extends StatefulWidget {
  final UserProfile userProfile;
  const MistakesScreen({super.key, required this.userProfile});

  @override
  State<MistakesScreen> createState() => _MistakesScreenState();
}

class _MistakesScreenState extends State<MistakesScreen> {
  final LearningProgressService _service = LearningProgressService();
  final TextEditingController _fillController = TextEditingController();

  bool _loading = true;
  final List<Map<String, dynamic>> _queue = [];
  int _totalAtStart = 0;
  int _corrected = 0;
  int _skipped = 0;

  bool _revealed = false;
  bool _lastCorrect = false;
  int? _mcSelected;
  bool? _tfSelected;
  List<int>? _order;
  bool _shaking = false;

  // Señales de corrección
  bool _clearFailed = false; // falló el borrado del error en Firestore
  bool _changed = false; // al menos un error se borró de verdad

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _fillController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final list = await _service.getMistakes().first;
    if (!mounted) return;
    setState(() {
      _queue
        ..clear()
        ..addAll(list);
      _totalAtStart = list.length;
      _loading = false;
      if (_queue.isNotEmpty) _prepareCurrent();
    });
  }

  void _close() {
    Navigator.pop(context, _changed);
  }

  Map<String, dynamic> get _mistake => _queue.first;
  Map<String, dynamic> get _q => Map<String, dynamic>.from(_mistake['questionData'] ?? {});
  _MType get _type => _detectType(_q);
  String get _tema => (_mistake['tema'] ?? 'General').toString();
  int get _attempts => (_mistake['attempts'] ?? 1) as int;

  String _getQuestionText() {
    if (_q.containsKey(_K.pregunta)) return _q[_K.pregunta].toString();
    if (_q.containsKey(_K.text)) return _q[_K.text].toString();
    if (_q.containsKey(_K.question)) return _q[_K.question].toString();
    if (_q.containsKey(_K.prompt)) return _q[_K.prompt].toString();
    if (_q.containsKey(_K.afirmacion)) return _q[_K.afirmacion].toString();
    if (_q.containsKey(_K.afirmacionTilde)) return _q[_K.afirmacionTilde].toString();
    if (_q.containsKey(_K.oracion)) return _q[_K.oracion].toString();
    if (_q.containsKey(_K.oracionTilde)) return _q[_K.oracionTilde].toString();
    if (_q.containsKey(_K.instruccion)) return _q[_K.instruccion].toString();
    if (_q.containsKey(_K.instruccionTilde)) return _q[_K.instruccionTilde].toString();
    return 'Pregunta sin texto';
  }

  void _prepareCurrent() {
    _revealed = false;
    _lastCorrect = false;
    _clearFailed = false;
    _mcSelected = null;
    _tfSelected = null;
    _fillController.clear();
    _order = null;

    if (_type == _MType.ordering) {
      final items = _items(_q);
      final order = List<int>.generate(items.length, (i) => i)..shuffle();
      if (order.length > 1 && _isOrderCorrect(order)) {
        order.add(order.removeAt(0));
      }
      _order = order;
    }
  }

  List<String> _options(Map<String, dynamic> q) {
    if (q.containsKey(_K.opciones)) return List<String>.from(q[_K.opciones] ?? const []);
    if (q.containsKey(_K.options)) return List<String>.from(q[_K.options] ?? const []);
    if (q.containsKey(_K.choices)) return List<String>.from(q[_K.choices] ?? const []);
    if (q.containsKey(_K.alternativas)) return List<String>.from(q[_K.alternativas] ?? const []);
    return const [];
  }

  List<String> _items(Map<String, dynamic> q) {
    if (q.containsKey(_K.elementos)) return List<String>.from(q[_K.elementos] ?? const []);
    if (q.containsKey(_K.items)) return List<String>.from(q[_K.items] ?? const []);
    if (q.containsKey(_K.item)) return List<String>.from(q[_K.item] ?? const []);
    if (q.containsKey(_K.lista)) return List<String>.from(q[_K.lista] ?? const []);
    if (q.containsKey(_K.list)) return List<String>.from(q[_K.list] ?? const []);
    return const [];
  }

  String _explanation(Map<String, dynamic> q) {
    if (q.containsKey(_K.explicacion)) return q[_K.explicacion].toString();
    if (q.containsKey(_K.explicacionTilde)) return q[_K.explicacionTilde].toString();
    if (q.containsKey(_K.justificacion)) return q[_K.justificacion].toString();
    if (q.containsKey(_K.justificacionTilde)) return q[_K.justificacionTilde].toString();
    if (q.containsKey(_K.explanation)) return q[_K.explanation].toString();
    return 'Revisa el documento de estudio.';
  }

  int _correctIndexMC(Map<String, dynamic> q) {
    if (q.containsKey(_K.respuestaCorrecta)) {
      final raw = q[_K.respuestaCorrecta];
      if (raw is int) return raw;
      if (raw is num) return raw.toInt();
      if (raw is String) {
        final options = _options(q);
        final byText = options.indexOf(raw);
        if (byText >= 0) return byText;
        if (raw.trim().length == 1) {
          final byLetter = raw.trim().toUpperCase().codeUnitAt(0) - 65;
          if (byLetter >= 0 && byLetter < options.length) return byLetter;
        }
      }
    }
    if (q.containsKey(_K.respuestaCorrectaCamel)) {
      final raw = q[_K.respuestaCorrectaCamel];
      if (raw is int) return raw;
    }
    if (q.containsKey(_K.correctIndex)) return (q[_K.correctIndex] as num).toInt();
    if (q.containsKey(_K.correctIndexSnake)) return (q[_K.correctIndexSnake] as num).toInt();
    if (q.containsKey(_K.answerIndex)) return (q[_K.answerIndex] as num).toInt();
    if (q.containsKey(_K.correcta)) return (q[_K.correcta] as num).toInt();
    return 0;
  }

  bool _correctTF(Map<String, dynamic> q) {
    if (q.containsKey(_K.esVerdadero)) return (q[_K.esVerdadero] ?? true) as bool;
    if (q.containsKey(_K.esVerdaderoSnake)) return (q[_K.esVerdaderoSnake] ?? true) as bool;
    if (q.containsKey(_K.isTrue)) return (q[_K.isTrue] ?? true) as bool;
    if (q.containsKey(_K.isTrueSnake)) return (q[_K.isTrueSnake] ?? true) as bool;
    if (q.containsKey(_K.verdadero)) return (q[_K.verdadero] ?? true) as bool;
    return true;
  }

  List<String> _blankAnswers(Map<String, dynamic> q) {
    if (q.containsKey(_K.respuesta)) {
      final raw = q[_K.respuesta];
      if (raw is List) return raw.map((e) => e.toString()).toList();
      if (raw != null) return [raw.toString()];
    }
    if (q.containsKey(_K.answer)) {
      final raw = q[_K.answer];
      if (raw is List) return raw.map((e) => e.toString()).toList();
      if (raw != null) return [raw.toString()];
    }
    if (q.containsKey(_K.answers)) {
      final raw = q[_K.answers];
      if (raw is List) return raw.map((e) => e.toString()).toList();
    }
    if (q.containsKey(_K.respuestas)) {
      final raw = q[_K.respuestas];
      if (raw is List) return raw.map((e) => e.toString()).toList();
    }
    if (q.containsKey(_K.solucion)) {
      final raw = q[_K.solucion];
      if (raw is List) return raw.map((e) => e.toString()).toList();
      if (raw != null) return [raw.toString()];
    }
    if (q.containsKey(_K.solution)) {
      final raw = q[_K.solution];
      if (raw is List) return raw.map((e) => e.toString()).toList();
      if (raw != null) return [raw.toString()];
    }
    return const [];
  }

  String _norm(String s) {
    const from = 'áéíóúüñ';
    const to = 'aeiouun';
    var out = s.trim().toLowerCase();
    for (var i = 0; i < from.length; i++) {
      out = out.replaceAll(from[i], to[i]);
    }
    return out;
  }

  bool _isOrderCorrect(List<int> order) {
    for (var i = 0; i < order.length; i++) {
      if (order[i] != i) return false;
    }
    return true;
  }

  Future<void> _answer(bool correct) async {
    if (_revealed) return;
    HapticFeedback.mediumImpact();

    final questionId = _mistake['questionId'];

    setState(() {
      _revealed = true;
      _lastCorrect = correct;
      _clearFailed = false;
    });

    if (correct) {
      try {
        await _service.clearMistake(questionId);
        _changed = true;
      } catch (e) {
        debugPrint('Error al limpiar el error: $e');
        if (mounted) setState(() => _clearFailed = true);
      }
    } else {
      setState(() => _shaking = true);
      Future.delayed(const Duration(milliseconds: 450), () {
        if (mounted) setState(() => _shaking = false);
      });
    }
  }

  void _verifyFillBlank() {
    if (_revealed) return;
    final answers = _blankAnswers(_q).map(_norm).toSet();
    _answer(answers.contains(_norm(_fillController.text)));
  }

  void _verifyOrdering() {
    if (_revealed || _order == null) return;
    _answer(_isOrderCorrect(_order!));
  }

  void _next() {
    setState(() {
      if (_lastCorrect) {
        _corrected++;
      } else {
        _skipped++;
      }
      _queue.removeAt(0);
      if (_queue.isNotEmpty) _prepareCurrent();
    });
  }

  void _reorder(int oldIndex, int newIndex) {
    if (_revealed || _order == null) return;
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      _order!.insert(newIndex, _order!.removeAt(oldIndex));
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _close();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter, 
              end: Alignment.bottomCenter, 
              colors: [AppColors.surface, AppColors.background]
            ),
          ),
          child: SafeArea(
            child: _loading
                ? Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _queue.isEmpty
                    ? (_totalAtStart == 0 ? _buildEmpty() : _buildSessionDone())
                    : _buildQuiz(context),
          ),
        ),
      ),
    );
  }

  Widget _topBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary, size: 32),
            onPressed: _close,
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Column(
      children: [
        _topBar(context),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.success.withValues(alpha: 0.15),
                      border: Border.all(color: AppColors.success.withValues(alpha: 0.6), width: 2),
                      boxShadow: [BoxShadow(color: AppColors.success.withValues(alpha: 0.3), blurRadius: 40)],
                    ),
                    child: Icon(Icons.check_rounded, size: 72, color: AppColors.success),
                  ),
                  const SizedBox(height: 32),
                  Text('No tienes errores', style: TextStyle(color: AppColors.textPrimary, fontSize: 32, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 16),
                  Text(
                    'Cuando falles una pregunta aparecerá aquí para que la repases.\nPor ahora vas muy bien.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textMuted, fontSize: 18, height: 1.4),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSessionDone() {
    final total = _corrected + _skipped;
    return Column(
      children: [
        _topBar(context),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: [AppColors.primary, AppColors.secondary]),
                      boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.45), blurRadius: 32)],
                    ),
                    child: Icon(Icons.emoji_events_rounded, size: 64, color: AppColors.textOnPrimary),
                  ),
                  const SizedBox(height: 32),
                  Text('¡Sesión terminada!', style: TextStyle(color: AppColors.textPrimary, fontSize: 32, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 16),
                  Text(
                    'Corregiste $_corrected de $total ${total == 1 ? "error" : "errores"}.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 18),
                  ),
                  if (_skipped > 0) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Los $_skipped que aún fallaste te esperan la próxima vez.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textMuted, fontSize: 16),
                    ),
                  ],
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    child: _GradientButton(
                      label: 'Volver al inicio',
                      icon: Icons.check_rounded,
                      onPressed: _close,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuiz(BuildContext context) {
    final total = _totalAtStart;
    final position = total - _queue.length + 1;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary, size: 32),
                    onPressed: _close,
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: _ProgressBar(current: _corrected, total: total)),
                ],
              ),
              const SizedBox(height: 32),
              Text(
                '¡Vamos a mejorar!',
                style: TextStyle(color: AppColors.info, fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'Corrige tus errores',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 36, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              Text(
                'Revisa cada pregunta, corrige el error y avanza.\nCada acierto te acerca a dominar el tema.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 16, height: 1.4),
              ),
              const SizedBox(height: 32),
              _ShakeWrap(
                active: _shaking,
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: AppColors.border, width: 1.5),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 32, offset: const Offset(0, 16))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _Chip(icon: Icons.auto_awesome_rounded, label: _tema),
                          _Pill(text: 'Pregunta $position / $total'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: _Pill(text: 'Fallaste $_attempts ${_attempts == 1 ? "vez" : "veces"}', muted: true),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        _getQuestionText(),
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 28),
                      KeyedSubtree(
                        key: ValueKey(_mistake['questionId']),
                        child: _buildBody(),
                      ),
                      if (_revealed) ...[
                        const SizedBox(height: 28),
                        _FeedbackPanel(
                          isCorrect: _lastCorrect,
                          explanation: _explanation(_q),
                          detail: _lastCorrect
                              ? (_clearFailed
                                  ? 'Correcto, pero no se pudo actualizar tu lista de errores.'
                                  : 'Error corregido: ya salió de tu lista de errores.')
                              : _wrongDetail(),
                        ),
                      ],
                      const SizedBox(height: 32),
                      SizedBox(width: double.infinity, child: _buildActionButton()),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _wrongDetail() {
    switch (_type) {
      case _MType.trueFalse:
        return 'Respuesta correcta: ${_correctTF(_q) ? "Verdadero" : "Falso"}';
      case _MType.multipleChoice:
        final i = _correctIndexMC(_q);
        final options = _options(_q);
        if (i < 0 || i >= options.length) return null;
        return 'Respuesta correcta: ${String.fromCharCode(65 + i)}. ${options[i]}';
      case _MType.fillBlank:
        final answers = _blankAnswers(_q);
        if (answers.isEmpty) return null;
        return 'Respuesta correcta: ${answers.first}';
      case _MType.ordering:
        return 'Revisa el orden correcto arriba.';
      case _MType.unsupported:
        return 'No se pudo determinar el tipo de pregunta. Revisa los campos en Firestore.';
    }
  }

  Widget _buildBody() {
    switch (_type) {
      case _MType.multipleChoice:
        return _buildMultipleChoice();
      case _MType.trueFalse:
        return _buildTrueFalse();
      case _MType.fillBlank:
        return _buildFillBlank();
      case _MType.ordering:
        return _buildOrdering();
      case _MType.unsupported:
        return _buildUnsupported();
    }
  }

  Widget _buildMultipleChoice() {
    final options = _options(_q);
    final correctIndex = _correctIndexMC(_q);
    return Column(
      children: [
        for (var i = 0; i < options.length; i++) ...[
          if (i > 0) const SizedBox(height: 16),
          _OptionRow(
            letter: String.fromCharCode(65 + i),
            text: options[i],
            state: _revealed ? (i == _mcSelected ? (i == correctIndex ? _OState.correct : _OState.wrong) : _OState.idle) : _OState.idle,
            onTap: _revealed
                ? null
                : () {
                    setState(() => _mcSelected = i);
                    _answer(i == correctIndex);
                  },
          ),
        ],
      ],
    );
  }

  Widget _buildTrueFalse() {
    final correct = _correctTF(_q);
    Widget row(bool value, String label) {
      return _OptionRow(
        letter: value ? 'V' : 'F',
        text: label,
        state: _revealed ? (_tfSelected == value ? (value == correct ? _OState.correct : _OState.wrong) : _OState.idle) : _OState.idle,
        onTap: _revealed
            ? null
            : () {
                setState(() => _tfSelected = value);
                _answer(value == correct);
              },
      );
    }

    return Column(children: [row(true, 'Verdadero'), const SizedBox(height: 16), row(false, 'Falso')]);
  }

  Widget _buildFillBlank() {
    final sentence = (_q[_K.oracion] ?? _q[_K.oracionTilde] ?? _q[_K.sentence] ?? _q[_K.pregunta] ?? '').toString();
    final parts = sentence.split('___');
    final before = parts.first;
    final after = parts.length > 1 ? parts.sublist(1).join(' ') : '';
    final color = !_revealed ? AppColors.primary : (_lastCorrect ? AppColors.success : AppColors.error);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            style: TextStyle(color: AppColors.textPrimary, fontSize: 20, height: 1.6),
            children: [
              TextSpan(text: before),
              WidgetSpan(
                alignment: PlaceholderAlignment.baseline,
                baseline: TextBaseline.alphabetic,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 120),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(border: Border(bottom: BorderSide(color: color, width: 3))),
                  child: Text(_fillController.text.isEmpty ? ' ' : _fillController.text, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 20)),
                ),
              ),
              TextSpan(text: after),
            ],
          ),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _fillController,
          enabled: !_revealed,
          onChanged: (_) => setState(() {}),
          style: TextStyle(color: AppColors.textPrimary, fontSize: 18),
          cursorColor: AppColors.info,
          decoration: InputDecoration(
            hintText: 'Escribe la respuesta...',
            hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 16),
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: AppColors.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: AppColors.info, width: 2)),
            disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: color, width: 2)),
          ),
        ),
      ],
    );
  }

  Widget _buildOrdering() {
    final items = _items(_q);
    final order = _order ?? List<int>.generate(items.length, (i) => i);

    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: false,
      itemCount: order.length,
      onReorder: (int oldIndex, int newIndex) {
        _reorder(oldIndex, newIndex);
      },
      proxyDecorator: (child, index, animation) => Material(color: Colors.transparent, child: child),
      itemBuilder: (context, position) {
        final itemIndex = order[position];
        Color border = AppColors.border;
        if (_revealed) border = position == itemIndex ? AppColors.success : AppColors.error;

        return Container(
          key: ValueKey(itemIndex),
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border, width: _revealed ? 2 : 1.5),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle, 
                  gradient: LinearGradient(colors: [AppColors.primary, AppColors.secondary])
                ),
                child: Text('${position + 1}', style: TextStyle(color: AppColors.textOnPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 16),
              Expanded(child: Text(items[itemIndex], style: TextStyle(color: AppColors.textPrimary, fontSize: 16))),
              if (!_revealed)
                ReorderableDragStartListener(
                  index: position,
                  child: Icon(Icons.drag_indicator_rounded, color: AppColors.textMuted, size: 28),
                )
              else
                Icon(
                  position == itemIndex ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  color: position == itemIndex ? AppColors.success : AppColors.error,
                  size: 24,
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUnsupported() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
      child: Text(
        'No se pudo determinar el tipo de pregunta. Asegúrate de que los campos en Firestore coincidan con: pregunta, opciones, afirmacion, oracion o elementos.',
        style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
      ),
    );
  }

  Widget _buildActionButton() {
    if (_revealed) {
      return _GradientButton(label: 'Siguiente', icon: Icons.arrow_forward_rounded, onPressed: _next);
    }
    switch (_type) {
      case _MType.fillBlank:
        return _GradientButton(label: 'Verificar', icon: Icons.check_rounded, onPressed: _fillController.text.trim().isEmpty ? null : _verifyFillBlank);
      case _MType.ordering:
        return _GradientButton(label: 'Verificar', icon: Icons.check_rounded, onPressed: _verifyOrdering);
      case _MType.unsupported:
        return _GradientButton(label: 'Marcar como corregido', icon: Icons.check_rounded, onPressed: () => _answer(true));
      case _MType.multipleChoice:
      case _MType.trueFalse:
        return const _GradientButton(label: 'Siguiente', icon: Icons.arrow_forward_rounded, onPressed: null);
    }
  }
}

// ─────────────────────────── Widgets de apoyo ──────────────────────────

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.current, required this.total});
  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    final value = total == 0 ? 0.0 : (current / total).clamp(0.0, 1.0);
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value.toDouble()),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      builder: (context, v, _) => Container(
        height: 12,
        decoration: BoxDecoration(color: AppColors.surface.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
        child: Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: v,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: LinearGradient(colors: [AppColors.primary, AppColors.info]),
                boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.6), blurRadius: 12)],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.55)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, this.muted = false});
  final String text;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(24)),
      child: Text(
        text,
        style: TextStyle(color: muted ? AppColors.warning : AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w600),
      ),
    );
  }
}

enum _OState { idle, correct, wrong }

class _OptionRow extends StatelessWidget {
  const _OptionRow({required this.letter, required this.text, required this.state, required this.onTap});
  final String letter;
  final String text;
  final _OState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    Color border = AppColors.border;
    Color badgeBg = AppColors.surface;
    IconData? trailing;
    Color trailingColor = Colors.transparent;

    if (state == _OState.correct) {
      border = AppColors.success;
      trailing = Icons.check_rounded;
      trailingColor = AppColors.success;
    } else if (state == _OState.wrong) {
      border = AppColors.error;
      trailing = Icons.close_rounded;
      trailingColor = AppColors.error;
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: border, width: state == _OState.idle ? 1.5 : 2.5),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(shape: BoxShape.circle, color: badgeBg, border: Border.all(color: AppColors.border)),
              child: Text(letter, style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 16),
            Expanded(child: Text(text, style: TextStyle(color: AppColors.textPrimary, fontSize: 18, height: 1.3))),
            if (trailing != null) ...[
              const SizedBox(width: 12),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(shape: BoxShape.circle, color: trailingColor),
                child: Icon(trailing, size: 20, color: AppColors.textOnPrimary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FeedbackPanel extends StatelessWidget {
  const _FeedbackPanel({required this.isCorrect, required this.explanation, this.detail});
  final bool isCorrect;
  final String explanation;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final color = isCorrect ? AppColors.success : AppColors.error;
    final hasExplanation = explanation.trim().isNotEmpty;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutBack,
      builder: (context, v, child) => Opacity(opacity: v.clamp(0.0, 1.0).toDouble(), child: Transform.translate(offset: Offset(0, 10 * (1 - v)), child: child)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20), border: Border.all(color: color, width: 2)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color),
              child: Icon(isCorrect ? Icons.check_rounded : Icons.close_rounded, color: AppColors.textOnPrimary, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isCorrect ? '¡Correcto!' : 'Incorrecto', style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w800)),
                  if (detail != null) ...[
                    const SizedBox(height: 8),
                    Text(detail!, style: TextStyle(color: AppColors.textSecondary, fontSize: 16, height: 1.4)),
                  ],
                  if (hasExplanation) ...[
                    const SizedBox(height: 8),
                    Text(explanation, style: TextStyle(color: AppColors.textMuted, fontSize: 16, height: 1.4)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  const _GradientButton({required this.label, required this.icon, required this.onPressed});
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return AnimatedOpacity(
      opacity: enabled ? 1 : 0.45,
      duration: const Duration(milliseconds: 180),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AppColors.primary, AppColors.secondary]),
              borderRadius: BorderRadius.circular(20),
              boxShadow: enabled ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.45), blurRadius: 24)] : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: AppColors.textOnPrimary, size: 24),
                const SizedBox(width: 12),
                Text(label, style: TextStyle(color: AppColors.textOnPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ShakeWrap extends StatelessWidget {
  const _ShakeWrap({required this.active, required this.child});
  final bool active;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: active ? 1 : 0),
      duration: const Duration(milliseconds: 450),
      child: child,
      builder: (context, t, child) {
        final dx = math.sin(t * math.pi * 6) * 12 * (1 - t);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
    );
  }
}