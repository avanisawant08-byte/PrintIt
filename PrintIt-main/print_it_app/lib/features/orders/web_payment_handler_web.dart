// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use, undefined_function, undefined_method

import 'dart:js' as js;
import 'package:razorpay_flutter/razorpay_flutter.dart';

void handleWebPayment({
  required Map<String, dynamic> options,
  required Function(PaymentSuccessResponse) onSuccess,
  required Function(PaymentFailureResponse) onError,
}) {
  options['handler'] = js.allowInterop((response) {
    onSuccess(PaymentSuccessResponse.fromMap({
      'razorpay_order_id': response['razorpay_order_id'],
      'razorpay_payment_id': response['razorpay_payment_id'],
      'razorpay_signature': response['razorpay_signature']
    }));
  });

  try {
    var rzp = js.context.callMethod('Razorpay', [js.JsObject.jsify(options)]);
    rzp.callMethod('on', ['payment.failed', js.allowInterop((response) {
      onError(PaymentFailureResponse.fromMap({
        'code': 0,
        'message': response['error']['description']
      }));
    })]);
    rzp.callMethod('open');
  } catch (e) {
    onError(PaymentFailureResponse.fromMap({
      'code': 1,
      'message': 'Failed to initialize Razorpay Web checkout: $e'
    }));
  }
}
