import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:aplicacion_luz/models/categoria_model.dart';
import 'package:aplicacion_luz/services/categoria_service.dart';

class CategoriasPage extends StatefulWidget {
  const CategoriasPage({super.key});

  @override
  State<CategoriasPage> createState() => _CategoriasPageState();
}

class _CategoriasPageState extends State<CategoriasPage> {
  late final CategoriaService _categoriaService;
  List<Categoria> _categorias = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _categoriaService = Provider.of<CategoriaService>(context, listen: false);
    _cargarCategorias();
  }

  Future<void> _cargarCategorias() async {
    setState(() => _isLoading = true);
    try {
      final categorias = await _categoriaService.obtenerCategorias();
      setState(() => _categorias = categorias);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al cargar categorías: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<Categoria> _filtrarCategorias() {
    if (_searchController.text.isEmpty) {
      return _categorias;
    }
    return _categorias
        .where(
          (categoria) => categoria.nombre.toLowerCase().contains(
            _searchController.text.toLowerCase(),
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final categoriasFiltradas = _filtrarCategorias();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categorías'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarCategorias,
            tooltip: 'Recargar',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Buscar categorías',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
              ),
              onChanged: (value) => setState(() {}),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : categoriasFiltradas.isEmpty
                ? const Center(child: Text('No se encontraron categorías'))
                : RefreshIndicator(
                    onRefresh: _cargarCategorias,
                    child: ListView.builder(
                      itemCount: categoriasFiltradas.length,
                      itemBuilder: (context, index) {
                        final categoria = categoriasFiltradas[index];
                        return _buildCategoriaItem(categoria);
                      },
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarDialogoNuevaCategoria(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCategoriaItem(Categoria categoria) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 2,
      child: ListTile(
        leading: const Icon(Icons.category, color: Colors.blue),
        title: Text(categoria.nombre),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Creada: ${DateFormat('dd/MM/yyyy').format(categoria.fechaCreacion)}',
            ),
            if (categoria.ultimaActualizacion != null)
              Text(
                'Editada: ${DateFormat('dd/MM/yyyy').format(categoria.ultimaActualizacion!)}',
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.orange),
              onPressed: () =>
                  _mostrarDialogoEditarCategoria(context, categoria),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () =>
                  _mostrarDialogoConfirmarEliminacion(context, categoria.id),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _mostrarDialogoNuevaCategoria(BuildContext context) async {
    final nombreController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Nueva Categoría'),
          content: TextField(
            controller: nombreController,
            decoration: const InputDecoration(
              labelText: 'Nombre de la categoría',
              hintText: 'Ej: Deportes',
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                if (nombreController.text.trim().isNotEmpty) {
                  Navigator.pop(context);
                  try {
                    await _categoriaService.agregarCategoria(
                      nombreController.text.trim(),
                    );
                    await _cargarCategorias();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Categoría creada')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                }
              },
              child: const Text('Crear'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _mostrarDialogoEditarCategoria(
    BuildContext context,
    Categoria categoria,
  ) async {
    final nombreController = TextEditingController(text: categoria.nombre);

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Editar Categoría'),
          content: TextField(
            controller: nombreController,
            decoration: const InputDecoration(labelText: 'Nuevo nombre'),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                if (nombreController.text.trim().isNotEmpty) {
                  Navigator.pop(context);
                  try {
                    await _categoriaService.actualizarCategoria(
                      categoria.id,
                      nombreController.text.trim(),
                    );
                    await _cargarCategorias();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Categoría actualizada')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _mostrarDialogoConfirmarEliminacion(
    BuildContext context,
    String categoriaId,
  ) async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirmar Eliminación'),
          content: const Text(
            '¿Estás seguro de eliminar esta categoría? Esta acción no se puede deshacer.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  await _categoriaService.eliminarCategoria(categoriaId);
                  await _cargarCategorias();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Categoría eliminada')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              },
              child: const Text(
                'Eliminar',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
