import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import 'package:field_inventory_edge_ai/core/platform/app_mode.dart';
import 'package:field_inventory_edge_ai/core/theme/fieldline_theme.dart';
import 'package:field_inventory_edge_ai/core/widgets/fieldline_widgets.dart';

import '../../domain/auth_repository.dart';
import '../auth_providers.dart';

final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

String? _validateEmail(String? v) {
  final value = v?.trim() ?? '';
  if (value.isEmpty) return 'Nhập email';
  if (!_emailPattern.hasMatch(value)) return 'Email không hợp lệ';
  return null;
}

/// Màn Đăng nhập (Card 26). Cần có mạng ở lần đầu; sau đó phiên được giữ
/// trên máy nên app dùng được ngoại tuyến cho tới khi đăng xuất.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
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
    if (_busy || !_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(authRepositoryProvider)
          .signIn(email: _email.text, password: _password.text);
      TextInput.finishAutofillContext();
      // Bộ định tuyến tự chuyển vào Tổng quan khi phiên đăng nhập thay đổi.
    } on AuthFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _AuthLayout(
      title: 'Đăng nhập',
      subtitle: 'Dùng tài khoản được cấp hoặc tài khoản bạn đã đăng ký.',
      child: Form(
        key: _formKey,
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FlTextField(
                label: 'Email',
                controller: _email,
                hint: 'ten@congty.vn',
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                validator: _validateEmail,
              ),
              const Gap(16),
              FlTextField(
                label: 'Mật khẩu',
                controller: _password,
                obscureText: _hidePassword,
                autofillHints: const [AutofillHints.password],
                suffix: _PasswordToggle(
                  hidden: _hidePassword,
                  onTap: () => setState(() => _hidePassword = !_hidePassword),
                ),
                validator: (v) => (v ?? '').isEmpty ? 'Nhập mật khẩu' : null,
                onSubmitted: (_) => _submit(),
              ),
              if (_error != null) ...[const Gap(16), _ErrorBox(_error!)],
              const Gap(24),
              FilledButton(
                onPressed: _busy ? null : _submit,
                child: Text(_busy ? 'Đang đăng nhập...' : 'Đăng nhập'),
              ),
              const Gap(12),
              TextButton(
                onPressed: _busy ? null : () => context.go('/register'),
                child: const Text('Chưa có tài khoản? Đăng ký'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Màn Đăng ký tài khoản kiểm kê viên mới.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  bool _hidePassword = true;
  String? _error;

  /// Email đã đăng ký nhưng cần xác nhận qua thư.
  String? _sentTo;

  @override
  void dispose() {
    for (final c in [_name, _email, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final outcome = await ref
          .read(authRepositoryProvider)
          .signUp(
            email: _email.text,
            password: _password.text,
            fullName: _name.text,
          );
      TextInput.finishAutofillContext();
      if (outcome == SignUpOutcome.confirmEmail && mounted) {
        setState(() => _sentTo = _email.text.trim());
      }
    } on AuthFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sentTo = _sentTo;
    if (sentTo != null) {
      return _AuthLayout(
        title: 'Kiểm tra email',
        subtitle: 'Tài khoản đã được tạo.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InfoBanner(
              icon: Icons.mark_email_read_outlined,
              title: 'Đã gửi thư xác nhận tới $sentTo',
              subtitle: 'Mở thư, bấm liên kết xác nhận rồi quay lại đăng nhập.',
            ),
            const Gap(24),
            FilledButton(
              onPressed: () => context.go('/login'),
              child: const Text('Về màn đăng nhập'),
            ),
          ],
        ),
      );
    }

    return _AuthLayout(
      title: 'Đăng ký tài khoản',
      subtitle: 'Tài khoản mới có vai trò Kiểm kê viên.',
      child: Form(
        key: _formKey,
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FlTextField(
                label: 'Họ và tên',
                controller: _name,
                hint: 'Nguyễn Văn A',
                textCapitalization: TextCapitalization.words,
                autofillHints: const [AutofillHints.name],
                validator: (v) =>
                    (v ?? '').trim().isEmpty ? 'Nhập họ và tên' : null,
              ),
              const Gap(16),
              FlTextField(
                label: 'Email',
                controller: _email,
                hint: 'ten@congty.vn',
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                validator: _validateEmail,
              ),
              const Gap(16),
              FlTextField(
                label: 'Mật khẩu',
                controller: _password,
                obscureText: _hidePassword,
                autofillHints: const [AutofillHints.newPassword],
                suffix: _PasswordToggle(
                  hidden: _hidePassword,
                  onTap: () => setState(() => _hidePassword = !_hidePassword),
                ),
                validator: (v) => (v ?? '').length < 6
                    ? 'Mật khẩu cần ít nhất 6 ký tự'
                    : null,
              ),
              const Gap(16),
              FlTextField(
                label: 'Nhập lại mật khẩu',
                controller: _confirm,
                obscureText: _hidePassword,
                validator: (v) =>
                    v != _password.text ? 'Mật khẩu nhập lại không khớp' : null,
                onSubmitted: (_) => _submit(),
              ),
              if (_error != null) ...[const Gap(16), _ErrorBox(_error!)],
              const Gap(24),
              FilledButton(
                onPressed: _busy ? null : _submit,
                child: Text(_busy ? 'Đang tạo tài khoản...' : 'Đăng ký'),
              ),
              const Gap(12),
              TextButton(
                onPressed: _busy ? null : () => context.go('/login'),
                child: const Text('Đã có tài khoản? Đăng nhập'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuthLayout extends ConsumerWidget {
  const _AuthLayout({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: FlColors.sidebar,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: FlColors.logoTile,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.center_focus_strong_outlined,
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                        const Gap(12),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'FIELDLINE',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'INVENTORY & EDGE AI',
                              style: TextStyle(
                                color: Color(0xFF82A5AE),
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Gap(28),
                    FlCard(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Gap(6),
                          Text(
                            subtitle,
                            style: const TextStyle(
                              fontSize: 13,
                              color: FlColors.muted,
                            ),
                          ),
                          const Gap(24),
                          child,
                        ],
                      ),
                    ),
                    const Gap(16),
                    Text(
                      ref.watch(appModeProvider).canScan
                          ? 'Cần có mạng ở lần đăng nhập đầu. Sau đó app vẫn dùng được khi ngoại tuyến.'
                          : 'Bản web quản lý dữ liệu trên đám mây. Quét và lập phiếu bằng app điện thoại.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF8EAEB8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PasswordToggle extends StatelessWidget {
  const _PasswordToggle({required this.hidden, required this.onTap});

  final bool hidden;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: hidden ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
      onPressed: onTap,
      icon: Icon(
        hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        size: 20,
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return InfoBanner(
      icon: Icons.error_outline_rounded,
      tone: FlTone.danger,
      title: message,
    );
  }
}
