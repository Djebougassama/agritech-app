import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:agri_tech_app/ecrans/authentification/ecran_connexion.dart';
import 'package:agri_tech_app/main.dart';
import 'package:agri_tech_app/ecrans/Notifications/notifications_page.dart';

class ParametresPage extends StatefulWidget {
  @override
  _ParametresPageState createState() => _ParametresPageState();
}

class _ParametresPageState extends State<ParametresPage> {
  bool _darkMode = false;

  @override
  void initState() {
    super.initState();
    _loadDarkMode();
  }

  _loadDarkMode() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _darkMode = prefs.getBool('darkMode') ?? false;
    });
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => EcranConnexion()),
    );
  }

  Future<void> _changePassword() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.email != null) {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: user.email!);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lien de réinitialisation envoyé à ${user.email}")),
      );
    }
  }

  Future<void> _deleteAccount() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.delete();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Compte supprimé avec succès.")));
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => EcranConnexion()));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur : ${e.toString()}")));
    }
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? Theme.of(context).colorScheme.primary),
      title: Text(title, style: TextStyle(fontSize: 16)),
      trailing: Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      appBar: AppBar(
        title: Text("Paramètres"),
        backgroundColor: _darkMode ? Colors.black : Colors.green,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _signOut,
          )
        ],
      ),
      body: Container(
        color: bgColor,
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // Section : Apparence
            Text("Apparence", style: Theme.of(context).textTheme.titleLarge),
            ListTile(
              leading: Icon(Icons.dark_mode),
              title: Text('Mode Sombre'),
              trailing: Switch(
                value: _darkMode,
                onChanged: (bool value) {
                  setState(() {
                    _darkMode = value;
                  });
                  MyApp.of(context)?.toggleTheme(value);
                },
              ),
            ),
            Divider(),

            // Section : Compte
            Text("Compte", style: Theme.of(context).textTheme.titleLarge),
            _buildSettingTile(
              icon: Icons.person,
              title: 'Mon Profil',
              onTap: () {
                Navigator.pushNamed(context, '/UtilisateurProfil');
              },
            ),
            _buildSettingTile(
              icon: Icons.lock_reset,
              title: 'Changer le mot de passe',
              onTap: _changePassword,
            ),
            _buildSettingTile(
              icon: Icons.delete_forever,
              title: 'Supprimer le compte',
              iconColor: Colors.red,
              onTap: () {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Text("Confirmation"),
                    content: Text("Voulez-vous vraiment supprimer votre compte ?"),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context), child: Text("Annuler")),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _deleteAccount();
                        },
                        child: Text("Supprimer", style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
            ),
            _buildSettingTile(
              icon: Icons.logout,
              title: 'Déconnexion',
              onTap: _signOut,
              iconColor: Colors.redAccent,
            ),
            Divider(),

            // Section : Préférences
            Text("Préférences", style: Theme.of(context).textTheme.titleLarge),
            _buildSettingTile(
              icon: Icons.notifications,
              title: 'Notifications',
              onTap: () {
                Navigator.push(context, MaterialPageRoute(
                builder: (context) =>  NotificationsPage(),
              ));
              },
            ),
            _buildSettingTile(
              icon: Icons.language,
              title: 'Langue',
              onTap: () {
                Navigator.pushNamed(context, '/language');
              },
            ),
            _buildSettingTile(
              icon: Icons.info_outline,
              title: 'À propos de l’application',
              onTap: () {
                showAboutDialog(
                  context: context,
                  applicationName: "AgriTech",
                  applicationVersion: "1.0.0",
                  applicationLegalese: "© 2025 AgriTech. Tous droits réservés.",
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
