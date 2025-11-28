import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class GeminiService {
  static GeminiService? _instance;
  late GenerativeModel _model;
  bool _isInitialized = false;

  GeminiService._();

  static GeminiService get instance {
    _instance ??= GeminiService._();
    return _instance!;
  }

  /// Lista de modelos para tentar em ordem de preferência (fallback)
  static const List<String> _fallbackModels = [
    'gemini-1.5-flash-latest',
    'gemini-1.5-flash',
    'gemini-1.5-pro-latest',
    'gemini-1.5-pro',
    'gemini-pro',
    'gemini-2.0-flash-exp',
  ];

  /// Verifica se um modelo deve ser usado (filtra previews e experimentais problemáticos)
  bool _isModelValid(String modelName) {
    // Filtrar modelos de preview, experimentais e versões específicas problemáticas
    final invalidPatterns = [
      RegExp(r'-preview-', caseSensitive: false),
      RegExp(r'-exp$', caseSensitive: false),
      RegExp(r'-experimental', caseSensitive: false),
      RegExp(r'gemini-2\.5', caseSensitive: false), // Modelos 2.5 podem ter problemas
      RegExp(r'-\d{2}-\d{2}$'), // Versões com data (ex: -03-25)
    ];
    
    for (final pattern in invalidPatterns) {
      if (pattern.hasMatch(modelName)) {
        debugPrint('⚠️ Modelo filtrado (preview/experimental): $modelName');
        return false;
      }
    }
    
    return true;
  }

  /// Prioriza modelos estáveis conhecidos
  List<String> _prioritizeModels(List<String> models) {
    // Modelos estáveis conhecidos em ordem de preferência
    final stableModels = [
      'gemini-1.5-flash-latest',
      'gemini-1.5-flash',
      'gemini-1.5-pro-latest',
      'gemini-1.5-pro',
      'gemini-pro',
    ];
    
    final prioritized = <String>[];
    final others = <String>[];
    
    // Adicionar modelos estáveis primeiro
    for (final stable in stableModels) {
      if (models.contains(stable)) {
        prioritized.add(stable);
      }
    }
    
    // Adicionar outros modelos válidos
    for (final model in models) {
      if (!prioritized.contains(model) && _isModelValid(model)) {
        others.add(model);
      }
    }
    
    // Combinar: estáveis primeiro, depois outros válidos
    return [...prioritized, ...others];
  }

  /// Lista os modelos disponíveis na API do Gemini
  /// Retorna uma lista de nomes de modelos que suportam generateContent
  Future<List<String>> listAvailableModels(String apiKey) async {
    try {
      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey'
      );
      
      debugPrint('📡 Buscando modelos disponíveis na API...');
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final models = data['models'] as List<dynamic>? ?? [];
        
        final availableModels = <String>[];
        
        for (final model in models) {
          final modelData = model as Map<String, dynamic>;
          final name = modelData['name'] as String? ?? '';
          final supportedMethods = modelData['supportedGenerationMethods'] as List<dynamic>? ?? [];
          
          // Filtrar apenas modelos que suportam generateContent
          if (supportedMethods.contains('generateContent')) {
            // Remover o prefixo "models/" se existir
            final modelName = name.replaceFirst(RegExp(r'^models/'), '');
            
            // Filtrar modelos inválidos (preview, experimentais, etc)
            if (_isModelValid(modelName)) {
              availableModels.add(modelName);
              debugPrint('✅ Modelo disponível: $modelName');
            }
          }
        }
        
        // Priorizar modelos estáveis
        final prioritizedModels = _prioritizeModels(availableModels);
        
        debugPrint('📋 Total de modelos disponíveis: ${prioritizedModels.length}');
        if (prioritizedModels.isEmpty) {
          debugPrint('⚠️ Nenhum modelo válido encontrado, usando lista de fallback');
          return _fallbackModels;
        }
        
        return prioritizedModels;
      } else {
        debugPrint('❌ Erro ao buscar modelos: ${response.statusCode} - ${response.body}');
        return _fallbackModels;
      }
    } catch (e) {
      debugPrint('❌ Erro ao listar modelos: $e');
      debugPrint('⚠️ Usando lista de fallback');
      return _fallbackModels;
    }
  }

  /// Tenta inicializar o modelo com diferentes nomes até encontrar um que funcione
  Future<void> _initializeModelWithFallback(String apiKey) async {
    Exception? lastException;
    
    // Primeiro, tentar buscar os modelos disponíveis da API
    List<String> modelsToTry = _fallbackModels;
    try {
      debugPrint('🔍 Buscando modelos disponíveis na API...');
      final availableModels = await listAvailableModels(apiKey);
      if (availableModels.isNotEmpty) {
        modelsToTry = availableModels;
        debugPrint('✅ Usando ${modelsToTry.length} modelos da API');
      } else {
        debugPrint('⚠️ Nenhum modelo encontrado na API, usando lista de fallback');
      }
    } catch (e) {
      debugPrint('⚠️ Erro ao buscar modelos da API, usando lista de fallback: $e');
    }
    
    for (final modelName in modelsToTry) {
      try {
        debugPrint('🔄 Tentando modelo: $modelName');
        _model = GenerativeModel(
          model: modelName,
          apiKey: apiKey,
        );
        // Testar se o modelo funciona fazendo uma chamada simples
        // Mas não vamos fazer isso na inicialização para não gastar tokens
        // Apenas criar o modelo já valida se ele existe
        debugPrint('✅ Modelo $modelName inicializado com sucesso');
        return;
      } catch (e) {
        debugPrint('❌ Modelo $modelName falhou: $e');
        lastException = e is Exception ? e : Exception(e.toString());
        continue;
      }
    }
    
    // Se nenhum modelo funcionou, lançar o último erro
    throw Exception(
      'Nenhum modelo do Gemini está disponível. '
      'Último erro: ${lastException?.toString() ?? "Desconhecido"}\n\n'
      'Modelos tentados: ${modelsToTry.join(", ")}\n\n'
      'Verifique se sua chave API está correta e se você tem acesso aos modelos do Gemini.\n\n'
      'Use listAvailableModels() para ver quais modelos estão disponíveis para sua conta.'
    );
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

      debugPrint('✅ Inicializando Gemini com chave: ${apiKey.substring(0, 10)}...');
      await _initializeModelWithFallback(apiKey);

      _isInitialized = true;
      debugPrint('✅ Gemini Service inicializado com sucesso');
    } catch (e) {
      debugPrint('❌ Erro ao inicializar Gemini: $e');
          rethrow;
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

    // Tentar gerar resposta, se falhar por modelo inválido, tentar outro modelo
    for (int attempt = 0; attempt < 2; attempt++) {
    try {
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      
      if (response.text == null || response.text!.isEmpty) {
        throw Exception('A resposta do Gemini está vazia');
      }
      
      return response.text!;
    } catch (e) {
        final errorString = e.toString();
        
        // Verificar se é erro de modelo não encontrado ou não suportado
        if (errorString.contains('is not found') || 
            errorString.contains('is not supported') ||
            errorString.contains('not found for API version')) {
          debugPrint('❌ Modelo atual não é suportado, tentando reinicializar com outro modelo...');
          
          // Resetar inicialização e tentar novamente
          _isInitialized = false;
          try {
            // Obter a chave API
            String? apiKey = dotenv.env['GEMINI_API_KEY'];
            if (apiKey == null || apiKey.isEmpty) {
              try {
                await dotenv.load(fileName: '.env');
                apiKey = dotenv.env['GEMINI_API_KEY'];
              } catch (e) {
                try {
                  await dotenv.load();
                  apiKey = dotenv.env['GEMINI_API_KEY'];
                } catch (e2) {
                  // Ignorar
                }
              }
            }
            
            if (apiKey != null && apiKey.isNotEmpty && apiKey != 'sua_chave_api_aqui') {
              await _initializeModelWithFallback(apiKey);
              _isInitialized = true;
              debugPrint('✅ Reinicializado com novo modelo, tentando novamente...');
              continue; // Tentar novamente com o novo modelo
            }
          } catch (e2) {
            debugPrint('❌ Erro ao reinicializar: $e2');
          }
        }
        
        // Se não for erro de modelo ou se já tentou 2 vezes, lançar o erro
        if (attempt == 1 || !errorString.contains('is not found') && 
            !errorString.contains('is not supported') &&
            !errorString.contains('not found for API version')) {
          if (errorString.contains('API_KEY') || errorString.contains('api key')) {
        throw Exception(
          'Erro de autenticação com a API do Gemini. '
          'Verifique se a chave API está correta no arquivo .env'
        );
      }
      throw Exception('Erro ao gerar resposta do Gemini: $e');
        }
    }
    }
    
    throw Exception('Erro ao gerar resposta do Gemini após múltiplas tentativas');
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
    String? dietaryRestrictions,
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
${dietaryRestrictions != null && dietaryRestrictions.isNotEmpty ? '''

⚠️ RESTRIÇÕES ALIMENTARES CRÍTICAS - SEGURANÇA ALIMENTAR ⚠️
$dietaryRestrictions

INSTRUÇÕES OBRIGATÓRIAS SOBRE RESTRIÇÕES:
1. É ABSOLUTAMENTE PROIBIDO incluir alimentos que contenham, possam conter ou sejam derivados dos ingredientes/alergênicos mencionados nas restrições acima.
2. Verifique cuidadosamente cada alimento antes de incluí-lo no plano:
   - Se a restrição menciona "Lactose": NÃO inclua leite, queijos, iogurtes, manteiga ou qualquer derivado lácteo.
   - Se a restrição menciona "Glúten": NÃO inclua trigo, cevada, centeio, aveia (a menos que seja sem glúten) ou produtos que contenham esses cereais.
   - Se a restrição menciona "Frutos do mar": NÃO inclua peixes, camarões, mariscos, lulas ou qualquer alimento marinho.
   - Se a restrição menciona "Amendoim" ou "Nozes": NÃO inclua esses alimentos ou produtos que possam conter traços.
   - Se a restrição menciona "Soja": NÃO inclua soja, tofu, leite de soja ou derivados.
   - Se a restrição menciona "Ovos": NÃO inclua ovos ou produtos que contenham ovos.
   - Se a restrição menciona "Vegetariano": NÃO inclua carnes, peixes ou produtos de origem animal.
   - Se a restrição menciona "Vegano": NÃO inclua qualquer produto de origem animal (carnes, laticínios, ovos, mel, etc.).
   - Se a restrição menciona "Diabético": Priorize alimentos com baixo índice glicêmico e evite açúcares simples.
   - Se a restrição menciona "Hipertensão" ou "Colesterol alto": Evite alimentos com alto teor de sódio ou gordura saturada.

3. Quando houver dúvida sobre um alimento, NÃO o inclua. É melhor ser conservador e garantir a segurança do usuário.

4. Se as restrições tornarem difícil atingir as necessidades nutricionais, ajuste as quantidades dos alimentos permitidos, mas NUNCA inclua alimentos proibidos.

AVISO DE SEGURANÇA ALIMENTAR:
Este plano alimentar é gerado automaticamente e deve ser revisado por um nutricionista ou profissional de saúde qualificado antes do consumo, especialmente quando há restrições alimentares, alergias ou condições médicas. O usuário deve sempre verificar os rótulos dos alimentos e consultar um profissional de saúde em caso de dúvida.
''' : ''}

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
${dietaryRestrictions != null && dietaryRestrictions.isNotEmpty ? '''5. SEGURANÇA ALIMENTAR É PRIORIDADE: É OBRIGATÓRIO respeitar TODAS as restrições alimentares mencionadas. NÃO inclua alimentos proibidos, mesmo que isso dificulte atingir as metas nutricionais. A segurança do usuário é mais importante que valores nutricionais exatos.
6. Verifique cada alimento individualmente antes de incluí-lo. Se houver qualquer dúvida sobre compatibilidade com as restrições, NÃO inclua o alimento.
7. Se necessário, ajuste as quantidades dos alimentos permitidos para tentar atingir as necessidades nutricionais, mas NUNCA comprometa a segurança alimentar.''' : '5. Retorne APENAS o JSON, sem texto adicional antes ou depois'}
${dietaryRestrictions != null && dietaryRestrictions.isNotEmpty ? '8. Retorne APENAS o JSON, sem texto adicional antes ou depois' : '6. Retorne APENAS o JSON, sem texto adicional antes ou depois'}
${dietaryRestrictions != null && dietaryRestrictions.isNotEmpty ? '9. Certifique-se de que a soma total das refeições se aproxime das necessidades diárias, respeitando todas as restrições' : '7. Certifique-se de que a soma total das refeições se aproxime das necessidades diárias'}
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

  /// Método público para listar modelos disponíveis (útil para debug)
  /// Retorna uma lista de nomes de modelos que suportam generateContent
  Future<List<String>> getAvailableModels() async {
    try {
      String? apiKey = dotenv.env['GEMINI_API_KEY'];
      
      if (apiKey == null || apiKey.isEmpty) {
        try {
          await dotenv.load(fileName: '.env');
          apiKey = dotenv.env['GEMINI_API_KEY'];
        } catch (e) {
          try {
            await dotenv.load();
            apiKey = dotenv.env['GEMINI_API_KEY'];
          } catch (e2) {
            // Ignorar erro
          }
        }
      }
      
      if (apiKey == null || apiKey.isEmpty || apiKey == 'sua_chave_api_aqui') {
        throw Exception(
          'Chave API do Gemini não configurada.\n\n'
          'Por favor:\n'
          '1. Certifique-se de que o arquivo .env existe na raiz do projeto\n'
          '2. Adicione: GEMINI_API_KEY=sua_chave_aqui\n'
          '3. Obtenha sua chave em: https://makersuite.google.com/app/apikey'
        );
      }
      
      return await listAvailableModels(apiKey);
    } catch (e) {
      debugPrint('❌ Erro ao obter modelos disponíveis: $e');
      rethrow;
    }
  }
}

