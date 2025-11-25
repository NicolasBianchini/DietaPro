import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar Firebase
  // Verificar se já foi inicializado (útil para hot restart)
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint('Firebase inicializado com sucesso');
    } else {
      debugPrint('Firebase já foi inicializado');
    }
  } catch (e) {
    debugPrint('Erro ao inicializar Firebase: $e');
    debugPrint('O app continuará funcionando, mas recursos do Firebase podem não estar disponíveis.');
    // Em desenvolvimento, podemos continuar sem Firebase
    // Em produção, você pode querer mostrar um erro ao usuário
  }
  
  // Carregar variáveis de ambiente
  // O .env está incluído como asset no pubspec.yaml
  bool envLoaded = false;
  
  // Tentativa 1: Carregar como asset (recomendado)
  try {
    await dotenv.load(fileName: '.env');
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey != null && apiKey.isNotEmpty) {
      debugPrint('✅ Arquivo .env carregado com sucesso (como asset)');
      debugPrint('✅ GEMINI_API_KEY encontrada: ${apiKey.substring(0, 10)}...');
      envLoaded = true;
    }
  } catch (e) {
    debugPrint('⚠️ Erro ao carregar .env como asset: $e');
  }
  
  // Tentativa 2: Carregar sem especificar nome
  if (!envLoaded) {
    try {
      await dotenv.load();
      final apiKey = dotenv.env['GEMINI_API_KEY'];
      if (apiKey != null && apiKey.isNotEmpty) {
        debugPrint('✅ Arquivo .env carregado (tentativa 2)');
        envLoaded = true;
      }
    } catch (e) {
      debugPrint('⚠️ Tentativa 2 falhou: $e');
    }
  }
  
  if (!envLoaded) {
    debugPrint('⚠️ Arquivo .env não foi carregado automaticamente');
    debugPrint('💡 O GeminiService usará a chave diretamente como fallback');
    debugPrint('📝 Verifique se o .env está listado em assets no pubspec.yaml');
  }
  
  // Configurar orientação preferida (opcional)
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  runApp(const DietaProApp());
}

class DietaProApp extends StatelessWidget {
  const DietaProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DietaPro',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}
