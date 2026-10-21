import 'package:careerbridge_ai/app/app.dart';
import 'package:careerbridge_ai/features/auth/auth_backend.dart';
import 'package:careerbridge_ai/features/shell/server_status.dart';
import 'package:careerbridge_ai/features/testing/testing_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

/// Starts the app with fake services at a given window size.
Future<ProviderContainer> pumpApp(
  WidgetTester tester,
  Size size, {
  AuthBackend? auth,
  ProfileApi? profiles,
  HomeApi? home,
  TestingApi? testing,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  // Reduced motion: the drifting background stays still so pumpAndSettle can finish.
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

  final container = ProviderContainer(
    overrides: [
      authBackendProvider.overrideWithValue(auth ?? FakeAuthBackend()),
      profileApiProvider.overrideWithValue(profiles ?? FakeProfileApi({})),
      homeApiProvider.overrideWithValue(home ?? FakeHomeApi()),
      testingApiProvider.overrideWithValue(testing ?? FakeTestingApi()),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const CareerBridgeApp(),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}
