import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart'; 
import 'providers/auth_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'widgets/auth_wrapper.dart';

@immutable
class SpacingTheme extends ThemeExtension<SpacingTheme> {
  final double s8;
  final double s12;
  final double s16;

  const SpacingTheme({
    this.s8 = 8.0,
    this.s12 = 12.0,
    this.s16 = 16.0,
  });

  @override
  SpacingTheme copyWith({double? s8, double? s12, double? s16}) =>
      SpacingTheme(s8: s8 ?? this.s8, s12: s12 ?? this.s12, s16: s16 ?? this.s16);

  @override
  ThemeExtension<SpacingTheme> lerp(ThemeExtension<SpacingTheme>? other, double t) {
    if (other is! SpacingTheme) return this;
    return SpacingTheme(
      s8: lerpDouble(s8, other.s8, t)!,
      s12: lerpDouble(s12, other.s12, t)!,
      s16: lerpDouble(s16, other.s16, t)!,
    );
  }
}

class Gap extends SizedBox {
  const Gap(double size, {super.key}) : super(width: size, height: size);
  const Gap.s8({Key? key}) : this(8, key: key);
  const Gap.s12({Key? key}) : this(12, key: key);
  const Gap.s16({Key? key}) : this(16, key: key);
}

class Gaps {
  static const h8 = SizedBox(height: 8);
  static const h12 = SizedBox(height: 12);
  static const h16 = SizedBox(height: 16);
  static const w8 = SizedBox(width: 8);
  static const w12 = SizedBox(width: 12);
  static const w16 = SizedBox(width: 16);
}

class Insets {
  static const a8 = EdgeInsets.all(8);
  static const a12 = EdgeInsets.all(12);
  static const a16 = EdgeInsets.all(16);
  static const h8 = EdgeInsets.symmetric(horizontal: 8);
  static const h12 = EdgeInsets.symmetric(horizontal: 12);
  static const h16 = EdgeInsets.symmetric(horizontal: 16);
  static const v8 = EdgeInsets.symmetric(vertical: 8);
  static const v12 = EdgeInsets.symmetric(vertical: 12);
  static const v16 = EdgeInsets.symmetric(vertical: 16);
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(seedColor: Colors.indigo);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return AuthWrapper(
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'UnisonMap',
              theme: ThemeData(
                useMaterial3: true,
                colorScheme: colorScheme,
                textTheme: GoogleFonts.interTextTheme().copyWith(
                  displayLarge: GoogleFonts.inter(fontWeight: FontWeight.w700),
                  displayMedium: GoogleFonts.inter(fontWeight: FontWeight.w700),
                  headlineSmall: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  titleLarge: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  bodyLarge: GoogleFonts.inter(fontWeight: FontWeight.w400),
                  bodyMedium: GoogleFonts.inter(fontWeight: FontWeight.w400),
                  labelLarge: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
                appBarTheme: AppBarTheme(
                  backgroundColor: colorScheme.surface,
                  foregroundColor: colorScheme.onSurface,
                  elevation: 0,
                  centerTitle: true,
                  titleTextStyle: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                scaffoldBackgroundColor: colorScheme.surface,
                extensions: const [SpacingTheme()],
              ),
              home: const SplashScreen(),
              routes: {
                '/login': (_) => const LoginScreen(),
                '/register': (_) => const RegisterScreen(),
                '/dashboard': (_) => const DashboardScreen(),
              },
            ),
          );
        },
      ),
    );
  }
}
