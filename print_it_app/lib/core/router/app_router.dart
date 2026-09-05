import 'package:go_router/go_router.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/orders/order_tracking_screen.dart';
import '../../features/orders/upload_document_screen.dart';
import '../../features/orders/document_config_screen.dart';
import '../../features/orders/secure_payment_screen.dart';
import '../../features/orders/schedule_pickup_screen.dart';
import '../../features/orders/express_pickup_screen.dart';
import '../../features/orders/order_success_screen.dart';
import '../../features/orders/order_history_screen.dart';
import '../../features/orders/payment_failed_screen.dart';
import '../../features/home/profile_screen.dart';
import '../../features/home/edit_profile_screen.dart';
import '../../features/wallet/wallet_screen.dart';
import '../../features/wallet/wallet_success_screen.dart';
import '../../features/wallet/wallet_failed_screen.dart';
import '../../features/orders/select_shop_screen.dart';
import '../../features/notifications/notifications_screen.dart';
import '../../features/support/help_support_screen.dart';
import '../../features/shops/browse_categories_screen.dart';
import '../../features/shops/shop_list_screen.dart';
import '../../features/shops/shop_detail_screen.dart';
import '../../features/shops/manage_shop_services_screen.dart';
import '../../features/shops/express_dashboard_screen.dart';
import '../../features/marketplace/browse_manuals_screen.dart';
import '../../features/marketplace/product_detail_screen.dart';
import '../../features/marketplace/post_order_screen.dart';

import '../../features/support/my_tickets_screen.dart';
import '../../features/support/create_ticket_screen.dart';
import '../../features/support/ticket_detail_screen.dart';
import '../../features/navigation/not_found_screen.dart';
import '../../features/legal/privacy_policy_screen.dart';
import '../../features/legal/terms_screen.dart';
import '../../features/legal/refund_policy_screen.dart';
import '../../features/legal/security_policy_screen.dart';
import '../../features/legal/accessibility_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/login',
  errorBuilder: (context, state) => NotFoundScreen(uri: state.uri.toString()),
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

    // In-Store QR Code Scan Routes - Auto Locks Vendor Shop & Opens Upload
    GoRoute(
      path: '/upload-document/:shopId',
      builder: (context, state) {
        final shopId = state.pathParameters['shopId']!;
        return UploadDocumentScreen(shopId: shopId);
      },
    ),
    GoRoute(
      path: '/shop/:shopId',
      builder: (context, state) {
        final shopId = state.pathParameters['shopId']!;
        return UploadDocumentScreen(shopId: shopId);
      },
    ),
    GoRoute(
      path: '/qr/:shopId',
      builder: (context, state) {
        final shopId = state.pathParameters['shopId']!;
        return UploadDocumentScreen(shopId: shopId);
      },
    ),
    GoRoute(
      path: '/scan/:shopId',
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
      path: '/schedule-pickup',
      builder: (context, state) => const SchedulePickupScreen(),
    ),
    GoRoute(
      path: '/express-pickup',
      builder: (context, state) => const ExpressPickupScreen(),
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
      path: '/edit-profile',
      builder: (context, state) => const EditProfileScreen(),
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
    GoRoute(
      path: '/help',
      builder: (context, state) => const HelpSupportScreen(),
    ),
    GoRoute(
      path: '/browse-categories',
      builder: (context, state) => const BrowseCategoriesScreen(),
    ),
    GoRoute(
      path: '/shop-list/:capability',
      builder: (context, state) {
        final capability = state.pathParameters['capability']!;
        final name = state.uri.queryParameters['name'] ?? capability;
        return ShopListScreen(capability: capability, capabilityName: name);
      },
    ),
    GoRoute(
      path: '/shop-detail/:shopId',
      builder: (context, state) {
        final shopId = state.pathParameters['shopId']!;
        return ShopDetailScreen(shopId: shopId);
      },
    ),
    GoRoute(
      path: '/manage-services',
      builder: (context, state) => const ManageShopServicesScreen(),
    ),
    GoRoute(
      path: '/express-dashboard',
      builder: (context, state) => const ExpressDashboardScreen(),
    ),
    GoRoute(
      path: '/browse-manuals',
      builder: (context, state) => const BrowseManualsScreen(),
    ),
    GoRoute(
      path: '/manual-detail',
      builder: (context, state) {
        final item = state.extra as Map<String, dynamic>? ?? {};
        return ProductDetailScreen(manual: item);
      },
    ),
    GoRoute(
      path: '/post-order',
      builder: (context, state) {
        final order = state.extra as Map<String, dynamic>? ?? {};
        return PostOrderScreen(order: order);
      },
    ),
    GoRoute(
      path: '/my-tickets',
      builder: (context, state) => const MyTicketsScreen(),
    ),
    GoRoute(
      path: '/create-ticket',
      builder: (context, state) => const CreateTicketScreen(),
    ),
    GoRoute(
      path: '/ticket/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return TicketDetailScreen(ticketId: id);
      },
    ),
    GoRoute(
      path: '/privacy',
      builder: (context, state) => const PrivacyPolicyScreen(),
    ),
    GoRoute(
      path: '/terms',
      builder: (context, state) => const TermsScreen(),
    ),
    GoRoute(
      path: '/refund-policy',
      builder: (context, state) => const RefundPolicyScreen(),
    ),
    GoRoute(
      path: '/security',
      builder: (context, state) => const SecurityPolicyScreen(),
    ),
    GoRoute(
      path: '/accessibility',
      builder: (context, state) => const AccessibilityScreen(),
    ),
    GoRoute(
      path: '/not-found',
      builder: (context, state) => const NotFoundScreen(),
    ),
  ],
);
