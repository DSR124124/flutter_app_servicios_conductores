import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'config/router/app_router.dart';
import 'config/theme/app_theme.dart';
import 'features/auth/presentation/bloc/auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar el locale español para DateFormat
  await initializeDateFormatting('es_ES', null);
  
  runApp(const NettalcoConductoresApp());
}

class NettalcoConductoresApp extends StatelessWidget {
  const NettalcoConductoresApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = AuthProvider();
    AppRouter.initialize(authProvider);

    return ChangeNotifierProvider.value(
      value: authProvider,
      child: MaterialApp.router(
        title: 'Nettalco Conductores',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        routerConfig: AppRouter.router,
      ),
    );
  }
}
