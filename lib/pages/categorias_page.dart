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
        backgroundColor: Colors.pink.shade100,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.pink.shade800),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.pink.shade800),
            onPressed: _cargarCategorias,
            tooltip: 'Recargar',
          ),
        ],
      ),
      body: Container(
        color: Colors.pink.shade50,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Buscar categorías',
                  labelStyle: TextStyle(color: Colors.pink.shade600),
                  prefixIcon: Icon(Icons.search, color: Colors.pink.shade600),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(color: Colors.pink.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(color: Colors.pink.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(color: Colors.pink.shade400),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: Colors.pink.shade600),
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
                  ? Center(
                      child: CircularProgressIndicator(
                        color: Colors.pink.shade600,
                      ),
                    )
                  : categoriasFiltradas.isEmpty
                  ? Center(
                      child: Text(
                        'No se encontraron categorías',
                        style: TextStyle(
                          color: Colors.pink.shade800,
                          fontSize: 16,
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      color: Colors.pink.shade600,
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarDialogoNuevaCategoria(context),
        backgroundColor: Colors.pink.shade600,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildCategoriaItem(Categoria categoria) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(Icons.category, color: Colors.pink.shade600),
        title: Text(
          categoria.nombre,
          style: TextStyle(
            color: Colors.grey.shade800,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Creada: ${DateFormat('dd/MM/yyyy').format(categoria.fechaCreacion)}',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            if (categoria.ultimaActualizacion != null)
              Text(
                'Editada: ${DateFormat('dd/MM/yyyy').format(categoria.ultimaActualizacion!)}',
                style: TextStyle(color: Colors.grey.shade600),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit, color: Colors.pink.shade600),
              onPressed: () =>
                  _mostrarDialogoEditarCategoria(context, categoria),
            ),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.pink.shade300),
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
          backgroundColor: Colors.pink.shade50,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Text(
            'Nueva Categoría',
            style: TextStyle(color: Colors.pink.shade800),
          ),
          content: TextField(
            controller: nombreController,
            decoration: InputDecoration(
              labelText: 'Nombre de la categoría',
              labelStyle: TextStyle(color: Colors.pink.shade600),
              hintText: 'Ej: Deportes',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.pink.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.pink.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.pink.shade400),
              ),
            ),
            autofocus: true,
            style: TextStyle(color: Colors.grey.shade800),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancelar',
                style: TextStyle(color: Colors.pink.shade800),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nombreController.text.trim().isNotEmpty) {
                  Navigator.pop(context);
                  try {
                    await _categoriaService.agregarCategoria(
                      nombreController.text.trim(),
                    );
                    await _cargarCategorias();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Categoría creada'),
                        backgroundColor: Colors.pink.shade600,
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red.shade400,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink.shade600,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Crear', style: TextStyle(color: Colors.white)),
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
          backgroundColor: Colors.pink.shade50,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Text(
            'Editar Categoría',
            style: TextStyle(
              color: Colors.pink.shade800,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: TextField(
            controller: nombreController,
            decoration: InputDecoration(
              labelText: 'Nuevo nombre',
              labelStyle: TextStyle(color: Colors.pink.shade600),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.pink.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.pink.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.pink.shade400),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            autofocus: true,
            style: TextStyle(color: Colors.grey.shade800),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancelar',
                style: TextStyle(color: Colors.pink.shade800),
              ),
            ),
            ElevatedButton(
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
                      SnackBar(
                        content: const Text('Categoría actualizada'),
                        backgroundColor: Colors.pink.shade600,
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red.shade400,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink.shade600,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Guardar',
                style: TextStyle(color: Colors.white),
              ),
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
          backgroundColor: Colors.pink.shade50,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Text(
            'Confirmar Eliminación',
            style: TextStyle(
              color: Colors.pink.shade800,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            '¿Estás seguro de eliminar esta categoría? Esta acción no se puede deshacer.',
            style: TextStyle(color: Colors.grey.shade800),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancelar',
                style: TextStyle(color: Colors.pink.shade800),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  await _categoriaService.eliminarCategoria(categoriaId);
                  await _cargarCategorias();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Categoría eliminada'),
                      backgroundColor: Colors.pink.shade600,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red.shade400,
                    ),
                  );
                }
              },
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
