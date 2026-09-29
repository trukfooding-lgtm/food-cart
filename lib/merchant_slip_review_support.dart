import 'api.config.dart';

bool merchantOrderHasSlipEvidence(Map<String, dynamic> order) {
  final value = order['has_payment_slip'];
  if (value == true || value?.toString().toLowerCase() == 'true') return true;
  return (order['latest_slip_status']?.toString().trim().isNotEmpty ?? false) ||
      (order['latest_slip_created_at']?.toString().trim().isNotEmpty ?? false);
}

String resolveMerchantSlipImageUrl(String rawUrl) {
  final value = rawUrl.trim();
  if (value.isEmpty) return '';
  final uri = Uri.tryParse(value);
  if (uri != null && uri.hasScheme) {
    return uri.scheme == 'http' && uri.host.endsWith('.onrender.com')
        ? uri.replace(scheme: 'https').toString()
        : value;
  }
  return Uri.parse(ApiConfig.baseUrl).resolve(value).toString();
}
