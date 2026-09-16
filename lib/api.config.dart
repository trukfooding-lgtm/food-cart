class ApiConfig {
  // สำหรับรันบน Android Emulator (10.0.2.2 ชี้ไปยัง localhost ของเครื่อง Mac/PC)
  static const String baseUrl = 'https://food-cart-c20i.onrender.com';

  // รายการ API ลูกค้า
  static const String login = '$baseUrl/api/customers/login';
  static const String register = '$baseUrl/api/customers/register';
  static const String sendOtp = '$baseUrl/api/otp/send';
  static const String verifyOtp = '$baseUrl/api/otp/verify';
  static const String resetPassword = '$baseUrl/api/customers/reset-password';
  static const String uploadCustomerImage = '$baseUrl/api/customers/upload-image';

  // รายการ API ร้านค้า (ของเพื่อน)
  static const String merchantLogin = '$baseUrl/api/merchants/login';
  static String merchantProfile(Object merchantId) => '$baseUrl/api/merchants/$merchantId';
  static String merchantPassword(Object merchantId) => '$baseUrl/api/merchants/$merchantId/password';
  static String merchantFollowers(Object merchantId) => '$baseUrl/api/merchants/$merchantId/followers';
  static String merchantHours(Object merchantId) => '$baseUrl/api/merchants/$merchantId/hours';
  static String merchantPrepTime(Object merchantId) => '$baseUrl/api/merchants/$merchantId/prep-time';
  static String merchantStatus(Object merchantId) => '$baseUrl/api/merchants/$merchantId/status';
  static String merchantPreferences(Object merchantId) => '$baseUrl/api/merchants/$merchantId/preferences';
  static String merchantLoyaltySettings(Object merchantId) => '$baseUrl/api/merchants/$merchantId/loyalty-settings';
  static String merchantReviews(Object merchantId) => '$baseUrl/api/merchants/$merchantId/reviews';
  static String merchantMenus(Object merchantId) => '$baseUrl/api/merchants/$merchantId/menus';
  static String merchantNotifications(Object merchantId) => '$baseUrl/api/merchants/$merchantId/notifications';
  static String merchantFcmToken(Object merchantId) => '$baseUrl/api/merchants/$merchantId/fcm-token';
  static String merchantIssueReports(Object merchantId) => '$baseUrl/api/merchants/$merchantId/issue-reports';
  static String merchantOrders(Object merchantId) => '$baseUrl/api/merchants/$merchantId/orders';
  static String merchantOrderStatus(Object merchantId, Object orderId) => '$baseUrl/api/merchants/$merchantId/orders/$orderId/status';
  static String merchantSalesSummary(Object merchantId) => '$baseUrl/api/merchants/$merchantId/sales-summary';
  static String merchantBankAccounts(Object merchantId) => '$baseUrl/api/merchants/$merchantId/bank-accounts';
  static String merchantPrimaryBankAccount(Object merchantId, Object accountId) => '$baseUrl/api/merchants/$merchantId/bank-accounts/$accountId/primary';
  static String merchantBankAccount(Object merchantId, Object accountId) => '$baseUrl/api/merchants/$merchantId/bank-accounts/$accountId';

  // รายการ API ออเดอร์และร้านค้าทั่วไป
  static const String getFoodTrucks = '$baseUrl/api/merchants/trucks';
  static const String createOrder = '$baseUrl/api/orders/create';
  static const String getOrderHistory = '$baseUrl/api/orders/history';

  // 🟢 รายการ API แจ้งเตือน (เพิ่มใหม่)
  static const String saveFcmToken = '$baseUrl/api/orders/fcm-token';
  static const String getNotifications = '$baseUrl/api/orders/notifications';
}
