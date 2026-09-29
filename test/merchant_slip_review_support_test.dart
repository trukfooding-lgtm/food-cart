import 'package:flutter_test/flutter_test.dart';
import 'package:food_cart_app/api.config.dart';
import 'package:food_cart_app/merchant_slip_review_support.dart';

void main() {
  group('merchantOrderHasSlipEvidence', () {
    test('recognizes the backend boolean for a newly attached slip', () {
      expect(merchantOrderHasSlipEvidence({'has_payment_slip': true}), isTrue);
      expect(
        merchantOrderHasSlipEvidence({'has_payment_slip': 'true'}),
        isTrue,
      );
    });

    test('recognizes slip rows when the boolean is absent', () {
      expect(
        merchantOrderHasSlipEvidence({'latest_slip_status': 'REJECTED'}),
        isTrue,
      );
      expect(
        merchantOrderHasSlipEvidence({'latest_slip_created_at': '2026-09-29'}),
        isTrue,
      );
    });

    test('returns false when an order has no slip', () {
      expect(
        merchantOrderHasSlipEvidence({'has_payment_slip': false}),
        isFalse,
      );
      expect(merchantOrderHasSlipEvidence({}), isFalse);
    });
  });

  group('resolveMerchantSlipImageUrl', () {
    test('keeps a signed URL with its token intact', () {
      const url = 'https://storage.example/object/sign/proof.png?token=abc';
      expect(resolveMerchantSlipImageUrl(url), url);
    });

    test('upgrades Render image URLs to HTTPS', () {
      expect(
        resolveMerchantSlipImageUrl('http://food-cart.onrender.com/proof.png'),
        'https://food-cart.onrender.com/proof.png',
      );
    });

    test('resolves relative paths against the API host', () {
      expect(
        resolveMerchantSlipImageUrl('/uploads/proof.png'),
        '${ApiConfig.baseUrl}/uploads/proof.png',
      );
    });
  });
}
