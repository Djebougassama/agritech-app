import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

class AidePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Aide",
          style: GoogleFonts.lato(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green.shade700,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(LucideIcons.helpCircle, color: Colors.green.shade700, size: 28),
                        SizedBox(width: 8),
                        Text(
                          "FAQ",
                          style: GoogleFonts.lato(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade800,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    _buildFaqItem(
                      "Comment modifier mon profil ?",
                      "Pour modifier votre profil, allez dans la section 'Profil' et cliquez sur 'Modifier'.",
                    ),
                    _buildFaqItem(
                      "Comment contacter le support ?",
                      "Vous pouvez nous contacter via le formulaire ci-dessous ou par email à support@agritech.com.",
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(LucideIcons.mail, color: Colors.green.shade700, size: 28),
                        SizedBox(width: 8),
                        Text(
                          "Contactez-nous",
                          style: GoogleFonts.lato(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade800,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: "Votre message",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      maxLines: 5,
                    ),
                    SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Message envoyé avec succès !"),
                              backgroundColor: Colors.green,
                            ),
                          );
                        },
                        icon: Icon(LucideIcons.send, color: Colors.white),
                        label: Text("Envoyer", style: GoogleFonts.lato(fontSize: 18, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          padding: EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return ExpansionTile(
      leading: Icon(LucideIcons.chevronDown, color: Colors.green.shade700),
      title: Text(
        question,
        style: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            answer,
            style: GoogleFonts.lato(fontSize: 14, color: Colors.black87),
          ),
        ),
      ],
    );
  }
}
