import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_page.dart';

class AuthGate extends StatelessWidget {
  final Widget signedIn;

  const AuthGate({super.key, required this.signedIn});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        // Luôn kiểm tra session hiện tại từ client để đảm bảo tính thời gian thực
        final session = Supabase.instance.client.auth.currentSession;

        if (session == null) {
          return const LoginPage();
        }

        return signedIn;
      },
    );
  }
}
