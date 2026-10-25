import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:agri_tech_app/services/connectivity_service.dart';


class VenteGroupeePage extends StatefulWidget {
  @override
  _VenteGroupeePageState createState() => _VenteGroupeePageState();
}

class _VenteGroupeePageState extends State<VenteGroupeePage> {
  final _formKey = GlobalKey<FormState>();
  final _produitController = TextEditingController();
  final _quantiteController = TextEditingController();
  final _prixController = TextEditingController();
  final _commentaireController = TextEditingController();
  String? selectedUnite;
  String? cooperativeId;
  Map<String, bool> selectedRecoltes = {};

  @override
  void initState() {
    super.initState();
    _fetchCooperativeId();
  }

  Future<void> _fetchCooperativeId() async {
    final user = FirebaseAuth.instance.currentUser;
    final connectivityService = Provider.of<ConnectivityService>(context, listen: false);
    final bool isOffline = connectivityService.isOffline;

    if (user != null) {
      try {
        final querySnapshot = await FirebaseFirestore.instance
            .collection('cooperatives')
            .where('userId', isEqualTo: user.uid)
            .limit(1)
            .get();
        if (querySnapshot.docs.isNotEmpty) {
          setState(() {
            cooperativeId = querySnapshot.docs.first.id;
            _fetchRecoltes();
          });
          if (isOffline) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('ID de coopérative chargé localement'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement de l\'ID de coopérative : $e')),
        );
      }
    }
  }

  Future<void> _fetchRecoltes() async {
    if (cooperativeId == null) return;
    final connectivityService = Provider.of<ConnectivityService>(context, listen: false);
    final bool isOffline = connectivityService.isOffline;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('recoltesCoop')
          .where('cooperativeId', isEqualTo: cooperativeId)
          .get();
      setState(() {
        selectedRecoltes = {for (var doc in snapshot.docs) doc.id: false};
      });
      if (isOffline) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Récoltes chargées localement'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du chargement des récoltes : $e')),
      );
    }
  }

  Future<int> getTotalQuantite() async {
    final connectivityService = Provider.of<ConnectivityService>(context, listen: false);
    final bool isOffline = connectivityService.isOffline;

    final selectedIds = selectedRecoltes.entries.where((e) => e.value).map((e) => e.key).toList();
    if (selectedIds.isEmpty) {
      _quantiteController.text = isOffline ? '0 (local)' : '0';
      return 0;
    }
    final quantites = await Future.wait(selectedIds.map((id) => FirebaseFirestore.instance
        .collection('recoltesCoop')
        .doc(id)
        .get()
        .then((doc) => (doc['quantite'] as num?)?.toInt() ?? 0)));
    final total = quantites.reduce((a, b) => a + b);
    _quantiteController.text = isOffline ? '$total (local)' : '$total';
    return total;
  }

  Future<void> _proposerVenteGroupee() async {
    final connectivityService = Provider.of<ConnectivityService>(context, listen: false);
    final bool isOffline = connectivityService.isOffline;

    if (_formKey.currentState!.validate() && cooperativeId != null) {
      final quantiteTotale = await getTotalQuantite();
      final prix = double.tryParse(_prixController.text.trim()) ?? 0.0;
      final unite = selectedUnite ?? 'kg';
      final commentaire = _commentaireController.text.trim();

      if (quantiteTotale <= 0 || prix <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Quantité ou prix invalide')));
        return;
      }

      final produit = _produitController.text.isNotEmpty
          ? _produitController.text
          : 'Mélange de récoltes';

      try {
        await FirebaseFirestore.instance
            .collection('cooperatives')
            .doc(cooperativeId)
            .collection('ventesCollectives')
            .add({
          'produit': produit,
          'quantiteTotale': quantiteTotale,
          'unite': unite,
          'prix': prix,
          'statut': 'proposé',
          'dateCreation': FieldValue.serverTimestamp(),
          'commentaire': commentaire.isNotEmpty ? commentaire : null,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isOffline
                  ? 'Vente collective enregistrée localement, synchronisation en attente'
                  : 'Vente collective proposée avec succès !',
            ),
            backgroundColor: isOffline ? Colors.orange : Colors.green,
          ),
        );
        _produitController.clear();
        _quantiteController.clear();
        _prixController.clear();
        _commentaireController.clear();
        setState(() {
          selectedRecoltes = {};
          _fetchRecoltes();
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur : $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Proposer une vente collective'),
        backgroundColor: Colors.green[700],
      ),
      body: cooperativeId == null
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
                                TextFormField(
                                  controller: _produitController,
                                  decoration: InputDecoration(
                                    labelText: 'Produit (optionnel)',
                                    prefixIcon: const Icon(Icons.agriculture),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _quantiteController,
                                  readOnly: true,
                                  decoration: InputDecoration(
                                    labelText: isOffline ? 'Quantité totale (automatique, local)' : 'Quantité totale (automatique)',
                                    prefixIcon: const Icon(Icons.scale),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _prixController,
                                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                                  decoration: InputDecoration(
                                    labelText: 'Prix (en unité monétaire)',
                                    prefixIcon: const Icon(Icons.attach_money),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  validator: (value) => value == null || value.isEmpty ? 'Entrez un prix' : null,
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _commentaireController,
                                  decoration: InputDecoration(
                                    labelText: 'Commentaire (optionnel)',
                                    prefixIcon: const Icon(Icons.comment),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                DropdownButtonFormField<String>(
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
                                      selectedUnite = value;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          isOffline ? 'Sélectionner les récoltes (local) :' : 'Sélectionner les récoltes :',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        selectedRecoltes.isEmpty
                            ? Center(child: Text(isOffline ? 'Aucune récolte disponible (local)' : 'Aucune récolte disponible'))
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: selectedRecoltes.length,
                                itemBuilder: (context, index) {
                                  final recolteId = selectedRecoltes.keys.elementAt(index);
                                  return FutureBuilder<DocumentSnapshot>(
                                    future: FirebaseFirestore.instance.collection('recoltesCoop').doc(recolteId).get(),
                                    builder: (context, snapshot) {
                                      if (!snapshot.hasData) return const ListTile();
                                      final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
                                      final produit = data['produit'] ?? 'Inconnu';
                                      final quantite = (data['quantite'] as num?)?.toInt() ?? 0;
                                      final unite = data['unite'] ?? 'kg';
                                      return CheckboxListTile(
                                        title: Text(isOffline ? '$produit - $quantite $unite (local)' : '$produit - $quantite $unite'),
                                        value: selectedRecoltes[recolteId] ?? false,
                                        onChanged: (bool? value) {
                                          if (value != null) {
                                            setState(() {
                                              selectedRecoltes[recolteId] = value;
                                              getTotalQuantite();
                                            });
                                          }
                                        },
                                        controlAffinity: ListTileControlAffinity.leading,
                                      );
                                    },
                                  );
                                },
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
                            onPressed: _proposerVenteGroupee,
                            icon: const Icon(Icons.group_add),
                            label: const Text('Proposer vente collective', style: TextStyle(fontSize: 16)),
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