import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:aplicacion_luz/services/publicacion_service.dart';
import 'package:aplicacion_luz/models/publicacion_model.dart';

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

  @override
  void dispose() {
    _comentarioControllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final publicacionService = Provider.of<PublicacionService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Todas las Publicaciones'),
        elevation: 0,
      ),
      body: NotificationListener<ScrollNotification>(
        onNotification: (notification) => false,
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('publicaciones')
              .orderBy('fechaPublicacion', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            return ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final doc = snapshot.data!.docs[index];
                final publicacionId = doc.id;
                _comentariosExpandidos.putIfAbsent(publicacionId, () => false);
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
                  onToggleComments: () => _handleComments(publicacionId),
                );
              },
            );
          },
        ),
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

    // Actualización optimista
    setState(() {
      _localLikes[publicacionId] = !currentLikeStatus;
      _localLikesCount[publicacionId] = currentLikeStatus
          ? currentLikesCount - 1
          : currentLikesCount + 1;
    });

    try {
      await service.toggleLike(publicacionId);
    } catch (e) {
      // Revertir en caso de error
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

  const PublicacionItem({
    super.key,
    required this.doc,
    required this.publicacionId,
    required this.service,
    required this.isCommentsExpanded,
    required this.onToggleLike,
    required this.onToggleComments,
  });

  @override
  Widget build(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;
    final fecha = (data['fechaPublicacion'] as Timestamp).toDate();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(data, fecha),
          _buildContent(data),
          _buildStats(context),
          const Divider(height: 1, thickness: 1),
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
                backgroundColor: Colors.grey[200],
                child: data['esAnonimo'] == true
                    ? const Icon(Icons.person, size: 20)
                    : Text(
                        nombreUsuario.substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
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
                      ),
                    ),
                    Text(
                      DateFormat('dd MMM yyyy · HH:mm').format(fecha),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
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
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(data['contenido'] ?? '', style: const TextStyle(fontSize: 15)),
        ],
      ),
    );
  }

  Widget _buildStats(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('publicaciones')
                .doc(publicacionId)
                .snapshots(),
            builder: (context, snapshot) {
              final likesCount =
                  snapshot.data?.data()?['likesCount'] as int? ?? 0;
              return Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.thumb_up,
                      size: 14,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    likesCount.toString(),
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
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
                style: const TextStyle(fontSize: 14, color: Colors.grey),
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
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
                      color: hasLiked ? Colors.blue : Colors.grey,
                    ),
                    label: Text(
                      'Me gusta ${likesCount > 0 ? '($likesCount)' : ''}',
                      style: TextStyle(
                        color: hasLiked ? Colors.blue : Colors.grey,
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
              color: isCommentsExpanded ? Colors.blue : Colors.grey,
            ),
            label: Text(
              'Comentar',
              style: TextStyle(
                color: isCommentsExpanded ? Colors.blue : Colors.grey,
              ),
            ),
            onPressed: onToggleComments,
          ),
          TextButton.icon(
            icon: const Icon(Icons.share_outlined, color: Colors.grey),
            label: const Text(
              'Compartir',
              style: TextStyle(color: Colors.grey),
            ),
            onPressed: () {},
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
                  child: CircularProgressIndicator(),
                );
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('No hay comentarios aún'),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final comentario = snapshot.data![index];
                  final fecha = (comentario['fecha'] as Timestamp).toDate();

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.grey[200],
                      child: Text(
                        comentario['usuarioNombre']
                            .substring(0, 1)
                            .toUpperCase(),
                      ),
                    ),
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          comentario['usuarioNombre'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(comentario['contenido']),
                      ],
                    ),
                    subtitle: Text(DateFormat('dd MMM HH:mm').format(fecha)),
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
    final controller = TextEditingController();

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'Escribe un comentario...',
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: Colors.blue),
            onPressed: () async {
              final contenido = controller.text.trim();
              if (contenido.isNotEmpty) {
                await service.agregarComentario(
                  publicacionId: publicacionId,
                  contenido: contenido,
                );
                controller.clear();
              }
            },
          ),
        ],
      ),
    );
  }
}

extension on Object? {
  void operator [](String other) {}
}
