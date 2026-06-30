backend/
├── prisma/
│   ├── schema.prisma
│   └── seed.js
├── src/
│   ├── config/
│   │   └── database.js
│   ├── controllers/
│   │   ├── authController.js
│   │   ├── coursController.js
│   │   ├── moduleController.js
│   │   ├── contenuController.js
│   │   ├── inscriptionController.js
│   │   ├── progressionController.js
│   │   └── notificationController.js
│   ├── middlewares/
│   │   ├── authMiddleware.js
│   │   ├── uploadMiddleware.js
│   │   └── roleMiddleware.js
│   ├── routes/
│   │   ├── authRoutes.js
│   │   ├── coursRoutes.js
│   │   ├── moduleRoutes.js
│   │   ├── contenuRoutes.js
│   │   ├── inscriptionRoutes.js
│   │   ├── progressionRoutes.js
│   │   └── notificationRoutes.js
│   ├── services/
│   │   ├── authService.js
│   │   ├── coursService.js
│   │   └── notificationService.js
│   └── app.js
├── uploads/
│   ├── videos/
│   ├── documents/
│   └── images/
├── .env
├── package.json
└── server.js




flutter_app/
├── lib/
│   ├── core/
│   │   ├── constants/
│   │   │   ├── app_colors.dart
│   │   │   ├── app_strings.dart
│   │   │   └── app_routes.dart
│   │   ├── network/
│   │   │   └── api_client.dart
│   │   └── utils/
│   │       └── helpers.dart
│   ├── data/
│   │   ├── models/
│   │   │   ├── user_model.dart
│   │   │   ├── cours_model.dart
│   │   │   ├── module_model.dart
│   │   │   └── contenu_model.dart
│   │   └── repositories/
│   │       ├── auth_repository.dart
│   │       ├── cours_repository.dart
│   │       └── progression_repository.dart
│   ├── presentation/
│   │   ├── screens/
│   │   │   ├── auth/
│   │   │   │   ├── login_screen.dart
│   │   │   │   └── register_screen.dart
│   │   │   ├── home/
│   │   │   │   └── home_screen.dart
│   │   │   ├── cours/
│   │   │   │   ├── cours_list_screen.dart
│   │   │   │   ├── cours_detail_screen.dart
│   │   │   │   └── module_screen.dart
│   │   │   ├── enseignant/
│   │   │   │   ├── dashboard_screen.dart
│   │   │   │   ├── create_cours_screen.dart
│   │   │   │   └── create_module_screen.dart
│   │   │   └── profil/
│   │   │       └── profil_screen.dart
│   │   └── widgets/
│   │       ├── cours_card.dart
│   │       ├── module_tile.dart
│   │       └── progress_bar.dart
│   └── main.dart
├── assets/
│   ├── images/
│   └── fonts/
└── pubspec.yaml