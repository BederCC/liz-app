import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aplicacion_luz/models/publicacion_model.dart';
import 'package:aplicacion_luz/services/publicacion_service.dart';
import 'package:aplicacion_luz/pages/publicaciones/crear_publicacion_page.dart';
import 'package:intl/intl.dart';

class PublicacionesPage extends StatefulWidget {
  const PublicacionesPage({super.key});

  @override
  State<PublicacionesPage> createState() => _PublicacionesPageState();
}

class _PublicacionesPageState extends State<PublicacionesPage> {
  late final PublicacionService _publicacionService;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _publicacionService = Provider.of<PublicacionService>(
      context,
      listen: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Publicaciones'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _navegarACrearPublicacion(context),
          ),
        ],
      ),
      body: FutureBuilder<List<Publicacion>>(
        future: _publicacionService.obtenerPublicacionesDelUsuario(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final publicaciones = snapshot.data ?? [];

          if (publicaciones.isEmpty) {
            return const Center(child: Text('No tienes publicaciones aún'));
          }

          return ListView.builder(
            itemCount: publicaciones.length,
            itemBuilder: (context, index) {
              return _PublicacionCard(publicacion: publicaciones[index]);
            },
          );
        },
      ),
    );
  }

  void _navegarACrearPublicacion(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CrearPublicacionPage()),
    );
  }
}

class _PublicacionCard extends StatelessWidget {
  final Publicacion publicacion;

  const _PublicacionCard({required this.publicacion});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              publicacion.titulo,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(publicacion.contenido),
            const SizedBox(height: 8),
            Row(
              children: [
                Chip(
                  label: Text(publicacion.esAnonimo ? 'Anónimo' : 'Público'),
                ),
                const Spacer(),
                Text(
                  DateFormat(
                    'dd/MM/yyyy HH:mm',
                  ).format(publicacion.fechaPublicacion),
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
