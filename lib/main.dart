import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final isDark = prefs.getBool('darkMode') ?? true;
  runApp(CogniReadApp(initialDarkMode: isDark));
}

// ─── Paleta de colores ────────────────────────────────────────────────────────

class AppColors {
  // Dark theme
  static const darkBg = Color(0xFF0D0F14);
  static const darkSurface = Color(0xFF161B26);
  static const darkCard = Color(0xFF1E2535);
  static const darkBorder = Color(0xFF2A3450);
  static const accent = Color(0xFF4ECDC4);
  static const accentDim = Color(0xFF2A7D78);
  static const accentGlow = Color(0x334ECDC4);
  static const missing = Color(0xFFFF6B6B);
  static const missingDim = Color(0x44FF6B6B);
  static const roundBadge = Color(0xFFFFE66D);

  // Light theme
  static const lightBg = Color(0xFFF0F4FF);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightCard = Color(0xFFE8EEFF);
  static const lightBorder = Color(0xFFCDD4F0);
  static const lightText = Color(0xFF1A1F36);
  static const lightTextSub = Color(0xFF5A6490);
}

// ─── Lógica de transformación ─────────────────────────────────────────────────

class TextTransformer {
  static final _random = Random();

  /// Separa el texto en tokens: palabras y no-palabras (espacios, puntuación)
  static List<String> tokenize(String text) {
    final tokens = <String>[];
    final regex = RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚüÜñÑ]+|[^a-zA-ZáéíóúÁÉÍÓÚüÜñÑ]+');
    for (final match in regex.allMatches(text)) {
      tokens.add(match.group(0)!);
    }
    return tokens;
  }

  static bool _isWord(String token) {
    return RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚüÜñÑ]').hasMatch(token);
  }

  /// Transforma una palabra según la ronda (1-3)
  static String transformWord(String word, int round) {
    if (word.length <= 2) return word; // palabras muy cortas: sin cambios

    final chars = word.split('');

    switch (round) {
      case 1:
        // Eliminar 1-2 letras (no la primera)
        return _removeLetters(chars, min: 1, max: 2, keepFirst: true, keepLast: false);
      case 2:
        // Eliminar 2-3 letras (no la primera)
        return _removeLetters(chars, min: 2, max: 3, keepFirst: true, keepLast: false);
      case 3:
        // Eliminar hasta 50%, mantener primera y última
        final maxRemove = (word.length * 0.5).floor().clamp(1, word.length - 2);
        return _removeLetters(chars, min: maxRemove, max: maxRemove, keepFirst: true, keepLast: true);
      default:
        return word;
    }
  }

  static String _removeLetters(
    List<String> chars, {
    required int min,
    required int max,
    required bool keepFirst,
    required bool keepLast,
  }) {
    final len = chars.length;
    // Índices disponibles para eliminar
    final start = keepFirst ? 1 : 0;
    final end = keepLast ? len - 1 : len;
    final available = List<int>.generate(end - start, (i) => i + start);

    if (available.isEmpty) return chars.join();

    available.shuffle(_random);
    final count = _random.nextInt(max - min + 1) + min;
    final toRemove = available.take(count.clamp(0, available.length)).toSet();

    return chars.asMap().entries.map((e) {
      return toRemove.contains(e.key) ? '_' : e.value;
    }).join();
  }

  /// Transforma todos los tokens del texto para una ronda dada
  static List<TransformedToken> transformText(List<String> tokens, int round) {
    return tokens.map((token) {
      if (_isWord(token) && token.length > 1) {
        final transformed = transformWord(token, round);
        final hasMissing = transformed.contains('_');
        return TransformedToken(
          original: token,
          display: transformed,
          isWord: true,
          hasMissing: hasMissing,
        );
      }
      return TransformedToken(
        original: token,
        display: token,
        isWord: false,
        hasMissing: false,
      );
    }).toList();
  }
}

class TransformedToken {
  final String original;
  final String display;
  final bool isWord;
  final bool hasMissing;

