import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aplicacion_luz/services/categoria_service.dart';
import 'package:aplicacion_luz/services/publicacion_service.dart';
import 'package:aplicacion_luz/models/categoria_model.dart';
import 'package:aplicacion_luz/models/publicacion_model.dart';

class CrearPublicacionPage extends StatefulWidget {
  final Publicacion? publicacionExistente;

  const CrearPublicacionPage({super.key, this.publicacionExistente});

  @override
  State<CrearPublicacionPage> createState() => _CrearPublicacionPageState();
}

class _CrearPublicacionPageState extends State<CrearPublicacionPage> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _contenidoController = TextEditingController();
  String? _categoriaSeleccionada;
  bool _esAnonimo = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.publicacionExistente != null) {
      _tituloController.text = widget.publicacionExistente!.titulo;
      _contenidoController.text = widget.publicacionExistente!.contenido;
      _categoriaSeleccionada = widget.publicacionExistente!.categoriaId;
      _esAnonimo = widget.publicacionExistente!.esAnonimo;
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriaService = Provider.of<CategoriaService>(
      context,
      listen: false,
    );
    final publicacionService = Provider.of<PublicacionService>(
      context,
      listen: false,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.publicacionExistente == null
              ? 'Nueva Publicación'
              : 'Editar Publicación',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                FutureBuilder<List<Categoria>>(
                  future: categoriaService.obtenerCategorias(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    }

                    final categorias = snapshot.data ?? [];

                    return DropdownButtonFormField<String>(
                      value: _categoriaSeleccionada,
                      hint: const Text('Selecciona una categoría'),
                      items: categorias.map((categoria) {
                        return DropdownMenuItem<String>(
                          value: categoria.id,
                          child: Text(categoria.nombre),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _categoriaSeleccionada = value;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Debes seleccionar una categoría';
                        }
                        return null;
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _tituloController,
                  decoration: const InputDecoration(
                    labelText: 'Título',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingresa un título';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _contenidoController,
                  decoration: const InputDecoration(
                    labelText: 'Contenido',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 5,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingresa el contenido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Publicación anónima'),
                  value: _esAnonimo,
                  onChanged: (value) {
                    setState(() {
                      _esAnonimo = value;
                    });
                  },
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () => _crearOActualizarPublicacion(
                          context,
                          publicacionService,
                        ),
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : Text(
                          widget.publicacionExistente == null
                              ? 'Publicar'
                              : 'Actualizar',
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _crearOActualizarPublicacion(
    BuildContext context,
    PublicacionService service,
  ) async {
    if (_formKey.currentState!.validate() && _categoriaSeleccionada != null) {
      setState(() => _isLoading = true);

      try {
        if (widget.publicacionExistente == null) {
          await service.crearPublicacion(
            categoriaId: _categoriaSeleccionada!,
            titulo: _tituloController.text,
            contenido: _contenidoController.text,
            esAnonimo: _esAnonimo,
          );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Publicación creada con éxito')),
          );
        } else {
          await service.actualizarPublicacion(
            publicacionId: widget.publicacionExistente!.id,
            categoriaId: _categoriaSeleccionada!,
            titulo: _tituloController.text,
            contenido: _contenidoController.text,
            esAnonimo: _esAnonimo,
          );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Publicación actualizada con éxito')),
          );
        }

        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _contenidoController.dispose();
    super.dispose();
  }
}
