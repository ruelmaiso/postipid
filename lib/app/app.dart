import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'theme/app_theme.dart';
import '../features/app/app_root.dart';
import '../features/app/app_controller.dart';

class TipidPosApp extends StatelessWidget {
  const TipidPosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TipidPosController>(
      builder: (context, controller, _) {
        return MaterialApp(
          title: 'TipidPOS',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.buildLight(),
          darkTheme: AppTheme.buildDark(),
          themeMode: controller.themeMode,
          home: const AppRoot(),
        );
      },
    );
  }
}
