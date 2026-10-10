Learnova — AI-Powered Learning Platform

Learnova is an AI-powered educational application built with Flutter and Python to support interactive learning, personalized assessments, AI-assisted explanations, and student progress tracking.

The platform combines a mobile learning interface with backend services for AI assistance, retrieval-augmented generation (RAG), assessment processing, and educational content retrieval.

Overview

Learnova aims to make learning more interactive and personalized through structured learning content, assessments, AI-generated explanations, progress analytics, and virtual science practicals.

Key Modules

AI Assistant: AI-assisted educational question answering.

Chapters and Topics: Organized learning content.

Assessment: Student assessments and evaluation.

Test Series: Test-taking and result screens.

Progress Tracking: Subject performance, topic performance, trends, and recent tests.

Explanation Module: Dedicated screen for learning explanations.

Dream Lab: Interactive chemistry and physics practical experiences.

User Accounts: Login, signup, email verification, and profile screens.

Admin Dashboard: An administrative interface.

Technology Stack

Component

Technology

Mobile application

Flutter, Dart

Backend API

Python

Authentication

Firebase Authentication

Database

Cloud Firestore

File storage

Firebase Storage

AI retrieval pipeline

RAG

Vector storage

Qdrant integration

Text embeddings

Python embedding module

Speech input

Speech-to-Text

Voice output

Flutter TTS

Video playback

Video Player

Markdown rendering

Flutter Markdown

UI animations

Flutter Animate

The RAG components and Qdrant integration are present in the project structure. The specific models, deployment configuration, and production readiness should be documented after verification.

System Architecture

flowchart TD
U["Student"] --> APP["Flutter Mobile Application"]

    APP --> AUTH["Authentication and Profile"]
    APP --> LEARN["Chapters and Topics"]
    APP --> ASSESS["Assessment and Test Series"]
    APP --> PROGRESS["Progress Dashboard"]
    APP --> LAB["Dream Lab"]
    APP --> AI["AI Assistant"]

    AUTH --> FB["Firebase Services"]
    FB --> FIREAUTH["Firebase Authentication"]
    FB --> DB["Cloud Firestore"]
    FB --> STORAGE["Firebase Storage"]

    AI --> API["Python Backend"]
    API --> RAG["RAG Pipeline"]
    RAG --> RET["Retriever"]
    RET --> VDB["Qdrant Vector Store"]
    RAG --> CONTEXT["Context Builder"]
    CONTEXT --> API

AI Assistant and RAG Workflow

flowchart TD
A["Student Question"] --> B["Flutter AI Assistant"]
B --> C["Python Backend"]
C --> D["Prepare Retrieval Query"]
D --> E["Retrieve Relevant Content"]
E --> F["Build Context"]
F --> G["Generate or Prepare Answer"]
G --> H["Return Response to App"]
H --> I["Display Answer"]

This diagram illustrates the intended retrieval-augmented answering flow. The actual generation provider and integration should be confirmed from the backend implementation.

Assessment and Learning Workflow

flowchart TD
A["Open Learnova"] --> B["Login or Sign Up"]
B --> C["Home Screen"]
C --> D["Select Chapter or Topic"]
D --> E["Study Learning Content"]
E --> F["Take Assessment or Test"]
F --> G["View Results"]
G --> H["Review Progress"]
H --> I["Identify Topics to Improve"]

Project Structure

learnovaapp/
├── assets/
│   ├── Images, logos and animations
│   └── Other learning resources
├── backend/
│   ├── app.py
│   ├── assessment_engine.py
│   ├── assistant_engine.py
│   ├── explanation_engine.py
│   ├── test_series_engine.py
│   ├── check_models.py
│   ├── requirements.txt
│   └── rag/
│       ├── chunker.py
│       ├── context_builder.py
│       ├── create_collection.py
│       ├── embeddings.py
│       ├── ingest.py
│       ├── qdrant_store.py
│       └── retriever.py
├── lib/
│   ├── screens/
│   │   ├── ai_assistant/
│   │   ├── chapters/
│   │   ├── dream_lab/
│   │   ├── explanation/
│   │   ├── home/
│   │   ├── progress/
│   │   ├── test_series/
│   │   └── topics/
│   ├── services/
│   ├── themes/
│   ├── widgets/
│   ├── admin_dashboard.dart
│   ├── assessment_page.dart
│   ├── login_page.dart
│   ├── signup_page.dart
│   ├── profile_page.dart
│   ├── main.dart
│   └── firebase_options.dart
├── test/
├── android/
├── ios/
├── web/
├── pubspec.yaml
├── LEARNOVA_SYSTEM_DESIGN.md
└── README.md

Getting Started

Prerequisites

Flutter SDK compatible with the project's Dart SDK constraint

Android Studio or Visual Studio Code

Python installed for the backend

A configured Firebase project

A configured Qdrant service if running the RAG pipeline

1. Clone the Repository

git clone https://github.com/Sumit182004/LearnovaApp.git
cd LearnovaApp

If your repository uses a different URL or capitalization, replace the clone URL with the exact URL shown on GitHub.

2. Configure Flutter

flutter pub get
flutter doctor

3. Configure Firebase

Set up the Firebase project and verify the platform configuration used by the application.

Do not commit private service-account keys, API keys, or .env files containing secrets.

4. Configure the Python Backend

cd backend
python -m venv .venv

Activate the virtual environment.

Windows PowerShell:

.venv\Scripts\Activate.ps1

Install the backend dependencies:

pip install -r requirements.txt

Configure the environment variables and any required vector-store or AI-provider settings before starting the backend. The exact startup command depends on the implementation in backend/app.py.

5. Run the Flutter Application

Open a second terminal in the project root:

flutter run

Ensure that the selected device or emulator is available and the required Firebase configuration is valid.

Screenshots

Add your actual application screenshots to a folder such as screenshots/ in the repository.

For example, if you create screenshots/home.png, use:

![Learnova Home Screen](screenshots/home.png)

Add screenshots of the home screen, AI assistant, assessment, progress dashboard, and Dream Lab when available.

Security Notes

Keep .env files and service-account JSON keys out of version control.

Use environment variables for backend secrets.

Avoid exposing privileged Firebase credentials in the mobile application.

Configure Firebase security rules and backend authorization appropriately.

Future Improvements

Improve the accuracy and evaluation of AI-generated answers.

Expand the educational content and retrieval pipeline.

Enhance progress-based personalized learning recommendations.

Add automated testing for assessment and backend workflows.

Improve error handling, loading states, and accessibility.

Author

Sumit Bhatia

GitHub Profile