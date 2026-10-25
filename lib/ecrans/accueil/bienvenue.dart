import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PageBienvenue extends StatelessWidget {
  const PageBienvenue({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double iconSize = constraints.maxWidth * 0.25;
        final double textSize = constraints.maxWidth * 0.06;
        final double buttonWidth = constraints.maxWidth * 0.75;
        final double padding = constraints.maxWidth * 0.07;
        final double spacing = constraints.maxHeight * 0.03;

        return Scaffold(
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF2E7D32), Color(0xFF66BB6A)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: padding),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.agriculture,
                      size: iconSize.clamp(50, 120), // Taille adaptable
                      color: Colors.white,
                    ),
                    SizedBox(height: spacing),
                    Text(
                      "Bienvenue sur AgriTech",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.lato(
                        fontSize: textSize.clamp(16, 32),
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: spacing * 0.5),
                    Text(
                      "Optimisez votre gestion agricole avec notre plateforme",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.lato(
                        fontSize: (textSize * 0.6).clamp(12, 20),
                        color: Colors.white70,
                      ),
                    ),
                    SizedBox(height: spacing * 2),
                    SizedBox(
                      width: buttonWidth,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(context, '/inscription');
                        },
                        icon: const Icon(Icons.app_registration),
                        label: const Text("Créer un compte"),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.green.shade700,
                          padding: EdgeInsets.symmetric(
                              vertical: (constraints.maxHeight * 0.02).clamp(10, 18)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          textStyle: GoogleFonts.lato(fontSize: textSize * 0.6),
                          elevation: 5,
                        ),
                      ),
                    ),
                    SizedBox(height: spacing * 0.5),
                    SizedBox(
                      width: buttonWidth,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(context, '/connexion');
                        },
                        icon: const Icon(Icons.login),
                        label: const Text("Se connecter"),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white),
                          padding: EdgeInsets.symmetric(
                              vertical: (constraints.maxHeight * 0.02).clamp(10, 18)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          textStyle: GoogleFonts.lato(fontSize: textSize * 0.6),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
