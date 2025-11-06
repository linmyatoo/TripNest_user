import 'package:flutter/material.dart';

import '../../app_router.dart';
import '../../core/widgets/primary_button.dart';
import '../../models/event.dart';

class PaymentPage extends StatefulWidget {
  final Event event;
  const PaymentPage({super.key, required this.event});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  int method = 0; // 0: MasterCard, 1: Paypal
  final cardCtrl = TextEditingController(text: '2234 8678 1236 1236');
  final nameCtrl = TextEditingController(text: 'Harry');
  final expCtrl = TextEditingController(text: '12/25');
  final cvvCtrl = TextEditingController(text: '720');

  @override
  Widget build(BuildContext context) {
    final e = widget.event;
    final discount = (e.priceBaht * 0.1).round();
    final tax = 10;
    final total = e.priceBaht - discount + tax;

    return Scaffold(
      appBar: AppBar(title: const Text('Review Booking')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        children: [
          _eventTile(e),
          const SizedBox(height: 12),
          const Text('Detail', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          _kv('Ticket Fee', e.priceBaht.toStringAsFixed(2)),
          _kv('Discount', '- $discount.00'),
          _kv('Tax 10%', '10.00'),
          const Divider(height: 24),
          _kv('Total', '฿ ${total.toStringAsFixed(2)}', bold: true),
          const SizedBox(height: 18),
          const Text('Select Payment',
              style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          _radio(0, 'Master Card'),
          _radio(1, 'Paypal'),
          const SizedBox(height: 12),
          const Text('Card Number'),
          const SizedBox(height: 6),
          TextField(controller: cardCtrl),
          const SizedBox(height: 12),
          const Text('Card Holder Name'),
          const SizedBox(height: 6),
          TextField(controller: nameCtrl),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  const Text('Expired'),
                  const SizedBox(height: 6),
                  TextField(controller: expCtrl),
                ])),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  const Text('CVV Code'),
                  const SizedBox(height: 6),
                  TextField(controller: cvvCtrl),
                ])),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Checkbox(value: true, onChanged: (_) {}),
            const Expanded(
                child: Text(
                    'By clicking, you agree to the rules, policies, and payment responsibility.')),
          ]),
          const SizedBox(height: 12),
          PrimaryButton(
            label: 'Pay Now',
            onPressed: () async {
              await _showSuccess(context);
              // reset stack to Home tab
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil(
                    AppRoutes.appShell, (r) => false,
                    arguments: 0);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _kv(String k, String v, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(k)),
          Text(v,
              style: TextStyle(
                  fontWeight: bold ? FontWeight.w800 : FontWeight.w400)),
        ],
      ),
    );
  }

  Widget _radio(int index, String label) {
    return InkWell(
      onTap: () => setState(() => method = index),
      child: Row(children: [
        Radio<int>(
            value: index,
            groupValue: method,
            onChanged: (v) => setState(() => method = v!)),
        Text(label),
      ]),
    );
  }

  Widget _eventTile(Event e) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(
            e.imageUrl,
            width: 56,
            height: 56,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 56,
                height: 56,
                color: Colors.grey[300],
                child: const Icon(Icons.image_not_supported,
                    color: Colors.grey, size: 24),
              );
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                width: 56,
                height: 56,
                color: Colors.grey[200],
                child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2)),
              );
            },
          ),
        ),
        title:
            Text(e.title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text('${e.location}\n${e.priceBaht}B/Person'),
        isThreeLine: true,
      ),
    );
  }

  Future<void> _showSuccess(BuildContext context) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const SizedBox(height: 6),
            const Icon(Icons.check_circle, size: 72, color: Colors.blue),
            const SizedBox(height: 14),
            const Text('Booking Success!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            const Text(
                'Your payment has been successfully processed.\nYour booking is confirmed!',
                textAlign: TextAlign.center),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Go To Home'),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
