<p align="center">
  <img src="assets/logodinpar.jpg" width="120" alt="Banten Explorer Logo">
</p>

<h1 align="center">Banten Explorer — Tourism & Navigation</h1>

<p align="center">
  <strong>Sistem Panduan Pariwisata Interaktif & Integrasi AI</strong><br>
  Smart tourism guide, AI-based interactive chat, voice navigation, and real-time mapping for Banten Province.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-%5E3.10.4-02569B?style=flat-square&logo=flutter" alt="Flutter">
  <img src="https://img.shields.io/badge/Dart-3.0-0175C2?style=flat-square&logo=dart" alt="Dart">
  <img src="https://img.shields.io/badge/Firebase-Firestore-FFCA28?style=flat-square&logo=firebase" alt="Firebase">
  <img src="https://img.shields.io/badge/Google_Maps-API-4285F4?style=flat-square&logo=googlemaps" alt="Google Maps">
  <img src="https://img.shields.io/badge/Provider-State_Management-14b8a6?style=flat-square" alt="Provider">
</p>

---

## 📋 Table of Contents

- [Overview](#-overview)
- [Tech Stack](#-tech-stack)
- [Architecture](#-architecture)
- [Features](#-features)
- [Hardware & Sensors](#-hardware--sensors)
- [Installation](#-installation)
- [Project Structure](#-project-structure)
- [Service Layer](#-service-layer)
- [Deployment](#-deployment)

---

## 🌎 Overview

**Banten Explorer** is a high-performance, cross-platform mobile application designed to digitize and enhance the tourism experience in Banten. The system integrates advanced mapping capabilities with conversational AI directly on the device.

Built strictly on Flutter with Firebase backend synchronization, the app ensures real-time responsiveness, seamless day/night visual transitions, and hands-free voice assistance for travelers.

---

## 🛠 Tech Stack

| Layer | Technology |
|-------|-----------|
| **Core Framework** | Flutter `^3.10.4`, Dart |
| **State Management** | Provider (ChangeNotifier) |
| **Backend & DB** | Firebase Core, Cloud Firestore |
| **Networking API** | Dio `^5.4.0` |
| **Mapping & Location**| Google Maps Flutter, Geolocator |
| **Voice Processing** | Speech-to-Text, Flutter TTS |
| **UI Components** | Lottie, Carousel Slider, Flutter SVG |
| **Theming** | Custom Adaptive Theme (Dark/Light mode) |

---

## 🏗 Architecture

```text
┌─────────────────────────────────────────────────────┐
│                    FRONTEND (Flutter)               │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌─────────┐ │
│  │  Splash  │ │   Home   │ │ AI Chat  │ │   Maps  │ │
│  │  Screen  │ │  Screen  │ │ Assistant│ │Explorer │ │
│  └────┬─────┘ └────┬─────┘ └────┬─────┘ └───┬─────┘ │
│       └─────────────┴───────────┴───────────┘       │
│                Provider State Management            │
├─────────────────────────────────────────────────────┤
│                    SERVICES LAYER                   │
│  ┌───────────┐ ┌─────────────┐ ┌──────────────────┐ │
│  │ API Client│ │  Hardware   │ │  Data Repository │ │
│  │   (Dio)   │ │ Speech, TTS │ │ ChatRepository   │ │
│  │           │ │ Geolocator  │ │ ThemeProvider    │ │
│  └───────────┘ └─────────────┘ └──────────────────┘ │
├─────────────────────────────────────────────────────┤
│                   BACKEND LAYER                     │
│  Firebase App initialization & Error Handling       │
│  Cloud Firestore (databaseId: 'bantenexplorer')     │
└─────────────────────────────────────────────────────┘
```

**Pattern: Clean UI / Service Separation** — UI widgets dynamically react to changes provided by decoupled business sub-services.

---

## ✨ Features

### 🤖 AI Chatbot Assistance
- **Voice Commands**: Native `speech_to_text` integration for dictating tourist queries.
- **Audio Feedback**: Text replayed to users utilizing `flutter_tts` for conversational flow.
- **Persistent Chat Context**: Chat progression is managed through `ChatProvider` connecting real-time updates via API / Firestore.

### 🗺 Interactive Map & Routing
- **Google Maps Ready**: Live customized map layers via `google_maps_flutter`.
- **GPS Telemetry**: Live coordinate retrieval handled through `geolocator` with runtime permission handling.

### 🎨 Visual & Theming System
- **Dynamic Theming**: Instant toggle between Dark and Light mode without app restart (`ThemeProvider`).
- **Premium Asset Loaders**: Animations utilizing `lottie` files and vector scaling via `flutter_svg` for crisp interface delivery.
- **Fluid Carousel**: Showcase top Banten destinations through `carousel_slider`.

---

## 🎤 Hardware & Sensors

| Plugin | Responsibility | Access Requirements |
|--------|---------------|---------------------|
| `geolocator` | Extracting latitude/longitude for POI. | `<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />` |
| `speech_to_text` | Listening to microphone audio feed. | Microhphone Access (`NSMicrophoneUsageDescription`) |
| `flutter_tts` | Synthesizing Text into dialect. | Audio background configurations |
| `url_launcher` | External route mapping / Web redirection. | `queries` element in AndroidManifest |

---

## 🚀 Installation

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`^3.10.4` up to latest stable)
- Android Studio / Xcode
- Valid Google Maps API Keys
- `google-services.json` / `GoogleService-Info.plist` attached to the specific package namespace.

### Setup Process

```bash
# 1. Clone repository
git clone https://github.com/organization/banten_explorer.git
cd banten_explorer

# 2. Fetch packages
flutter pub get

# 3. Setup Firebase Core environment
# Guarantee valid bantenexplorer database initialization 
# in Firebase Console settings.

# 4. Compile & Run for debugging
flutter run
```

---

## 📁 Project Structure

```text
lib/
├── core/
│   └── network/           # API handlers (api_client.dart)
├── data/
│   └── repositories/      # External data integrations (chat_repository_impl.dart)
├── presentation/
│   ├── providers/         # Global App States (chat_provider, theme_provider)
│   ├── screens/           # Scaffold widgets (splash_screen)
│   └── services/          # Abstracted hardware services (speech_service, tts_service)
└── main.dart              # Dependency wiring & initialization hook
```

---

## 🔌 Service Layer

Core services consumed via `MultiProvider` in the bootstrap process:

| Service | Architecture Behavior |
|---------|-----------------------|
| `ChatProvider` | Glues `ChatRepositoryImpl`, `SpeechService`, and `TtsService` under a unified interface for screens. |
| `ThemeProvider` | Tracks memory-mapped visual density and `themeMode` states across the navigation stack. |
| `FirebaseFirestore` | Bootstrapped uniquely targeting `databaseId: 'bantenexplorer'` to ensure isolated data context. |

---

## 🚢 Deployment

### Android Release
```bash
flutter build apk --release
flutter build appbundle --release
```
*Note: Ensure your `android/app/build.gradle` is signed with the appropriate release keystore and Proguard rules to protect the Maps API Key.*

### iOS Release
```bash
flutter build ipa --release
```
*Note: Requires active Apple Developer License. Review your Podfile for any deployment target minimums (typically iOS 12+).*

---

<p align="center">
  <sub>Developed & Architected for digitalizing Banten Province. Empowering local exploration.</sub>
</p>
