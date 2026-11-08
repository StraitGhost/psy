import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_colors.dart';
import '../profile_selection/profile_selection_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _emailFocus = FocusNode();
  final _passFocus = FocusNode();

  bool _loading = false;
  bool _hide = true;
  bool _checkingSession = true;
  bool _remember = true; // ✅ Nueva opción

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    _emailFocus.dispose();
    _passFocus.dispose();
    super.dispose();
  }

  Future<void> _checkSession() async {
    try {
      final user = await FirebaseAuth.instance.authStateChanges().first;
      if (!mounted) return;

      if (user != null) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const ProfileSelectionScreen()),
          (route) => false,
        );
        return;
      }
    } catch (_) {}

    if (mounted) setState(() => _checkingSession = false);
  }

  Future<void> _login() async {
    // ✅ Permite ejecutar desde Enter aunque el foco esté en el TextField
    _emailFocus.unfocus();
    _passFocus.unfocus();

    if (_email.text.trim().isEmpty || _pass.text.isEmpty) {
      return _error('Completa todos los campos');
    }

    setState(() => _loading = true);
    try {
      // ✅ Configurar persistencia según el checkbox
      await FirebaseAuth.instance.setPersistence(
        _remember ? Persistence.LOCAL : Persistence.SESSION,
      );

      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _email.text.trim(),
        password: _pass.text,
      );
      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const ProfileSelectionScreen()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      _error(switch (e.code) {
        'user-not-found' || 'wrong-password' || 'invalid-credential' =>
          'Correo o contraseña incorrectos',
        'invalid-email' => 'El formato del correo no es válido',
        _ => 'Error al iniciar sesión',
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _error(String msg) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.error,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          content: Text(msg, textAlign: TextAlign.center, style: TextStyle(color: AppColors.textOnPrimary)),
        ),
      );

  @override
  Widget build(BuildContext context) {
    if (_checkingSession) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned(top: -120, right: -80, child: _Glow(AppColors.primary, 320)),
          Positioned(bottom: -140, left: -100, child: _Glow(AppColors.secondary, 300)),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.easeOutCubic,
                  builder: (_, v, child) => Opacity(
                    opacity: v,
                    child: Transform.translate(offset: Offset(0, 24 * (1 - v)), child: child),
                  ),
                  child: _card(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card() => Container(
        padding: const EdgeInsets.fromLTRB(28, 36, 28, 20),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.8)),
          boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.18), blurRadius: 60, offset: const Offset(0, 24))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [AppColors.primary, AppColors.secondary], begin: Alignment.topLeft, end: Alignment.bottomRight),
                ),
                child: const Icon(Icons.psychology_outlined, size: 40, color: Colors.white),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Bienvenido de nuevo',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
            const SizedBox(height: 6),
            Text('Inicia sesión para acceder a tus perfiles',
                textAlign: TextAlign.center, style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
            const SizedBox(height: 32),
            _field(
              _email,
              'Correo electrónico',
              Icons.mail_outline_rounded,
              focusNode: _emailFocus,
              type: TextInputType.emailAddress,
              textInputAction: TextInputAction.next, // ✅ Pasa al siguiente campo
              onSubmitted: (_) => FocusScope.of(context).requestFocus(_passFocus),
            ),
            const SizedBox(height: 16),
            _field(
              _pass,
              'Contraseña',
              Icons.lock_outline_rounded,
              focusNode: _passFocus,
              obscure: _hide,
              enableSuggestions: false,
              autocorrect: false,
              textInputAction: TextInputAction.done, // ✅ Muestra "Listo/Go" en el teclado
              onSubmitted: (_) => _login(), // ✅ Ejecuta login al presionar Enter
              suffix: IconButton(
                icon: Icon(_hide ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.textMuted, size: 20),
                onPressed: () => setState(() => _hide = !_hide),
              ),
            ),
            const SizedBox(height: 12),

            // ✅ Checkbox "Mantener sesión iniciada"
            Row(
              children: [
                SizedBox(
                  width: 22,
                  height: 22,
                  child: Checkbox(
                    value: _remember,
                    onChanged: (v) => setState(() => _remember = v ?? true),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    activeColor: AppColors.primary,
                    side: BorderSide(color: AppColors.border, width: 1.5),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _remember = !_remember),
                    child: Text(
                      'Mantener sesión iniciada',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 13.5),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 22),
            _button(),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
              child: Text('¿No tienes cuenta? Regístrate',
                  style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );

  Widget _field(
    TextEditingController c,
    String label,
    IconData icon, {
    FocusNode? focusNode,
    bool obscure = false,
    TextInputType? type,
    TextInputAction? textInputAction,
    ValueChanged<String>? onSubmitted,
    Widget? suffix,
    bool enableSuggestions = true,
    bool autocorrect = true,
  }) {
    OutlineInputBorder b(Color col, [double w = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: col, width: w));
    return TextField(
      controller: c,
      focusNode: focusNode,
      obscureText: obscure,
      keyboardType: type,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      enableSuggestions: enableSuggestions,
      autocorrect: autocorrect,
      cursorColor: AppColors.primary,
      style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: AppColors.textMuted),
        floatingLabelStyle: TextStyle(color: AppColors.primary),
        prefixIcon: Icon(icon, color: AppColors.textMuted, size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: AppColors.background.withValues(alpha: 0.55),
        enabledBorder: b(AppColors.border),
        focusedBorder: b(AppColors.primary, 1.8),
      ),
    );
  }

  Widget _button() => DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(colors: [AppColors.primary, AppColors.secondary]),
          boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.45), blurRadius: 24, offset: const Offset(0, 10))],
        ),
        child: ElevatedButton(
          onPressed: _loading ? null : _login,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            minimumSize: const Size.fromHeight(56),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: _loading
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
              : const Text('Iniciar sesión',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white)),
        ),
      );
}

class _Glow extends StatelessWidget {
  const _Glow(this.color, this.size);
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color.withValues(alpha: 0.35), color.withValues(alpha: 0)]),
        ),
      );
}