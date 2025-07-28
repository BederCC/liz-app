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
      body: RefreshIndicator(
        onRefresh: _refreshPublicaciones,
        child: FutureBuilder<List<Publicacion>>(
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
                final publicacion = publicaciones[index];
                return _PublicacionCard(
                  publicacion: publicacion,
                  onEdit: () => _editarPublicacion(context, publicacion),
                  onDelete: () => _eliminarPublicacion(context, publicacion.id),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _refreshPublicaciones() async {
    setState(() {});
  }

  void _navegarACrearPublicacion(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CrearPublicacionPage()),
    ).then((_) => setState(() {}));
  }

  void _editarPublicacion(BuildContext context, Publicacion publicacion) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            CrearPublicacionPage(publicacionExistente: publicacion),
      ),
    ).then((_) => setState(() {}));
  }

  Future<void> _eliminarPublicacion(
    BuildContext context,
    String publicacionId,
  ) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar publicación'),
        content: const Text(
          '¿Estás seguro de que quieres eliminar esta publicación?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        await _publicacionService.eliminarPublicacion(publicacionId);
        setState(() {});
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Publicación eliminada')));
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al eliminar: $e')));
      }
    }
  }
}

class _PublicacionCard extends StatelessWidget {
  final Publicacion publicacion;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PublicacionCard({
    required this.publicacion,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    publicacion.titulo,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: onEdit,
                ),
                IconButton(
                  icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                  onPressed: onDelete,
                ),
              ],
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
