import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';

class EmailAuthPage extends StatefulWidget {
  const EmailAuthPage({super.key});

  @override
  State<EmailAuthPage> createState() => _EmailAuthPageState();
}

class _EmailAuthPageState extends State<EmailAuthPage> {
  final _formKey = GlobalKey<FormState>();

  bool _isSignIn = true;
  bool _isSubmitting = false;

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String? _errorText;

  SupabaseClient get _client => Supabase.instance.client;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ----------------------------------------------------------
  // SUBMIT (SIGN IN or SIGN UP)
  // ----------------------------------------------------------
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final username = _usernameController.text.trim();

    try {
      if (_isSignIn) {
        // ----------------------------------------------------------
        // SIGN IN
        // ----------------------------------------------------------
        await _client.auth.signInWithPassword(
          email: email,
          password: password,
        );

        if (!mounted) return;

        context.go('/home'); // Redirect to home
      } else {
        // ----------------------------------------------------------
        // SIGN UP
        // ----------------------------------------------------------
        final response = await _client.auth.signUp(
          email: email,
          password: password,
        );

        final user = response.user;

        if (user != null) {
          // Create profile row in "profiles" table
          await _client.from('profiles').insert({
            'id': user.id,
            'full_name': username,
          });
        }

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Account created. Check your email if verification is required."),
          ),
        );

        // Switch to sign-in mode after signup
        setState(() => _isSignIn = true);
      }
    } catch (e) {
      setState(() => _errorText = e.toString());
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  // ----------------------------------------------------------
  // FORGOT PASSWORD
  // ----------------------------------------------------------
  Future<void> _forgotPassword() async {
    final TextEditingController emailController = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Reset Password'),
          content: TextField(
            controller: emailController,
            decoration: const InputDecoration(
              labelText: 'Enter your email',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.pop(context, emailController.text.trim()),
              child: const Text('Send reset link'),
            ),
          ],
        );
      },
    );

    if (result == null || result.isEmpty) return;

    try {
      await _client.auth.resetPasswordForEmail(result);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("If an account exists, a reset link was sent."),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  // ----------------------------------------------------------
  // UI
  // ----------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final isSignIn = _isSignIn;

    return Scaffold(
      appBar: AppBar(
        title: Text(isSignIn ? 'Sign In' : 'Create Account'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!isSignIn)
                    TextFormField(
                      controller: _usernameController,
                      decoration: const InputDecoration(labelText: 'Username'),
                      validator: (v) {
                        if (!isSignIn && (v == null || v.trim().isEmpty)) {
                          return 'Username required';
                        }
                        return null;
                      },
                    ),
                  if (!isSignIn) const SizedBox(height: 12),

                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Email required';
                      }
                      if (!v.contains('@')) return 'Enter valid email';
                      return null;
                    },
                  ),

                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(labelText: 'Password'),
                    obscureText: true,
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return 'Password required';
                      }
                      if (v.length < 6) {
                        return 'Min 6 characters';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  if (_errorText != null)
                    Text(
                      _errorText!,
                      style: const TextStyle(color: Colors.red),
                    ),

                  const SizedBox(height: 8),

                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    child: _isSubmitting
                        ? const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          )
                        : Text(isSignIn ? 'Sign In' : 'Sign Up'),
                  ),

                  if (isSignIn)
                    TextButton(
                      onPressed: _isSubmitting ? null : _forgotPassword,
                      child: const Text('Forgot password?'),
                    ),

                  const SizedBox(height: 8),

                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isSignIn = !_isSignIn;
                        _errorText = null;
                      });
                    },
                    child: Text(
                      isSignIn
                          ? "Don't have an account? Create one"
                          : "Already have an account? Sign in",
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
