import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:aplicacion_luz/services/publicacion_service.dart';
import 'package:aplicacion_luz/services/categoria_service.dart';
import 'package:aplicacion_luz/models/publicacion_model.dart';
import 'package:aplicacion_luz/models/categoria_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TodasPublicacionesPage extends StatefulWidget {
  const TodasPublicacionesPage({super.key});

  @override
  State<TodasPublicacionesPage> createState() => _TodasPublicacionesPageState();
}

class _TodasPublicacionesPageState extends State<TodasPublicacionesPage> {
  final Map<String, bool> _comentariosExpandidos = {};
  final Map<String, TextEditingController> _comentarioControllers = {};
  final Map<String, bool> _localLikes = {};
  final Map<String, int> _localLikesCount = {};
  int _selectedIndex = 2;

  String? _categoriaSeleccionada;
  List<Categoria> _categorias = [];
  late CategoriaService _categoriaService;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _categoriaService = Provider.of<CategoriaService>(context, listen: false);
    _cargarCategorias();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.popAndPushNamed(context, '/perfil');
        break;
      case 1:
        Navigator.popAndPushNamed(context, '/publicaciones');
        break;
      case 2:
        Navigator.popAndPushNamed(context, '/todas-publicaciones');
        break;
      case 3:
        FirebaseAuth.instance.signOut();
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
        break;
    }
  }

  Future<void> _cargarCategorias() async {
    final categorias = await _categoriaService.obtenerCategorias();
    setState(() {
      _categorias = categorias;
    });
  }

  @override
  void dispose() {
    _comentarioControllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final publicacionService = Provider.of<PublicacionService>(context);

    Stream<QuerySnapshot> getPublicacionesStream() {
      if (_categoriaSeleccionada == null) {
        return FirebaseFirestore.instance
            .collection('publicaciones')
            .orderBy('fechaPublicacion', descending: true)
            .snapshots();
      } else {
        return FirebaseFirestore.instance
            .collection('publicaciones')
            .where('categoriaId', isEqualTo: _categoriaSeleccionada)
            .orderBy('fechaPublicacion', descending: true)
            .snapshots();
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Todas las Publicaciones',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Container(
        color: Colors.white,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _categoriaSeleccionada,
                      decoration: InputDecoration(
                        labelText: 'Filtrar por Categoría',
                        labelStyle: const TextStyle(color: Colors.black),
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.black),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                            color: Colors.black,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      dropdownColor: Colors.white,
                      style: const TextStyle(color: Colors.black),
                      icon: const Icon(
                        Icons.arrow_drop_down,
                        color: Colors.black,
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('Todas las categorías'),
                        ),
                        ..._categorias.map((categoria) {
                          return DropdownMenuItem(
                            value: categoria.id,
                            child: Text(categoria.nombre),
                          );
                        }).toList(),
                      ],
                      onChanged: (String? newValue) {
                        setState(() {
                          _categoriaSeleccionada = newValue;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: NotificationListener<ScrollNotification>(
                onNotification: (notification) => false,
                child: StreamBuilder<QuerySnapshot>(
                  stream: getPublicacionesStream(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.black),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        final doc = snapshot.data!.docs.elementAt(index);
                        final publicacionId = doc.id;
                        _comentariosExpandidos.putIfAbsent(
                          publicacionId,
                          () => false,
                        );
                        _comentarioControllers.putIfAbsent(
                          publicacionId,
                          () => TextEditingController(),
                        );

                        return PublicacionItem(
                          key: ValueKey(publicacionId),
                          doc: doc,
                          publicacionId: publicacionId,
                          service: publicacionService,
                          isCommentsExpanded:
                              _comentariosExpandidos[publicacionId] ?? false,
                          onToggleLike: () =>
                              _handleLike(publicacionService, publicacionId),
                          onToggleComments: () =>
                              _handleComments(publicacionId),
                          comentarioController:
                              _comentarioControllers[publicacionId]!,
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
          // BottomNavigationBarItem(
          //   icon: Icon(Icons.category),
          //   label: 'Categorías',
          // ),
          BottomNavigationBarItem(
            icon: Icon(Icons.my_library_books),
            label: 'Mis Publicaciones',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Todas'),
          BottomNavigationBarItem(icon: Icon(Icons.logout), label: 'Salir'),
        ],
      ),
    );
  }

  Future<void> _handleLike(
    PublicacionService service,
    String publicacionId,
  ) async {
    final currentLikeStatus =
        _localLikes[publicacionId] ?? await service.hasUserLiked(publicacionId);
    final currentLikesCount =
        _localLikesCount[publicacionId] ??
        await service.getLikesCount(publicacionId);

    setState(() {
      _localLikes[publicacionId] = !currentLikeStatus;
      _localLikesCount[publicacionId] = currentLikeStatus
          ? (currentLikesCount ?? 0) - 1
          : (currentLikesCount ?? 0) + 1;
    });

    try {
      await service.toggleLike(publicacionId);
    } catch (e) {
      setState(() {
        _localLikes[publicacionId] = currentLikeStatus;
        _localLikesCount[publicacionId] = currentLikesCount;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al actualizar like: $e')));
    }
  }

  void _handleComments(String publicacionId) {
    setState(() {
      _comentariosExpandidos[publicacionId] =
          !(_comentariosExpandidos[publicacionId] ?? false);
    });
  }
}

class PublicacionItem extends StatelessWidget {
  final DocumentSnapshot doc;
  final String publicacionId;
  final PublicacionService service;
  final bool isCommentsExpanded;
  final VoidCallback onToggleLike;
  final VoidCallback onToggleComments;
  final TextEditingController comentarioController;

  const PublicacionItem({
    super.key,
    required this.doc,
    required this.publicacionId,
    required this.service,
    required this.isCommentsExpanded,
    required this.onToggleLike,
    required this.onToggleComments,
    required this.comentarioController,
  });

  @override
  Widget build(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;
    final fecha = (data['fechaPublicacion'] as Timestamp).toDate();
    final imagenUrl = data['imagenUrl'] as String?;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(data, fecha),
          _buildContent(data),
          if (imagenUrl != null && imagenUrl.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  image: DecorationImage(
                    image: NetworkImage(imagenUrl),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          _buildStats(context),
          const Divider(height: 1, thickness: 1, color: Colors.grey),
          _buildActions(context),
          if (isCommentsExpanded) _buildCommentsSection(),
        ],
      ),
    );
  }

  Widget _buildHeader(Map<String, dynamic> data, DateTime fecha) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('usuarios')
          .doc(data['usuarioId'])
          .get(),
      builder: (context, userSnapshot) {
        final nombreUsuario = data['esAnonimo'] == true
            ? 'Anónimo'
            : (userSnapshot.data?.data() as Map<String, dynamic>?)?['nombre'] ??
                  'Usuario';

        return Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.grey.shade200,
                child: data['esAnonimo'] == true
                    ? const Icon(Icons.person, size: 20, color: Colors.black)
                    : Text(
                        nombreUsuario.substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nombreUsuario,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      DateFormat('dd MMM yyyy · HH:mm').format(fecha),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContent(Map<String, dynamic> data) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data['titulo'] ?? 'Sin título',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            data['contenido'] ?? '',
            style: const TextStyle(fontSize: 15, color: Colors.black),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildStats(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          StreamBuilder<int>(
            stream: service.getLikesCountStream(publicacionId),
            builder: (context, snapshot) {
              final likesCount = snapshot.data ?? 0;
              return Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.thumb_up,
                      size: 14,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    likesCount.toString(),
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ],
              );
            },
          ),
          const Spacer(),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('comentarios')
                .where('publicacionId', isEqualTo: publicacionId)
                .snapshots(),
            builder: (context, snapshot) {
              final commentCount = snapshot.data?.docs.length ?? 0;
              return Text(
                '$commentCount comentarios',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('publicaciones')
                .doc(publicacionId)
                .snapshots(),
            builder: (context, snapshot) {
              final likesCount =
                  snapshot.data?.data()?['likesCount'] as int? ?? 0;
              return StreamBuilder<bool>(
                stream: service.hasUserLikedStream(publicacionId),
                builder: (context, likeSnapshot) {
                  final hasLiked = likeSnapshot.data ?? false;
                  return TextButton.icon(
                    icon: Icon(
                      hasLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                      color: hasLiked ? Colors.black : Colors.grey,
                    ),
                    label: Text(
                      'Me gusta ${likesCount > 0 ? '($likesCount)' : ''}',
                      style: TextStyle(
                        color: hasLiked ? Colors.black : Colors.grey,
                      ),
                    ),
                    onPressed: onToggleLike,
                  );
                },
              );
            },
          ),
          TextButton.icon(
            icon: Icon(
              isCommentsExpanded
                  ? Icons.mode_comment
                  : Icons.mode_comment_outlined,
              color: isCommentsExpanded ? Colors.black : Colors.grey,
            ),
            label: Text(
              'Comentar',
              style: TextStyle(
                color: isCommentsExpanded ? Colors.black : Colors.grey,
              ),
            ),
            onPressed: onToggleComments,
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          FutureBuilder<List<Map<String, dynamic>>>(
            future: service.obtenerComentarios(publicacionId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(color: Colors.black),
                );
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'No hay comentarios aún',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final comentario = snapshot.data!.elementAt(index);
                  final fecha = (comentario['fecha'] as Timestamp).toDate();

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.grey.shade200,
                      child: Text(
                        comentario['usuarioNombre']
                            .substring(0, 1)
                            .toUpperCase(),
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          comentario['usuarioNombre'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          comentario['contenido'],
                          style: const TextStyle(color: Colors.black),
                        ),
                      ],
                    ),
                    subtitle: Text(
                      DateFormat('dd MMM HH:mm').format(fecha),
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  );
                },
              );
            },
          ),
          _buildCommentInput(),
        ],
      ),
    );
  }

  Widget _buildCommentInput() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: comentarioController,
              decoration: InputDecoration(
                hintText: 'Escribe un comentario...',
                hintStyle: TextStyle(color: Colors.grey.shade600),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: Colors.black),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: Colors.black),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: Colors.black),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              style: const TextStyle(color: Colors.black),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: Colors.black,
            radius: 20,
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white, size: 16),
              onPressed: () async {
                final contenido = comentarioController.text.trim();
                if (contenido.isNotEmpty) {
                  await service.agregarComentario(
                    publicacionId: publicacionId,
                    contenido: contenido,
                  );
                  comentarioController.clear();
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

extension on Object? {
  void operator [](String other) {}
}
