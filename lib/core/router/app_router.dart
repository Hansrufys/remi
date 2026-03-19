import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/canvas/canvas_screen.dart';
import '../../features/people/people_screen.dart';
import '../../features/people/person_detail_screen.dart';
import '../../features/memory/query_screen.dart';
import '../../features/echoes/evening_wrap_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/onboarding/onboarding_provider.dart';

class AppRouter {
  static late GoRouter _instance;
  static GoRouter get router => _instance;
  static set router(GoRouter r) => _instance = r;
}

final routerProvider = Provider<GoRouter>((ref) {
  final onboardingCompleted = ref.watch(onboardingProvider);
  
  final router = GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isGoingToOnboarding = state.matchedLocation == '/onboarding';

      if (!onboardingCompleted && !isGoingToOnboarding) {
        return '/onboarding';
      }
      if (onboardingCompleted && isGoingToOnboarding) {
        return '/';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/',
        name: 'canvas',
        builder: (context, state) {
          final quickRecord = state.uri.queryParameters['quick'] == 'true';
          return CanvasScreen(isQuickRecord: quickRecord);
        },
      ),
      GoRoute(
        path: '/people',
        name: 'people',
        builder: (context, state) => const PeopleScreen(),
        routes: [
          GoRoute(
            path: ':personId',
            name: 'person-detail',
            builder: (context, state) => PersonDetailScreen(
              personId: state.pathParameters['personId']!,
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/query',
        name: 'query',
        builder: (context, state) => const QueryScreen(),
      ),
      GoRoute(
        path: '/evening-wrap',
        name: 'evening-wrap',
        builder: (context, state) => const EveningWrapScreen(),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );

  AppRouter.router = router;
  return router;
});
