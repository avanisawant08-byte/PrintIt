import 'package:go_router/go_router.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/orders/order_tracking_screen.dart';
import '../../features/orders/upload_document_screen.dart';
import '../../features/orders/document_config_screen.dart';
import '../../features/orders/secure_payment_screen.dart';
import '../../features/orders/order_success_screen.dart';
import '../../features/orders/order_history_screen.dart';
import '../../features/orders/payment_failed_screen.dart';
import '../../features/home/profile_screen.dart';
import '../../features/wallet/wallet_screen.dart';
import '../../features/wallet/wallet_success_screen.dart';
import '../../features/wallet/wallet_failed_screen.dart';
import '../../features/orders/select_shop_screen.dart';
import '../../features/notifications/notifications_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationsScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/upload-document/:shopId',
      builder: (context, state) {
        final shopId = state.pathParameters['shopId']!;
        return UploadDocumentScreen(shopId: shopId);
      },
    ),
    GoRoute(
      path: '/quick-upload',
      builder: (context, state) => const UploadDocumentScreen(shopId: null),
    ),
    GoRoute(
      path: '/select-shop',
      builder: (context, state) => const SelectShopScreen(),
    ),
    GoRoute(
      path: '/document-config',
      builder: (context, state) => const DocumentConfigScreen(),
    ),
    GoRoute(
      path: '/payment',
      builder: (context, state) => const SecurePaymentScreen(),
    ),
    GoRoute(
      path: '/order-success',
      builder: (context, state) {
        final orderId = state.uri.queryParameters['orderId'] ?? '';
        return OrderSuccessScreen(orderId: orderId);
      },
    ),
    GoRoute(
      path: '/payment-failed',
      builder: (context, state) {
        final error = state.uri.queryParameters['error'];
        return PaymentFailedScreen(errorMessage: error);
      },
    ),
    GoRoute(
      path: '/order-tracking/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return OrderTrackingScreen(orderId: id);
      },
    ),
    GoRoute(
      path: '/orders',
      builder: (context, state) => const OrderHistoryScreen(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/wallet',
      builder: (context, state) => const WalletScreen(),
    ),
    GoRoute(
      path: '/wallet-success',
      builder: (context, state) {
        final amount = state.uri.queryParameters['amount'] ?? '0';
        return WalletSuccessScreen(amount: amount);
      },
    ),
    GoRoute(
      path: '/wallet-failed',
      builder: (context, state) {
        final error = state.uri.queryParameters['error'];
        return WalletFailedScreen(errorMessage: error);
      },
    ),
  ],
);
