import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_colors.dart';
import '../profile_selection/profile_selection_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;
  bool _hide = true;

  @override
  void dispose() {
    for (final c in [_name, _email, _pass, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _register() async {
    if (_name.text.trim().isEmpty || _email.text.trim().isEmpty || _pass.text.isEmpty) {
      return _error('Completa todos los campos');
    }
    if (_pass.text != _confirm.text) return _error('Las contraseñas no coinciden');

    setState(() => _loading = true);
    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _email.text.trim(),
        password: _pass.text,
      );
      await cred.user?.updateDisplayName(_name.text.trim());
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const ProfileSelectionScreen()),
        (_) => false,
      );
    } on FirebaseAuthException catch (e) {
      _error(switch (e.code) {
        'email-already-in-use' => 'Este correo ya está registrado',
        'weak-password' => 'La contraseña debe tener al menos 6 caracteres',
        'invalid-email' => 'El formato del correo no es válido',
        _ => 'Error al registrarse',
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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned(top: -120, left: -90, child: _Glow(AppColors.primary, 320)),
          Positioned(bottom: -140, right: -100, child: _Glow(AppColors.secondary, 300)),
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
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: IconButton(
                icon: Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
                onPressed: () => Navigator.pop(context),
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
                child: const Icon(Icons.person_add_alt_1_rounded, size: 38, color: Colors.white),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Crea tu cuenta',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
            const SizedBox(height: 6),
            Text('Regístrate para comenzar a usar PsyCase',
                textAlign: TextAlign.center, style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
            const SizedBox(height: 28),
            _field(_name, 'Nombre completo', Icons.person_outline_rounded),
            const SizedBox(height: 14),
            _field(_email, 'Correo electrónico', Icons.mail_outline_rounded, type: TextInputType.emailAddress),
            const SizedBox(height: 14),
            _field(
              _pass,
              'Contraseña',
              Icons.lock_outline_rounded,
              obscure: _hide,
              enableSuggestions: false, 
              autocorrect: false,
              suffix: IconButton(
                icon: Icon(_hide ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.textMuted, size: 20),
                onPressed: () => setState(() => _hide = !_hide),
              ),
            ),
            const SizedBox(height: 14),
            _field(
              _confirm, 
              'Confirmar contraseña', 
              Icons.verified_user_outlined, 
              obscure: _hide,
              enableSuggestions: false,
              autocorrect: false,
            ),
            const SizedBox(height: 26),
            _button(),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('¿Ya tienes cuenta? Inicia sesión',
                  style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );

  Widget _field(
    TextEditingController c, 
    String label, 
    IconData icon, {
    bool obscure = false, 
    TextInputType? type, 
    Widget? suffix,
    bool enableSuggestions = true, 
    bool autocorrect = true,
  }) {
    OutlineInputBorder b(Color col, [double w = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: col, width: w));
    return TextField(
      controller: c,
      obscureText: obscure,
      keyboardType: type,
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
          onPressed: _loading ? null : _register,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            minimumSize: const Size.fromHeight(56),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: _loading
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
              : const Text('Crear cuenta',
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