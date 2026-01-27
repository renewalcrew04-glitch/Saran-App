import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:saran_app/models/post_model.dart';
import 'package:saran_app/models/space_event_model.dart'; // ✅ Added for Detail Screen
import 'package:saran_app/features/settings/settings_routes.dart';
import 'package:saran_app/screens/auth/login_screen.dart';
import 'package:saran_app/screens/auth/signup_screen.dart';

import 'package:saran_app/screens/messages/messages_screen.dart';
import 'package:saran_app/screens/notifications/notifications_screen.dart';

import 'package:saran_app/screens/post/create_post_screen.dart';
import 'package:saran_app/screens/post/post_detail_screen.dart';
import 'package:saran_app/screens/post/edit_post_screen.dart';

import 'package:saran_app/screens/profile/liked_posts_screen.dart';
import 'package:saran_app/features/sframe/screens/sframe_create_screen.dart';
import 'package:saran_app/features/sframe/screens/sframe_viewer_screen.dart';
import 'package:saran_app/widgets/main_navigation.dart';

// =========================
// GAMES
// =========================
import 'package:saran_app/screens/profile/games/games_home_screen.dart';
import 'package:saran_app/screens/profile/games/garden_screen.dart';
import 'package:saran_app/screens/profile/games/soundboard_screen.dart';
import 'package:saran_app/screens/profile/games/mirror_screen.dart';

// =========================
// WELLNESS
// =========================
import 'package:saran_app/screens/profile/wellness/wellness_home_screen.dart';
import 'package:saran_app/screens/profile/wellness/calm_corner_screen.dart';
import 'package:saran_app/screens/profile/wellness/breathing_screen.dart';
import 'package:saran_app/screens/profile/wellness/grounding_screen.dart';
import 'package:saran_app/screens/profile/wellness/eye_relax_screen.dart';
import 'package:saran_app/screens/profile/wellness/mind_journal_screen.dart';
import 'package:saran_app/screens/profile/wellness/s_cycle_screen.dart';
import 'package:saran_app/screens/profile/wellness/hydration_screen.dart';

// =========================
// EXPLORE
// =========================
import 'package:saran_app/screens/explore/hashtag_explore_screen.dart';

// =========================
// SPACE (✅ ADDED THESE IMPORTS)
// =========================
import 'package:saran_app/screens/space/create_event_screen.dart';
import 'package:saran_app/screens/space/my_events_screen.dart';
import 'package:saran_app/screens/space/event_details_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/login',
    debugLogDiagnostics: true,
    routes: [
      // =========================
      // AUTH
      // =========================
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),

      // =========================
      // MAIN APP NAVIGATION
      // =========================
      GoRoute(
        path: '/home',
        builder: (context, state) => const MainNavigation(),
      ),

      // =========================
      // SPACE ROUTES (✅ ADDED)
      // =========================
      GoRoute(
        path: '/space/create',
        builder: (context, state) => const CreateEventScreen(),
      ),
      GoRoute(
        path: '/space/my-events',
        builder: (context, state) => const MyEventsScreen(),
      ),
      GoRoute(
        path: '/space/details',
        builder: (context, state) {
          final extra = state.extra;
          if (extra is SpaceEvent) {
            return EventDetailsScreen(event: extra); // Assuming you have this screen
          }
          return const _RouterErrorScreen(message: "Event details missing");
        },
      ),

      // =========================
      // MESSAGES
      // =========================
      GoRoute(
        path: '/messages',
        builder: (context, state) => const MessagesScreen(),
      ),

      // =========================
      // NOTIFICATIONS
      // =========================
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),

      // =========================
      // LIKED POSTS
      // =========================
      GoRoute(
        path: '/liked-posts',
        builder: (context, state) => const LikedPostsScreen(),
      ),

      // =========================
      // GAMES
      // =========================
      GoRoute(
        path: '/games',
        builder: (context, state) => const GamesHomeScreen(),
      ),
      GoRoute(
        path: '/games/garden',
        builder: (context, state) => const GardenScreen(),
      ),
      GoRoute(
        path: '/games/soundboard',
        builder: (context, state) => const SoundboardScreen(),
      ),
      GoRoute(
        path: '/games/mirror',
        builder: (context, state) => const MirrorScreen(),
      ),

      // =========================
      // WELLNESS
      // =========================
      GoRoute(
        path: '/wellness',
        builder: (context, state) => const WellnessHomeScreen(),
      ),
      GoRoute(
        path: '/wellness/calm-corner',
        builder: (context, state) => const CalmCornerScreen(),
      ),
      GoRoute(
        path: '/wellness/breathing',
        builder: (context, state) => const BreathingScreen(),
      ),
      GoRoute(
        path: '/wellness/grounding',
        builder: (context, state) => const GroundingScreen(),
      ),
      GoRoute(
        path: '/wellness/eye-relax',
        builder: (context, state) => const EyeRelaxScreen(),
      ),
      GoRoute(
        path: '/wellness/mind-journal',
        builder: (context, state) => const MindJournalScreen(),
      ),
      GoRoute(
        path: '/wellness/s-cycle',
        builder: (context, state) => const SCycleScreen(),
      ),
      GoRoute(
        path: '/wellness/hydration',
        builder: (context, state) => const HydrationScreen(),
      ),

      // =========================
      // HASHTAG EXPLORE
      // =========================
      GoRoute(
        path: '/hashtags',
        builder: (context, state) => const HashtagExploreScreen(),
      ),

      // =========================
      // POST EDIT
      // =========================
      GoRoute(
        path: '/post-edit',
        builder: (context, state) => const EditPostScreen(),
      ),

      // =========================
      // S-FRAME
      // =========================
      GoRoute(
        path: '/sframe-create',
        builder: (context, state) => const SFrameCreateScreen(),
      ),
      GoRoute(
        path: '/sframe-viewer',
        builder: (context, state) {
          final extra = state.extra;
          
          if (extra == null ||
          extra is! Map<String, dynamic> ||
          extra['frames'] == null ||
          extra['startIndex'] == null) {
            return const _RouterErrorScreen(
               message: "S-Frame data missing. Please reopen S-Frames.",
               );
               }
               
               return SFrameViewerScreen(
          frames: extra['frames'],
          startIndex: extra['startIndex'],
        );
  },
),

      // =========================
      // POSTS
      // =========================
      GoRoute(
        path: '/post-create',
        builder: (context, state) => const CreatePostScreen(),
      ),
      GoRoute(
        path: '/post',
        builder: (context, state) {
          final extra = state.extra;
          if (extra == null || extra is! Post) {
            return const _RouterErrorScreen(
              message: "Post data missing. Please open the post again.",
            );
          }
          return PostDetailScreen(post: extra);
        },
      ),

      // =========================
      // SETTINGS
      // =========================
      ...settingsRoutes,
    ],
    errorBuilder: (context, state) => _RouterErrorScreen(
      message: state.error.toString(),
    ),
  );
}

/// Safe fallback so routing never crashes
class _RouterErrorScreen extends StatelessWidget {
  final String message;
  const _RouterErrorScreen({required this.message, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Route Error"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          message,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}