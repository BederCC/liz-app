import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfilePage extends StatelessWidget {
  final User user;

  const ProfilePage({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            CircleAvatar(
              radius: 60,
              backgroundColor: Colors.blue[100],
              child: Icon(Icons.person, size: 60, color: Colors.blue[800]),
            ),
            const SizedBox(height: 20),
            Text(
              user.email ?? 'Correo no disponible',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'Usuario desde: ${_formatDate(user.metadata.creationTime)}',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 30),
            _buildInfoCard(
              'Verificación de correo',
              user.emailVerified ? 'Verificado' : 'No verificado',
              user.emailVerified ? Icons.verified : Icons.warning,
              user.emailVerified ? Colors.green : Colors.orange,
            ),
            const SizedBox(height: 15),
            _buildInfoCard(
              'ID de usuario',
              user.uid,
              Icons.fingerprint,
              Colors.blue,
            ),
            const SizedBox(height: 15),
            if (!user.emailVerified)
              ElevatedButton(
                onPressed: () async {
                  await user.sendEmailVerification();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Correo de verificación enviado'),
                    ),
                  );
                },
                child: const Text('Verificar correo electrónico'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 5),
                Text(value, style: const TextStyle(fontSize: 16)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Fecha desconocida';
    return '${date.day}/${date.month}/${date.year}';
  }
}
