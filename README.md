# Solodev — Modern Cross-Platform Portfolio & Admin Ecosystem

Production personal portfolio and project showcase for **Solodev** (Flutter Developer & AI Designer). Built using **Flutter 3.44.9**, **Dart 3.12.2**, **Riverpod**, **GoRouter**, and **Firebase** (Auth, Firestore, Cloud Storage, Hosting).

---

## 🚀 Key Highlights & Architecture

- **Cross-Platform Parity:** Pixel-perfect adaptive layouts for Web, Android, iOS, and Desktop.
- **Brand System:** Futuristic glassmorphism with `#1565C0` vibrant electric blue, cyan neon micro-accents, deep dark charcoal backgrounds, and Google Fonts Inter typography.
- **Robust Cloud Backend:**
  - **Firestore:** Typed serialization models (`ProjectModel`, `ServiceModel`, `CertificateModel`, `AchievementModel`, `ContactMessageModel`, `SkillModel`).
  - **Security Rules (`firestore.rules`):** Strict public read constraints (`isPublished == true`), validated anonymous contact submissions, and authenticated admin-only mutations.
  - **Storage Rules (`storage.rules`):** Public read for media assets, admin upload limits (max 25MB after compression, strict MIME checking).
  - **Media Compression (`MediaCompressorService`):** Pure Dart image compression using package `image` guaranteeing zero native channel crashes across web and mobile.
- **Offline & Fallback Safety:** Fallback datasets and graceful error boundaries ensure the portfolio always displays even without active cloud connection.
- **Deep Routing (`app_router.dart`):** GoRouter with clean web URLs (`/`, `/services`, `/services/:id`, `/projects`, `/projects/:id`, `/certificates`, `/contact`, `/admin/login`, `/admin/dashboard`, `/admin/project-editor`).
- **Admin Management Portal:** Dedicated dashboard to view inbound inquiries and manage projects.

---

## 🛠 Project Structure

```
lib/
├── core/
│   ├── constants/
│   │   └── app_colors.dart
│   ├── responsive/
│   │   └── responsive_layout.dart
│   ├── routing/
│   │   └── app_router.dart
│   ├── services/
│   │   └── media_compressor_service.dart
│   ├── theme/
│   │   └── app_theme.dart
│   └── widgets/
│       ├── app_widgets.dart
│       ├── navigation_bars.dart
│       └── public_footer.dart
├── data/
│   ├── datasources/
│   │   └── portfolio_providers.dart
│   ├── models/
│   │   ├── more_models.dart
│   │   ├── project_model.dart
│   │   └── service_model.dart
│   └── repositories/
│       └── portfolio_repository.dart
├── features/
│   ├── admin/
│   │   ├── admin_dashboard_screen.dart
│   │   ├── admin_login_screen.dart
│   │   └── project_editor_screen.dart
│   ├── certificates/
│   │   └── certificates_screen.dart
│   ├── contact/
│   │   └── contact_screen.dart
│   ├── home/
│   │   ├── hero_section.dart
│   │   ├── home_screen.dart
│   │   ├── projects_cta_sections.dart
│   │   └── services_section.dart
│   ├── projects/
│   │   ├── project_detail_screen.dart
│   │   └── projects_screen.dart
│   └── services/
│       ├── service_detail_screen.dart
│       └── services_screen.dart
├── firebase_options.dart
└── main.dart
```

---

## 🏃 Getting Started

### Run locally
```bash
flutter pub get
flutter run -d chrome
```

### Build for production web
```bash
flutter build web --release
```

