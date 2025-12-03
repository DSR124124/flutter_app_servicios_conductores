import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../shared/services/app_info_service.dart';
import '../../../../shared/widgets/app_loading_spinner.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../app_update/presentation/bloc/app_update_provider.dart';
import '../../../app_update/presentation/widgets/app_update_dialog.dart';
import '../../../auth/presentation/bloc/auth_provider.dart';
import '../../../auth/presentation/pages/perfil_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _HomeView();
  }
}

class _HomeView extends StatefulWidget {
  const _HomeView();

  @override
  State<_HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<_HomeView> {
  int _currentPageIndex = 0; // 0 = Panel, 1 = Perfil
  final AppUpdateProvider _updateProvider = AppUpdateProvider();
  final AppInfoService _appInfoService = AppInfoService();
  bool _hasCheckedForUpdates = false;
  String _installedVersion = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForUpdates();
      _loadInstalledVersion();
    });
  }

  Future<void> _loadInstalledVersion() async {
    final version = await _appInfoService.getCurrentVersion();
    if (!mounted) return;
    setState(() {
      _installedVersion = version;
    });
  }

  Future<void> _checkForUpdates() async {
    if (_hasCheckedForUpdates) return;
    _hasCheckedForUpdates = true;

    final authProvider = context.read<AuthProvider>();
    final user = authProvider.user;

    if (user == null) return;

    await _updateProvider.checkForUpdates(
      idUsuario: user.idUsuario,
      token: user.token,
    );

    if (_updateProvider.hasUpdate && mounted) {
      AppUpdateDialog.show(
        context,
        updateInfo: _updateProvider.availableUpdate!,
        onDismiss: _updateProvider.dismissUpdate,
      );
    }
  }

  Future<void> _handleLogout() async {
    if (!mounted) return;
    
    AppGradientSpinner.showOverlay(
      context,
      message: 'Cerrando sesión...',
    );

    try {
      final authProvider = context.read<AuthProvider>();
      await authProvider.logout();

      if (!mounted) return;

      AppGradientSpinner.hideOverlay(context);
      
      AppToast.show(
        context,
        message: 'Sesión cerrada exitosamente',
        type: ToastType.success,
      );
    } catch (e) {
      if (mounted) {
        AppGradientSpinner.hideOverlay(context);
        AppToast.show(
          context,
          message: 'Error al cerrar sesión',
          type: ToastType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textoHeader,
        title: Text(_currentPageIndex == 0 
            ? AppStrings.dashboardTitle 
            : AppStrings.menuMiPerfil),
      ),
      drawer: _buildDrawer(context, user),
      body: _currentPageIndex == 0
              ? _buildPanelBody(user)
              : const PerfilPage(),
    );
  }

  Widget _buildDrawer(BuildContext context, user) {
    return Drawer(
      backgroundColor: AppColors.surface,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: AppColors.primary,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.white,
                  child: Text(
                    (user?.nombreCompleto?.isNotEmpty == true 
                        ? user!.nombreCompleto![0] 
                        : user?.username?.isNotEmpty == true
                            ? user!.username![0]
                            : 'C').toUpperCase(),
                    style: TextStyle(
                      fontSize: 24,
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  user?.nombreCompleto ?? user?.username ?? 'Conductor',
                  style: const TextStyle(
                    color: AppColors.textoHeader,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (user?.nombreRol != null || user?.rol != null)
                  Text(
                    user?.nombreRol ?? user?.rol ?? '',
                    style: TextStyle(
                      color: AppColors.textoHeader.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
              ],
            ),
          ),
          // Mi Perfil
          ListTile(
            leading: Icon(
              Icons.person_outline,
              color: _currentPageIndex == 1 
                  ? AppColors.primary 
                  : AppColors.textSecondary,
            ),
            title: Text(
              AppStrings.menuMiPerfil,
              style: TextStyle(
                color: _currentPageIndex == 1 
                    ? AppColors.primary 
                    : AppColors.textPrimary,
                fontWeight: _currentPageIndex == 1 
                    ? FontWeight.w600 
                    : FontWeight.normal,
              ),
            ),
            selected: _currentPageIndex == 1,
            selectedTileColor: AppColors.primary.withOpacity(0.1),
            onTap: () {
              setState(() {
                _currentPageIndex = 1;
              });
              Navigator.pop(context);
            },
          ),
          // Panel Principal
          ListTile(
            leading: Icon(
              Icons.dashboard_outlined,
              color: _currentPageIndex == 0 
                  ? AppColors.primary 
                  : AppColors.textSecondary,
            ),
            title: Text(
              'Panel',
              style: TextStyle(
                color: _currentPageIndex == 0 
                    ? AppColors.primary 
                    : AppColors.textPrimary,
                fontWeight: _currentPageIndex == 0 
                    ? FontWeight.w600 
                    : FontWeight.normal,
              ),
            ),
            selected: _currentPageIndex == 0,
            selectedTileColor: AppColors.primary.withOpacity(0.1),
            onTap: () {
              setState(() {
                _currentPageIndex = 0;
              });
              Navigator.pop(context);
            },
          ),
          const Divider(color: AppColors.border, height: 1),
          ListTile(
            leading: const Icon(
              Icons.logout,
              color: AppColors.error,
            ),
            title: const Text(
              AppStrings.menuCerrarSesion,
              style: TextStyle(color: AppColors.error),
            ),
            onTap: () async {
              Navigator.pop(context);
              await Future.delayed(const Duration(milliseconds: 100));
              if (mounted) {
                _handleLogout();
              }
            },
          ),
          const Divider(color: AppColors.border, height: 1),
          // Versión de la app
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Versión ${_installedVersion.isEmpty ? '...' : _installedVersion}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPanelBody(user) {
    return Stack(
      children: [
        // Contenido principal centrado
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.directions_bus_outlined,
                size: 80,
                color: AppColors.textSecondary.withOpacity(0.5),
              ),
              const SizedBox(height: 24),
              Text(
                '¡Hola, ${user?.nombreCompleto ?? user?.username ?? 'Conductor'}!',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Bienvenido al panel de conductores',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Usa los accesos rápidos para navegar',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        // Botones de acción (estilo servicios)
        Positioned(
          top: 16,
          left: 16,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Mis Viajes
              _buildActionButton(
                icon: Icons.directions_bus,
                label: 'Mis Viajes',
                onTap: () => context.push('/mis-viajes'),
              ),
              const SizedBox(width: 16),
              // Historial
              _buildActionButton(
                icon: Icons.history,
                label: 'Historial',
                onTap: () => context.push('/historial'),
              ),
              const SizedBox(width: 16),
              // Estadísticas
              _buildActionButton(
                icon: Icons.bar_chart,
                label: 'Estadísticas',
                onTap: () => context.push('/estadisticas'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: AppColors.white,
                size: 28,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