  const TransformedToken({
    required this.original,
    required this.display,
    required this.isWord,
    required this.hasMissing,
  });
}

// ─── App Root ─────────────────────────────────────────────────────────────────

class CogniReadApp extends StatefulWidget {
  final bool initialDarkMode;
  const CogniReadApp({super.key, required this.initialDarkMode});

  @override
  State<CogniReadApp> createState() => _CogniReadAppState();
}

class _CogniReadAppState extends State<CogniReadApp> {
  late bool _isDark;

  @override
  void initState() {
    super.initState();
    _isDark = widget.initialDarkMode;
  }

  void toggleTheme(bool isDark) async {
    setState(() => _isDark = isDark);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', isDark);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CogniRead',
      debugShowCheckedModeBanner: false,
      themeMode: _isDark ? ThemeMode.dark : ThemeMode.light,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.darkBg,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.accent,
          surface: AppColors.darkSurface,
        ),
        textTheme: GoogleFonts.spaceGroteskTextTheme(ThemeData.dark().textTheme),
      ),
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.lightBg,
        colorScheme: const ColorScheme.light(
          primary: AppColors.accent,
          surface: AppColors.lightSurface,
        ),
        textTheme: GoogleFonts.spaceGroteskTextTheme(ThemeData.light().textTheme),
      ),
      home: HomeScreen(isDark: _isDark, onThemeToggle: toggleTheme),
    );
  }
}

// ─── Home Screen ──────────────────────────────────────────────────────────────

class HomeScreen extends StatefulWidget {
  final bool isDark;
  final ValueChanged<bool> onThemeToggle;

  const HomeScreen({super.key, required this.isDark, required this.onThemeToggle});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  List<String> _tokens = [];
  List<TransformedToken> _transformed = [];
  int _currentRound = 0; // 0 = sin generar
  bool _generated = false;
  bool _showOriginal = false;

  late AnimationController _roundAnimController;

  static const int maxRounds = 3;

  // Estadísticas
  int _totalWords = 0;
  int _missingLetters = 0;

  @override
  void initState() {
    super.initState();
    _roundAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _roundAnimController.dispose();
    super.dispose();
  }

  void _generate() {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      _showSnack('Por favor ingresa un texto primero.');
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() {
      _tokens = TextTransformer.tokenize(text);
      _currentRound = 1;
      _generated = true;
      _showOriginal = false;
      _applyRound();
    });
    _animateRound();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _applyRound() {
    _transformed = TextTransformer.transformText(_tokens, _currentRound);
    _totalWords = _transformed.where((t) => t.isWord).length;
    _missingLetters = _transformed.fold(0, (acc, t) {
      return acc + (t.hasMissing ? t.display.split('_').length - 1 : 0);
    });
  }

  void _nextRound() {
    if (_currentRound >= maxRounds) {
      _showSnack('¡Has completado todas las rondas!');
      return;
    }
    HapticFeedback.lightImpact();
    setState(() {
      _currentRound++;
      _showOriginal = false;
      _applyRound();
    });
    _animateRound();
  }

  void _reset() {
    HapticFeedback.heavyImpact();
    setState(() {
      _currentRound = 0;
      _generated = false;
      _transformed = [];
      _tokens = [];
      _showOriginal = false;
      _totalWords = 0;
      _missingLetters = 0;
    });
  }

  void _toggleOriginal() {
    setState(() => _showOriginal = !_showOriginal);
  }

  void _animateRound() {
    _roundAnimController.reset();
    _roundAnimController.forward();
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.spaceGrotesk()),
        backgroundColor: AppColors.accentDim,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final cardColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textColor = isDark ? Colors.white : AppColors.lightText;
    final subColor = isDark ? Colors.white38 : AppColors.lightTextSub;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──
              _buildHeader(isDark, textColor, subColor),
              const SizedBox(height: 24),

              // ── Input Card ──
              _buildInputCard(isDark, surface, border, textColor, subColor),
              const SizedBox(height: 16),

              // ── Generate Button ──
              _buildGenerateButton(),
              const SizedBox(height: 24),

