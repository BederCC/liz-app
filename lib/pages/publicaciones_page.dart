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
        backgroundColor: Colors.pink.shade100,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.pink.shade800),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: Colors.pink.shade800),
            onPressed: () => _navegarACrearPublicacion(context),
            tooltip: 'Crear nueva publicación',
          ),
        ],
      ),
      body: Container(
        color: Colors.pink.shade50,
        child: RefreshIndicator(
          color: Colors.pink.shade600,
          onRefresh: _refreshPublicaciones,
          child: FutureBuilder<List<Publicacion>>(
            future: _publicacionService.obtenerPublicacionesDelUsuario(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(color: Colors.pink.shade600),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error: ${snapshot.error}',
                    style: TextStyle(color: Colors.pink.shade800),
                  ),
                );
              }

              final publicaciones = snapshot.data ?? [];

              if (publicaciones.isEmpty) {
                return Center(
                  child: Text(
                    'No tienes publicaciones aún',
                    style: TextStyle(color: Colors.pink.shade800, fontSize: 16),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: publicaciones.length,
                itemBuilder: (context, index) {
                  final publicacion = publicaciones[index];
                  return _PublicacionCard(
                    publicacion: publicacion,
                    onEdit: () => _editarPublicacion(context, publicacion),
                    onDelete: () =>
                        _eliminarPublicacion(context, publicacion.id),
                  );
                },
              );
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navegarACrearPublicacion(context),
        backgroundColor: Colors.pink.shade600,
        child: const Icon(Icons.add, color: Colors.white),
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
        backgroundColor: Colors.pink.shade50,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(
          'Eliminar publicación',
          style: TextStyle(
            color: Colors.pink.shade800,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          '¿Estás seguro de que quieres eliminar esta publicación?',
          style: TextStyle(color: Colors.grey.shade800),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancelar',
              style: TextStyle(color: Colors.pink.shade800),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        await _publicacionService.eliminarPublicacion(publicacionId);
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Publicación eliminada'),
            backgroundColor: Colors.pink.shade600,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar: $e'),
            backgroundColor: Colors.red.shade400,
          ),
        );
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
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    publicacion.titulo,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.edit, size: 20, color: Colors.pink.shade600),
                  onPressed: onEdit,
                ),
                IconButton(
                  icon: Icon(
                    Icons.delete,
                    size: 20,
                    color: Colors.pink.shade300,
                  ),
                  onPressed: onDelete,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              publicacion.contenido,
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Chip(
                  backgroundColor: publicacion.esAnonimo
                      ? Colors.pink.shade100
                      : Colors.green.shade100,
                  label: Text(
                    publicacion.esAnonimo ? 'Anónimo' : 'Público',
                    style: TextStyle(
                      color: publicacion.esAnonimo
                          ? Colors.pink.shade800
                          : Colors.green.shade800,
                    ),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const Spacer(),
                Text(
                  DateFormat(
                    'dd/MM/yyyy HH:mm',
                  ).format(publicacion.fechaPublicacion),
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
