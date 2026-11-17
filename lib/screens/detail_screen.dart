import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/sunset.dart';
import '../services/database_service.dart';

class DetailScreen extends StatefulWidget {
  final Sunset sunset;

  const DetailScreen({super.key, required this.sunset});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late String _imagePath;
  bool _loading = false;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _imagePath = widget.sunset.imagePath;
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _replaceImage() async {
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1600,
      );

      if (image == null || !mounted) return;

      setState(() => _loading = true);

      final savedPath = await DatabaseService.instance.updateSunsetImage(
        widget.sunset.id!,
        image.path,
      );

      if (!mounted) return;

      setState(() {
        _imagePath = savedPath;
        _changed = true;
      });

      _showMessage('Fotografía actualizada correctamente.');
    } catch (e) {
      _showMessage('No se pudo reemplazar la fotografía.');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _deleteSunset() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar atardecer'),
        content: const Text(
          '¿Deseas eliminar este recuerdo y su fotografía guardada? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _loading = true);

    try {
      await DatabaseService.instance.deleteSunset(widget.sunset);

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      _showMessage('No se pudo eliminar el recuerdo.');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _openMap() async {
    try {
      final latitude = widget.sunset.latitude;
      final longitude = widget.sunset.longitude;

      final url = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
      );

      final opened = await launchUrl(url, mode: LaunchMode.externalApplication);

      if (!opened) {
        throw Exception('No se pudo abrir el mapa');
      }
    } catch (e) {
      _showMessage('No se pudo abrir Google Maps.');
    }
  }

  String _formatDate() {
    try {
      return DateFormat(
        'dd/MM/yyyy - HH:mm',
      ).format(DateTime.parse(widget.sunset.date));
    } catch (e) {
      return widget.sunset.date;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Navigator.pop(context, _changed);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mi recuerdo'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context, _changed),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Hero(
                    tag: 'sunset_${widget.sunset.id}',
                    flightShuttleBuilder:
                        (
                          flightContext,
                          animation,
                          flightDirection,
                          fromHeroContext,
                          toHeroContext,
                        ) {
                          return Container(
                            color: const Color(0xFF222C3C),
                            child: Center(
                              child: Icon(
                                Icons.landscape_outlined,
                                color: Colors.white54,
                                size: 55,
                              ),
                            ),
                          );
                        },
                    child: Image.file(
                      File(_imagePath),
                      key: ValueKey(_imagePath),
                      width: double.infinity,
                      height: 280,
                      fit: BoxFit.cover,

                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: double.infinity,
                          height: 280,
                          color: const Color(0xFF222C3C),
                          child: const Center(
                            child: Icon(
                              Icons.broken_image_outlined,
                              size: 55,
                              color: Colors.white54,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _loading ? null : _replaceImage,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Reemplazar fotografía'),
                ),
                const SizedBox(height: 20),
                Text(
                  widget.sunset.title,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    const Icon(Icons.place_outlined, color: Color(0xFFFFA45B)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.sunset.place,
                        style: const TextStyle(fontSize: 17),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      color: Color(0xFFFFA45B),
                    ),
                    const SizedBox(width: 10),
                    Text(_formatDate()),
                  ],
                ),
                const SizedBox(height: 30),
                const Text(
                  'Mi historia',
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF222C3C),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    widget.sunset.description.isEmpty
                        ? 'No agregaste una descripción.'
                        : widget.sunset.description,
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),
                ),
                const SizedBox(height: 30),
                const Text(
                  'Ubicación del recuerdo',
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 15),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: const Color(0xFF222C3C),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 45,
                        color: Color(0xFFFFA45B),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Latitud: ${widget.sunset.latitude.toStringAsFixed(6)}',
                      ),
                      Text(
                        'Longitud: ${widget.sunset.longitude.toStringAsFixed(6)}',
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _openMap,
                          icon: const Icon(Icons.map_outlined),
                          label: const Text('Ver en Google Maps'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFA45B),
                            foregroundColor: const Color(0xFF101827),
                            padding: const EdgeInsets.all(16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _loading ? null : _deleteSunset,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Eliminar recuerdo'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
                const SizedBox(height: 25),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
