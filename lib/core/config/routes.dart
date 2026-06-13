import 'package:flutter/material.dart';

import '../../pages/admin/admin_guard.dart';
import '../../pages/admin/drivers_admin_page.dart';
import '../../pages/admin/requests_admin_page.dart';
import '../../pages/admin/users_admin_page.dart';
import '../../pages/auth/admin_login.dart';
import '../../pages/auth/login_page.dart';
import '../../pages/auth/register_page.dart';
import '../../pages/driver/driver_dashboard_page.dart';
import '../../pages/home/dashboard_page.dart';
import '../../pages/home/history_page.dart';
import '../../pages/home/map_page.dart';
import '../../pages/payment_page.dart';
import '../../pages/profile/addresses_page.dart';
import '../../pages/profile/personal_info_page.dart';
import '../../pages/profile/security_page.dart';
import '../../pages/profile/settings_page.dart';
import '../../pages/profile/support_page.dart';
import '../../pages/request/request_page.dart';
import '../../pages/services/depannage_page.dart';
import '../../pages/services/services_page.dart';
import '../../pages/services/taxi_page.dart';

class AppRoutes {
  static Map<String, WidgetBuilder> routes = {
    '/login': (_) => const LoginPage(),
    '/register': (_) => const RegisterPage(),
    '/admin-login': (_) => const AdminLogin(),
    '/home': (_) => const DashboardPage(),
    '/driver': (_) => const DriverDashboardPage(),
    '/history': (_) => const HistoryPage(),
    '/map': (_) => const MapPage(),
    '/request': (_) => const RequestPage(),
    '/services': (_) => const ServicesPage(),
    '/taxi': (_) => const TaxiPage(),
    '/depannage': (_) => const DepannagePage(),
    '/profile-info': (_) => const PersonalInfoPage(),
    '/payments': (_) => const PaymentPage(),
    '/addresses': (_) => const AddressesPage(),
    '/settings': (_) => const SettingsPage(),
    '/security': (_) => const SecurityPage(),
    '/support': (_) => const SupportPage(),
    '/admin': (_) => const AdminGuard(),
    '/admin-requests': (_) => const RequestsAdminPage(),
    '/admin-drivers': (_) => const DriversAdminPage(),
    '/admin-users': (_) => const UsersAdminPage(),
  };
}
