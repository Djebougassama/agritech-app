import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../modeles/conseil.dart';
import 'package:agri_tech_app/services/notification_service.dart';

class AjoutConseilPage extends StatefulWidget {
  final Conseil? conseilToEdit;

  const AjoutConseilPage({super.key, this.conseilToEdit});

  @override
  State<AjoutConseilPage> createState() => _AjoutConseilPageState();
}

class _AjoutConseilPageState extends State<AjoutConseilPage> {
  final _formKey = GlobalKey<FormState>();
  final _titreController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagsController = TextEditingController();
  String _categorie = 'Cultures';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.conseilToEdit != null) {
      _titreController.text = widget.conseilToEdit!.titre;
      _descriptionController.text = widget.conseilToEdit!.description;
      _categorie = widget.conseilToEdit!.categorie;
      _tagsController.text = widget.conseilToEdit!.tags?.join(', ') ?? '';
    }
  }

  Future<void> _enregistrerConseil() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;

      // 🔄 Conversion des tags
      final tags = _tagsController.text
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList();

      final conseilData = {
        'titre': _titreController.text.trim(),
        'description': _descriptionController.text.trim(),
        'categorie': _categorie,
        'tags': tags,
        'datePublication': widget.conseilToEdit != null 
            ? widget.conseilToEdit!.datePublication.toIso8601String()
            : DateTime.now().toIso8601String(),
        'auteurId': userId,
      };

      if (widget.conseilToEdit == null) {
        await FirebaseFirestore.instance.collection('conseils').add(conseilData);

        // 🔔 Notifier les autres utilisateurs
        final usersSnapshot = await FirebaseFirestore.instance.collection('utilisateurs').get();

        for (var doc in usersSnapshot.docs) {
          if (doc.id != userId) {
            await ServiceNotifications.notifierNouveauConseil(
              userId: doc.id,
              categorie: _categorie,
            );
          }
        }
      } else {
        await FirebaseFirestore.instance
            .collection('conseils')
            .doc(widget.conseilToEdit!.id)
            .update(conseilData);
      }

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Erreur lors de l'enregistrement"),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.conseilToEdit == null 
            ? "Ajouter un Conseil" 
            : "Modifier le Conseil"),
        backgroundColor: Colors.green.shade700,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titreController,
                decoration: const InputDecoration(labelText: 'Titre'),
                validator: (val) => val!.isEmpty ? 'Champ requis' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Description'),
                validator: (val) => val!.isEmpty ? 'Champ requis' : null,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _categorie,
                items: [
                  'Cultures',
                  'Engrais',
                  'Irrigation',
                  'Machinerie',
                  'Protection des Plantes',
                  'Récolte',
                  'Autres'
                ].map((cat) => DropdownMenuItem(
                      value: cat,
                      child: Text(cat),
                    )).toList(),
                onChanged: (val) => setState(() => _categorie = val!),
                decoration: const InputDecoration(labelText: 'Catégorie'),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _tagsController,
                decoration: const InputDecoration(
                  labelText: 'Mots-clés (séparés par des virgules)',
                  hintText: 'ex: tomate, arrosage, bio',
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loading ? null : _enregistrerConseil,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _loading
                    ? const CircularProgressIndicator()
                    : Text(widget.conseilToEdit == null 
                        ? "Ajouter le conseil" 
                        : "Mettre à jour"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
