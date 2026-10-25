import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';


class HistoriquePaiementPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text("Mes transactions"),
        backgroundColor: Colors.green.shade700,
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('transactions')
            .where('user_id', isEqualTo: userId)
            .orderBy('created_at', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) return Center(child: Text('Aucune transaction enregistrée.'));

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index];
              return ListTile(
                leading: Icon(Icons.payment, color: Colors.green),
                title: Text('${data['provider']} - ${data['amount']} GNF'),
                subtitle: Text('Status: ${data['status']}'),
                trailing: Text(
                  (data['created_at'] as Timestamp).toDate().toLocal().toString().substring(0, 16),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
