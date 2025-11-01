import 'package:flutter/material.dart';
import '../../data/supabase_client.dart';

class AuthGate extends StatefulWidget { const AuthGate({super.key}); @override State<AuthGate> createState()=>_AuthGateState(); }
class _AuthGateState extends State<AuthGate> {
  final emailCtrl = TextEditingController();
  @override Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(title: const Text('Build Your Match')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children:[
          TextField(controller: emailCtrl, decoration: const InputDecoration(labelText:'Email')),
          const SizedBox(height: 12),
          FilledButton(onPressed: () async {
            await supa.auth.signInWithOtp(email: emailCtrl.text);
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Check your email.')));
          }, child: const Text('Send magic link')),
        ]),
      ),
    );
  }
}
