// lib/features/game/game_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import '../../core/theme/app_colors.dart';
import '../../models/profile.dart';
import '../../services/learning_progress_service.dart';
import '../../services/profile_data_service.dart';
import 'widgets/question_hero.dart';
import 'widgets/question_layout.dart';
import 'widgets/question_header.dart';
import 'widgets/multiple_choice_widget.dart';
import 'widgets/true_false_widget.dart';
import 'widgets/fill_blank_widget.dart';
import 'widgets/matching_widget.dart';
import 'widgets/ordering_widget.dart';
import 'widgets/explanation_widget.dart';
import 'widgets/action_hint_widget.dart';
import 'widgets/next_button_widget.dart';
import 'widgets/game_result_screen.dart';

enum QuestionType { trueFalse, multipleChoice, matching, ordering, fillBlank }

/// Convierte cualquier valor de Firestore (int, double, String) a int.
int _safeInt(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) {
    return int.tryParse(v) ?? double.tryParse(v)?.toInt() ?? 0;
  }
  return 0;
}

class GameQuestion {
  const GameQuestion({
    required this.questionId,
    required this.type,
    required this.topic,
    required this.topicIcon,
    required this.prompt,
    required this.hint,
    required this.explanation,
    this.artIcon = Icons.psychology_outlined,
    this.answerIsTrue = true,
    this.options = const [],
    this.correctIndex = 0,
    this.pairs = const [],
    this.matchLeftTitle = 'Términos',
    this.matchRightTitle = 'Descripciones',
    this.orderedItems = const [],
    this.correctOrder = const [],
    this.blankSentence = '',
    this.blankAnswers = const [],
  });

  final String questionId;
  final QuestionType type;
  final String topic;
  final IconData topicIcon;
  final String prompt;
  final String hint;
  final String explanation;
  final IconData artIcon;
  final bool answerIsTrue;
  final List<String> options;
  final int correctIndex;
  final List<MatchPair> pairs;
  final String matchLeftTitle;
  final String matchRightTitle;
  final List<String> orderedItems;
  final List<String> correctOrder;
  final String blankSentence;
  final List<String> blankAnswers;
}

class GameScreen extends StatefulWidget {
  final String moduleName;
  final UserProfile userProfile;
  final String? reviewQuestionId;

