import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/sunset.dart';
import '../services/database_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Sunset>> _sunsets;

  @override
  void initState() {
    super.initState();
    _loadSunsets();
  }

  void _loadSunsets() {
    _sunsets = DatabaseService.instance.getSunsets();
  }

  Future<void> _newSunset() async {
    final saved = await Navigator.pushNamed(context, '/new');

    if (saved == true && mounted) {
      setState(() {
        _loadSunsets();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Atardecer guardado correctamente!')),
      );
    }
  }

  Future<void> _openDetail(Sunset sunset) async {
    final changed = await Navigator.pushNamed(
      context,
      '/detail',
      arguments: sunset,
    );

    if (changed == true && mounted) {
      setState(() {
        _loadSunsets();
      });
    }
  }

  String _formatDate(String date) {
    try {
      return DateFormat('dd/MM/yyyy').format(DateTime.parse(date));
    } catch (e) {
      return date;
    }
  }

  Widget _emptyGallery() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 44),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2738),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.landscape_outlined,
            size: 75,
            color: Color(0xFFFFAA73),
          ),
          const SizedBox(height: 20),
          const Text(
            'Tu historia comienza aquí',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            'Todavía no tienes atardeceres guardados. Captura tu primer recuerdo.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white60),
          ),
          const SizedBox(height: 25),
          ElevatedButton.icon(
            onPressed: _newSunset,
            icon: const Icon(Icons.add),
            label: const Text('Mi primer atardecer'),
          ),
        ],
      ),
    );
  }

  Widget _sunsetCard(Sunset sunset) {
    return Card(
      color: const Color(0xFF1C2738),
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: () => _openDetail(sunset),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: 'sunset_${sunset.id}',
              child: Image.file(
                File(sunset.imagePath),
                height: 220,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const SizedBox(
                    height: 220,
                    child: Center(
                      child: Icon(Icons.broken_image_outlined, size: 55),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sunset.title,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                        Icons.place_outlined,
                        size: 19,
                        color: Color(0xFFFFA45B),
                      ),
                      const SizedBox(width: 6),
                      Expanded(child: Text(sunset.place)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 18,
                        color: Color(0xFFFFA45B),
                      ),
                      const SizedBox(width: 8),
                      Text(_formatDate(sunset.date)),
                      const Spacer(),
                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Color(0xFFFFA45B),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Sunset Diary',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: _newSunset,
            icon: const Icon(Icons.add_a_photo_outlined),
            tooltip: 'Nuevo atardecer',
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: const Color(0xFF192334),
        child: SafeArea(
          child: Column(
            children: [
              const UserAccountsDrawerHeader(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFFFF9B54),
                      Color(0xFFB54B75),
                      Color(0xFF41366D),
                    ],
                  ),
                ),
                accountName: Text(
                  'Sunset Diary',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                accountEmail: Text('Tus mejores momentos'),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: Colors.white24,
                  child: Icon(Icons.wb_twilight, color: Colors.white, size: 32),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Mis atardeceres'),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.add_circle_outline),
                title: const Text('Nuevo atardecer'),
                onTap: () {
                  Navigator.pop(context);
                  _newSunset();
                },
              ),
              const Divider(),
              const ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('Sunset Diary'),
                subtitle: Text('Tu diario de atardeceres'),
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: FutureBuilder<List<Sunset>>(
          future: _sunsets,
          builder: (context, snapshot) {
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFFFA45B),
                        Color(0xFFDD6678),
                        Color(0xFF6F488A),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.wb_twilight, size: 46, color: Colors.white),
                      SizedBox(height: 22),
                      Text(
                        'Colecciona momentos,\nno solamente fotografías.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Guarda los colores, lugares y recuerdos de cada atardecer.',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Mis atardeceres',
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Tu colección de momentos especiales',
                  style: TextStyle(color: Colors.white60),
                ),
                const SizedBox(height: 25),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const Center(child: CircularProgressIndicator())
                else if (snapshot.hasError)
                  const Center(
                    child: Text('No se pudieron cargar los atardeceres.'),
                  )
                else if (!snapshot.hasData || snapshot.data!.isEmpty)
                  _emptyGallery()
                else
                  ...snapshot.data!.map(_sunsetCard),
                const SizedBox(height: 20),
              ],
            );
          },
        ),
      ),
    );
  }
}
