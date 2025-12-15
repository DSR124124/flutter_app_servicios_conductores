import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/constants/app_config.dart';
import '../../../../shared/widgets/app_loading_spinner.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../auth/presentation/bloc/auth_provider.dart';
import '../../data/dtos/crear_notificacion_dto.dart';
import '../../data/datasources/notificaciones_remote_data_source.dart';
import '../../data/repositories/notificaciones_repository_impl.dart';
import '../../data/models/usuario_destinatario_model.dart';
import '../../domain/usecases/crear_notificacion_usecase.dart';

class CrearNotificacionPage extends StatefulWidget {
  const CrearNotificacionPage({super.key});

  @override
  State<CrearNotificacionPage> createState() => _CrearNotificacionPageState();
}

class _CrearNotificacionPageState extends State<CrearNotificacionPage> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _mensajeController = TextEditingController();
  String _tipoNotificacion = 'info';
  String _prioridad = 'normal';
  int? _selectedDestinatarioId;
  List<UsuarioDestinatario> _usuarios = [];
  bool _isSubmitting = false;

  @override
  void dispose() {
    _tituloController.dispose();
    _mensajeController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _cargarUsuarios();
  }

  Future<void> _cargarUsuarios() async {
    try {
      final authProvider = context.read<AuthProvider>();
      final user = authProvider.user;
      if (user == null) return;

      final uri = Uri.parse(
        '${AppConfig.backendGestionBaseUrl}/api/usuarios',
      );

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${user.token}',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body) as List<dynamic>;
        final usuarios = jsonList
            .map((e) =>
                UsuarioDestinatario.fromJson(e as Map<String, dynamic>))
            .toList();
        setState(() {
          _usuarios = usuarios;
        });
      } else {
        AppToast.show(
          context,
          message: 'No se pudieron cargar los usuarios (${response.statusCode})',
          type: ToastType.error,
        );
      }
    } catch (_) {
      if (!mounted) return;
      AppToast.show(
        context,
        message: 'Error al cargar usuarios',
        type: ToastType.error,
      );
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final user = authProvider.user;
    if (user == null) {
      AppToast.show(
        context,
        message: 'No hay usuario autenticado',
        type: ToastType.error,
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // ID de la aplicación de notificaciones de conductores (esta app = 7)
      const int idAplicacion = 7;

      // Si no se selecciona destinatario, se envía al propio usuario
      final int destinatarioId = _selectedDestinatarioId ?? user.idUsuario;

      final dto = CrearNotificacionDto(
        titulo: _tituloController.text.trim(),
        mensaje: _mensajeController.text.trim(),
        tipoNotificacion: _tipoNotificacion,
        prioridad: _prioridad,
        idAplicacion: idAplicacion,
        creadoPor: user.idUsuario,
        // Siempre true según tu requerimiento
        requiereConfirmacion: true,
        mostrarComoRecordatorio: true,
        idUsuarios: [destinatarioId],
      );

      final remoteDataSource = NotificacionesRemoteDataSourceImpl(
        client: http.Client(),
      );
      final repository = NotificacionesRepositoryImpl(
        remoteDataSource: remoteDataSource,
      );
      final useCase = CrearNotificacionUseCase(repository);

      await useCase(
        dto: dto,
        token: user.token,
      );

      if (!mounted) return;
      AppToast.show(
        context,
        message: 'Notificación enviada',
        type: ToastType.success,
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      AppToast.show(
        context,
        message: 'Error al enviar notificación: $e',
        type: ToastType.error,
        duration: const Duration(seconds: 6),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva notificación'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Detalle del mensaje',
                style: AppTextStyles.h4,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _tituloController,
                decoration: const InputDecoration(
                  labelText: 'Título',
                ),
                maxLength: 255,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El título es obligatorio';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(
                  labelText: 'Usuario destinatario',
                ),
                // Solo usamos el valor seleccionado explícitamente
                value: _selectedDestinatarioId,
                items: [
                  ..._usuarios.map(
                    (u) => DropdownMenuItem(
                      value: u.idUsuario,
                      child: Text(u.nombre),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedDestinatarioId = value;
                  });
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _mensajeController,
                decoration: const InputDecoration(
                  labelText: 'Mensaje',
                ),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El mensaje es obligatorio';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Tipo',
                      ),
                      value: _tipoNotificacion,
                      items: const [
                        DropdownMenuItem(
                          value: 'info',
                          child: Text('Info'),
                        ),
                        DropdownMenuItem(
                          value: 'warning',
                          child: Text('Advertencia'),
                        ),
                        DropdownMenuItem(
                          value: 'error',
                          child: Text('Error'),
                        ),
                        DropdownMenuItem(
                          value: 'success',
                          child: Text('Éxito'),
                        ),
                        DropdownMenuItem(
                          value: 'critical',
                          child: Text('Crítica'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _tipoNotificacion = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Prioridad',
                      ),
                      value: _prioridad,
                      items: const [
                        DropdownMenuItem(
                          value: 'baja',
                          child: Text('Baja'),
                        ),
                        DropdownMenuItem(
                          value: 'normal',
                          child: Text('Normal'),
                        ),
                        DropdownMenuItem(
                          value: 'alta',
                          child: Text('Alta'),
                        ),
                        DropdownMenuItem(
                          value: 'urgente',
                          child: Text('Urgente'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _prioridad = value;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submit,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: AppLoadingSpinner(size: 16, strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                  label: Text(
                    _isSubmitting ? 'Enviando...' : 'Enviar notificación',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textoHeader,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