              // ── Output Area ──
              if (_generated) ...[
                _buildRoundHeader(isDark, textColor, subColor),
                const SizedBox(height: 12),
                _buildTextOutput(isDark, cardColor, border, textColor),
                const SizedBox(height: 20),
                _buildActionButtons(isDark, textColor),
                const SizedBox(height: 32),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────

  Widget _buildHeader(bool isDark, Color textColor, Color subColor) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(color: AppColors.accentGlow, blurRadius: 8),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'CogniRead',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 20),
                child: Text(
                  'Entrenamiento de lectura activa',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 13,
                    color: subColor,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Theme toggle
        GestureDetector(
          onTap: () => widget.onThemeToggle(!widget.isDark),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 52,
            height: 28,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: isDark ? AppColors.darkCard : AppColors.lightCard,
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            child: Stack(
              children: [
                AnimatedAlign(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  alignment: isDark ? Alignment.centerLeft : Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.all(3),
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.accent,
                      ),
                      child: Icon(
                        isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                        size: 14,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Input Card ───────────────────────────────────────────────────────────────

  Widget _buildInputCard(bool isDark, Color surface, Color border, Color textColor, Color subColor) {
    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
        boxShadow: isDark
            ? [BoxShadow(color: Colors.black26, blurRadius: 20, offset: const Offset(0, 4))]
            : [BoxShadow(color: Colors.black12, blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                Icon(Icons.edit_note_rounded, size: 18, color: AppColors.accent),
                const SizedBox(width: 8),
                Text(
                  'Texto a entrenar',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accent,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          Divider(color: border, height: 1),
          TextField(
            controller: _controller,
            maxLines: 8,
            minLines: 5,
            style: GoogleFonts.sourceSerif4(
              fontSize: 15,
              color: textColor,
              height: 1.7,
            ),
            decoration: InputDecoration(
              hintText: 'Pega o escribe el texto que deseas practicar...',
              hintStyle: GoogleFonts.spaceGrotesk(
                color: isDark ? Colors.white24 : Colors.black26,
                fontSize: 14,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(20),
            ),
          ),
          // Word count
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: _controller,
              builder: (_, value, __) {
                final wordCount = value.text.trim().isEmpty
                    ? 0
                    : value.text.trim().split(RegExp(r'\s+')).length;
                return Text(
                  '$wordCount palabras',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12,
                    color: subColor,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Generate Button ───────────────────────────────────────────────────────────

  Widget _buildGenerateButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _generate,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.black,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          shadowColor: AppColors.accentGlow,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.auto_awesome_rounded, size: 20),
            const SizedBox(width: 10),
            Text(
              'Generar',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0);
  }

  // ── Round Header ─────────────────────────────────────────────────────────────

  Widget _buildRoundHeader(bool isDark, Color textColor, Color subColor) {
    final roundNames = ['', 'Principiante', 'Intermedio', 'Experto'];
    final roundIcons = [null, Icons.looks_one_rounded, Icons.looks_two_rounded, Icons.looks_3_rounded];
    final roundColors = [
      Colors.transparent,
      const Color(0xFF4ECDC4),
      const Color(0xFFFFE66D),
      const Color(0xFFFF6B6B),
    ];

    return AnimatedBuilder(
      animation: _roundAnimController,
      builder: (_, child) {
        return Transform.scale(
          scale: 1.0 + (_roundAnimController.value * 0.02 * sin(_roundAnimController.value * pi)),
          child: child,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              roundColors[_currentRound].withValues(alpha: 0.15),
              roundColors[_currentRound].withValues(alpha: 0.05),
            ],
          ),
          border: Border.all(color: roundColors[_currentRound].withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Icon(roundIcons[_currentRound], color: roundColors[_currentRound], size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ronda $_currentRound de $maxRounds — ${roundNames[_currentRound]}',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: roundColors[_currentRound],
                    ),
                  ),
                  Text(
                    '$_totalWords palabras · $_missingLetters letras ocultas',
                    style: GoogleFonts.spaceGrotesk(fontSize: 12, color: subColor),
                  ),
                ],
              ),
            ),
            // Progress dots
            Row(
              children: List.generate(maxRounds, (i) {
                final active = i < _currentRound;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.only(left: 4),
                  width: active ? 12 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: active
                        ? roundColors[_currentRound]
                        : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    ).animate().fadeIn().slideX(begin: -0.05, end: 0);
  }

  // ── Text Output ──────────────────────────────────────────────────────────────

  Widget _buildTextOutput(bool isDark, Color cardColor, Color border, Color textColor) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      transitionBuilder: (child, anim) {
        return FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero).animate(anim),
            child: child,
          ),
        );
      },
      child: Container(
        key: ValueKey('round_$_currentRound\_$_showOriginal'),
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: border),
          boxShadow: isDark
              ? [BoxShadow(color: Colors.black26, blurRadius: 16, offset: const Offset(0, 4))]
              : [BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: const Offset(0, 3))],
        ),
        child: _showOriginal
            ? Text(
                _tokens.join(),
                style: GoogleFonts.sourceSerif4(
                  fontSize: 16,
                  color: textColor,
                  height: 1.8,
                ),
              )
            : _buildRichText(textColor),
      ),
    );
  }

  Widget _buildRichText(Color textColor) {
    return RichText(
      text: TextSpan(
        children: _transformed.map((token) {
          if (!token.isWord || !token.hasMissing) {
            return TextSpan(
              text: token.display,
              style: GoogleFonts.sourceSerif4(
                fontSize: 16,
                color: textColor,
                height: 1.8,
              ),
            );
          }

          // Palabra con letras faltantes: colorear '_' de forma especial
          final parts = <TextSpan>[];
          for (int i = 0; i < token.display.length; i++) {
            if (token.display[i] == '_') {
              parts.add(TextSpan(
                text: '_',
                style: GoogleFonts.sourceSerif4(
                  fontSize: 16,
                  color: AppColors.missing,
                  height: 1.8,
                  fontWeight: FontWeight.w700,
                  backgroundColor: AppColors.missingDim,
                ),
              ));
            } else {
              parts.add(TextSpan(
                text: token.display[i],
                style: GoogleFonts.sourceSerif4(
                  fontSize: 16,
                  color: textColor,
                  height: 1.8,
                ),
              ));
            }
          }
          return TextSpan(children: parts);
        }).toList(),
      ),
    );
  }

  // ── Action Buttons ────────────────────────────────────────────────────────────

  Widget _buildActionButtons(bool isDark, Color textColor) {
    return Column(
      children: [
        Row(
          children: [
            // Siguiente ronda
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _currentRound < maxRounds ? _nextRound : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _currentRound < maxRounds
                        ? AppColors.accent
                        : (isDark ? AppColors.darkCard : AppColors.lightCard),
                    foregroundColor: _currentRound < maxRounds ? Colors.black : Colors.grey,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _currentRound >= maxRounds ? '¡Completado!' : 'Siguiente ronda',
                        style: GoogleFonts.spaceGrotesk(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      if (_currentRound < maxRounds) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.arrow_forward_rounded, size: 18),
                      ]
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Ver original
            SizedBox(
              height: 52,
              child: OutlinedButton(
                onPressed: _toggleOriginal,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.accent,
                  side: BorderSide(color: AppColors.accent.withValues(alpha: 0.5)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                child: Icon(
                  _showOriginal ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Reiniciar
            SizedBox(
              height: 52,
              child: OutlinedButton(
                onPressed: _reset,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.missing,
                  side: BorderSide(color: AppColors.missing.withValues(alpha: 0.4)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                child: const Icon(Icons.restart_alt_rounded, size: 20),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Hint row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline_rounded, size: 13, color: isDark ? Colors.white24 : Colors.black26),
            const SizedBox(width: 6),
            Text(
              _showOriginal ? 'Mostrando texto original' : 'Completa mentalmente las letras marcadas en rojo',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12,
                color: isDark ? Colors.white24 : Colors.black38,
              ),
            ),
          ],
        ),
      ],
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0);
  }
}
