import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../shared/widgets/app_loading_spinner.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../bloc/auth_provider.dart';
import '../bloc/perfil_provider.dart';
import '../widgets/perfil_info_list.dart';
import '../../data/repositories/perfil_repository_impl.dart';
import '../../domain/usecases/get_perfil_info_usecase.dart';

class PerfilPage extends StatelessWidget {
  const PerfilPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PerfilProvider(
        getPerfilInfoUseCase: GetPerfilInfoUseCase(
          PerfilRepositoryImpl(
            authRepository: context.read<AuthProvider>().repository,
          ),
        ),
      ),
      child: const _PerfilView(),
    );
  }
}

class _PerfilView extends StatefulWidget {
  const _PerfilView();

  @override
  State<_PerfilView> createState() => _PerfilViewState();
}

class _PerfilViewState extends State<_PerfilView> {
  String? _lastErrorMessage;

  @override
  Widget build(BuildContext context) {
    final perfilProvider = context.watch<PerfilProvider>();
    final error = perfilProvider.error;

    if (error != null && error != _lastErrorMessage) {
      _lastErrorMessage = error;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        AppToast.show(context, message: error, type: ToastType.error);
      });
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.dashboardCardTitle,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AppStrings.dashboardCardSubtitle,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.textSecondary),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: perfilProvider.isLoading
                        ? null
                        : perfilProvider.loadPerfil,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: perfilProvider.isLoading
                ? const Center(
                    child: AppLoadingSpinner(
                      message: 'Cargando información del perfil...',
                    ),
                  )
                : perfilProvider.perfil != null
                ? PerfilInfoList(perfil: perfilProvider.perfil!)
                : perfilProvider.error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: AppColors.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          perfilProvider.error!,
                          style: TextStyle(
                            color: AppColors.error,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: perfilProvider.loadPerfil,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  )
                : perfilProvider.isInitialLoading
                ? const Center(
                    child: AppLoadingSpinner(
                      message: 'Cargando información del perfil...',
                    ),
                  )
                : const Center(child: Text(AppStrings.noData)),
          ),
        ],
      ),
    );
  }
}

