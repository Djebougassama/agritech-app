import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:agri_tech_app/services/connectivity_service.dart';

class AjoutRecoltePage extends StatefulWidget {
  @override
  _AjoutRecoltePageState createState() => _AjoutRecoltePageState();
}

class _AjoutRecoltePageState extends State<AjoutRecoltePage> {
  final _formKey = GlobalKey<FormState>();
  final _produitController = TextEditingController();
  final _quantiteController = TextEditingController();

  String? selectedMembreId;
  String? selectedUnite = 'kg';
  DateTime selectedDate = DateTime.now();

  List<Map<String, dynamic>> membres = [];

  @override
  void initState() {
    super.initState();
    fetchMembres();
  }

  Future<void> fetchMembres() async {
    final connectivityService = Provider.of<ConnectivityService>(context, listen: false);
    final bool isOffline = connectivityService.isOffline;

    try {
      final snapshot = await FirebaseFirestore.instance.collection('membres').get();
      setState(() {
        membres = snapshot.docs.map((doc) => {
              'id': doc.id,
              'nom': doc['nom'],
            }).toList();
      });
      if (isOffline) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Membres chargés localement'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du chargement des membres : $e')),
      );
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> mettreAJourStock({
    required String produit,
    required String? cooperativeId,
    required int quantite,
    required String unite,
  }) async {
    if (cooperativeId == null) {
      print("Erreur: cooperativeId est null");
      return;
    }
    final stockQuery = await FirebaseFirestore.instance
        .collection('cooperatives')
        .doc(cooperativeId)
        .collection('stocksCoop')
        .where('produit', isEqualTo: produit)
        .limit(1)
        .get();

    if (stockQuery.docs.isNotEmpty) {
      final stockDoc = stockQuery.docs.first;
      final ancienneQuantite = (stockDoc['quantite'] as num?)?.toInt() ?? 0;
      await stockDoc.reference.update({
        'quantite': ancienneQuantite + quantite,
        'derniereMiseAJour': FieldValue.serverTimestamp(),
      });
    } else {
      final stockId = '${DateTime.now().millisecondsSinceEpoch}_$produit';
      await FirebaseFirestore.instance
          .collection('cooperatives')
          .doc(cooperativeId)
          .collection('stocksCoop')
          .doc(stockId)
          .set({
        'id': stockId,
        'cooperativeId': cooperativeId,
        'produit': produit,
        'quantite': quantite,
        'unite': unite,
        'derniereMiseAJour': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<String?> getCooperativeIdFromUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final querySnapshot = await FirebaseFirestore.instance
        .collection('cooperatives')
        .where('userId', isEqualTo: user.uid)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      return querySnapshot.docs.first.id;
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter une récolte'),
        backgroundColor: Colors.green[700],
      ),
      body: membres.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Consumer<ConnectivityService>(
              builder: (context, connectivityService, child) {
                final bool isOffline = connectivityService.isOffline;
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        if (isOffline)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: Text(
                              "Hors ligne - Données enregistrées localement",
                              style: GoogleFonts.lato(
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 4,
                          color: Colors.green[50],
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                DropdownButtonFormField<String>(
                                  value: selectedMembreId,
                                  decoration: InputDecoration(
                                    labelText: isOffline ? 'Sélectionner un membre (local)' : 'Sélectionner un membre',
                                    prefixIcon: const Icon(Icons.person, color: Colors.green),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  items: membres.map((membre) {
                                    return DropdownMenuItem<String>(
                                      value: membre['id'],
                                      child: Text(membre['nom']),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      selectedMembreId = value;
                                    });
                                  },
                                  validator: (value) => value == null ? 'Choisir un membre' : null,
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _produitController,
                                  decoration: InputDecoration(
                                    labelText: 'Produit',
                                    prefixIcon: const Icon(Icons.agriculture, color: Colors.brown),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  validator: (value) => value!.isEmpty ? 'Entrer le nom du produit' : null,
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: TextFormField(
                                        controller: _quantiteController,
                                        keyboardType: TextInputType.number,
                                        decoration: InputDecoration(
                                          labelText: 'Quantité',
                                          prefixIcon: const Icon(Icons.scale, color: Colors.green),
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                        validator: (value) {
                                          if (value!.isEmpty) return 'Entrer la quantité';
                                          final quantite = int.tryParse(value);
                                          return quantite == null || quantite <= 0 ? 'Quantité invalide' : null;
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      flex: 1,
                                      child: DropdownButtonFormField<String>(
                                        value: selectedUnite,
                                        decoration: InputDecoration(
                                          labelText: 'Unité',
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                        items: ['kg', 'sacs', 'caisses', 'tonnes']
                                            .map((unit) => DropdownMenuItem(value: unit, child: Text(unit)))
                                            .toList(),
                                        onChanged: (value) {
                                          setState(() {
                                            selectedUnite = value!;
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                InkWell(
                                  onTap: () => _selectDate(context),
                                  child: InputDecorator(
                                    decoration: InputDecoration(
                                      labelText: 'Date de récolte',
                                      prefixIcon: const Icon(Icons.calendar_today, color: Colors.orange),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    child: Text(DateFormat('yyyy-MM-dd').format(selectedDate)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              backgroundColor: const Color.fromARGB(255, 75, 153, 79),
                            ),
                            onPressed: () async {
                              if (_formKey.currentState!.validate()) {
                                final user = FirebaseAuth.instance.currentUser;

                                if (user == null || selectedMembreId == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Utilisateur ou membre non identifié')));
                                  return;
                                }

                                final cooperativeId = await getCooperativeIdFromUser();
                                if (cooperativeId == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('ID de coopérative non trouvé')));
                                  return;
                                }

                                final produit = _produitController.text.trim();
                                final quantiteStr = _quantiteController.text.trim();
                                final quantite = int.tryParse(quantiteStr);
                                if (quantite == null || quantite <= 0) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Quantité invalide')));
                                  return;
                                }

                                try {
                                  await FirebaseFirestore.instance.collection('recoltesCoop').add({
                                    'membreId': selectedMembreId,
                                    'produit': produit,
                                    'quantite': quantite,
                                    'unite': selectedUnite,
                                    'dateRecolte': selectedDate,
                                    'userId': user.uid,
                                    'cooperativeId': cooperativeId,
                                  });

                                  await mettreAJourStock(
                                    produit: produit,
                                    cooperativeId: cooperativeId,
                                    quantite: quantite,
                                    unite: selectedUnite!,
                                  );

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        isOffline
                                            ? 'Récolte enregistrée localement, synchronisation en attente'
                                            : 'Récolte ajoutée avec succès !',
                                      ),
                                      backgroundColor: isOffline ? Colors.orange : Colors.green,
                                    ),
                                  );
                                  Navigator.pop(context);
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Erreur : $e')));
                                }
                              }
                            },
                            icon: const Icon(Icons.check),
                            label: const Text('Enregistrer', style: TextStyle(fontSize: 16)),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}