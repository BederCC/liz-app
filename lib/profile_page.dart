import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfilePage extends StatelessWidget {
  final User user;

  const ProfilePage({super.key, required this.user});

  Future<DocumentSnapshot> _getUserData() async {
    return await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(user.uid)
        .get();
  }

  Future<void> _sendVerificationEmail(BuildContext context) async {
    try {
      await user.sendEmailVerification();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Correo de verificación enviado'),
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al enviar correo: ${e.toString()}'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Fecha desconocida';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: _getUserData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Si no existe el documento en Firestore, el perfil no está completo
        final perfilCompleto = snapshot.hasData && snapshot.data!.exists;
        final userData = perfilCompleto
            ? snapshot.data!.data() as Map<String, dynamic>
            : null;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Mi Perfil'),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () => FirebaseAuth.instance.signOut(),
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 50,
                  child: perfilCompleto && userData?['nombre'] != null
                      ? Text(
                          '${userData?['nombre'][0]}${userData?['apellido']?[0] ?? ''}',
                          style: const TextStyle(fontSize: 30),
                        )
                      : const Icon(Icons.person, size: 40),
                ),
                const SizedBox(height: 20),
                Text(
                  user.email ?? 'No email',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (perfilCompleto && userData?['nombre'] != null) ...[
                  const SizedBox(height: 5),
                  Text(
                    '${userData?['nombre']} ${userData?['apellido']}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
                const SizedBox(height: 10),
                Text(
                  'Usuario desde: ${_formatDate(user.metadata.creationTime)}',
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 30),

                // Estado de verificación
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Icon(
                          user.emailVerified ? Icons.verified : Icons.warning,
                          color: user.emailVerified
                              ? Colors.green
                              : Colors.orange,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          user.emailVerified ? 'Verificado' : 'No verificado',
                          style: TextStyle(
                            color: user.emailVerified
                                ? Colors.green
                                : Colors.orange,
                          ),
                        ),
                        if (!user.emailVerified) ...[
                          const Spacer(),
                          TextButton(
                            onPressed: () => _sendVerificationEmail(context),
                            child: const Text('Enviar verificación'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Estado de perfil
                if (!perfilCompleto) ...[
                  Card(
                    color: Colors.orange[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.orange),
                          const SizedBox(height: 8),
                          const Text(
                            'Perfil incompleto',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Debes completar tu información personal para acceder a todas las funciones de la aplicación.',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () =>
                                Navigator.pushNamed(context, '/perfil'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                            ),
                            child: const Text('Completar perfil ahora'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Botón para actualizar datos (siempre visible)
                ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/perfil'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: Colors.blueAccent,
                  ),
                  child: const Text('Actualizar Datos'),
                ),
                const SizedBox(height: 15),

                // Botones condicionales
                if (perfilCompleto) ...[
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/publicaciones');
                          },
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(0, 50),
                            backgroundColor: Colors.green,
                          ),
                          child: const Text('Mis Publicaciones'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              '/todas-publicaciones',
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(0, 50),
                            backgroundColor: const Color.fromARGB(
                              255,
                              255,
                              234,
                              114,
                            ),
                          ),
                          child: const Text('Ver Publicaciones'),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  Row(
                    children: [
                      Expanded(
                        child: AbsorbPointer(
                          child: ElevatedButton(
                            onPressed: null,
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(0, 50),
                              backgroundColor: Colors.grey[300],
                            ),
                            child: Text(
                              'Mis Publicaciones',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: AbsorbPointer(
                          child: ElevatedButton(
                            onPressed: null,
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(0, 50),
                              backgroundColor: Colors.grey[300],
                            ),
                            child: Text(
                              'Ver Publicaciones',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Completa tu perfil para desbloquear estas funciones',
                    style: TextStyle(
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
