/// Layar Login — autentikasi user single-owner.
///
/// Flow:
/// 1. User input email/username & password
/// 2. Validasi lokal (tidak kosong, password >= 6 karakter)
/// 3. Panggil AuthRepository.login()
/// 4. Simpan token ke flutter_secure_storage
/// 5. Navigasi ke Dashboard
///
/// UI:
/// - Logo app di atas
/// - Email field
/// - Password field (obscure)
/// - Login button (full width)
/// - Loading state
/// - Error message dari API
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    // Sukses → status auth berubah → GoRouter redirect ke /dashboard.
    // Error ditampilkan lewat authProvider.errorMessage di build().
    await ref.read(authProvider.notifier).login(
          _emailController.text.trim(),
          _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final isLoading = auth.isSubmitting;
    final errorMessage = auth.errorMessage;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: AppSpacing.xxxl),

                // Logo
                Icon(
                  Icons.account_balance_wallet,
                  size: 64,
                  color: AppColors.primary,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Personal Finance',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                ),
                Text(
                  'Tracker',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                ),

                const SizedBox(height: AppSpacing.xxxl),

                // Email Field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Email / Username',
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: Validators.validateEmail,
                ),

                const SizedBox(height: AppSpacing.lg),

                // Password Field
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _handleLogin(),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                  ),
                  validator: Validators.validatePassword,
                ),

                const SizedBox(height: AppSpacing.xl),

                // Login Button
                SizedBox(
                  width: double.infinity,
                  height: AppSpacing.buttonHeight,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'MASUK',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),

                // Error Message
                if (errorMessage != null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    errorMessage,
                    style: AppTextStyles.errorMessage(context),
                    textAlign: TextAlign.center,
                  ),
                ],

                const SizedBox(height: AppSpacing.xxl),

                // Version
                Text(
                  'v1.0.0',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textHint,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
