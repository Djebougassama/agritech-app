import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'SelectionRecoltesPage.dart';

class AjoutVenteGroupeePage extends StatelessWidget {
  const AjoutVenteGroupeePage({super.key});

  Future<String?> getCurrentCoopId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final snap = await FirebaseFirestore.instance
        .collection('cooperatives')
        .where('userId', isEqualTo: user.uid)
        .limit(1)
        .get();

    if (snap.docs.isNotEmpty) {
      return snap.docs.first.id;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: getCurrentCoopId(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Scaffold(
            appBar: AppBar(title: Text("Nouvelle vente groupée")),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return Scaffold(
            appBar: AppBar(title: Text("Nouvelle vente groupée")),
            body: Center(child: Text("Coopérative non trouvée.")),
          );
        }

        return _AjoutVenteGroupeeForm(currentCoopId: snapshot.data!);
      },
    );
  }
}

class _AjoutVenteGroupeeForm extends StatefulWidget {
  final String currentCoopId;

  const _AjoutVenteGroupeeForm({required this.currentCoopId});

  @override
  State<_AjoutVenteGroupeeForm> createState() => _AjoutVenteGroupeeFormState();
}

class _AjoutVenteGroupeeFormState extends State<_AjoutVenteGroupeeForm> {
  final _formKey = GlobalKey<FormState>();
  String? selectedProduit;
  final _quantiteController = TextEditingController();
  final _prixUnitaireController = TextEditingController();
  DateTime selectedDate = DateTime.now().add(Duration(days: 7));

  List<String> produits = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchProduitsFromRecoltes();
  }

  Future<void> fetchProduitsFromRecoltes() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('recoltesCoop')
        .where('cooperativeId', isEqualTo: widget.currentCoopId)
        .get();

    final produitsSet = <String>{};
    for (var doc in snapshot.docs) {
      final prod = doc['produit'] as String?;
      if (prod != null && prod.isNotEmpty) {
        produitsSet.add(prod);
      }
    }

    setState(() {
      produits = produitsSet.toList();
      isLoading = false;
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );
    if (picked != null && picked != selectedDate)
      setState(() {
        selectedDate = picked;
      });
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final quantiteMin = int.tryParse(_quantiteController.text.trim());
    final prixUnitaire = double.tryParse(_prixUnitaireController.text.trim());

    if (quantiteMin == null || quantiteMin <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Quantité minimale invalide")));
      return;
    }

    if (prixUnitaire == null || prixUnitaire <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Prix unitaire invalide")));
      return;
    }

    if (selectedProduit == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Veuillez sélectionner un produit")));
      return;
    }

    await FirebaseFirestore.instance.collection('ventes_groupées').add({
      'produit': selectedProduit,
      'quantite_min': quantiteMin,
      'prix_unitaire': prixUnitaire,
      'date_limite': selectedDate,
      'etat': 'ouverte',
      'date_creation': DateTime.now(),
      'cooperativeId': widget.currentCoopId,
    });

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Vente groupée créée avec succès")));
    final venteDoc = await FirebaseFirestore.instance.collection('ventes_groupées').add({
  'produit': selectedProduit,
  'quantite_min': quantiteMin,
  'prix_unitaire': prixUnitaire,
  'date_limite': selectedDate,
  'etat': 'ouverte',
  'date_creation': DateTime.now(),
  'cooperativeId': widget.currentCoopId,
});


Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => SelectionRecoltesPage(
      cooperativeId: widget.currentCoopId,
      produit: selectedProduit!,
      venteId: venteDoc.id,
    ),
  ),
);

  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text("Nouvelle vente groupée"), backgroundColor: Colors.green[700]),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (produits.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text("Nouvelle vente groupée"), backgroundColor: Colors.green[700]),
        body: Center(child: Text("Aucun produit disponible depuis les récoltes.")),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text("Nouvelle vente groupée"), backgroundColor: Colors.green[700]),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              DropdownButtonFormField<String>(
                value: selectedProduit,
                hint: Text("Sélectionner un produit"),
                items: produits.map((prod) => DropdownMenuItem(value: prod, child: Text(prod))).toList(),
                onChanged: (val) => setState(() => selectedProduit = val),
                validator: (val) => val == null ? "Veuillez sélectionner un produit" : null,
              ),
              SizedBox(height: 16),

              TextFormField(
                controller: _quantiteController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Quantité minimale (kg)",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return "Entrer la quantité minimale";
                  if (int.tryParse(val) == null || int.parse(val) <= 0) return "Quantité minimale invalide";
                  return null;
                },
              ),
              SizedBox(height: 16),

              TextFormField(
                controller: _prixUnitaireController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: "Prix unitaire (GNF)",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return "Entrer le prix unitaire";
                  if (double.tryParse(val) == null || double.parse(val) <= 0) return "Prix unitaire invalide";
                  return null;
                },
              ),
              SizedBox(height: 16),

              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.calendar_today, color: Colors.orange),
                title: Text("Date limite: ${DateFormat('yyyy-MM-dd').format(selectedDate)}"),
                trailing: TextButton(
                  onPressed: () => _selectDate(context),
                  child: Text("Modifier"),
                ),
              ),

              SizedBox(height: 32),

              ElevatedButton.icon(
                onPressed: _submit,
                icon: Icon(Icons.check),
                label: Text("Créer la vente groupée"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
