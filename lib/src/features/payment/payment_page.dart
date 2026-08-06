import 'package:flutter/material.dart';

import '../../app_router.dart';
import '../../core/services/booking_service.dart';
import '../../core/services/local_notification_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/app_log.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/remote_image.dart';
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

  // Fields start empty. They used to ship pre-filled with a fake PAN and CVV,
  // which trains users to submit without reading and hides the fact that the
  // values were never validated.
  final cardCtrl = TextEditingController();
  final nameCtrl = TextEditingController();
  final expCtrl = TextEditingController();
  final cvvCtrl = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;
  bool _consentGiven = false;

  @override
  void dispose() {
    cardCtrl.dispose();
    nameCtrl.dispose();
    expCtrl.dispose();
    cvvCtrl.dispose();
    super.dispose();
  }

  // ---- Validation -------------------------------------------------------
  //
  // NOTE: this screen does not talk to a payment processor — there is no PSP
  // endpoint in this app. It validates the card details client-side and then
  // creates/confirms the booking. Card data never leaves the device. Wire a
  // real PSP here before charging anyone.

  String? _validateCardNumber(String? value) {
    final digits = (value ?? '').replaceAll(RegExp(r'\s+'), '');
    if (digits.isEmpty) return 'Enter the card number';
    if (!RegExp(r'^\d{13,19}$').hasMatch(digits)) {
      return 'Card number must be 13–19 digits';
    }
    if (!_passesLuhn(digits)) return 'That card number is not valid';
    return null;
  }

  String? _validateHolderName(String? value) {
    final name = (value ?? '').trim();
    if (name.isEmpty) return 'Enter the card holder name';
    if (name.length < 2) return 'Enter the full name on the card';
    return null;
  }

  String? _validateExpiry(String? value) {
    final text = (value ?? '').trim();
    final match = RegExp(r'^(\d{2})\s*/\s*(\d{2})$').firstMatch(text);
    if (match == null) return 'Use MM/YY';

    final month = int.parse(match.group(1)!);
    final year = 2000 + int.parse(match.group(2)!);
    if (month < 1 || month > 12) return 'Month must be 01–12';

    // Valid through the last moment of the expiry month.
    final expiresAt = DateTime(year, month + 1);
    if (!expiresAt.isAfter(DateTime.now())) return 'That card has expired';
    return null;
  }

  String? _validateCvv(String? value) {
    final cvv = (value ?? '').trim();
    if (cvv.isEmpty) return 'Enter the CVV';
    if (!RegExp(r'^\d{3,4}$').hasMatch(cvv)) return 'CVV must be 3 or 4 digits';
    return null;
  }

  /// Standard Luhn checksum — catches typos and obviously fabricated numbers.
  static bool _passesLuhn(String digits) {
    var sum = 0;
    var alternate = false;
    for (var i = digits.length - 1; i >= 0; i--) {
      var digit = int.parse(digits[i]);
      if (alternate) {
        digit *= 2;
        if (digit > 9) digit -= 9;
      }
      sum += digit;
      alternate = !alternate;
    }
    return sum % 10 == 0;
  }

  /// Card details are only required for the card flow, not for Paypal.
  bool get _requiresCardDetails => method == 0;

  bool get _canSubmit => _consentGiven && !_isSubmitting;

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
      body: Form(
        key: _formKey,
        child: ListView(
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
            if (_requiresCardDetails) ...[
              const SizedBox(height: 12),
              const Text('Card Number'),
              const SizedBox(height: 6),
              TextFormField(
                controller: cardCtrl,
                keyboardType: TextInputType.number,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: _validateCardNumber,
                decoration: const InputDecoration(hintText: '#### #### #### ####'),
              ),
              const SizedBox(height: 12),
              const Text('Card Holder Name'),
              const SizedBox(height: 6),
              TextFormField(
                controller: nameCtrl,
                textCapitalization: TextCapitalization.words,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: _validateHolderName,
                decoration: const InputDecoration(hintText: 'Name on card'),
              ),
              const SizedBox(height: 12),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      const Text('Expired'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: expCtrl,
                        keyboardType: TextInputType.datetime,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        validator: _validateExpiry,
                        decoration: const InputDecoration(hintText: 'MM/YY'),
                      ),
                    ])),
                const SizedBox(width: 12),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      const Text('CVV Code'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: cvvCtrl,
                        keyboardType: TextInputType.number,
                        obscureText: true,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        validator: _validateCvv,
                        decoration: const InputDecoration(hintText: '123'),
                      ),
                    ])),
              ]),
            ],
            const SizedBox(height: 12),
            Row(children: [
              Checkbox(
                value: _consentGiven,
                onChanged: (value) =>
                    setState(() => _consentGiven = value ?? false),
              ),
              const Expanded(
                  child: Text(
                      'By clicking, you agree to the rules, policies, and payment responsibility.')),
            ]),
            const SizedBox(height: 12),
            PrimaryButton(
              label: _isSubmitting ? 'Processing...' : 'Pay Now',
              // Blocked until consent is actually ticked.
              onPressed: _canSubmit ? _handlePayNow : null,
            ),
            if (!_consentGiven)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Tick the box above to continue.',
                  style: TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ),
          ],
        ),
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
        leading: RemoteImage(
          url: e.primaryImage,
          width: 56,
          height: 56,
          borderRadius: BorderRadius.circular(10),
        ),
        title:
            Text(e.title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text('${e.location}\n${e.priceBaht}B/Person'),
        isThreeLine: true,
      ),
    );
  }

  Future<void> _handlePayNow() async {
    if (!_consentGiven) return;
    // Card fields are only part of the form when the card method is selected.
    if (_requiresCardDetails &&
        !(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final event = widget.event;
    final personCount = widget.personCount <= 0 ? 1 : widget.personCount;

    setState(() => _isSubmitting = true);

    try {
      // Reuse an existing booking when the caller already created one
      // (the payment route accepts a bookingId), otherwise create it now.
      final String bookingId;
      if (widget.bookingId != null && widget.bookingId!.isNotEmpty) {
        bookingId = widget.bookingId!;
      } else {
        // createBooking returns a non-nullable Booking; the old `booking?.id`
        // was a dead null-aware call.
        final booking = await BookingService.createBooking(
          eventId: event.id,
          ticketCounts: personCount,
        );
        bookingId = booking.id;
      }

      // A booking that cannot be confirmed is not a successful purchase, so
      // let the failure reach the catch block instead of swallowing it.
      await BookingService.confirmBooking(bookingId);

      // Trigger local notification with sound and vibration
      try {
        await LocalNotificationService.showBookingNotification(
          bookingId: event.id,
          eventTitle: event.title,
          ticketCount: personCount,
          totalPrice: (event.priceBaht * personCount).toDouble(),
        );
      } catch (notifError) {
        AppLog.e('Booking notification failed', notifError);
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
