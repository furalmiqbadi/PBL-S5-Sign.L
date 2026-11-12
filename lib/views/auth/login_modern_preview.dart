import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/modern_theme.dart';

class LoginModernPreview extends StatelessWidget {
  const LoginModernPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ModernTheme.light,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 60),
                // Logo/Icon Placeholder
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: ModernTheme.primaryBlue,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: ModernTheme.softShadow,
                  ),
                  child: const Icon(Icons.sign_language_rounded, color: Colors.white, size: 32),
                ),
                const SizedBox(height: 32),
                Text(
                  "Selamat Datang di Sign.L",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: ModernTheme.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Belajar bahasa isyarat lebih mudah dengan bantuan AI.",
                  style: TextStyle(color: ModernTheme.textGray, fontSize: 16),
                ),
                const SizedBox(height: 48),
                const TextField(
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.email_outlined, color: ModernTheme.primaryBlue),
                    hintText: "Email",
                  ),
                ),
                const SizedBox(height: 16),
                const TextField(
                  obscureText: true,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.lock_outline, color: ModernTheme.primaryBlue),
                    hintText: "Password",
                  ),
                ),
                const Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: null,
                    child: Text("Lupa Password?", style: TextStyle(color: ModernTheme.primaryBlue)),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {},
                  child: const Text("Login", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                const Spacer(),
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Belum punya akun?"),
                      TextButton(
                        onPressed: () {},
                        child: const Text("Daftar", style: TextStyle(fontWeight: FontWeight.bold, color: ModernTheme.primaryBlue)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
