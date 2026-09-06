import 'package:flutter/material.dart';

import '../../app_router.dart';
import '../../core/services/booking_service.dart';
import '../../core/services/local_notification_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/primary_button.dart';
import '../../models/event.dart';

class PaymentPageArgs {
  final Event event;
  final String? bookingId;
  final int personCount;

  const PaymentPageArgs({
    required this.event,
    this.bookingId,
    this.personCount = 1,
  });
}

class PaymentPage extends StatefulWidget {
  final Event event;
  final String? bookingId;
  final int personCount;
  const PaymentPage({
    super.key,
    required this.event,
    this.bookingId,
    this.personCount = 1,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  int method = 0; // 0: MasterCard, 1: Paypal
  final cardCtrl = TextEditingController(text: '2234 8678 1236 1236');
  final nameCtrl = TextEditingController(text: 'Harry');
  final expCtrl = TextEditingController(text: '12/25');
  final cvvCtrl = TextEditingController(text: '720');
  bool _isSubmitting = false;

  @override
  void dispose() {
    cardCtrl.dispose();
    nameCtrl.dispose();
    expCtrl.dispose();
    cvvCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.event;
    final personCount = widget.personCount <= 0 ? 1 : widget.personCount;
    final ticketFee = e.priceBaht * personCount;
    final discount = ticketFee * 0.1;
    const tax = 10.0;
    final total = ticketFee - discount + tax;

    return Scaffold(
      appBar: AppBar(title: const Text('Review Booking')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        children: [
          _eventTile(e),
          const SizedBox(height: 12),
          const Text('Detail', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          _kv('Ticket Fee (x$personCount)', ticketFee.toStringAsFixed(2)),
          _kv('Discount', '- ${discount.toStringAsFixed(2)}'),
          _kv('Tax 10%', tax.toStringAsFixed(2)),
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
            label: _isSubmitting ? 'Processing...' : 'Pay Now',
            onPressed: _isSubmitting ? null : _handlePayNow,
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
    final isSelected = method == index;
    return InkWell(
      onTap: () => setState(() => method = index),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color:
                      isSelected ? AppColors.primary : const Color(0xFFD1D5DB),
                  width: 2,
                ),
                color: isSelected ? AppColors.primary : Colors.transparent,
              ),
              child: isSelected
                  ? const Center(
                      child: Icon(Icons.check, size: 14, color: Colors.white),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
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
            e.primaryImage,
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

  Future<void> _handlePayNow() async {
    final event = widget.event;
    final personCount = widget.personCount <= 0 ? 1 : widget.personCount;

    setState(() => _isSubmitting = true);

    try {
      // Create booking and get bookingId
      final booking = await BookingService.createBooking(
        eventId: event.id,
        ticketCounts: personCount,
      );
      final bookingId = booking.id ?? widget.bookingId;

      // Confirm the booking if bookingId is available
      if (bookingId != null) {
        try {
          await BookingService.confirmBooking(bookingId);
        } catch (e) {
          print('❌ Booking confirmation error: $e');
        }
      }

      // Trigger local notification with sound and vibration
      print('📢 Triggering notification for: ${event.title}');
      try {
        await LocalNotificationService.showBookingNotification(
          bookingId: event.id,
          eventTitle: event.title,
          ticketCount: personCount,
          totalPrice: (event.priceBaht * personCount).toDouble(),
        );
        print('✅ Notification triggered successfully');
      } catch (notifError) {
        print('❌ Notification error: $notifError');
      }

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      await _showResultDialog(
        isSuccess: true,
        title: 'Booking Success',
        message: 'Your payment has been successfully processed.',
      );

      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.appShell, (r) => false,
          arguments: 0);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);

      await _showResultDialog(
        isSuccess: false,
        title: 'Payment Failed',
        message: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> _showResultDialog({
    required bool isSuccess,
    required String title,
    required String message,
  }) async {
    if (!mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const SizedBox(height: 6),
            Icon(
              isSuccess ? Icons.check_circle : Icons.error_outline,
              size: 72,
              color: isSuccess ? Colors.blue : Colors.red,
            ),
            const SizedBox(height: 14),
            Text(title,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
