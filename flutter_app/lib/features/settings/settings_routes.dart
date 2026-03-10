import 'package:go_router/go_router.dart';
import 'settings_screen.dart';
import 'screens/appearance_screen.dart';
import 'screens/close_friends_screen.dart';
import 'screens/muted_accounts_screen.dart';
import 'screens/dm_control_screen.dart';
import 'screens/comments_control_screen.dart';
import 'screens/delete_account_screen.dart';
import 'screens/privacy_settings_screen.dart';
import 'screens/blocked_accounts_screen.dart';
import 'screens/report_problem_screen.dart';
import 'screens/moderation_info_screen.dart';
import 'search/close_friends_search_screen.dart';
import 'search/mute_search_screen.dart';
import 'screens/notifications_settings_screen.dart';
import 'screens/blocked_list_screen.dart';

final List<GoRoute> settingsRoutes = [
  GoRoute(
    path: '/settings',
    builder: (c, s) => const SettingsScreen(),
    routes: [
      GoRoute(path: 'appearance', builder: (c, s) => const AppearanceScreen()),
      GoRoute(path: 'privacy', builder: (c, s) => const PrivacySettingsScreen()),
      GoRoute(path: 'blocked', builder: (c, s) => const BlockedAccountsScreen()),
      GoRoute(path: 'report', builder: (c, s) => const ReportProblemScreen()),
      GoRoute(path: 'close-friends', builder: (c, s) => const CloseFriendsScreen()),
      GoRoute(path: 'muted', builder: (c, s) => const MutedAccountsScreen()),
      GoRoute(path: 'dm', builder: (c, s) => const DMControlScreen()),
      GoRoute(path: 'comments', builder: (c, s) => const CommentsControlScreen()),
      GoRoute(path: 'delete-account', builder: (c, s) => const DeleteAccountScreen()),
      GoRoute(path: 'moderation-info', builder: (c, s) => const ModerationInfoScreen()),
      GoRoute(
        path: 'notifications',
        builder: (c, s) => const NotificationsSettingsScreen(),
      ),
      GoRoute(
        path: 'blocked-list',
        builder: (c, s) => const BlockedListScreen(),
      ),
      GoRoute(
        path: 'close-friends/search',
        builder: (c, s) => const CloseFriendsSearchScreen(),
      ),
      GoRoute(
        path: 'muted/search',
        builder: (c, s) => const MuteSearchScreen(),
      ),
    ],
  ),
];
