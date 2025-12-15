import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_loading_spinner.dart';
import '../../domain/entities/notificacion.dart';
import '../bloc/notificaciones_provider.dart';

class NotificacionesPage extends StatelessWidget {
  final int? initialNotificacionId;

  const NotificacionesPage({super.key, this.initialNotificacionId});

  @override
  Widget build(BuildContext context) {
    // Verificar si el provider está disponible de forma segura
    NotificacionesProvider? provider;
    try {
      provider = Provider.of<NotificacionesProvider>(context, listen: false);
    } catch (e) {
      debugPrint('NotificacionesProvider no disponible: $e');
    }

    if (provider == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Notificaciones'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(
          child: Text('Error: Provider de notificaciones no disponible'),
        ),
      );
    }

    return ChangeNotifierProvider<NotificacionesProvider>.value(
      value: provider,
      child: _NotificacionesView(initialNotificacionId: initialNotificacionId),
    );
  }
}

class _NotificacionesView extends StatefulWidget {
  final int? initialNotificacionId;

  const _NotificacionesView({this.initialNotificacionId});

  @override
  State<_NotificacionesView> createState() => _NotificacionesViewState();
}

class _NotificacionesViewState extends State<_NotificacionesView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      
      try {
        final provider = context.read<NotificacionesProvider>();
        provider.cargarNotificaciones(context).then((_) {
          if (!mounted) return;
          
          final id = widget.initialNotificacionId;
          if (id == null) return;

          Notificacion? notif;
          for (final n in provider.notificaciones) {
            if (n.idNotificacion == id) {
              notif = n;
              break;
            }
          }

          if (notif != null && mounted) {
            provider.marcarComoLeida(context, notif);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => NotificacionDetallePage(notificacion: notif!),
              ),
            );
          }
        }).catchError((error) {
          debugPrint('Error al cargar notificaciones: $error');
        });
      } catch (e) {
        debugPrint('Error al acceder a NotificacionesProvider: $e');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    NotificacionesProvider provider;
    try {
      provider = context.watch<NotificacionesProvider>();
    } catch (e) {
      debugPrint('Error al acceder a NotificacionesProvider en build: $e');
      return Scaffold(
        appBar: AppBar(title: const Text('Notificaciones')),
        body: const Center(
          child: Text('Error al cargar notificaciones'),
        ),
      );
    }
    
    final unread = provider.unreadCount;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Mis notificaciones'),
            if (unread > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  unread.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Nueva notificación',
            onPressed: () async {
              try {
                final created = await context.push('/notificaciones/nueva');
                if (created == true && mounted) {
                  try {
                    provider.cargarNotificaciones(context);
                  } catch (e) {
                    debugPrint('Error al recargar notificaciones: $e');
                  }
                }
              } catch (e) {
                debugPrint('Error al navegar a crear notificación: $e');
              }
            },
          ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: AppLoadingSpinner())
          : provider.notificaciones.isEmpty
              ? const Center(
                  child: Text('No tienes notificaciones por el momento'),
                )
              : ListView.builder(
                  itemCount: provider.notificaciones.length,
                  itemBuilder: (context, index) {
                    final notif = provider.notificaciones[index];
                    return _NotificacionListTile(
                      notificacion: notif,
                      selected: false,
                      onTap: () {
                        try {
                          provider.marcarComoLeida(context, notif);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => NotificacionDetallePage(
                                notificacion: notif,
                              ),
                            ),
                          ).then((_) {
                            if (mounted) {
                              try {
                                provider.cargarNotificaciones(context);
                              } catch (e) {
                                debugPrint('Error al recargar notificaciones: $e');
                              }
                            }
                          }).catchError((error) {
                            debugPrint('Error al navegar a detalle: $error');
                          });
                        } catch (e) {
                          debugPrint('Error al marcar como leída: $e');
                        }
                      },
                    );
                  },
                ),
    );
  }
}

class _NotificacionListTile extends StatelessWidget {
  final Notificacion notificacion;
  final bool selected;
  final VoidCallback onTap;

  const _NotificacionListTile({
    required this.notificacion,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.primary.withOpacity(0.08)
          : (notificacion.leida
              ? Colors.transparent
              : AppColors.grayLighter),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      notificacion.titulo,
                      style: AppTextStyles.h4.copyWith(
                        fontWeight: notificacion.leida
                            ? FontWeight.normal
                            : FontWeight.w600,
                        color: notificacion.leida
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    notificacion.leida ? Icons.mark_email_read : Icons.mark_email_unread,
                    size: 18,
                    color: notificacion.leida
                        ? AppColors.success
                        : AppColors.primaryDark,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                notificacion.mensaje,
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textSecondary),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                notificacion.nombreAplicacion ?? '',
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificacionDetalle extends StatelessWidget {
  final Notificacion notificacion;

  const _NotificacionDetalle({required this.notificacion});

  @override
  Widget build(BuildContext context) {
    // Si no hay fecha de envío programada, usamos la fecha de creación
    final String fechaParaMostrar =
        notificacion.fechaEnvio ?? notificacion.fechaCreacion;

    String formatearFechaHora(String iso) {
      try {
        final dt = DateTime.parse(iso);
        String two(int n) => n.toString().padLeft(2, '0');
        return '${two(dt.day)}/${two(dt.month)}/${dt.year} ${two(dt.hour)}:${two(dt.minute)}';
      } catch (_) {
        return iso;
      }
    }

    final String textoEnviadoPor =
        notificacion.creadorNombre ?? notificacion.nombreAplicacion ?? '';

    return Padding(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera tipo correo / hilo
            Text(
              notificacion.titulo,
              style: AppTextStyles.h3,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  notificacion.leida
                      ? Icons.mark_email_read
                      : Icons.mark_email_unread,
                  size: 18,
                  color: notificacion.leida
                      ? AppColors.success
                      : AppColors.primaryDark,
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notificacion.nombreAplicacion ?? '',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textSecondary),
                    ),
                    if (textoEnviadoPor.isNotEmpty)
                      Text(
                        'Enviado por $textoEnviadoPor',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    Text(
                      'Enviado el ${formatearFechaHora(fechaParaMostrar)}',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Mensaje principal como "burbuja"
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  notificacion.mensaje,
                  style: AppTextStyles.bodyLarge,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Datos adicionales como "hilo" debajo
            if (notificacion.datosAdicionales != null)
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    notificacion.datosAdicionales.toString(),
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Página independiente para detalle
class NotificacionDetallePage extends StatelessWidget {
  final Notificacion notificacion;

  const NotificacionDetallePage({super.key, required this.notificacion});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de notificación'),
      ),
      body: _NotificacionDetalle(notificacion: notificacion),
    );
  }
}