  const GameScreen({
    super.key,
    required this.moduleName,
    required this.userProfile,
    this.reviewQuestionId,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  static const _starsPerCorrect = 10;
  final _scroll = ScrollController();
  final LearningProgressService _progressService = LearningProgressService();

  List<GameQuestion> _questions = [];
  int _index = 0;
  int _stars = 0;
  int _correct = 0;
  bool _finished = false;
  bool _isLoading = true;

  bool _revealed = false;
  bool _lastCorrect = false;
  bool? _tfSelected;
  int? _mcSelected;
  bool _ready = false;
  bool _pendingCorrect = false;

  GameQuestion get _q => _questions[_index];
  bool get _isLast => _index == _questions.length - 1;
  bool get _needsVerify =>
      _q.type == QuestionType.matching ||
      _q.type == QuestionType.ordering ||
      _q.type == QuestionType.fillBlank;

  @override
  void initState() {
    super.initState();
    // Asegura que todo el progreso se lea/escriba en ESTE perfil
    ProfileDataService.setActive(widget.userProfile.id);
    _loadQuestions();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  int _calculateLevel(int correct, int wrong) {
    final total = correct + wrong;
    if (total == 0) return 0;
    final accuracy = correct / total;
    if (accuracy >= 0.95) return 5;
    if (accuracy >= 0.80) return 4;
    if (accuracy >= 0.70) return 3;
    if (accuracy >= 0.60) return 2;
    if (accuracy >= 0.50) return 1;
    return 0;
  }

  int _getQuestionsForLevel(int level) {
    switch (level) {
      case 0: return 5;
      case 1: return 7;
      case 2: return 10;
      case 3: return 12;
      case 4: return 15;
      case 5: return 20;
      default: return 10;
    }
  }

  Future<void> _loadQuestions() async {
    final profileRef = ProfileDataService.refFor(widget.userProfile.id);
    int currentLevel = 0;

    if (profileRef != null) {
      try {
        final doc = await profileRef.get();
        if (doc.exists) {
          final data = doc.data() ?? <String, dynamic>{};
          final correct = _safeInt(data['correctAnswers']);
          final wrong = _safeInt(data['wrongAnswers']);
          currentLevel = _calculateLevel(correct, wrong);
        }
      } catch (e) {
        debugPrint('Error al obtener nivel: $e');
      }
    }

    final maxQuestions = _getQuestionsForLevel(currentLevel);
    final List<Map<String, dynamic>> allJsonQuestions = [];

    try {
      allJsonQuestions.addAll(await _loadJsonFile('assets/questions/opcion_multiple.json'));
      allJsonQuestions.addAll(await _loadJsonFile('assets/questions/verdadero_falso.json'));
      allJsonQuestions.addAll(await _loadJsonFile('assets/questions/completar.json'));
      allJsonQuestions.addAll(await _loadJsonFile('assets/questions/relacionar.json'));
      allJsonQuestions.addAll(await _loadJsonFile('assets/questions/ordenar.json'));
    } catch (e) {
      debugPrint('Error cargando JSONs: $e');
    }

    final filtered = allJsonQuestions.where((q) {
      final tema = q['tema']?.toString() ?? 'General';
      return _temaCoincide(tema, widget.moduleName);
    }).toList()..shuffle();

    final selected = filtered.length > maxQuestions ? filtered.sublist(0, maxQuestions) : filtered;

    if (!mounted) return;
    setState(() {
      _questions = selected.map(_mapJsonToGameQuestion).toList();
      _isLoading = false;
    });
  }

  bool _temaCoincide(String preguntaTema, String modulo) {
    const todosLosTemas = <String>{
      'Conciencia', 'Orientación', 'Atención', 'Memoria', 'Percepción',
      'Pensamiento', 'Sueño', 'Apetito e ingesta', 'Sexualidad', 'Síndromes'
    };

    if (todosLosTemas.contains(modulo)) {
      return preguntaTema == modulo;
    }

    final moduloTemas = <String, Set<String>>{
      'Casos Clínicos': todosLosTemas,
      'Entrevistas': {'Entrevista', 'Semiología'},
      'Laboratorio': {'Evaluación', 'Test'},
      'Biblioteca': {'Conceptos', 'Definiciones'},
    };
    final temas = moduloTemas[modulo];
    if (temas == null || temas.isEmpty) return true;
    return temas.contains(preguntaTema);
  }

  Future<List<Map<String, dynamic>>> _loadJsonFile(String path) async {
    try {
      final content = await rootBundle.loadString(path);
      final data = jsonDecode(content) as List<dynamic>;
      return data.map((item) => Map<String, dynamic>.from(item as Map)).toList();
    } catch (e) {
      debugPrint('Error cargando $path: $e');
      return [];
    }
  }

  GameQuestion _mapJsonToGameQuestion(Map<String, dynamic> q) {
    final id = q['id']?.toString() ?? 'UNKNOWN';
    final tema = q['tema']?.toString() ?? 'General';
    final explicacion = q['justificacion']?.toString() ?? 'Revisa el documento.';
    final pista = 'Pista: Basado en los documentos de Semiología y Síndromes.';

    if (q.containsKey('opciones')) {
      return GameQuestion(
        questionId: id, type: QuestionType.multipleChoice, topic: tema, topicIcon: Icons.psychology_outlined,
        prompt: q['pregunta'] ?? '', hint: pista, explanation: explicacion,
        options: List<String>.from(q['opciones'] ?? []), correctIndex: q['respuesta_correcta'] ?? 0,
      );
    }
    if (q.containsKey('afirmacion')) {
      final resp = q['respuesta_correcta'];
      final isTrue = resp == true || resp == 'V' || resp == 'Verdadero' || resp == 'v';
      return GameQuestion(
        questionId: id, type: QuestionType.trueFalse, topic: tema, topicIcon: Icons.check_circle_outline,
        prompt: q['afirmacion'] ?? '', hint: pista, explanation: explicacion, answerIsTrue: isTrue,
      );
    }
    if (q.containsKey('oracion')) {
      return GameQuestion(
        questionId: id, type: QuestionType.fillBlank, topic: tema, topicIcon: Icons.edit_note_rounded,
        prompt: 'Completa la oración con el término correcto.', hint: pista, explanation: explicacion,
        blankSentence: q['oracion'] ?? '', blankAnswers: [q['respuesta_correcta']?.toString() ?? ''],
      );
    }
    if (q.containsKey('columna_a')) {
      final colA = List<String>.from(q['columna_a'] ?? []);
      final colB = List<String>.from(q['columna_b'] ?? []);
      final pares = List<int>.from(q['pares_correctos'] ?? []);
      final pairsList = <MatchPair>[];
      for (int i = 0; i < pares.length; i++) {
        if (i < colA.length && pares[i] < colB.length) {
          pairsList.add(MatchPair(colA[i], colB[pares[i]]));
        }
      }
      return GameQuestion(
        questionId: id, type: QuestionType.matching, topic: tema, topicIcon: Icons.link_rounded,
        prompt: q['instruccion'] ?? 'Relaciona cada elemento con su descripción.', hint: pista, explanation: explicacion,
        pairs: pairsList, matchLeftTitle: 'Términos', matchRightTitle: 'Descripciones',
      );
    }

    if (q.containsKey('elementos')) {
      final elementos = List<String>.from(q['elementos'] ?? []);
      final rawCorrectOrder = q['orden_correcto'];
      List<String> correctOrder = [];

      if (rawCorrectOrder is String) {
        correctOrder = rawCorrectOrder.split('→').map((e) => e.trim()).toList();
      } else if (rawCorrectOrder is List) {
        if (rawCorrectOrder.isNotEmpty && rawCorrectOrder.first is int) {
          correctOrder = List<int>.from(rawCorrectOrder).map((index) => elementos[index]).toList();
        } else {
          correctOrder = List<String>.from(rawCorrectOrder);
        }
      }

      if (correctOrder.isEmpty) correctOrder = List.from(elementos);

      return GameQuestion(
        questionId: id,
        type: QuestionType.ordering,
        topic: tema,
        topicIcon: Icons.format_list_numbered_rounded,
        prompt: q['instruccion'] ?? 'Ordena los elementos correctamente.',
        hint: pista,
        explanation: 'El orden correcto es: ${correctOrder.join(" → ")}',
        orderedItems: List<String>.from(elementos)..shuffle(),
        correctOrder: correctOrder,
      );
    }

    return GameQuestion(
      questionId: id, type: QuestionType.multipleChoice, topic: tema, topicIcon: Icons.help_outline,
      prompt: q['pregunta'] ?? q['afirmacion'] ?? q['oracion'] ?? 'Pregunta sin formato', hint: pista, explanation: explicacion,
      options: ['Opción A', 'Opción B'], correctIndex: 0,
    );
  }

  (String, IconData) _typeMeta(QuestionType t) => switch (t) {
    QuestionType.trueFalse => ('Verdadero o Falso', Icons.check_circle_outline_rounded),
    QuestionType.multipleChoice => ('Opción Múltiple', Icons.format_list_bulleted_rounded),
    QuestionType.matching => ('Relacionar / Emparejar', Icons.link_rounded),
    QuestionType.ordering => ('Ordenar / Secuenciar', Icons.format_list_numbered_rounded),
    QuestionType.fillBlank => ('Completar', Icons.edit_note_rounded),
  };

  String? _wrongDetail(GameQuestion q) => switch (q.type) {
    QuestionType.trueFalse => 'Respuesta correcta: ${q.answerIsTrue ? 'Verdadero' : 'Falso'}',
    QuestionType.multipleChoice => 'Respuesta correcta: ${String.fromCharCode(65 + q.correctIndex)}. ${q.options[q.correctIndex]}',
    QuestionType.fillBlank => q.blankAnswers.isEmpty ? null : 'Respuesta correcta: ${q.blankAnswers.first}',
    QuestionType.matching => 'Revisa las coincidencias marcadas en rojo.',
    QuestionType.ordering => 'Revisa las posiciones marcadas en rojo.',
  };

  String _norm(String s) {
    const from = 'áéíóúüñ';
    const to = 'aeiouun';
    var out = s.trim().toLowerCase();
    for (var i = 0; i < from.length; i++) {
      out = out.replaceAll(from[i], to[i]);
    }
    return out;
  }

  void _resetQuestionState() {
    _revealed = false; _lastCorrect = false; _tfSelected = null; _mcSelected = null; _ready = false; _pendingCorrect = false;
  }

  void _answer(bool correct) {
    if (correct) {
      HapticFeedback.lightImpact();
    } else {
      HapticFeedback.heavyImpact();
    }

    setState(() {
      _revealed = true;
      _lastCorrect = correct;
      if (correct) {
        _correct++;
        _stars += _starsPerCorrect;
      }
    });

    _recordAnswerToFirebase(correct);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _recordAnswerToFirebase(bool isCorrect) async {
    try {
      final questionJson = <String, dynamic>{
        'questionId': _q.questionId,
        'type': _q.type.name,
        'topic': _q.topic,
        'prompt': _q.prompt,
        'hint': _q.hint,
        'explanation': _q.explanation,
        if (_q.options.isNotEmpty) 'opciones': _q.options,
        if (_q.blankSentence.isNotEmpty) 'oracion': _q.blankSentence,
        if (_q.orderedItems.isNotEmpty) 'elementos': _q.orderedItems,
      };

      await _progressService.recordAttempt(
        questionId: _q.questionId,
        tema: _q.topic,
        isCorrect: isCorrect,
        questionData: questionJson,
      );
    } catch (e) {
      debugPrint('Error guardando respuesta en Firebase: $e');
    }
  }

  Future<void> _finishGame() async {
    // Progreso de ESTE perfil: usuarios/{uid}/perfiles/{profileId}
    final profileRef = ProfileDataService.refFor(widget.userProfile.id);

    if (profileRef == null) {
      debugPrint('❌ ERROR: No hay usuario logueado.');
      return;
    }

    final bool isPerfectRun = (_correct == _questions.length) && _questions.isNotEmpty;

    int gemsEarned = 10;
    if (isPerfectRun) {
      gemsEarned += 20; // Bonus por completar todo perfecto
    }

    int newDayStreak = 1;

    try {
      final profileDoc = await profileRef.get();

      if (profileDoc.exists) {
        final profileData = profileDoc.data() ?? <String, dynamic>{};
        final int currentDayStreak = _safeInt(profileData['dayStreak']);

        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);

        DateTime? lastLessonDate;
        final rawDate = profileData['lastLessonDate'];
        if (rawDate is Timestamp) {
          final date = rawDate.toDate();
          lastLessonDate = DateTime(date.year, date.month, date.day);
        }

        if (lastLessonDate == null) {
          newDayStreak = 1;
        } else {
          final differenceInDays = today.difference(lastLessonDate).inDays;
          if (differenceInDays == 0) {
            newDayStreak = currentDayStreak < 1 ? 1 : currentDayStreak;
          } else if (differenceInDays == 1) {
            newDayStreak = currentDayStreak + 1;
          } else {
            newDayStreak = 1;
          }
        }
      }
    } catch (e) {
      debugPrint('Error leyendo racha del perfil: $e');
    }

    if (newDayStreak > 1) {
      gemsEarned += (newDayStreak * 5);
    }

    debugPrint('📊 Perfil ${widget.userProfile.id} -> Gemas: +$gemsEarned, Racha: $newDayStreak, ¿Perfecto?: $isPerfectRun');

    final Map<String, dynamic> updateData = {
      'dayStreak': newDayStreak,
      'lastLessonDate': Timestamp.fromDate(DateTime.now()),
      'gems': FieldValue.increment(gemsEarned),
      'correctAnswers': FieldValue.increment(_correct),
      'wrongAnswers': FieldValue.increment(_questions.length - _correct),
      'xp': FieldValue.increment(_stars),
    };

    if (isPerfectRun) {
      updateData['completedModules'] = {
        widget.moduleName: {
          'allCorrect': true,
          'completedAt': Timestamp.now(),
        }
      };
    }

    try {
      await profileRef.set(updateData, SetOptions(merge: true));
      debugPrint('✅ Guardado en el perfil ${widget.userProfile.id}');
    } catch (e) {
      debugPrint('❌ ERROR AL GUARDAR EN FIREBASE: $e');
    }

    if (mounted) {
      setState(() { _finished = true; });
    }
  }

  void _verify() { if (!_ready || _revealed) return; _answer(_pendingCorrect); }

  void _next() {
    if (_isLast) { _finishGame(); return; }
    setState(() { _index++; _resetQuestionState(); });
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  void _restart() {
    setState(() {
      _index = 0;
      _stars = 0;
      _correct = 0;
      _finished = false;
      _resetQuestionState();
    });
  }

  Widget _buildBody(GameQuestion q) {
    switch (q.type) {
      case QuestionType.trueFalse:
        return TrueFalseWidget(
          selected: _tfSelected,
          correctAnswer: _revealed ? q.answerIsTrue : null,
          locked: _revealed,
          onSelected: (value) {
            if (_revealed) return;
            setState(() => _tfSelected = value);
            _answer(value == q.answerIsTrue);
          },
        );
      case QuestionType.multipleChoice:
        return MultipleChoiceWidget(
          options: q.options,
          selectedIndex: _mcSelected,
          correctIndex: _revealed ? q.correctIndex : null,
          locked: _revealed,
          onSelected: (i) {
            if (_revealed) return;
            setState(() => _mcSelected = i);
            _answer(i == q.correctIndex);
          },
        );
      case QuestionType.matching:
        return MatchingWidget(
          pairs: q.pairs,
          leftTitle: q.matchLeftTitle,
          rightTitle: q.matchRightTitle,
          checked: _revealed,
          onChanged: (complete, correct) => setState(() {
            _ready = complete;
            _pendingCorrect = correct;
          }),
        );
      case QuestionType.ordering:
        return OrderingWidget(
          items: q.orderedItems,
          correctOrder: q.correctOrder,
          checked: _revealed,
          onChanged: (correct, wrongPositions) => setState(() {
            _ready = true;
            _pendingCorrect = correct;
          }),
        );
      case QuestionType.fillBlank:
        return FillBlankWidget(
          sentence: q.blankSentence,
          checked: _revealed,
          isCorrect: _revealed ? _lastCorrect : null,
          onChanged: (text) => setState(() {
            _ready = text.trim().isNotEmpty;
            _pendingCorrect = q.blankAnswers.map(_norm).contains(_norm(text));
          }),
        );
    }
  }

  Widget _buildActionButton() {
    if (_revealed) {
      return _isLast
          ? NextButtonWidget(label: 'Finalizar', icon: Icons.flag_rounded, onPressed: _next)
          : NextButtonWidget.next(onPressed: _next);
    }
    if (_needsVerify) {
      return NextButtonWidget.verify(onPressed: _ready ? _verify : null);
    }
    return const NextButtonWidget.next(onPressed: null);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (_finished) {
      return GameResultScreen(
        correct: _correct,
        total: _questions.length,
        stars: _stars,
        title: widget.moduleName,
        onRetry: _restart,
        onExit: () => Navigator.of(context).pop(),
      );
    }

    if (_questions.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Center(
            child: Text(
              'No hay preguntas disponibles',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
        ),
      );
    }

    final q = _q;
    final (typeLabel, typeIcon) = _typeMeta(q.type);
    final boxed = q.type == QuestionType.trueFalse ||
        q.type == QuestionType.multipleChoice;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: QuestionLayout(
        controller: _scroll,
        progress: (_index + 1) / _questions.length,
        header: QuestionHeader(
          title: widget.moduleName,
          current: _index + 1,
          total: _questions.length,
          stars: _stars,
          onBack: () => Navigator.of(context).maybePop(),
        ),
        questionBuilder: (wide) => QuestionHero(
          typeLabel: typeLabel,
          typeIcon: typeIcon,
          topic: q.topic,
          topicIcon: q.topicIcon,
          text: q.prompt,
          artIcon: q.artIcon,
          large: wide,
          boxed: boxed,
        ),
        answers: KeyedSubtree(key: ValueKey(_index), child: _buildBody(q)),
        feedback: _revealed
            ? ExplanationWidget(
                key: ValueKey('feedback_$_index'),
                isCorrect: _lastCorrect,
                explanation: q.explanation,
                detail: _wrongDetail(q) ?? '',
                starsEarned: _starsPerCorrect,
              )
            : null,
        footer: ActionHintWidget(hint: q.hint, action: _buildActionButton()),
      ),
    );
  }
}