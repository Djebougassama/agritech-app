import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '/../services/connectivity_service.dart';
import '/../services/mock_payment.dart';
import '/../ecrans/Rapport/rapport_transaction.dart';
import '/../services/notification_service.dart';

class PagePaiement extends StatefulWidget {
  final double? amount; // Optionnel, pour rétrocompatibilité
  final double? quantity; // Nouveau paramètre optionnel
  final double? price; // Nouveau paramètre optionnel

  const PagePaiement({
    Key? key,
    this.amount,
    this.quantity,
    this.price,
  }) : super(key: key);

  @override
  _PagePaiementState createState() => _PagePaiementState();
}

class _PagePaiementState extends State<PagePaiement> {
  bool _isLoading = false;
  String _phone = '';
  String _password = '';
  String? _selectedOption;
  double _totalAmount = 0.0;

  @override
  void initState() {
    super.initState();
    // Calcule le montant si quantity et price sont fournis, sinon utilise amount
    if (widget.quantity != null && widget.price != null) {
      _totalAmount = widget.quantity! * widget.price!;
    } else {
      _totalAmount = widget.amount ?? 0.0;
    }
  }

  Future<void> _processPayment(bool isOffline) async {
    if (_selectedOption == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Veuillez sélectionner un moyen de paiement"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final paymentResult = await MockPaymentService.processPayment(
        provider: _selectedOption!,
        phone: _phone,
        password: _password,
        amount: _totalAmount,
      );

      await _saveTransactionToFirestore(
        success: paymentResult['success'],
        transactionId: paymentResult['transaction_id'],
        isOffline: isOffline,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isOffline
                ? "Paiement enregistré localement, synchronisation en attente"
                : paymentResult['message'],
          ),
          backgroundColor: isOffline
              ? Colors.orange
              : paymentResult['success']
                  ? Colors.green
                  : Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur lors du paiement: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveTransactionToFirestore({
    required bool success,
    required String? transactionId,
    required bool isOffline,
  }) async {
    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;

      final transactionData = {
        'user_id': userId,
        'provider': _selectedOption,
        'amount': _totalAmount,
        'phone': _phone,
        'status': success ? 'completed' : 'failed',
        'transaction_id': transactionId,
        'created_at': FieldValue.serverTimestamp(),
        'isSynced': !isOffline,
      };

      await FirebaseFirestore.instance.collection('transactions').add(transactionData);

      if (success && !isOffline) {
        await ServiceNotifications.sendNotification(
          userId: userId,
          titre: "Paiement réussi",
          corps: "Votre paiement de $_totalAmount GNF via $_selectedOption a été effectué avec succès.",
          type: "transaction",
        );
      } else if (success && isOffline) {
        await FirebaseFirestore.instance.collection('pending_notifications').add({
          'type': 'transaction',
          'userId': userId,
          'titre': "Paiement réussi",
          'corps': "Votre paiement de $_totalAmount GNF via $_selectedOption a été effectué avec succès.",
          'timestamp': Timestamp.now(),
        });
      }
    } catch (e) {
      print("Erreur lors de l'enregistrement de la transaction: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur lors de l'enregistrement: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    final double textScaleFactor = MediaQuery.of(context).textScaleFactor;
    final double baseFontSize = screenWidth < 360 ? 14 : 16;
    final double basePadding = screenWidth * 0.04;
    final double imageHeight = screenHeight * 0.15;

    return Scaffold(
      backgroundColor: Colors.green[100],
      appBar: AppBar(
        title: Text(
          'Paiement',
          style: GoogleFonts.lato(
            fontSize: baseFontSize * 1.1 * textScaleFactor,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.receipt_long,
              size: baseFontSize * 1.5,
              color: Colors.white,
            ),
            tooltip: "Rapport Transactions",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => RapportTransactionPage()),
              );
            },
          ),
        ],
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.green[700],
      ),
      body: SafeArea(
        child: Consumer<ConnectivityService>(
          builder: (context, connectivityService, child) {
            final bool isOffline = connectivityService.isOffline;
            return SingleChildScrollView(
              padding: EdgeInsets.all(basePadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isOffline)
                    Padding(
                      padding: EdgeInsets.all(basePadding),
                      child: Text(
                        'Hors ligne - Données enregistrées localement',
                        style: GoogleFonts.lato(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                          fontSize: baseFontSize * 0.9 * textScaleFactor,
                        ),
                      ),
                    ),
                  Center(
                    child: Image.asset(
                      'assets/payment_banner.png',
                      height: imageHeight,
                      fit: BoxFit.contain,
                    ),
                  ),
                  SizedBox(height: basePadding * 2),
                  Center(
                    child: Text(
                      'Montant total: $_totalAmount GNF',
                      style: GoogleFonts.lato(
                        fontSize: baseFontSize * 1.2 * textScaleFactor,
                        fontWeight: FontWeight.bold,
                        color: Colors.brown,
                      ),
                    ),
                  ),
                  SizedBox(height: basePadding * 2),
                  Text(
                    'Quel moyen de paiement ?',
                    style: GoogleFonts.lato(
                      fontSize: baseFontSize * 0.9 * textScaleFactor,
                      fontWeight: FontWeight.bold,
                      color: Colors.brown,
                    ),
                  ),
                  SizedBox(height: basePadding * 2),
                  _PaymentOption(
                    icon: 'assets/orange_money.png',
                    title: 'Orange Money',
                    isSelected: _selectedOption == 'orange_money',
                    onTap: () => setState(() => _selectedOption = 'orange_money'),
                    baseFontSize: baseFontSize,
                    textScaleFactor: textScaleFactor,
                    basePadding: basePadding,
                  ),
                  SizedBox(height: basePadding),
                  _PaymentOption(
                    icon: 'assets/mobile_money.png',
                    title: 'MTN Mobile Money',
                    isSelected: _selectedOption == 'mobile_money',
                    onTap: () => setState(() => _selectedOption = 'mobile_money'),
                    baseFontSize: baseFontSize,
                    textScaleFactor: textScaleFactor,
                    basePadding: basePadding,
                  ),
                  if (_selectedOption != null) ...[
                    SizedBox(height: basePadding * 3),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Numéro de téléphone',
                        prefixText: '+224 ',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        prefixIcon: Icon(Icons.phone, color: Colors.green, size: baseFontSize * 1.2),
                        labelStyle: GoogleFonts.lato(fontSize: baseFontSize * 0.8 * textScaleFactor),
                        filled: true,
                        fillColor: Colors.green[50],
                      ),
                      style: GoogleFonts.lato(fontSize: baseFontSize * 0.8 * textScaleFactor),
                      keyboardType: TextInputType.phone,
                      onChanged: (value) => _phone = '+224$value',
                    ),
                    SizedBox(height: basePadding * 1.5),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Code secret',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        prefixIcon: Icon(Icons.lock, color: Colors.brown, size: baseFontSize * 1.2),
                        labelStyle: GoogleFonts.lato(fontSize: baseFontSize * 0.8 * textScaleFactor),
                        filled: true,
                        fillColor: Colors.green[50],
                      ),
                      style: GoogleFonts.lato(fontSize: baseFontSize * 0.8 * textScaleFactor),
                      obscureText: true,
                      onChanged: (value) => _password = value,
                    ),
                    SizedBox(height: basePadding * 2),
                    SizedBox(
                      width: double.infinity,
                      height: baseFontSize * 3,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : () => _processPayment(isOffline),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[600],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: _isLoading
                            ? CircularProgressIndicator(color: Colors.white)
                            : Text(
                                'Confirmer le paiement',
                                style: GoogleFonts.lato(
                                  fontSize: baseFontSize * 0.8 * textScaleFactor,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                  SizedBox(height: basePadding * 2),
                  SizedBox(
                    width: double.infinity,
                    height: baseFontSize * 3,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.red[700],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'Annuler',
                        style: GoogleFonts.lato(
                          fontSize: baseFontSize * 0.8 * textScaleFactor,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PaymentOption extends StatelessWidget {
  final String icon;
  final String title;
  final bool isSelected;
  final VoidCallback onTap;
  final double baseFontSize;
  final double textScaleFactor;
  final double basePadding;

  const _PaymentOption({
    required this.icon,
    required this.title,
    required this.isSelected,
    required this.onTap,
    required this.baseFontSize,
    required this.textScaleFactor,
    required this.basePadding,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: basePadding * 1.5, horizontal: basePadding),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green[100] : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? Colors.green : Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Image.asset(
              icon,
              width: baseFontSize * 2.5,
              height: baseFontSize * 2.5,
            ),
            SizedBox(width: basePadding),
            Text(
              title,
              style: GoogleFonts.lato(
                fontSize: baseFontSize * 0.8 * textScaleFactor,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            Spacer(),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: Colors.green,
                size: baseFontSize * 1.2,
              ),
          ],
        ),
      ),
    );
  }
}