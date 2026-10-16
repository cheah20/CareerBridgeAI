import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router.dart';
import 'theme/app_theme.dart';

class CareerBridgeApp extends ConsumerWidget {
  const CareerBridgeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final style = ref.watch(glassStyleProvider);
    return MaterialApp.router(
      title: 'CareerBridge AI',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(tokensFor(style)),
      routerConfig: ref.watch(routerProvider),
    );
  }
}
