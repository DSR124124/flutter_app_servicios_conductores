import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../domain/entities/app_update_info.dart';

/// Diálogo de actualización disponible
class AppUpdateDialog extends StatefulWidget {
  const AppUpdateDialog({
    super.key,
    required this.updateInfo,
    this.onDismiss,
  });

  final AppUpdateInfo updateInfo;
  final VoidCallback? onDismiss;

  /// Muestra el diálogo de actualización
  static Future<void> show(
    BuildContext context, {
    required AppUpdateInfo updateInfo,
    VoidCallback? onDismiss,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: !updateInfo.esCritico,
      builder: (context) => AppUpdateDialog(
        updateInfo: updateInfo,
        onDismiss: onDismiss,
      ),
    );
  }

  @override
  State<AppUpdateDialog> createState() => _AppUpdateDialogState();
}

class _AppUpdateDialogState extends State<AppUpdateDialog> {
  bool _isDownloading = false;
  double _downloadProgress = 0;
  String _statusMessage = '';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(
            widget.updateInfo.esCritico
                ? Icons.warning_amber_rounded
                : Icons.system_update,
            color: widget.updateInfo.esCritico
                ? AppColors.warning
                : AppColors.primary,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.updateInfo.esCritico
                  ? '¡Actualización Crítica!'
                  : 'Nueva Actualización',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Versión
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.new_releases, size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Versión ${widget.updateInfo.version}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Notas de versión
            const Text(
              'Novedades:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.grayDark,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.grayLighter,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                widget.updateInfo.notasVersion.isEmpty
                    ? 'Mejoras de rendimiento y corrección de errores.'
                    : widget.updateInfo.notasVersion,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.grayDark,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Tamaño del archivo
            if (widget.updateInfo.tamanoArchivo != null)
              Row(
                children: [
                  const Icon(Icons.storage, size: 18, color: AppColors.grayMedium),
                  const SizedBox(width: 8),
                  Text(
                    'Tamaño: ${widget.updateInfo.tamanoFormateado}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.grayMedium,
                    ),
                  ),
                ],
              ),

            // Progreso de descarga
            if (_isDownloading) ...[
              const SizedBox(height: 20),
              LinearProgressIndicator(
                value: _downloadProgress,
                backgroundColor: AppColors.grayLighter,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
              const SizedBox(height: 8),
              Text(
                _statusMessage.isEmpty
                    ? 'Descargando... ${(_downloadProgress * 100).toStringAsFixed(0)}%'
                    : _statusMessage,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.grayMedium,
                ),
                textAlign: TextAlign.center,
              ),
            ],

            // Advertencia para actualizaciones críticas
            if (widget.updateInfo.esCritico) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, size: 18, color: AppColors.warning),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Esta actualización es obligatoria para continuar usando la aplicación.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.warning,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        // Botón cancelar (solo para no críticas)
        if (!widget.updateInfo.esCritico && !_isDownloading)
          TextButton(
            onPressed: () {
              widget.onDismiss?.call();
              Navigator.of(context).pop();
            },
            child: const Text('Más tarde'),
          ),

        // Botón actualizar
        FilledButton.icon(
          onPressed: _isDownloading ? null : _startDownload,
          icon: _isDownloading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.download),
          label: Text(_isDownloading ? 'Descargando...' : 'Actualizar ahora'),
        ),
      ],
    );
  }

  Future<void> _startDownload() async {
    if (widget.updateInfo.urlDescarga.isEmpty) {
      AppToast.show(
        context,
        message: 'URL de descarga no disponible',
        type: ToastType.error,
      );
      return;
    }

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0;
      _statusMessage = 'Iniciando descarga...';
    });

    try {
      // Obtener directorio de descargas
      final directory = await _getDownloadDirectory();
      final fileName = 'nettalco_conductores_${widget.updateInfo.version}.apk';
      final filePath = '${directory.path}/$fileName';

      // Descargar el archivo
      final request = http.Request('GET', Uri.parse(widget.updateInfo.urlDescarga));
      final response = await http.Client().send(request);

      if (response.statusCode != 200) {
        throw Exception('Error al descargar: ${response.statusCode}');
      }

      final contentLength = response.contentLength ?? 0;
      final file = File(filePath);
      final sink = file.openWrite();

      int downloaded = 0;

      await for (final chunk in response.stream) {
        sink.add(chunk);
        downloaded += chunk.length;

        if (contentLength > 0) {
          setState(() {
            _downloadProgress = downloaded / contentLength;
          });
        }
      }

      await sink.close();

      setState(() {
        _statusMessage = 'Descarga completada. Instalando...';
      });

      // Instalar el APK
      await _installApk(filePath);
    } catch (e) {
      setState(() {
        _isDownloading = false;
        _statusMessage = '';
      });

      if (mounted) {
        AppToast.show(
          context,
          message: 'Error al descargar: $e',
          type: ToastType.error,
        );
      }
    }
  }

  Future<Directory> _getDownloadDirectory() async {
    return await getTemporaryDirectory();
  }

  Future<void> _installApk(String filePath) async {
    try {
      if (Platform.isAndroid) {
        final result = await OpenFilex.open(filePath);
        
        if (result.type == ResultType.done) {
          if (mounted) {
            AppToast.show(
              context,
              message: 'Instalando actualización...',
              type: ToastType.success,
            );
            Navigator.of(context).pop();
          }
        } else {
          if (mounted) {
            AppToast.show(
              context,
              message: 'APK descargado. Búscalo en: $filePath',
              type: ToastType.info,
            );
            
            setState(() {
              _isDownloading = false;
              _statusMessage = 'APK descargado correctamente';
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(
          context,
          message: 'Error al instalar: $e',
          type: ToastType.error,
        );
        setState(() {
          _isDownloading = false;
        });
      }
    }
  }
}

