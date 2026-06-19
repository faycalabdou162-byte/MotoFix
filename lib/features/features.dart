/// Feature-based architecture — canonical exports during migration.
library;

// Auth (Clean Architecture)
export 'auth/presentation/auth_gate.dart';
export 'auth/presentation/providers/auth_providers.dart';
export 'auth/domain/repositories/auth_repository.dart';
export 'auth/presentation/onboarding_page.dart';

// Request (Clean Architecture)
export 'request/presentation/providers/request_providers.dart';
export 'request/domain/repositories/request_repository.dart';

// Home
export '../pages/home/dashboard_page.dart';
export '../pages/home/history_page.dart';

// Tracking
export '../pages/home/map_page.dart';
export 'map/presentation/live_tracking_page.dart';

// Request UI (legacy pages — migrate incrementally)
export '../pages/request/request_page.dart';
export '../pages/services/depannage_page.dart';
export '../pages/services/taxi_page.dart';
export '../pages/services/services_page.dart';

// Payment
export '../pages/payment_page.dart';
export 'payment/presentation/receipt_page.dart';

// Profile & settings
export '../pages/profile/profile_page.dart';
export '../pages/profile/settings_page.dart';
export '../pages/profile/personal_info_page.dart';

// Notifications
export '../pages/notifications_page.dart';

// Chat
export '../pages/chat/chat_page.dart';

// Driver / mechanic
export '../pages/driver/driver_dashboard_page.dart';
export '../pages/driver/driver_revenue_page.dart';

// Admin
export '../pages/admin/admin_page.dart';
export '../pages/admin/admin_guard.dart';
export '../pages/admin/users_admin_page.dart';
export '../pages/admin/drivers_admin_page.dart';
export '../pages/admin/requests_admin_page.dart';

// Auth pages (legacy paths)
export '../pages/auth/login_page.dart';
export '../pages/auth/register_page.dart';
export '../pages/auth/admin_login.dart';

// Stubs — Phase 2 placeholders (implement in later phases)
// rewards, wallet: not yet implemented
