---

# Aplicación

---

Aplicación móvil desarrollada con **Flutter** y **Firebase** para crear una plataforma de comunicación y compartir publicaciones.

## 👨‍💻 Desarrollador

---

-   **Autor:** **[Beder Casa Condori](https://www.linkedin.com/in/beder-danilo-casa-condori-85520217b/)**
-   **Ecosistema:** **[VoltoraDevs](https://voltoradevs.tech)**

## 📝 Descripción

---

Es una plataforma que permite a los usuarios registrarse, iniciar sesión, crear publicaciones, comentar y dar "me gusta" a las publicaciones de otros usuarios. La aplicación utiliza Firebase como backend para la autenticación de usuarios y almacenamiento de datos.

## 🛠️ Tecnologías utilizadas

---

-   ![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
-   ![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black) (Authentication, Cloud Firestore)
-   🧩 **Provider** (para gestión de estado)

## ✨ Características principales

---

-   🔑 Autenticación de usuarios (registro, inicio de sesión, recuperación de contraseña).
-   ✍️ Creación y visualización de publicaciones.
-   ❤️ Sistema de "me gusta" para publicaciones.
-   💬 Comentarios en publicaciones.
-   👤 Perfil de usuario personalizable.
-   🏷️ Categorización de publicaciones.

## 📂 Estructura del proyecto

---
```
├── .gitignore
├── .metadata
├── README.md
├── analysis_options.yaml
├── android             # Configuración específica para Android
├── firebase.json
├── ios                 # Configuración específica para iOS
├── lib                 # Código fuente principal
│   ├── firebase_options.dart
│   ├── main.dart       # Punto de entrada de la aplicación
│   ├── models          # Modelos de datos
│   │   ├── categoria_model.dart
│   │   ├── publicacion_model.dart
│   │   └── usuario_model.dart
│   ├── pages           # Pantallas de la aplicación
│   │   ├── categorias_page.dart
│   │   ├── perfil_usuario_page.dart
│   │   ├── publicaciones
│   │   └── publicaciones_page.dart
│   ├── profile_page.dart
│   └── services        # Servicios para interactuar con Firebase
│       ├── categoria_service.dart
│       ├── publicacion_service.dart
│       └── user_service.dart
├── linux               # Configuración específica para Linux
├── macos               # Configuración específica para macOS
├── pubspec.lock
├── pubspec.yaml        # Dependencias del proyecto
├── test                # Pruebas
├── web                 # Configuración específica para Web
└── windows             # Configuración específica para Windows
```
## Instalación

---

1.  Clona este repositorio.
2.  Ejecuta `flutter pub get` para instalar las dependencias.
3.  Configura tu proyecto de Firebase y actualiza el archivo `firebase_options.dart` con tus credenciales.
4.  Ejecuta la aplicación con `flutter run`.

## Funcionalidades principales

---

### Sistema de autenticación

La aplicación utiliza **Firebase Authentication** para gestionar el registro e inicio de sesión de usuarios. Los datos de los usuarios se almacenan en Firestore en la colección 'usuarios'.

### Sistema de publicaciones

Los usuarios pueden crear publicaciones que se almacenan en la colección 'publicaciones' de Firestore. Cada publicación puede tener una categoría, título, contenido y puede ser anónima o no.

### Sistema de reacciones (likes)

Los usuarios pueden dar "me gusta" a las publicaciones. Las reacciones se almacenan en la colección 'reacciones' de Firestore, donde cada documento contiene el ID de la publicación, el ID del usuario, la fecha y el tipo de reacción.

### Sistema de comentarios

Los usuarios pueden comentar en las publicaciones. Los comentarios se almacenan en la colección 'comentarios' de Firestore.

## Licencia

---

Este proyecto está bajo la **licencia MIT**. Ver el archivo `LICENSE` para más detalles.