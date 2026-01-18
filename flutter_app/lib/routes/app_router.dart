import 'package:go_router/go_router.dart';
import 'package:saran_app/screens/auth/login_screen.dart';
import 'package:saran_app/screens/auth/signup_screen.dart';
import 'package:saran_app/screens/home/home_screen.dart';
import 'package:saran_app/screens/explore/explore_screen.dart';
import 'package:saran_app/screens/profile/profile_screen.dart';
import 'package:saran_app/screens/messages/messages_screen.dart';
import 'package:saran_app/screens/sos/sos_screen.dart';
import 'package:saran_app/screens/space/space_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/home',
    routes: [
      // Auth Routes
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      
      // Main App Routes
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/explore',
        builder: (context, state) => const ExploreScreen(),
      ),
      GoRoute(
        path: '/sos',
        builder: (context, state) => const SosScreen(),
      ),
      GoRoute(
        path: '/space',
        builder: (context, state) => const SpaceScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/messages',
        builder: (context, state) => const MessagesScreen(),
      ),
      
      // Add more routes as needed
    ],
  );
}
