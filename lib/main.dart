import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:banten_explorer/core/network/api_client.dart';
import 'package:banten_explorer/data/repositories/chat_repository_impl.dart';
import 'package:banten_explorer/presentation/services/speech_service.dart';
import 'package:banten_explorer/presentation/providers/chat_provider.dart';
import 'package:banten_explorer/presentation/screens/chat_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  String? firebaseInitError;
  
  try {
    await Firebase.initializeApp();
  } catch (e) {
    firebaseInitError = e.toString();
  }

  runApp(BantenExplorerApp(initError: firebaseInitError));
}

class BantenExplorerApp extends StatelessWidget {
  final String? initError;
  
  const BantenExplorerApp({Key? key, this.initError}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (initError != null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 60),
                  const SizedBox(height: 16),
                  const Text(
                    'Gagal Memuat Firebase',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    initError!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.black87),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final apiClient = ApiClient();
    final firestore = FirebaseFirestore.instanceFor(
      app: Firebase.app(),
      databaseId: 'bantenexplorer',
    );
    final chatRepository = ChatRepositoryImpl(
      apiClient: apiClient,
      firestore: firestore,
    );
    final speechService = SpeechService();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ChatProvider(
            chatRepository: chatRepository,
            speechService: speechService,
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Banten Explorer',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          scaffoldBackgroundColor: Colors.white,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          textSelectionTheme: TextSelectionThemeData(
          cursorColor: Colors.blue.shade700,
          selectionColor: Colors.blue.shade200,
          selectionHandleColor: Colors.blue.shade700
          ),
        ),
        home: const ChatScreen(),
      ),
    );
  }
}