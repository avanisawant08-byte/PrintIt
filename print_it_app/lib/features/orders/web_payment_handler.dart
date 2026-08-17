import 'package:razorpay_flutter/razorpay_flutter.dart';

void handleWebPayment({
  required Map<String, dynamic> options,
  required Function(PaymentSuccessResponse) onSuccess,
  required Function(PaymentFailureResponse) onError,
}) {
  throw UnsupportedError('Web payment is only supported on the web platform');
}
