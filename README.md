<p align="center">
  <img src="mobile/assets/logodinpar.jpg" width="120" alt="Banten Explorer Logo">
</p>

<h1 align="center">Banten Explorer Monorepo — Tourism & Navigation</h1>

<p align="center">
  <strong>Sistem Panduan Pariwisata Interaktif & Integrasi AI (RAG)</strong><br>
  Smart tourism guide, AI-based interactive chat with Retrieval-Augmented Generation, voice navigation, and real-time mapping for Banten Province.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-%5E3.10.4-02569B?style=flat-square&logo=flutter" alt="Flutter">
  <img src="https://img.shields.io/badge/Dart-3.0-0175C2?style=flat-square&logo=dart" alt="Dart">
  <img src="https://img.shields.io/badge/Python-3.10+-3776AB?style=flat-square&logo=python" alt="Python">
  <img src="https://img.shields.io/badge/FastAPI-005571?style=flat-square&logo=fastapi" alt="FastAPI">
  <img src="https://img.shields.io/badge/Groq-LLM-F36F21?style=flat-square" alt="Groq Api">
</p>

---

## 📋 Table of Contents

- [Overview](#-overview)
- [Tech Stack](#-tech-stack)
- [Architecture](#-architecture)
- [Features](#-features)
- [Tourism Data (RAG Context)](#-tourism-data-rag-context)
- [Installation](#-installation)
- [Project Structure](#-project-structure)
- [Deployment](#-deployment)

---

## 🌎 Overview

**Banten Explorer** is a comprehensive monorepo project designed to digitize and enhance the tourism experience in Banten. The system integrates advanced mapping capabilities with a conversational AI agent powered by a custom backend.

- **Mobile App**: Built strictly on Flutter, ensuring real-time responsiveness, seamless day/night visual transitions, and hands-free voice assistance for travelers.
- **AI Backend**: A Python FastAPI service that implements a Retrieval-Augmented Generation (RAG) pipeline using FAISS, Sentence Transformers, and the Groq API (LLaMA 3) to provide accurate, context-aware information about Banten tourism using localized JSON data.

---

## 🛠 Tech Stack

### 📱 Mobile (Frontend)
| Layer | Technology |
|-------|-----------|
| **Core Framework** | Flutter `^3.10.4`, Dart |
| **State Management** | Provider (ChangeNotifier) |
| **Networking API** | Dio `^5.4.0` |
| **Mapping & Location**| Google Maps Flutter, Geolocator |
| **Voice Processing** | Speech-to-Text, Flutter TTS |
| **UI Components** | Lottie, Carousel Slider, Flutter SVG |

### ⚙️ Backend (AI Service)
| Layer | Technology |
|-------|-----------|
| **Core Framework** | FastAPI, Uvicorn, Python `3.10+` |
| **Vector Database** | FAISS (Facebook AI Similarity Search) |
| **Embeddings** | `sentence-transformers` (`all-MiniLM-L6-v2`) |
| **LLM Provider** | Groq API (`llama-3.3-70b-versatile`) |
| **Data Parsing** | Pydantic, JSON |

---

## 🏗 Architecture

```text
┌─────────────────────────────────────────────────────┐
│                    MOBILE (Flutter)                 │
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
│  └─────┬─────┘ └─────────────┘ └──────────────────┘ │
└────────│────────────────────────────────────────────┘
         │ HTTP/JSON
         ▼
┌─────────────────────────────────────────────────────┐
│                   BACKEND (FastAPI)                 │
│  ┌───────────┐ ┌─────────────┐ ┌──────────────────┐ │
│  │ Endpoints │ │  RAG Engine │ │   Data & Index   │ │
│  │(/chat API)│ │(Groq LLaMA) │ │(FAISS, JSON Docs)│ │
│  └───────────┘ └─────────────┘ └──────────────────┘ │
└─────────────────────────────────────────────────────┘
```

---

## ✨ Features

### 🤖 Smart AI Chatbot (RAG)
- **Natural Conversation**: AI powered by Groq's LLaMA 3.3 70B providing localized tourism recommendations, facilities, pricing, and directions.
- **Context-Aware Retrieval**: Uses FAISS semantic search and `all-MiniLM-L6-v2` embeddings to pull facts exclusively from local datasets, avoiding hallucinations.
- **Voice Commands**: Native `speech_to_text` integration for dictating tourist queries.
- **Audio Feedback**: Text replayed to users utilizing `flutter_tts` for conversational flow.

### 🗺 Interactive Map & Routing
- **Google Maps Ready**: Live customized map layers via `google_maps_flutter`.
- **Location Intent**: AI automatically detects when users need directions and plots POI data on the map via `keyword_lokasi`.

---

## 📊 Tourism Data (RAG Context)

The AI relies on a meticulously structured JSON database detailing Banten’s prime destinations (e.g., Tanjung Lesung, Pantai Carita Anyer, Sawarna, Pulau Merak Kecil).

**Data Preview Structure:**
```json
{
  "destinasi_wisata": [
    {
      "nama_lokasi": "TANJUNG LESUNG",
      "sumber_data": [
        {
          "sumber": "traveloka",
          "halaman": [
            {
              "url": "https://...",
              "maps": "https://maps.app.goo.gl/...",
              "informasi": "Tanjung Lesung Beach Hotel berada di...",
              "media": ["url_gambar_1.jpg", "url_gambar_2.jpg"]
            }
          ]
        }
      ]
    }
  ]
}
```

**Key Data Elements**:
1. **`informasi`**: Granular information on pricing, ticket fees, opening hours, facilities, historical facts, and package prices.
2. **`maps`**: Direct Google Maps coordinates.
3. **`media`**: High-quality images that the AI can dynamically return inside the chat if a user specifically requests a photo.
4. **FAISS Index (`banten_wisata.faiss`)**: Pre-vectorized chunks of this JSON to guarantee sub-second semantic queries.

---

## 🚀 Installation

### 1. Backend Setup (FastAPI + Groq)
```bash
# Navigate to the backend directory
cd backend

# Create a virtual environment (optional but recommended)
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Setup Environment Variables
# Create a .env file and add your Groq API key
echo "GROQ_API_KEY=your_groq_api_key_here" > .env

# Run the API Server
uvicorn app:app --reload --host 0.0.0.0 --port 8000
```

### 2. Mobile Setup (Flutter)
```bash
# Navigate to the mobile directory
cd mobile

# Fetch packages
flutter pub get

# Setup API Key for Google Maps in AndroidManifest.xml and AppDelegate.swift

# Compile & Run for debugging
flutter run
```

---

## 📁 Project Structure

```text
banten-explorer-monorepo/
├── backend/                  # AI API Service (FastAPI)
│   ├── app.py                # Main backend server & Groq LLM logic
│   ├── requirements.txt      # Python dependencies
│   ├── banten_wisata.faiss   # Vector indexing for similarity search
│   ├── data.json             # Raw Banten Tourism structured data
│   └── documents.json        # Pre-processed text chunks for the RAG
└── mobile/                   # Flutter Application
    ├── lib/
    │   ├── core/network/     # API handlers pointing to the Backend
    │   ├── data/             # Repositories (Chat implementation)
    │   ├── presentation/     # UI screens, widgets, State Providers
    │   └── main.dart         # Flutter entry point
    ├── android/
    └── ios/
```

---

## 🚢 Deployment

### Backend Deployment
The Python API can be easily dockerized or deployed to platforms like **Render**, **Railway**, or **Heroku**. Just ensure `uvicorn app:app --host 0.0.0.0 --port $PORT` is the launch command and the `.env` variable for `GROQ_API_KEY` is provided.

### Mobile Releases
```bash
# Android APK / AppBundle
flutter build apk --release
flutter build appbundle --release

# iOS Release (Requires Apple Developer Account)
flutter build ipa --release
```

---

<p align="center">
  <sub>Developed & Architected for digitalizing Banten Province. Empowering local exploration.</sub>
</p>
