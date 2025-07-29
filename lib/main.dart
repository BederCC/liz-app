import 'dart:async';

import 'package:aplicacion_luz/pages/categorias_page.dart';
import 'package:aplicacion_luz/pages/perfil_usuario_page.dart';
import 'package:aplicacion_luz/pages/publicaciones/todas_publicaciones_page.dart';
import 'package:aplicacion_luz/pages/publicaciones_page.dart';
import 'package:aplicacion_luz/services/categoria_service.dart';
import 'package:aplicacion_luz/services/publicacion_service.dart';
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
        Provider<CategoriaService>(create: (_) => CategoriaService()),
        Provider<PublicacionService>(create: (_) => PublicacionService()),
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
          '/categorias': (context) => const CategoriasPage(),
          '/todas-publicaciones': (context) => const TodasPublicacionesPage(),
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
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.active) {
          final user = authSnapshot.data;
          if (user != null) {
            return StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('usuarios')
                  .doc(user.uid)
                  .snapshots(),
              builder: (context, userSnapshot) {
                if (userSnapshot.hasData) {
                  final userData =
                      userSnapshot.data!.data() as Map<String, dynamic>?;
                  final perfilCompleto = userData?['perfilCompleto'] ?? false;

                  _checkEmailVerification(user);
                  return ProfilePage(user: user);
                }
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              },
            );
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
      // Validación adicional del dominio
      final email = _emailController.text.trim();
      if (!email.endsWith('@khipu.edu.pe')) {
        setState(() {
          _errorMessage = 'Solo se permiten cuentas @khipu.edu.pe';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
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
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    if (!email.endsWith('@khipu.edu.pe')) {
      setState(() {
        _errorMessage = 'Solo se permiten cuentas @khipu.edu.pe';
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. Crear usuario solo en Authentication
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: email,
            password: _passwordController.text.trim(),
          )
          .timeout(const Duration(seconds: 30));

      final user = userCredential.user;
      if (user == null) throw Exception("Usuario no creado");

      // 2. Enviar email de verificación (NO crear en Firestore aún)
      await user.sendEmailVerification();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registro exitoso. Verifica tu email.'),
          duration: Duration(seconds: 5),
        ),
      );

      setState(() {
        _isLoading = false;
        _showRegisterForm = false;
      });
    } on FirebaseAuthException catch (e) {
      // Manejo de errores (igual que antes)
    } catch (e) {
      // Manejo de errores (igual que antes)
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.indigo.shade800, Colors.purple.shade600],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.lightbulb_outline,
                    size: 80,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Bienvenido',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Inicia sesión para continuar',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 40),
                  Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _emailController,
                              decoration: InputDecoration(
                                labelText: 'Correo electrónico',
                                prefixIcon: const Icon(Icons.email),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                              ),
                              validator: (value) {
                                if (value?.isEmpty ?? true)
                                  return 'Ingresa tu correo';
                                if (!value!.contains('@'))
                                  return 'Correo inválido';
                                if (!value.endsWith('@khipu.edu.pe')) {
                                  return 'Solo se permiten cuentas @khipu.edu.pe';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            if (_showRegisterForm) ...[
                              TextFormField(
                                controller: _passwordController,
                                decoration: InputDecoration(
                                  labelText: 'Contraseña',
                                  prefixIcon: const Icon(Icons.lock),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                ),
                                obscureText: true,
                                validator: (value) {
                                  if (value?.isEmpty ?? true)
                                    return 'Ingresa una contraseña';
                                  if (value!.length < 6)
                                    return 'Mínimo 6 caracteres';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),
                              TextFormField(
                                decoration: InputDecoration(
                                  labelText: 'Confirmar Contraseña',
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                ),
                                obscureText: true,
                                validator: (value) {
                                  if (value != _passwordController.text) {
                                    return 'Las contraseñas no coinciden';
                                  }
                                  return null;
                                },
                              ),
                            ] else ...[
                              TextFormField(
                                controller: _passwordController,
                                decoration: InputDecoration(
                                  labelText: 'Contraseña',
                                  prefixIcon: const Icon(Icons.lock),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
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
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.red.shade200,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      color: Colors.red.shade700,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        _errorMessage!,
                                        style: TextStyle(
                                          color: Colors.red.shade700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
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
                                      minimumSize: const Size(
                                        double.infinity,
                                        50,
                                      ),
                                      backgroundColor: Colors.purple.shade600,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      elevation: 5,
                                    ),
                                  ),
                                  const SizedBox(height: 15),
                                  TextButton(
                                    onPressed: () => setState(() {
                                      _showRegisterForm = false;
                                      _errorMessage = null;
                                    }),
                                    child: const Text(
                                      '¿Ya tienes cuenta? Inicia sesión',
                                    ),
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
                                      minimumSize: const Size(
                                        double.infinity,
                                        50,
                                      ),
                                      backgroundColor: Colors.indigo.shade600,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      elevation: 5,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Wrap(
                                    alignment: WrapAlignment.center,
                                    spacing: 12,
                                    children: [
                                      TextButton(
                                        onPressed: () => setState(() {
                                          _showRegisterForm = true;
                                          _errorMessage = null;
                                        }),
                                        child: const Text(
                                          'Crear cuenta',
                                          style: TextStyle(
                                            color: Colors.indigo,
                                          ),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: _resetPassword,
                                        child: const Text(
                                          'Recuperar contraseña',
                                          style: TextStyle(
                                            color: Colors.indigo,
                                          ),
                                        ),
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ProfilePage extends StatefulWidget {
  final User user;

  const ProfilePage({Key? key, required this.user}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isVerificationEmailSending = false;
  bool _perfilCompleto = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _checkProfileStatus();
  }

  Future<void> _checkProfileStatus() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(widget.user.uid)
          .get();

      setState(() {
        _perfilCompleto = doc.exists;
        _loading = false;
      });

      if (!_perfilCompleto && mounted) {
        _showProfileCompletionDialog();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
      }
      print('Error verificando estado del perfil: $e');
    }
  }

  void _showProfileCompletionDialog() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('¡Completa tu perfil!'),
          content: const Text(
            'Para acceder a todas las funciones de la aplicación, necesitamos que completes tu información personal.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _navigateToProfileUpdate();
              },
              child: const Text('Ir a completar perfil'),
            ),
          ],
        ),
      );
    });
  }

  void _navigateToProfileUpdate() {
    Navigator.pushNamed(context, '/perfil').then((_) {
      // Actualizar estado al regresar de editar el perfil
      _checkProfileStatus();
    });
  }

  Future<void> _sendVerificationEmail() async {
    if (_isVerificationEmailSending) return;

    setState(() => _isVerificationEmailSending = true);

    try {
      await widget.user.sendEmailVerification();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Correo de verificación enviado'),
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al enviar correo: ${e.toString()}'),
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isVerificationEmailSending = false);
      }
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Fecha desconocida';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        backgroundColor: Colors.pink.shade200,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color.fromARGB(255, 178, 178, 179),
              const Color.fromARGB(255, 249, 230, 255),
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                margin: const EdgeInsets.only(bottom: 20),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.indigo.shade100,
                        child: Icon(
                          Icons.person,
                          size: 40,
                          color: Colors.indigo.shade800,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        widget.user.email ?? 'No email',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Usuario desde: ${_formatDate(widget.user.metadata.creationTime)}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Estado de verificación de email
              Card(
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Icon(
                        widget.user.emailVerified
                            ? Icons.verified
                            : Icons.warning,
                        color: widget.user.emailVerified
                            ? Colors.green
                            : Colors.orange,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          widget.user.emailVerified
                              ? 'Correo verificado'
                              : 'Correo no verificado',
                          style: TextStyle(
                            color: widget.user.emailVerified
                                ? Colors.green
                                : Colors.orange,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (!widget.user.emailVerified) ...[
                        _isVerificationEmailSending
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : TextButton(
                                onPressed: _sendVerificationEmail,
                                child: Text(
                                  'Enviar verificación',
                                  style: TextStyle(
                                    color: Colors.indigo.shade800,
                                  ),
                                ),
                              ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Estado de completitud de perfil
              if (!_perfilCompleto) ...[
                Card(
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  color: Colors.orange.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Icon(Icons.info_outline, color: Colors.orange.shade800),
                        const SizedBox(height: 8),
                        Text(
                          'Perfil incompleto',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Debes completar tu información personal para acceder a todas las funciones de la aplicación.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _navigateToProfileUpdate,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange.shade800,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            minimumSize: const Size(double.infinity, 45),
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
                onPressed: _navigateToProfileUpdate,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: const Color.fromARGB(255, 157, 193, 255),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 3,
                ),
                child: const Text('Actualizar Datos'),
              ),
              const SizedBox(height: 15),

              // Botón de categorías
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/categorias');
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: const Color.fromARGB(255, 157, 193, 255),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 3,
                ),
                child: const Text('Ver Categorías'),
              ),
              const SizedBox(height: 15),

              // Botones condicionales
              if (_perfilCompleto) _buildEnabledFeatures(),
              if (!_perfilCompleto) _buildDisabledFeatures(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnabledFeatures() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/publicaciones');
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(0, 50),
                  backgroundColor: const Color.fromARGB(255, 214, 167, 253),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 3,
                ),
                child: const Text('Mis Publicaciones'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/todas-publicaciones');
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(0, 50),
                  backgroundColor: const Color.fromARGB(255, 214, 167, 253),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 3,
                ),
                child: const Text('Ver Publicaciones'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
      ],
    );
  }

  Widget _buildDisabledFeatures() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: AbsorbPointer(
                child: ElevatedButton(
                  onPressed: null,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 50),
                    backgroundColor: Colors.grey.shade300,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Mis Publicaciones',
                    style: TextStyle(color: Colors.grey.shade600),
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
                    backgroundColor: Colors.grey.shade300,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Ver Publicaciones',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          'Completa tu perfil para desbloquear estas funciones',
          style: TextStyle(color: Colors.white70, fontStyle: FontStyle.italic),
        ),
      ],
    );
  }
}
