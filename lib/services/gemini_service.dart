import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiService {
  static GeminiService? _instance;
  late GenerativeModel _model;
  bool _isInitialized = false;

  GeminiService._();

  static GeminiService get instance {
    _instance ??= GeminiService._();
    return _instance!;
  }

  /// Inicializa o serviço do Gemini com a chave API
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Verificar se já foi carregado
      String? apiKey = dotenv.env['GEMINI_API_KEY'];
      
      // Se não encontrou, tentar carregar o arquivo .env
      if (apiKey == null || apiKey.isEmpty) {
        try {
          await dotenv.load(fileName: '.env');
          apiKey = dotenv.env['GEMINI_API_KEY'];
          debugPrint('🔑 Tentativa 1: .env carregado, chave encontrada: ${apiKey != null && apiKey.isNotEmpty}');
        } catch (e) {
          debugPrint('⚠️ Erro ao carregar .env (tentativa 1): $e');
          // Tentar carregar sem especificar o nome
          try {
            await dotenv.load();
            apiKey = dotenv.env['GEMINI_API_KEY'];
            debugPrint('🔑 Tentativa 2: dotenv.load() sem nome, chave encontrada: ${apiKey != null && apiKey.isNotEmpty}');
          } catch (e2) {
            debugPrint('⚠️ Erro ao carregar .env (tentativa 2): $e2');
          }
        }
      } else {
        debugPrint('✅ Chave API já estava carregada');
      }
      
      // Verificar se a chave é válida
      if (apiKey == null || apiKey.isEmpty || apiKey == 'sua_chave_api_aqui') {
        // Solução temporária: usar chave diretamente se .env não funcionar
        // ⚠️ ATENÇÃO: Remova isso em produção e use apenas .env
        apiKey = 'AIzaSyBtGOuNqMmk_kTY5ybIUYxnpzQobv0wxUM';
        debugPrint('⚠️ Usando chave API diretamente (fallback)');
        
        if (apiKey == null || apiKey.isEmpty) {
          debugPrint('❌ Chave API inválida ou não encontrada');
          debugPrint('📝 Variáveis disponíveis no dotenv: ${dotenv.env.keys.toList()}');
          throw Exception(
            'Chave API do Gemini não configurada.\n\n'
            'Por favor:\n'
            '1. Certifique-se de que o arquivo .env existe na raiz do projeto\n'
            '2. Adicione: GEMINI_API_KEY=sua_chave_aqui\n'
            '3. Obtenha sua chave em: https://makersuite.google.com/app/apikey\n'
            '4. Pare o app completamente e reinicie (não use hot reload)'
          );
        }
      }

      debugPrint('✅ Inicializando Gemini com chave: ${apiKey.substring(0, 10)}...');
      _model = GenerativeModel(
        model: 'gemini-pro',
        apiKey: apiKey,
      );

      _isInitialized = true;
      debugPrint('✅ Gemini Service inicializado com sucesso');
    } catch (e) {
      debugPrint('❌ Erro ao inicializar Gemini: $e');
      
      // Se falhou, tentar usar a chave diretamente como último recurso
      try {
        debugPrint('🔄 Tentando inicializar com chave direta...');
        final fallbackKey = 'AIzaSyBtGOuNqMmk_kTY5ybIUYxnpzQobv0wxUM';
        _model = GenerativeModel(
          model: 'gemini-pro',
          apiKey: fallbackKey,
        );
        _isInitialized = true;
        debugPrint('✅ Gemini Service inicializado com chave direta (fallback)');
      } catch (e2) {
        debugPrint('❌ Erro ao usar fallback: $e2');
        if (e.toString().contains('GEMINI_API_KEY') || e.toString().contains('Chave API')) {
          rethrow;
        }
        throw Exception('Erro ao inicializar Gemini Service: ${e.toString()}');
      }
    }
  }

  /// Gera uma resposta do Gemini baseada no prompt fornecido
  Future<String> generateResponse(String prompt) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      if (!_isInitialized) {
        // Tentar inicializar novamente com fallback
        await initialize();
      }

      if (!_isInitialized) {
        throw Exception(
          'Gemini Service não foi inicializado. '
          'Verifique se a chave API está configurada corretamente.'
        );
      }
    } catch (e) {
      debugPrint('❌ Erro ao verificar inicialização: $e');
      // Tentar inicializar novamente
      try {
        await initialize();
      } catch (e2) {
        throw Exception('Erro ao inicializar Gemini Service: $e2');
      }
    }

    try {
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      
      if (response.text == null || response.text!.isEmpty) {
        throw Exception('A resposta do Gemini está vazia');
      }
      
      return response.text!;
    } catch (e) {
      if (e.toString().contains('API_KEY') || e.toString().contains('api key')) {
        throw Exception(
          'Erro de autenticação com a API do Gemini. '
          'Verifique se a chave API está correta no arquivo .env'
        );
      }
      throw Exception('Erro ao gerar resposta do Gemini: $e');
    }
  }

  /// Gera sugestões de plano alimentar baseado no perfil do usuário
  Future<String> generateMealPlan({
    required String userProfile,
    required int dailyCalories,
    required double protein,
    required double carbs,
    required double fats,
    int? mealsPerDay,
  }) async {
    final prompt = '''
Você é um nutricionista especializado em criar planos alimentares personalizados.

Perfil do usuário:
$userProfile

Necessidades nutricionais diárias:
- Calorias: $dailyCalories kcal
- Proteínas: ${protein}g
- Carboidratos: ${carbs}g
- Gorduras: ${fats}g
${mealsPerDay != null ? '- Número de refeições por dia: $mealsPerDay' : ''}

Crie um plano alimentar detalhado e saudável, incluindo:
1. Distribuição das refeições ao longo do dia
2. Sugestões de alimentos para cada refeição
3. Quantidades aproximadas
4. Dicas nutricionais relevantes

Responda em português brasileiro de forma clara e objetiva.
''';

    return await generateResponse(prompt);
  }

  /// Gera sugestões de alimentos baseado em critérios específicos
  Future<String> suggestFoods({
    required String mealType,
    required int targetCalories,
    required double targetProtein,
    String? dietaryRestrictions,
    String? preferences,
  }) async {
    final prompt = '''
Você é um assistente nutricional especializado em sugerir alimentos saudáveis.

Para a refeição: $mealType
Meta de calorias: $targetCalories kcal
Meta de proteínas: ${targetProtein}g
${dietaryRestrictions != null ? 'Restrições alimentares: $dietaryRestrictions' : ''}
${preferences != null ? 'Preferências: $preferences' : ''}

Sugira alimentos adequados para esta refeição, incluindo:
1. Lista de alimentos recomendados
2. Quantidades sugeridas
3. Valores nutricionais aproximados
4. Dicas de preparo (se relevante)

Responda em português brasileiro de forma clara e objetiva.
''';

    return await generateResponse(prompt);
  }

  /// Gera dicas nutricionais personalizadas
  Future<String> generateNutritionTips({
    required String userGoal,
    String? userProfile,
  }) async {
    final prompt = '''
Você é um nutricionista experiente.

Objetivo do usuário: $userGoal
${userProfile != null ? 'Perfil: $userProfile' : ''}

Forneça dicas nutricionais práticas e relevantes para ajudar o usuário a alcançar seu objetivo.
Inclua:
1. Dicas gerais de alimentação
2. Hábitos recomendados
3. Alimentos a priorizar
4. Alimentos a evitar ou moderar
5. Dicas de hidratação

Responda em português brasileiro de forma clara, objetiva e motivadora.
''';

    return await generateResponse(prompt);
  }

  /// Gera plano alimentar usando alimentos da Tabela TACO (Tabela Brasileira de Composição de Alimentos)
  /// Retorna uma lista de alimentos estruturada em JSON para cada refeição
  Future<Map<String, dynamic>> generateMealPlanFromTACO({
    required int dailyCalories,
    required double protein,
    required double carbs,
    required double fats,
    required String gender,
    required int age,
    required String activityLevel,
    required String goal,
    int mealsPerDay = 5,
  }) async {
    final prompt = '''
Você é um nutricionista especializado em criar planos alimentares usando EXCLUSIVAMENTE alimentos da Tabela TACO (Tabela Brasileira de Composição de Alimentos - 4ª edição).

Referência: https://cfn.org.br/wp-content/uploads/2017/03/taco_4_edicao_ampliada_e_revisada.pdf

Perfil do usuário:
- Gênero: $gender
- Idade: $age anos
- Nível de atividade: $activityLevel
- Objetivo: $goal

Necessidades nutricionais diárias:
- Calorias: $dailyCalories kcal
- Proteínas: ${protein}g
- Carboidratos: ${carbs}g
- Gorduras: ${fats}g
- Número de refeições: $mealsPerDay

IMPORTANTE: Use APENAS alimentos que estão na Tabela TACO. Retorne a resposta em formato JSON válido com a seguinte estrutura:

{
  "meals": [
    {
      "mealType": "breakfast",
      "mealName": "Café da Manhã",
      "foods": [
        {
          "name": "Nome do alimento (exatamente como no TACO)",
          "quantity": 100,
          "calories": 150,
          "protein": 10,
          "carbs": 20,
          "fats": 5
        }
      ]
    },
    {
      "mealType": "morning_snack",
      "mealName": "Lanche da Manhã",
      "foods": [...]
    },
    {
      "mealType": "lunch",
      "mealName": "Almoço",
      "foods": [...]
    },
    {
      "mealType": "afternoon_snack",
      "mealName": "Lanche da Tarde",
      "foods": [...]
    },
    {
      "mealType": "dinner",
      "mealName": "Jantar",
      "foods": [...]
    }
  ]
}

Regras:
1. Use APENAS alimentos da Tabela TACO
2. Os valores nutricionais devem ser baseados nos dados do TACO
3. Distribua as calorias e macronutrientes de forma equilibrada entre as refeições
4. Considere o objetivo do usuário ($goal) ao escolher os alimentos
5. Retorne APENAS o JSON, sem texto adicional antes ou depois
6. Certifique-se de que a soma total das refeições se aproxime das necessidades diárias
''';

    try {
      final response = await generateResponse(prompt);
      
      // Limpar a resposta para extrair apenas o JSON
      String jsonString = response.trim();
      
      // Remover markdown code blocks se existirem
      if (jsonString.startsWith('```')) {
        jsonString = jsonString.replaceFirst(RegExp(r'```(?:json)?'), '');
        jsonString = jsonString.replaceFirst(RegExp(r'```'), '');
        jsonString = jsonString.trim();
      }
      
      // Parse do JSON
      final Map<String, dynamic> parsed = 
          await Future.value(_parseJsonSafely(jsonString));
      
      return parsed;
    } catch (e) {
      throw Exception('Erro ao gerar plano alimentar do TACO: $e');
    }
  }

  /// Parse seguro de JSON, tentando corrigir erros comuns
  Map<String, dynamic> _parseJsonSafely(String jsonString) {
    try {
      // Tentar parse direto
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      // Se falhar, tentar extrair JSON de uma string
      try {
        // Remover qualquer texto antes ou depois do JSON
        final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(jsonString);
        if (jsonMatch != null) {
          final cleanJson = jsonMatch.group(0)!;
          return jsonDecode(cleanJson) as Map<String, dynamic>;
        }
      } catch (e2) {
        throw Exception('Não foi possível parsear o JSON: $e2');
      }
    }
    throw Exception('Erro desconhecido ao parsear JSON');
  }

  /// Verifica se o serviço está inicializado
  bool get isInitialized => _isInitialized;
}

