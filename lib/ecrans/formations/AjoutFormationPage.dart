import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:agri_tech_app/services/notification_service.dart';

class AjoutFormationPage extends StatefulWidget {
  @override
  _AjoutFormationPageState createState() => _AjoutFormationPageState();
}

class _AjoutFormationPageState extends State<AjoutFormationPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titreController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _dureeController = TextEditingController();
  String? _niveau;
  List<String> niveaux = ['Débutant', 'Intermédiaire', 'Avancé'];
  List<String> _tags = [];
  final _tagController = TextEditingController();

  Future<void> _ajouterFormation() async {
    if (_formKey.currentState!.validate()) {
      final titre = _titreController.text;
      final description = _descriptionController.text;
      final url = _urlController.text;
      final duree = int.tryParse(_dureeController.text) ?? 0;
      final niveau = _niveau;
      final tags = _tags;

      await FirebaseFirestore.instance.collection('formations').add({
        "titre": titre,
        "description": description,
        "url": url,
        "duree": duree,
        "niveau": niveau,
        "tags": tags,
        "created_at": FieldValue.serverTimestamp(),
      });

      final adminId = FirebaseAuth.instance.currentUser?.uid;
      final usersSnapshot = await FirebaseFirestore.instance.collection('utilisateurs').get();

      for (var doc in usersSnapshot.docs) {
        final userId = doc.id;
        if (userId != adminId) {
          await ServiceNotifications.notifierNouvelleFormation(
            userId: userId,
            titreFormation: titre,
          );
        }
      }

      Navigator.pop(context);
    }
  }

  void _ajouterTag() {
    if (_tagController.text.isNotEmpty && !_tags.contains(_tagController.text)) {
      setState(() {
        _tags.add(_tagController.text);
        _tagController.clear();
      });
    }
  }

  void _supprimerTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Nouvelle Formation",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.green[800],
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(15),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Remplissez les détails de la formation",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 25),
              _buildTextField(
                controller: _titreController,
                label: "Titre de la formation",
                hint: "Ex: Techniques de culture moderne",
                icon: Icons.title,
                validator: (value) => value!.isEmpty ? "Ce champ est requis" : null,
              ),
              SizedBox(height: 20),
              _buildTextField(
                controller: _descriptionController,
                label: "Description",
                hint: "Décrivez le contenu de la formation...",
                icon: Icons.description,
                maxLines: 3,
                validator: (value) => value!.isEmpty ? "Ce champ est requis" : null,
              ),
              SizedBox(height: 20),
              _buildTextField(
                controller: _urlController,
                label: "Lien YouTube",
                hint: "https://youtube.com/...",
                icon: Icons.link,
                validator: (value) => value!.isEmpty ? "Ce champ est requis" : null,
              ),
              SizedBox(height: 20),
              _buildTextField(
                controller: _dureeController,
                label: "Durée (minutes)",
                hint: "Ex: 45",
                icon: Icons.timer,
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 20),
              _buildDropdownField(),
              SizedBox(height: 20),
              _buildTagsField(),
              SizedBox(height: 30),
              Center(
                child: ElevatedButton(
                  onPressed: _ajouterFormation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[800],
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 3,
                  ),
                  child: Text(
                    "PUBLIER LA FORMATION",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int? maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.green[800]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[400]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.green[800]!, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
    );
  }

  Widget _buildDropdownField() {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: "Niveau",
        prefixIcon: Icon(Icons.school, color: Colors.green[800]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[400]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.green[800]!, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _niveau,
          isExpanded: true,
          hint: Text("Sélectionnez un niveau"),
          items: niveaux.map((String level) {
            return DropdownMenuItem(
              value: level,
              child: Text(level),
            );
          }).toList(),
          onChanged: (value) => setState(() => _niveau = value),
        ),
      ),
    );
  }

  Widget _buildTagsField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Tags (Mots-clés)",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.grey[800],
          ),
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _tagController,
                decoration: InputDecoration(
                  hintText: "Ajouter un tag...",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey[400]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.green[800]!, width: 2),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.add, color: Colors.green[800]),
                    onPressed: _ajouterTag,
                  ),
                ),
                onSubmitted: (_) => _ajouterTag(),
              ),
            ),
          ],
        ),
        SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _tags.map((tag) => Chip(
            label: Text(tag),
            deleteIcon: Icon(Icons.close, size: 18),
            onDeleted: () => _supprimerTag(tag),
            backgroundColor: Colors.green[50],
            shape: StadiumBorder(
              side: BorderSide(color: Colors.green[200]!),
            ),
          )).toList(),
        ),
      ],
    );
  }
}