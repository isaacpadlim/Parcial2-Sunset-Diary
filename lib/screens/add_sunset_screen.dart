import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:intl/intl.dart';
import '../models/sunset.dart';
import '../services/database_service.dart';

class AddSunsetScreen extends StatefulWidget {
  const AddSunsetScreen({super.key});

  @override
  State<AddSunsetScreen> createState() => _AddSunsetScreenState();
}

class _AddSunsetScreenState extends State<AddSunsetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _placeController = TextEditingController();
  final _descriptionController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  final stt.SpeechToText _speech = stt.SpeechToText();

  XFile? _image;
  Position? _position;
  bool _listening = false;
  bool _loadingLocation = false;
  bool _saving = false;

  final DateTime _date = DateTime.now();

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showPermissionDialog(String message) async {
    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permiso necesario'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await Geolocator.openAppSettings();
            },
            child: const Text('Abrir ajustes'),
          ),
        ],
      ),
    );
  }

  Future<void> _selectImage(ImageSource source) async {
    try {
      final image = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1600,
      );

      if (image != null && mounted) {
        setState(() {
          _image = image;
        });
      }
    } catch (e) {
      await _showPermissionDialog(
        'No se pudo acceder a la fotografía. Revisa los permisos de cámara o fotos en Ajustes del iPhone.',
      );
    }
  }

  Future<void> _startDictation() async {
    try {
      if (_listening) {
        await _speech.stop();
        if (mounted) {
          setState(() => _listening = false);
        }
        return;
      }

      final available = await _speech.initialize(
        onStatus: (status) {
          if (mounted && (status == 'done' || status == 'notListening')) {
            setState(() => _listening = false);
          }
        },
        onError: (error) {
          if (mounted) {
            setState(() => _listening = false);
            _showMessage('No se pudo completar el dictado.');
          }
        },
      );

      if (!available) {
        await _showPermissionDialog(
          'Sunset Diary necesita acceso al micrófono y al reconocimiento de voz para dictar recuerdos.',
        );
        return;
      }

      final previousText = _descriptionController.text.trim();
      final locales = await _speech.locales();

      final spanishLocales = locales
          .where((locale) => locale.localeId.toLowerCase().startsWith('es'))
          .toList();

      if (spanishLocales.isEmpty) {
        _showMessage('No hay reconocimiento en español disponible.');
        return;
      }

      final spanishLocale = spanishLocales.firstWhere(
        (locale) =>
            locale.localeId.toLowerCase().startsWith('es_mx') ||
            locale.localeId.toLowerCase().startsWith('es-mx'),
        orElse: () => spanishLocales.first,
      );

      await _speech.listen(
        onResult: (result) {
          if (!mounted) return;

          final newText = result.recognizedWords;
          final separator = previousText.isEmpty ? '' : ' ';

          _descriptionController.text = '$previousText$separator$newText';

          _descriptionController.selection = TextSelection.collapsed(
            offset: _descriptionController.text.length,
          );
        },
        listenOptions: stt.SpeechListenOptions(
          localeId: spanishLocale.localeId,
        ),
      );

      if (mounted) {
        setState(() => _listening = _speech.isListening);
      }
    } catch (e) {
      _showMessage('Error al utilizar el micrófono.');
    }
  }

  Future<void> _getLocation() async {
    setState(() => _loadingLocation = true);

    try {
      final enabled = await Geolocator.isLocationServiceEnabled();

      if (!enabled) {
        await _showPermissionDialog(
          'Activa los servicios de ubicación para registrar dónde viste el atardecer.',
        );
        return;
      }

      var permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        await _showPermissionDialog(
          'Permite el acceso a tu ubicación desde los ajustes del iPhone.',
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );

      if (mounted) {
        setState(() => _position = position);
        _showMessage('Ubicación obtenida correctamente.');
      }
    } catch (e) {
      _showMessage('No se pudo obtener la ubicación.');
    } finally {
      if (mounted) {
        setState(() => _loadingLocation = false);
      }
    }
  }

  Future<void> _saveSunset() async {
    if (_saving) return;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_image == null) {
      _showMessage('Selecciona una fotografía.');
      return;
    }

    if (_position == null) {
      _showMessage('Captura tu ubicación GPS.');
      return;
    }

    setState(() => _saving = true);

    try {
      final sunset = Sunset(
        title: _titleController.text.trim(),
        place: _placeController.text.trim(),
        description: _descriptionController.text.trim(),
        imagePath: _image!.path,
        date: _date.toIso8601String(),
        latitude: _position!.latitude,
        longitude: _position!.longitude,
      );

      await DatabaseService.instance.saveSunset(sunset);

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      _showMessage('No se pudo guardar el atardecer.');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  void dispose() {
    _speech.cancel();
    _titleController.dispose();
    _placeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Nuevo atardecer',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Guarda este momento',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Cada atardecer tiene una historia que contar.',
                  style: TextStyle(color: Colors.white60),
                ),
                const SizedBox(height: 24),

                Container(
                  width: double.infinity,
                  height: 230,
                  decoration: BoxDecoration(
                    color: const Color(0xFF222C3C),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _image == null
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.wb_twilight,
                              size: 65,
                              color: Color(0xFFFFA45B),
                            ),
                            SizedBox(height: 12),
                            Text('Agrega tu fotografía'),
                          ],
                        )
                      : Image.file(
                          File(_image!.path),
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                ),

                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _selectImage(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt_outlined),
                        label: const Text('Cámara'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _selectImage(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library_outlined),
                        label: const Text('Galería'),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 25),

                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Título del atardecer',
                    prefixIcon: Icon(Icons.wb_sunny_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingresa un título';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _placeController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del lugar',
                    hintText: 'Ej. Playa Progreso',
                    prefixIcon: Icon(Icons.place_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingresa el lugar';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                TextFormField(
                  initialValue: DateFormat('dd/MM/yyyy - HH:mm').format(_date),
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Fecha y hora del registro',
                    prefixIcon: Icon(Icons.calendar_today_outlined),
                  ),
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Mi recuerdo',
                    hintText: '¿Cómo fue este atardecer?',
                    alignLabelWithHint: true,
                  ),
                ),

                const SizedBox(height: 12),

                OutlinedButton.icon(
                  onPressed: _startDictation,
                  icon: Icon(
                    _listening ? Icons.stop_circle : Icons.mic,
                    color: const Color(0xFFFFA45B),
                  ),
                  label: Text(
                    _listening ? 'Detener dictado' : 'Dictar mi recuerdo',
                  ),
                ),

                const SizedBox(height: 25),

                const Text(
                  'Ubicación del atardecer',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 12),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF222C3C),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 38,
                        color: Color(0xFFFFA45B),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _position == null
                            ? 'Ubicación aún no capturada'
                            : 'Latitud: ${_position!.latitude.toStringAsFixed(6)}\n'
                                  'Longitud: ${_position!.longitude.toStringAsFixed(6)}',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 14),
                      OutlinedButton.icon(
                        onPressed: _loadingLocation ? null : _getLocation,
                        icon: _loadingLocation
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.my_location),
                        label: Text(
                          _loadingLocation
                              ? 'Obteniendo ubicación'
                              : 'Capturar ubicación GPS',
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : _saveSunset,
                    icon: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(_saving ? 'Guardando...' : 'Guardar atardecer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFA45B),
                      foregroundColor: const Color(0xFF101827),
                      padding: const EdgeInsets.all(17),
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
