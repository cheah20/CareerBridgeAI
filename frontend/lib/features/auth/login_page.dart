import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/glass_tokens.dart';
import '../../core/widgets/glass.dart';
import '../public/public_frame.dart';
import 'auth_backend.dart';
import 'auth_widgets.dart';
import 'session.dart';

/// Email + password login. After login the router sends the user to their
/// role's home (or the page they originally asked for).
class LoginPage extends StatelessWidget {
  const LoginPage({super.key, this.redirectTo});

  /// The page the guest originally asked for.
  final String? redirectTo;

  @override
  Widget build(BuildContext context) {
    return PublicFrame(
      centerContent: true,
      showLoginButton: false,
      child: AuthLayout(
        kicker: 'Welcome back',
        title: 'Log in to CareerBridge.',
        subtitle: 'One account for your resume, job matches and applications.',
        form: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _LoginForm(),
            if (kDebugMode) ...[const SizedBox(height: 16), _DeveloperPreview(redirectTo: redirectTo)],
          ],
        ),
      ),
    );
  }
}

class _LoginForm extends ConsumerStatefulWidget {
  const _LoginForm();

  @override
  ConsumerState<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends ConsumerState<_LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _hidePassword = true;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(sessionProvider.notifier).signIn(_email.text.trim(), _password.text);
      // The router moves on once the role has loaded.
    } on AuthFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = GlassTokens.of(context);
    final error = _error ?? ref.watch(sessionProvider).error;
    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Log in', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: t.text, fontWeight: FontWeight.w600)),
              const SizedBox(height: 20),
              if (error != null) ...[FormMessage(text: error), const SizedBox(height: 16)],
              TextFormField(
                key: const Key('login-email'),
                controller: _email,
                enabled: !_busy,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: validateEmail,
              ),
              const SizedBox(height: 14),
              TextFormField(
                key: const Key('login-password'),
                controller: _password,
                enabled: !_busy,
                obscureText: _hidePassword,
                autofillHints: const [AutofillHints.password],
                onFieldSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  labelText: 'Password',
                  suffixIcon: IconButton(
                    tooltip: _hidePassword ? 'Show password' : 'Hide password',
                    icon: Icon(_hidePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                    onPressed: () => setState(() => _hidePassword = !_hidePassword),
                  ),
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'Enter your password.' : null,
              ),
              const SizedBox(height: 20),
              FilledButton(
                key: const Key('login-submit'),
                onPressed: _busy ? null : _submit,
                child: BusyLabel(busy: _busy, label: 'Log in'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _busy ? null : () => context.go('/signup'),
                child: const Text('New here? Create an account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeveloperPreview extends ConsumerWidget {
  const _DeveloperPreview({required this.redirectTo});

  final String? redirectTo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = GlassTokens.of(context);
    return FocusCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Developer preview', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(
            'Open a role\'s layout without logging in. Debug builds only; the backend is not called.',
            style: TextStyle(fontSize: 12.5, color: t.focusTextSub),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final role in UserRole.values)
                OutlinedButton(
                  key: Key('preview-${role.pathSegment}'),
                  style: OutlinedButton.styleFrom(foregroundColor: t.focusText, backgroundColor: Colors.transparent),
                  onPressed: () {
                    ref.read(sessionProvider.notifier).previewAs(role);
                    final target = redirectTo;
                    context.go(target != null && target.startsWith(role.homePath) ? target : role.homePath);
                  },
                  child: Text(role.label),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
