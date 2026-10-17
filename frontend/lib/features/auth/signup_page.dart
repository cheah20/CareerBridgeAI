import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/glass_tokens.dart';
import '../../core/widgets/glass.dart';
import '../public/public_frame.dart';
import 'auth_backend.dart';
import 'auth_widgets.dart';
import 'session.dart';

/// Create an account as a Job Seeker or Recruiter. Admin accounts are never
/// created here (the database sign-up trigger also refuses them).
class SignUpPage extends StatelessWidget {
  const SignUpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PublicFrame(
      centerContent: true,
      child: AuthLayout(
        kicker: 'Create your account',
        title: 'Join CareerBridge.',
        subtitle: 'Choose how you will use CareerBridge. You can add your resume or company details after signing up.',
        form: _SignUpForm(),
      ),
    );
  }
}

class _SignUpForm extends ConsumerStatefulWidget {
  const _SignUpForm();

  @override
  ConsumerState<_SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends ConsumerState<_SignUpForm> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  UserRole _role = UserRole.jobSeeker;
  bool _busy = false;
  bool _hidePassword = true;
  String? _error;

  /// Set after sign-up when the email must be confirmed.
  String? _sentTo;

  @override
  void dispose() {
    for (final c in [_name, _email, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final email = _email.text.trim();
    try {
      final needsConfirmation = await ref.read(sessionProvider.notifier).signUp(
            email: email,
            password: _password.text,
            fullName: _name.text.trim(),
            role: _role,
          );
      if (needsConfirmation && mounted) setState(() => _sentTo = email);
      // Without confirmation the user is logged in and the router moves on.
    } on AuthFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = GlassTokens.of(context);
    final title = Theme.of(context).textTheme.titleLarge?.copyWith(color: t.text, fontWeight: FontWeight.w600);

    if (_sentTo != null) {
      return GlassCard(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.mark_email_read_outlined, size: 32, color: t.text),
            const SizedBox(height: 12),
            Text('Check your inbox', style: title),
            const SizedBox(height: 8),
            Text(
              'We sent a confirmation link to $_sentTo. Open it to activate your account, then log in. '
              'If you cannot find it, check your spam folder.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            FilledButton(onPressed: () => context.go('/login'), child: const Text('Go to log in')),
          ],
        ),
      );
    }

    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Sign up', style: title),
              const SizedBox(height: 16),
              Text('I am a', style: TextStyle(fontSize: 12.5, color: t.textSub)),
              const SizedBox(height: 8),
              SegmentedButton<UserRole>(
                key: const Key('signup-role'),
                segments: const [
                  ButtonSegment(value: UserRole.jobSeeker, label: Text('Job seeker'), icon: Icon(Icons.person_search_outlined)),
                  ButtonSegment(value: UserRole.recruiter, label: Text('Recruiter'), icon: Icon(Icons.apartment_outlined)),
                ],
                selected: {_role},
                onSelectionChanged: _busy ? null : (s) => setState(() => _role = s.first),
              ),
              const SizedBox(height: 18),
              if (_error != null) ...[FormMessage(text: _error!), const SizedBox(height: 16)],
              TextFormField(
                key: const Key('signup-name'),
                controller: _name,
                enabled: !_busy,
                autofillHints: const [AutofillHints.name],
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Full name'),
                validator: (v) => (v == null || v.trim().length < 2) ? 'Enter your full name.' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                key: const Key('signup-email'),
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
                key: const Key('signup-password'),
                controller: _password,
                enabled: !_busy,
                obscureText: _hidePassword,
                autofillHints: const [AutofillHints.newPassword],
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'Password',
                  helperText: 'At least 8 characters',
                  suffixIcon: IconButton(
                    tooltip: _hidePassword ? 'Show password' : 'Hide password',
                    icon: Icon(_hidePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                    onPressed: () => setState(() => _hidePassword = !_hidePassword),
                  ),
                ),
                validator: (v) => (v == null || v.length < 8) ? 'Use at least 8 characters.' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                key: const Key('signup-confirm'),
                controller: _confirm,
                enabled: !_busy,
                obscureText: _hidePassword,
                onFieldSubmitted: (_) => _submit(),
                decoration: const InputDecoration(labelText: 'Confirm password'),
                validator: (v) => v != _password.text ? 'Passwords do not match.' : null,
              ),
              const SizedBox(height: 20),
              FilledButton(
                key: const Key('signup-submit'),
                onPressed: _busy ? null : _submit,
                child: BusyLabel(busy: _busy, label: 'Create account'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _busy ? null : () => context.go('/login'),
                child: const Text('Already have an account? Log in'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
