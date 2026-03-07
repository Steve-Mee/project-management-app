import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Stripe webhook function uses real signature verification logic', () async {
    final file = File('supabase/functions/stripe_webhook/index.ts');
    expect(file.existsSync(), isTrue);

    final content = await file.readAsString();

    expect(content.contains('return true'), isFalse,
        reason: 'Webhook verifier must not use placeholder always-true logic.');
    expect(content.contains('computeHmacSha256Hex('), isTrue);
    expect(content.contains('timingSafeEqual('), isTrue);
    expect(content.contains('parseStripeSignatureHeader('), isTrue);
    expect(content.contains('STRIPE_WEBHOOK_SECRET'), isTrue);
  });
}
