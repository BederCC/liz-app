import 'dart:async';

import 'package:aplicacion_luz/pages/perfil_usuario_page.dart';
import 'package:aplicacion_luz/pages/publicaciones_page.dart';
import 'package:aplicacion_luz/services/user_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("Firebase inicializado correctamente");

    // Configuración de Firestore
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );

    // Verificación de conexión (opcional, puedes quitarlo en producción)
    try {
      await FirebaseFirestore.instance
          .collection('test')
          .doc('connection_test')
          .set({'timestamp': FieldValue.serverTimestamp()});
      print("Conexión a Firestore verificada correctamente");
    } catch (e) {
      print("Error al verificar conexión a Firestore: $e");
    }
  } catch (e) {
    print("Error crítico inicializando Firebase: $e");
  }

  runApp(
    MultiProvider(
      providers: [
        Provider<UserService>(create: (_) => UserService()),
        // Agrega otros providers aquí si los necesitas
      ],
      child: MaterialApp(
        // Mueve MaterialApp aquí como único punto de entrada
        title: 'Tu Aplicación',
        theme: ThemeData(primarySwatch: Colors.blue),
        home: const AuthWrapper(), // Widget que decide si mostrar login o home
        routes: {
          '/perfil': (context) => const PerfilUsuarioPage(),
          '/publicaciones': (context) => const PublicacionesPage(),
        },
        debugShowCheckedModeBanner: false,
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Este widget ahora es redundante y puede ser eliminado
    // porque ya tenemos MaterialApp en el runApp
    return MaterialApp(
      title: 'Tu Aplicación',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const AuthWrapper(),
      routes: {'/perfil': (context) => const PerfilUsuarioPage()},
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  Future<void> _checkEmailVerification(User user) async {
    try {
      if (!user.emailVerified) {
        await user.reload();
        final updatedUser = FirebaseAuth.instance.currentUser;
        if (updatedUser != null && updatedUser.emailVerified) {
          await FirebaseFirestore.instance
              .collection('usuarios')
              .doc(updatedUser.uid)
              .update({'verificado': true});
        }
      }
    } catch (e) {
      // Ignorar error específico de PigeonUserInfo
      if (!e.toString().contains('PigeonUserInfo')) {
        print("Error verificando email: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          final user = snapshot.data;
          if (user != null) {
            _checkEmailVerification(user);
            return ProfilePage(user: user);
          }
          return const LoginPage();
        }
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _showRegisterForm = false;

  Future<void> _signIn() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } on FirebaseAuthException catch (e) {
        setState(() {
          _errorMessage = e.message ?? "Error al iniciar sesión";
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate() || !mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      print("Intentando registrar usuario: $email");

      // Crear usuario en Auth directamente sin la verificación de prueba
      print("Creando usuario en Authentication...");
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      final user = userCredential.user;
      if (user == null || !mounted) return;
      print("Usuario creado en Authentication con ID: ${user.uid}");

      // Crear documento en Firestore
      try {
        print("Intentando crear usuario en Firestore...");
        await _createFirestoreUser(user.uid, email);
      } catch (e) {
        // Si falla la creación en Firestore, eliminar el usuario de Authentication
        print(
          "Error al crear usuario en Firestore, eliminando usuario de Authentication: $e",
        );
        await user.delete();
        throw Exception("Error al crear perfil de usuario: $e");
      }

      // Enviar verificación
      await user.sendEmailVerification();
      print("Email de verificación enviado a: $email");

      // Mostrar éxito
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registro exitoso. Verifica tu email.')),
      );
    } catch (e) {
      print("Error en el proceso de registro: $e");
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _createFirestoreUser(String uid, String email) async {
    try {
      await FirebaseFirestore.instance.collection('usuarios').doc(uid).set({
        'email': email,
        'nombre': '',
        'apellido': '',
        'telefono': '',
        'creado': FieldValue.serverTimestamp(),
        'verificado': false,
      });
      print("Usuario creado exitosamente en Firestore con ID: $uid");
    } catch (e) {
      print("Error crítico creando usuario en Firestore: $e");
      throw Exception("No se pudo crear el perfil de usuario en Firestore: $e");
    }
  }

  Future<void> _resetPassword() async {
    if (_emailController.text.isEmpty) {
      setState(() => _errorMessage = 'Ingresa tu correo electrónico');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Correo de recuperación enviado')),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = e.message ?? "Error al enviar correo");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Autenticación')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Correo electrónico',
                    prefixIcon: Icon(Icons.email),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Ingresa tu correo';
                    if (!value!.contains('@')) return 'Correo inválido';
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                if (_showRegisterForm) ...[
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Contraseña',
                      prefixIcon: Icon(Icons.lock),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value?.isEmpty ?? true)
                        return 'Ingresa una contraseña';
                      if (value!.length < 6) return 'Mínimo 6 caracteres';
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Confirmar Contraseña',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value != _passwordController.text)
                        return 'Las contraseñas no coinciden';
                      return null;
                    },
                  ),
                ] else ...[
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Contraseña',
                      prefixIcon: Icon(Icons.lock),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value?.isEmpty ?? true)
                        return 'Ingresa tu contraseña';
                      return null;
                    },
                  ),
                ],
                if (_errorMessage != null) ...[
                  const SizedBox(height: 15),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
                const SizedBox(height: 25),
                if (_isLoading)
                  const CircularProgressIndicator()
                else if (_showRegisterForm)
                  Column(
                    children: [
                      ElevatedButton(
                        onPressed: _register,
                        child: const Text('Registrarse'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                        ),
                      ),
                      TextButton(
                        onPressed: () => setState(() {
                          _showRegisterForm = false;
                          _errorMessage = null;
                        }),
                        child: const Text('¿Ya tienes cuenta?'),
                      ),
                    ],
                  )
                else
                  Column(
                    children: [
                      ElevatedButton(
                        onPressed: _signIn,
                        child: const Text('Iniciar Sesión'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                        ),
                      ),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 12,
                        children: [
                          TextButton(
                            onPressed: () => setState(() {
                              _showRegisterForm = true;
                              _errorMessage = null;
                            }),
                            child: const Text('Crear cuenta'),
                          ),
                          TextButton(
                            onPressed: _resetPassword,
                            child: const Text('Recuperar contraseña'),
                          ),
                        ],
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ProfilePage extends StatelessWidget {
  final User user;

  const ProfilePage({super.key, required this.user});

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

  @override
  Widget build(BuildContext context) {
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
            CircleAvatar(radius: 50, child: Icon(Icons.person, size: 40)),
            const SizedBox(height: 20),
            Text(
              user.email ?? 'No email',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'Usuario desde: ${_formatDate(user.metadata.creationTime)}',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 30),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Icon(
                      user.emailVerified ? Icons.verified : Icons.warning,
                      color: user.emailVerified ? Colors.green : Colors.orange,
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
            // Botón para actualizar datos
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/perfil');
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(
                        0,
                        50,
                      ), // Alto fijo, ancho flexible
                      backgroundColor: Colors.blueAccent,
                    ),
                    child: const Text('Actualizar Datos'),
                  ),
                ),
                const SizedBox(width: 10),
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
              ],
            ),

            const SizedBox(height: 20),
            if (!user.emailVerified)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Text(
                  'Por favor verifica tu correo electrónico para acceder a todas las funciones.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.blue),
                ),
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
