import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../models/user_profile.dart';
import '../models/food_item.dart';
import '../utils/nutrition_calculator.dart';
import '../utils/food_database.dart';
import '../services/gemini_service.dart';
import '../services/firestore_service.dart';
import 'terms_and_disclaimer_screen.dart';

class DietCalculatorScreen extends StatefulWidget {
  final UserProfile? userProfile;
  final String? mealPlanId; // Para edição de planos existentes

  const DietCalculatorScreen({
    super.key,
    this.userProfile,
    this.mealPlanId,
  });

  @override
  State<DietCalculatorScreen> createState() => _DietCalculatorScreenState();
}

class _DietCalculatorScreenState extends State<DietCalculatorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dietNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();

  Map<String, dynamic>? _nutritionData;
  bool _isCalculated = false;
  bool _isLoadingPlan = false;

  // Alimentos por refeição - será inicializado dinamicamente baseado no mealsPerDay
  late Map<String, List<MealFood>> _meals;

  // Controllers de busca por refeição
  final Map<String, TextEditingController> _searchControllers = {};

  // Resultados de busca por refeição
  final Map<String, List<FoodItem>> _searchResults = {};

  // Restrições alimentares
  Set<String> _selectedRestrictions = {};
  final TextEditingController _customRestrictionsController = TextEditingController();
  Timer? _restrictionsSaveTimer;
  
  // Lista de restrições alimentares comuns
  final List<String> _commonRestrictions = [
    'Lactose',
    'Glúten',
    'Frutos do mar',
    'Amendoim',
    'Soja',
    'Ovos',
    'Nozes',
    'Vegetariano',
    'Vegano',
    'Diabético',
    'Hipertensão',
    'Colesterol alto',
  ];

  @override
  void initState() {
    super.initState();
    // Inicializar refeições baseado no mealsPerDay do usuário
    _initializeMeals();
    
    // Preencher com dados do perfil se disponível
    if (widget.userProfile != null) {
      if (widget.userProfile!.height != null) {
        _heightController.text = widget.userProfile!.height!.toStringAsFixed(0);
      }
      if (widget.userProfile!.weight != null) {
        _weightController.text = widget.userProfile!.weight!.toStringAsFixed(1);
      }
      
      // Carregar restrições do perfil
      if (widget.userProfile!.dietaryRestrictions != null) {
        _selectedRestrictions = Set<String>.from(widget.userProfile!.dietaryRestrictions!);
      }
      if (widget.userProfile!.customDietaryRestrictions != null) {
        _customRestrictionsController.text = widget.userProfile!.customDietaryRestrictions!;
      }
      
      // Tentar carregar também da sub-coleção settings (local definitivo)
      _loadDietaryRestrictionsFromSettings();
    }

    // Adicionar listeners para busca
    for (final entry in _searchControllers.entries) {
      entry.value.addListener(() {
        _performSearch(entry.key, entry.value.text);
      });
    }
    
    // Listener para salvar restrições customizadas automaticamente (com delay)
    _customRestrictionsController.addListener(() {
      // Cancelar timer anterior se existir
      _restrictionsSaveTimer?.cancel();
      
      // Criar novo timer de 2 segundos (salva só quando parar de digitar)
      _restrictionsSaveTimer = Timer(const Duration(seconds: 2), () {
        _saveDietaryRestrictionsToProfile();
      });
    });

    // Se há mealPlanId, carregar plano existente
    if (widget.mealPlanId != null) {
      _loadExistingMealPlan();
    }
  }

  /// Inicializa as refeições baseado no número de refeições por dia do usuário
  void _initializeMeals() {
    final mealsPerDay = widget.userProfile?.mealsPerDayOrDefault ?? 5;
    
    print('\n📱 INICIALIZANDO CALCULADORA DE DIETA');
    print('👤 Perfil: ${widget.userProfile?.name ?? "não definido"}');
    print('📊 mealsPerDay: ${widget.userProfile?.mealsPerDay ?? "null"}');
    print('📊 Usando: $mealsPerDay refeições\n');
    
    // Mapeamento de refeições por número
    final mealConfigs = <int, List<String>>{
      3: ['breakfast', 'lunch', 'dinner'],
      4: ['breakfast', 'lunch', 'afternoon_snack', 'dinner'],
      5: ['breakfast', 'morning_snack', 'lunch', 'afternoon_snack', 'dinner'],
      6: ['breakfast', 'morning_snack', 'lunch', 'afternoon_snack', 'dinner', 'evening_snack'],
      7: ['breakfast', 'morning_snack', 'lunch', 'afternoon_snack', 'dinner', 'evening_snack', 'late_snack'],
    };
    
    // Obter lista de refeições correspondente ao mealsPerDay
    final mealTypes = mealConfigs[mealsPerDay] ?? mealConfigs[5]!;
    
    // Inicializar mapas
    _meals = {};
    _searchControllers.clear();
    _searchResults.clear();
    
    for (final mealType in mealTypes) {
      _meals[mealType] = [];
      _searchControllers[mealType] = TextEditingController();
      _searchResults[mealType] = [];
    }
  }

  @override
  void dispose() {
    _restrictionsSaveTimer?.cancel();
    _dietNameController.dispose();
    _descriptionController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _customRestrictionsController.dispose();
    _searchControllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  /// Carrega um plano alimentar existente para edição
  Future<void> _loadExistingMealPlan() async {
    if (widget.mealPlanId == null || widget.userProfile?.id == null) return;

    setState(() {
      _isLoadingPlan = true;
    });

    try {
      final firestoreService = FirestoreService();
      final mealPlan = await firestoreService.getMealPlan(widget.mealPlanId!);

      if (mealPlan != null && mounted) {
        // Preencher nome e descrição
        _dietNameController.text = mealPlan['dietName'] as String? ?? '';
        _descriptionController.text = mealPlan['description'] as String? ?? '';

        // Carregar dados nutricionais
        if (mealPlan['nutritionData'] != null) {
          _nutritionData = mealPlan['nutritionData'] as Map<String, dynamic>;
          _isCalculated = true;
        }

        // Carregar refeições
        if (mealPlan['meals'] != null) {
          final mealsData = mealPlan['meals'] as Map<String, dynamic>;
          
          // Limpar refeições atuais
          _meals.forEach((key, value) => value.clear());
          
          // Carregar refeições do plano
          mealsData.forEach((mealType, mealFoodsData) {
            if (_meals.containsKey(mealType)) {
              final mealFoodsList = mealFoodsData as List<dynamic>;
              _meals[mealType] = mealFoodsList.map((mfData) {
                try {
                  return MealFood.fromMap(mfData as Map<String, dynamic>);
                } catch (e) {
                  debugPrint('Erro ao carregar MealFood: $e');
                  return null;
                }
              }).whereType<MealFood>().toList();
            }
          });
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Plano alimentar carregado com sucesso!'),
              backgroundColor: AppTheme.primaryColor,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Erro ao carregar plano: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar plano: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingPlan = false;
        });
      }
    }
  }

  void _performSearch(String mealType, String query) {
    setState(() {
      if (query.isEmpty) {
        _searchResults[mealType] = [];
      } else {
        _searchResults[mealType] = FoodDatabase.searchFoods(query);
      }
    });
  }

  void _calculateNutrition() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Verificar se temos todos os dados necessários
    if (widget.userProfile == null ||
        widget.userProfile!.gender == null ||
        widget.userProfile!.age == null ||
        widget.userProfile!.activityLevel == null ||
        widget.userProfile!.goal == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Complete seu perfil para calcular as necessidades nutricionais'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    final height = double.tryParse(_heightController.text);
    final weight = double.tryParse(_weightController.text);

    if (height == null || weight == null) {
      return;
    }

    // Calcular necessidades nutricionais
    final nutritionData = NutritionCalculator.calculateNutrition(
      weight: weight,
      height: height,
      age: widget.userProfile!.age!,
      gender: widget.userProfile!.gender!,
      activityLevel: widget.userProfile!.activityLevel!,
      goal: widget.userProfile!.goal!,
    );

    setState(() {
      _nutritionData = nutritionData;
      _isCalculated = true;
    });

    // Mostrar loading enquanto a IA gera o plano
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Gerando plano alimentar com IA...'),
                  SizedBox(height: 8),
                  Text(
                    'Buscando alimentos da Tabela TACO',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    try {
      // Inicializar o serviço Gemini
      await GeminiService.instance.initialize();

      // Converter enums para strings legíveis
      final genderText = _getGenderText(widget.userProfile!.gender!);
      final activityText = _getActivityText(widget.userProfile!.activityLevel!);
      final goalText = _getGoalText(widget.userProfile!.goal!);

      // Preparar informações de restrições alimentares
      String restrictionsText = '';
      if (_selectedRestrictions.isNotEmpty) {
        restrictionsText = 'Restrições alimentares: ${_selectedRestrictions.join(', ')}';
      }
      if (_customRestrictionsController.text.trim().isNotEmpty) {
        if (restrictionsText.isNotEmpty) {
          restrictionsText += '. ';
        }
        restrictionsText += 'Outras restrições: ${_customRestrictionsController.text.trim()}';
      }

      // Gerar plano alimentar usando TACO
      // Usar o número de refeições do perfil do usuário (padrão: 5)
      final mealsPerDay = widget.userProfile!.mealsPerDayOrDefault;
      
      print('\n🍽️ ===== GERANDO PLANO COM IA =====');
      print('👤 Perfil: ${widget.userProfile!.name}');
      print('📊 mealsPerDay do perfil: ${widget.userProfile!.mealsPerDay}');
      print('📊 mealsPerDayOrDefault: $mealsPerDay');
      print('🤖 IA vai gerar $mealsPerDay refeições');
      print('🍽️ ================================\n');
      
      final mealPlanData = await GeminiService.instance.generateMealPlanFromTACO(
        dailyCalories: (nutritionData['calories'] as double).round(),
        protein: nutritionData['protein'] as double,
        carbs: nutritionData['carbs'] as double,
        fats: nutritionData['fats'] as double,
        gender: genderText,
        age: widget.userProfile!.age!,
        activityLevel: activityText,
        goal: goalText,
        mealsPerDay: mealsPerDay,
        dietaryRestrictions: restrictionsText.isNotEmpty ? restrictionsText : null,
      );

      // Processar e adicionar alimentos às refeições
      if (mealPlanData['meals'] != null) {
        final meals = mealPlanData['meals'] as List<dynamic>;
        
        setState(() {
          // Limpar refeições existentes
          _meals.forEach((key, value) => value.clear());
          
          // Adicionar alimentos sugeridos pela IA
          for (var mealData in meals) {
            final mealType = mealData['mealType'] as String;
            final foods = mealData['foods'] as List<dynamic>;
            
            // Garantir que a refeição existe no mapa (caso a IA retorne uma refeição não esperada)
            if (!_meals.containsKey(mealType)) {
              _meals[mealType] = [];
              if (!_searchControllers.containsKey(mealType)) {
                _searchControllers[mealType] = TextEditingController();
                _searchControllers[mealType]!.addListener(() {
                  _performSearch(mealType, _searchControllers[mealType]!.text);
                });
              }
              if (!_searchResults.containsKey(mealType)) {
                _searchResults[mealType] = [];
              }
            }
            
            for (var foodData in foods) {
              final foodItem = FoodItem(
                id: '${DateTime.now().millisecondsSinceEpoch}_${foodData['name']}',
                name: foodData['name'] as String,
                category: _getCategoryFromFood(foodData['name'] as String),
                calories: (foodData['calories'] as num).toDouble(),
                protein: (foodData['protein'] as num).toDouble(),
                carbs: (foodData['carbs'] as num).toDouble(),
                fats: (foodData['fats'] as num).toDouble(),
              );
              
              final mealFood = MealFood(
                food: foodItem,
                quantity: (foodData['quantity'] as num).toDouble(),
                mealType: mealType,
              );
              
              _meals[mealType]!.add(mealFood);
            }
          }
        });
      }

      if (mounted) {
        Navigator.pop(context); // Fechar dialog de loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Plano alimentar gerado com sucesso usando Tabela TACO!'),
            backgroundColor: AppTheme.primaryColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Fechar dialog de loading
        
        // Mostrar mensagem de erro mais amigável
        String errorMessage = 'Erro ao gerar plano alimentar';
        if (e.toString().contains('GEMINI_API_KEY') || e.toString().contains('Chave API')) {
          errorMessage = 'Chave API do Gemini não configurada.\n\n'
              'Configure a chave API no arquivo .env para usar a IA.';
        } else {
          errorMessage = 'Erro: ${e.toString()}';
        }
        
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Erro'),
            content: Text(errorMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  String _getGenderText(Gender gender) {
    switch (gender) {
      case Gender.male:
        return 'Masculino';
      case Gender.female:
        return 'Feminino';
      case Gender.other:
        return 'Outro';
    }
  }

  String _getActivityText(ActivityLevel level) {
    switch (level) {
      case ActivityLevel.sedentary:
        return 'Sedentário';
      case ActivityLevel.light:
        return 'Leve (exercício 1-3x/semana)';
      case ActivityLevel.moderate:
        return 'Moderado (exercício 3-5x/semana)';
      case ActivityLevel.active:
        return 'Ativo (exercício 6-7x/semana)';
      case ActivityLevel.veryActive:
        return 'Muito ativo (exercício 2x/dia)';
    }
  }

  String _getGoalText(Goal goal) {
    switch (goal) {
      case Goal.loseWeight:
        return 'Perder peso';
      case Goal.gainWeight:
        return 'Ganhar peso';
      case Goal.gainMuscle:
        return 'Ganhar massa muscular';
      case Goal.maintain:
        return 'Manutenção';
      case Goal.eatBetter:
        return 'Comer melhor';
    }
  }

  String _getCategoryFromFood(String foodName) {
    final name = foodName.toLowerCase();
    if (name.contains('frango') || name.contains('carne') || name.contains('peixe') || 
        name.contains('ovo') || name.contains('leite') || name.contains('queijo') ||
        name.contains('iogurte') || name.contains('proteína')) {
      return 'Proteína';
    } else if (name.contains('arroz') || name.contains('batata') || name.contains('pão') ||
               name.contains('macarrão') || name.contains('açúcar') || name.contains('massa')) {
      return 'Carboidrato';
    } else if (name.contains('óleo') || name.contains('azeite') || name.contains('gordura') ||
               name.contains('manteiga') || name.contains('abacate')) {
      return 'Gordura';
    } else if (name.contains('fruta') || name.contains('verdura') || name.contains('legume') ||
               name.contains('salada')) {
      return 'Vegetal/Fruta';
    }
    return 'Outros';
  }

  void _addFoodToMeal(String mealType, FoodItem food) {
    _showQuantityDialog(mealType, food);
  }

  void _showQuantityDialog(String mealType, FoodItem food) {
    final quantityController = TextEditingController(text: '100');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Adicionar ${food.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Quantidade (g):'),
            const SizedBox(height: 8),
            TextField(
              controller: quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'Ex: 100',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final quantity = double.tryParse(quantityController.text) ?? 100;
              setState(() {
                _meals[mealType]!.add(MealFood(
                  food: food,
                  quantity: quantity,
                  mealType: mealType,
                ));
              });
              Navigator.pop(context);
              _searchControllers[mealType]!.clear();
            },
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );
  }

  void _removeFoodFromMeal(String mealType, int index) {
    setState(() {
      _meals[mealType]!.removeAt(index);
    });
  }

  void _editFoodQuantity(String mealType, int index) {
    final mealFood = _meals[mealType]![index];
    final quantityController = TextEditingController(
      text: mealFood.quantity.toStringAsFixed(0),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Editar ${mealFood.food.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Quantidade (g):'),
            const SizedBox(height: 8),
            TextField(
              controller: quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'Ex: 100',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final quantity = double.tryParse(quantityController.text) ?? mealFood.quantity;
              setState(() {
                _meals[mealType]![index] = MealFood(
                  food: mealFood.food,
                  quantity: quantity,
                  mealType: mealType,
                );
              });
              Navigator.pop(context);
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  Map<String, double> _calculateMealTotals(String mealType) {
    final foods = _meals[mealType]!;
    double calories = 0;
    double protein = 0;
    double carbs = 0;
    double fats = 0;

    for (var mealFood in foods) {
      calories += mealFood.totalCalories;
      protein += mealFood.totalProtein;
      carbs += mealFood.totalCarbs;
      fats += mealFood.totalFats;
    }

    return {
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fats': fats,
    };
  }

  Map<String, double> _calculateTotalNutrition() {
    double calories = 0;
    double protein = 0;
    double carbs = 0;
    double fats = 0;

    _meals.forEach((mealType, foods) {
      final totals = _calculateMealTotals(mealType);
      calories += totals['calories']!;
      protein += totals['protein']!;
      carbs += totals['carbs']!;
      fats += totals['fats']!;
    });

    return {
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fats': fats,
    };
  }

  /// Carrega as restrições alimentares da sub-coleção settings
  Future<void> _loadDietaryRestrictionsFromSettings() async {
    if (widget.userProfile?.id == null) return;

    try {
      final firestoreService = FirestoreService();
      final restrictions = await firestoreService.getUserDietaryRestrictions(widget.userProfile!.id!);
      
      if (mounted) {
        setState(() {
          if (restrictions['dietaryRestrictions'] != null) {
            _selectedRestrictions = Set<String>.from(restrictions['dietaryRestrictions'] as List);
          }
          if (restrictions['customRestrictions'] != null) {
            _customRestrictionsController.text = restrictions['customRestrictions'] as String;
          }
        });
        
        print('✅ Restrições carregadas da sub-coleção settings');
      }
    } catch (e) {
      print('⚠️ Erro ao carregar restrições: $e');
      // Não mostrar erro - continua com as restrições do perfil principal
    }
  }

  /// Salva as restrições alimentares no perfil do usuário
  Future<void> _saveDietaryRestrictionsToProfile() async {
    if (widget.userProfile?.id == null) return;

    try {
      final firestoreService = FirestoreService();
      
      // Salvar no perfil principal (para backup)
      final updatedProfile = UserProfile(
        id: widget.userProfile!.id,
        email: widget.userProfile!.email,
        name: widget.userProfile!.name,
        gender: widget.userProfile!.gender,
        dateOfBirth: widget.userProfile!.dateOfBirth,
        height: widget.userProfile!.height,
        weight: widget.userProfile!.weight,
        activityLevel: widget.userProfile!.activityLevel,
        goal: widget.userProfile!.goal,
        mealsPerDay: widget.userProfile!.mealsPerDay,
        dietaryRestrictions: _selectedRestrictions.isNotEmpty 
            ? _selectedRestrictions.toList() 
            : null,
        customDietaryRestrictions: _customRestrictionsController.text.trim().isEmpty 
            ? null 
            : _customRestrictionsController.text.trim(),
        termsAccepted: widget.userProfile!.termsAccepted,
        termsAcceptedAt: widget.userProfile!.termsAcceptedAt,
        createdAt: widget.userProfile!.createdAt,
        updatedAt: DateTime.now(),
      );

      await firestoreService.saveUserProfile(updatedProfile);
      
      // Também salvar na sub-coleção settings/dietary_restrictions
      // (local onde o FirestoreService busca as restrições)
      await firestoreService.saveUserDietaryRestrictions(
        userId: widget.userProfile!.id!,
        dietaryRestrictions: _selectedRestrictions.isNotEmpty 
            ? _selectedRestrictions.toList() 
            : [],
        customRestrictions: _customRestrictionsController.text.trim().isEmpty 
            ? null 
            : _customRestrictionsController.text.trim(),
      );
      
      print('✅ Restrições alimentares salvas no perfil');
    } catch (e) {
      print('❌ Erro ao salvar restrições: $e');
      // Não mostrar erro ao usuário para não interromper o fluxo
    }
  }

  Future<void> _saveMealPlan() async {
    if (widget.userProfile == null || widget.userProfile!.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro: Usuário não identificado'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    if (_dietNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, insira o nome da dieta'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    if (_nutritionData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, calcule as necessidades nutricionais primeiro'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    // Verificar se há pelo menos uma refeição com alimentos
    bool hasMeals = false;
    for (final mealList in _meals.values) {
      if (mealList.isNotEmpty) {
        hasMeals = true;
        break;
      }
    }

    if (!hasMeals) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Adicione pelo menos um alimento às refeições'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    try {
      // Mostrar loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Salvando plano alimentar...'),
                ],
              ),
            ),
          ),
        ),
      );

      final firestoreService = FirestoreService();
      
      // Filtrar apenas refeições que têm alimentos antes de salvar
      final mealsToSave = <String, List<MealFood>>{};
      debugPrint('\n🍽️ ===== SALVANDO PLANO: ${_dietNameController.text} =====');
      debugPrint('📋 Total de refeições no mapa _meals: ${_meals.length}');
      
      _meals.forEach((mealType, mealFoods) {
        debugPrint('  - $mealType: ${mealFoods.length} alimentos');
        if (mealFoods.isNotEmpty) {
          mealsToSave[mealType] = mealFoods;
          debugPrint('    ✅ SERÁ SALVA');
        } else {
          debugPrint('    ❌ VAZIA - NÃO SERÁ SALVA');
        }
      });
      
      debugPrint('📊 Total de refeições que serão salvas: ${mealsToSave.length}');
      debugPrint('🍽️ ===== FIM =====\n');
      
      // Salvar ou atualizar o plano alimentar
      if (widget.mealPlanId != null) {
        // Atualizar plano existente
        await firestoreService.updateMealPlan(
          mealPlanId: widget.mealPlanId!,
          dietName: _dietNameController.text.trim(),
          description: _descriptionController.text.trim().isEmpty 
              ? null 
              : _descriptionController.text.trim(),
          nutritionData: _nutritionData!,
          meals: mealsToSave,
        );
      } else {
        // Criar novo plano
        await firestoreService.saveMealPlan(
          userId: widget.userProfile!.id!,
          dietName: _dietNameController.text.trim(),
          description: _descriptionController.text.trim().isEmpty 
              ? null 
              : _descriptionController.text.trim(),
          nutritionData: _nutritionData!,
          meals: mealsToSave,
          createdAt: DateTime.now(),
        );
      }

      if (mounted) {
        Navigator.pop(context); // Fechar dialog de loading
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.mealPlanId != null 
                  ? 'Plano alimentar atualizado com sucesso!'
                  : 'Plano alimentar salvo com sucesso!',
            ),
            backgroundColor: AppTheme.primaryColor,
            duration: const Duration(seconds: 2),
          ),
        );

        // Voltar para a tela anterior após um breve delay
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            Navigator.pop(context);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Fechar dialog de loading
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar plano alimentar: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Calculadora de Dieta'),
      ),
      body: _isLoadingPlan
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
              // Título e descrição com card destacado
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.calculate,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Calculadora de Dieta',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Monte dietas personalizadas',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Banner de Aviso Médico
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.red.shade300,
                    width: 2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.red.shade700,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Aviso Médico Importante',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'O DietaPro é uma ferramenta de apoio e não substitui o acompanhamento de um nutricionista clínico ou profissional de saúde qualificado.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.red.shade800,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const TermsAndDisclaimerScreen(),
                          ),
                        );
                      },
                      child: Text(
                        'Leia os Termos de Uso e Aviso Legal',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.red.shade900,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                          decorationColor: Colors.red.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Formulário básico
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _dietNameController,
                      decoration: InputDecoration(
                        labelText: 'Nome da Dieta *',
                        hintText: 'Ex: Dieta para Emagrecimento',
                        prefixIcon: Icon(Icons.restaurant_menu, color: AppTheme.primaryColor),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, insira o nome da dieta';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Descrição (opcional)',
                        hintText: 'Adicione observações sobre a dieta...',
                        prefixIcon: Icon(Icons.description, color: AppTheme.primaryColor),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _heightController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                            ],
                            decoration: InputDecoration(
                              labelText: 'Altura (cm) *',
                              hintText: 'Ex: 175',
                              prefixIcon: Icon(Icons.height, color: AppTheme.primaryColor),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Obrigatório';
                              }
                              final height = double.tryParse(value);
                              if (height == null || height < 100 || height > 250) {
                                return 'Altura inválida';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _weightController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                            ],
                            decoration: InputDecoration(
                              labelText: 'Peso (kg) *',
                              hintText: 'Ex: 70.5',
                              prefixIcon: Icon(Icons.monitor_weight, color: AppTheme.primaryColor),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Obrigatório';
                              }
                              final weight = double.tryParse(value);
                              if (weight == null || weight < 30 || weight > 300) {
                                return 'Peso inválido';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Botão de Restrições Alimentares
                    OutlinedButton.icon(
                      onPressed: _showDietaryRestrictionsDialog,
                      icon: const Icon(Icons.restaurant_menu),
                      label: const Text('Restrições Alimentares'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryColor,
                        side: BorderSide(color: AppTheme.primaryColor),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _calculateNutrition,
                        icon: const Icon(Icons.calculate, color: Colors.white),
                        label: const Text(
                          'Calcular Necessidades Nutricionais',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          shadowColor: AppTheme.primaryColor.withValues(alpha: 0.3),
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Resumo Nutricional (se calculado)
              if (_isCalculated && _nutritionData != null) ...[
                const SizedBox(height: 32),
                _buildNutritionSummary(),
              ],
              // Seções de Refeições
              if (_isCalculated) ...[
                const SizedBox(height: 24),
                ..._buildMealSections(),
                const SizedBox(height: 24),
                // Resumo Total do Plano
                _buildTotalPlanSummary(),
                const SizedBox(height: 24),
                // Botões de ação
                Row(
                  children: [
                    if (widget.mealPlanId != null) ...[
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _calculateNutrition,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Gerar Nova'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.primaryColor,
                            side: BorderSide(color: AppTheme.primaryColor),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: _saveMealPlan,
                        icon: const Icon(Icons.check, color: Colors.white),
                        label: Text(
                          widget.mealPlanId != null 
                              ? 'Salvar Alterações'
                              : 'Confirmar Plano Alimentar',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
                  ],
                ),
              ),
            ),
    );
  }

  /// Retorna as seções de refeições baseadas no número de refeições do usuário
  List<Widget> _buildMealSections() {
    final mealsPerDay = widget.userProfile?.mealsPerDayOrDefault ?? 5;
    final sections = <Widget>[];
    
    // Mapeamento de refeições por número
    final mealConfigs = <int, List<Map<String, dynamic>>>{
      3: [
        {'type': 'breakfast', 'title': 'Café da Manhã', 'icon': Icons.wb_sunny_outlined},
        {'type': 'lunch', 'title': 'Almoço', 'icon': Icons.lunch_dining_outlined},
        {'type': 'dinner', 'title': 'Jantar', 'icon': Icons.dinner_dining_outlined},
      ],
      4: [
        {'type': 'breakfast', 'title': 'Café da Manhã', 'icon': Icons.wb_sunny_outlined},
        {'type': 'lunch', 'title': 'Almoço', 'icon': Icons.lunch_dining_outlined},
        {'type': 'afternoon_snack', 'title': 'Lanche da Tarde', 'icon': Icons.cookie_outlined},
        {'type': 'dinner', 'title': 'Jantar', 'icon': Icons.dinner_dining_outlined},
      ],
      5: [
        {'type': 'breakfast', 'title': 'Café da Manhã', 'icon': Icons.wb_sunny_outlined},
        {'type': 'morning_snack', 'title': 'Lanche da Manhã', 'icon': Icons.cookie_outlined},
        {'type': 'lunch', 'title': 'Almoço', 'icon': Icons.lunch_dining_outlined},
        {'type': 'afternoon_snack', 'title': 'Lanche da Tarde', 'icon': Icons.cookie_outlined},
        {'type': 'dinner', 'title': 'Jantar', 'icon': Icons.dinner_dining_outlined},
      ],
      6: [
        {'type': 'breakfast', 'title': 'Café da Manhã', 'icon': Icons.wb_sunny_outlined},
        {'type': 'morning_snack', 'title': 'Lanche da Manhã', 'icon': Icons.cookie_outlined},
        {'type': 'lunch', 'title': 'Almoço', 'icon': Icons.lunch_dining_outlined},
        {'type': 'afternoon_snack', 'title': 'Lanche da Tarde', 'icon': Icons.cookie_outlined},
        {'type': 'dinner', 'title': 'Jantar', 'icon': Icons.dinner_dining_outlined},
        {'type': 'evening_snack', 'title': 'Ceia', 'icon': Icons.nightlight_outlined},
      ],
      7: [
        {'type': 'breakfast', 'title': 'Café da Manhã', 'icon': Icons.wb_sunny_outlined},
        {'type': 'morning_snack', 'title': 'Lanche da Manhã', 'icon': Icons.cookie_outlined},
        {'type': 'lunch', 'title': 'Almoço', 'icon': Icons.lunch_dining_outlined},
        {'type': 'afternoon_snack', 'title': 'Lanche da Tarde', 'icon': Icons.cookie_outlined},
        {'type': 'dinner', 'title': 'Jantar', 'icon': Icons.dinner_dining_outlined},
        {'type': 'evening_snack', 'title': 'Ceia', 'icon': Icons.nightlight_outlined},
        {'type': 'late_snack', 'title': 'Lanche Noturno', 'icon': Icons.bedtime_outlined},
      ],
    };
    
    // Obter configuração de refeições (padrão: 5)
    final config = mealConfigs[mealsPerDay] ?? mealConfigs[5]!;
    
    // Inicializar refeições que não existem no mapa
    for (final meal in config) {
      final mealType = meal['type'] as String;
      if (!_meals.containsKey(mealType)) {
        _meals[mealType] = [];
      }
      if (!_searchControllers.containsKey(mealType)) {
        _searchControllers[mealType] = TextEditingController();
        _searchControllers[mealType]!.addListener(() {
          _performSearch(mealType, _searchControllers[mealType]!.text);
        });
      }
      if (!_searchResults.containsKey(mealType)) {
        _searchResults[mealType] = [];
      }
    }
    
    // Construir widgets das seções
    for (int i = 0; i < config.length; i++) {
      final meal = config[i];
      sections.add(
        _buildMealSection(
          meal['type'] as String,
          meal['title'] as String,
          meal['icon'] as IconData,
        ),
      );
      if (i < config.length - 1) {
        sections.add(const SizedBox(height: 24));
      }
    }
    
    return sections;
  }

  Widget _buildMealSection(String mealType, String title, IconData icon) {
    final totals = _calculateMealTotals(mealType);
    final foods = _meals[mealType]!;
    final searchController = _searchControllers[mealType]!;
    final searchResults = _searchResults[mealType]!;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho da refeição
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: AppTheme.primaryColor, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Resumo da refeição
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${totals['calories']!.round()} kcal • '
                  'P: ${totals['protein']!.toStringAsFixed(1)}g • '
                  'C: ${totals['carbs']!.toStringAsFixed(1)}g • '
                  'G: ${totals['fats']!.toStringAsFixed(1)}g',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Campo de busca
          TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: 'Adicionar alimento...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        searchController.clear();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: searchResults.isNotEmpty
                      ? AppTheme.primaryColor
                      : Colors.grey.shade300,
                  width: searchResults.isNotEmpty ? 2 : 1,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: searchResults.isNotEmpty
                      ? AppTheme.primaryColor
                      : Colors.grey.shade300,
                  width: searchResults.isNotEmpty ? 2 : 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppTheme.primaryColor,
                  width: 2,
                ),
              ),
            ),
          ),
          // Resultados da busca
          if (searchResults.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: searchResults.length,
                itemBuilder: (context, index) {
                  final food = searchResults[index];
                  return ListTile(
                    title: Text(food.name),
                    subtitle: Text(
                      '${food.category} • ${food.calories} kcal • '
                      'P: ${food.protein}g | C: ${food.carbs}g | G: ${food.fats}g',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.add_circle, color: AppTheme.primaryColor),
                      onPressed: () => _addFoodToMeal(mealType, food),
                    ),
                  );
                },
              ),
            ),
          ],
          // Lista de alimentos adicionados
          if (foods.isEmpty) ...[
            const SizedBox(height: 16),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  'Nenhum alimento adicionado ainda',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 16),
            ...foods.asMap().entries.map((entry) {
              final index = entry.key;
              final mealFood = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            mealFood.food.name,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${mealFood.quantity.toStringAsFixed(0)}g • '
                            '${mealFood.totalCalories.toStringAsFixed(0)} kcal • '
                            'P: ${mealFood.totalProtein.toStringAsFixed(1)}g | '
                            'C: ${mealFood.totalCarbs.toStringAsFixed(1)}g | '
                            'G: ${mealFood.totalFats.toStringAsFixed(1)}g',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, color: AppTheme.primaryColor),
                      onPressed: () => _editFoodQuantity(mealType, index),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: AppTheme.errorColor),
                      onPressed: () => _removeFoodFromMeal(mealType, index),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildNutritionSummary() {
    final calories = _nutritionData!['calories'] as double;
    final protein = _nutritionData!['protein'] as double;
    final carbs = _nutritionData!['carbs'] as double;
    final fats = _nutritionData!['fats'] as double;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor,
            AppTheme.secondaryColor,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.analytics,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Necessidades Nutricionais',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildNutritionItem(
            label: 'Calorias',
            value: '${calories.round()} kcal',
            icon: Icons.local_fire_department,
            color: Colors.white,
          ),
          const SizedBox(height: 16),
          _buildNutritionItem(
            label: 'Proteínas',
            value: '${protein.round()}g',
            icon: Icons.fitness_center,
            color: Colors.white,
          ),
          const SizedBox(height: 16),
          _buildNutritionItem(
            label: 'Carboidratos',
            value: '${carbs.round()}g',
            icon: Icons.breakfast_dining,
            color: Colors.white,
          ),
          const SizedBox(height: 16),
          _buildNutritionItem(
            label: 'Gorduras',
            value: '${fats.round()}g',
            icon: Icons.water_drop,
            color: Colors.white,
          ),
        ],
      ),
    );
  }

  Widget _buildTotalPlanSummary() {
    final totals = _calculateTotalNutrition();
    final goals = _nutritionData != null
        ? {
            'calories': _nutritionData!['calories'] as double,
            'protein': _nutritionData!['protein'] as double,
            'carbs': _nutritionData!['carbs'] as double,
            'fats': _nutritionData!['fats'] as double,
          }
        : null;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.accentColor,
            AppTheme.accentColor.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentColor.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.summarize,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Resumo Nutricional Total',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildNutritionItem(
            label: 'Calorias',
            value: '${totals['calories']!.round()} kcal',
            icon: Icons.local_fire_department,
            color: Colors.white,
            goal: goals != null ? '${goals['calories']!.round()} kcal' : null,
          ),
          const SizedBox(height: 16),
          _buildNutritionItem(
            label: 'Proteínas',
            value: '${totals['protein']!.round()}g',
            icon: Icons.fitness_center,
            color: Colors.white,
            goal: goals != null ? '${goals['protein']!.round()}g' : null,
          ),
          const SizedBox(height: 16),
          _buildNutritionItem(
            label: 'Carboidratos',
            value: '${totals['carbs']!.round()}g',
            icon: Icons.breakfast_dining,
            color: Colors.white,
            goal: goals != null ? '${goals['carbs']!.round()}g' : null,
          ),
          const SizedBox(height: 16),
          _buildNutritionItem(
            label: 'Gorduras',
            value: '${totals['fats']!.round()}g',
            icon: Icons.water_drop,
            color: Colors.white,
            goal: goals != null ? '${goals['fats']!.round()}g' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionItem({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    String? goal,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                if (goal != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Meta: $goal',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: color.withValues(alpha: 0.8),
                        ),
                  ),
                ],
              ],
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  /// Mostra dialog para coletar restrições alimentares
  Future<void> _showDietaryRestrictionsDialog() async {
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.restaurant_menu, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              const Text('Restrições Alimentares'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selecione suas alergias, intolerâncias ou restrições alimentares:',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                
                // Checkboxes de restrições comuns
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _commonRestrictions.map((restriction) {
                    final isSelected = _selectedRestrictions.contains(restriction);
                    return FilterChip(
                      label: Text(
                        restriction,
                        overflow: TextOverflow.ellipsis,
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        setDialogState(() {
                          if (selected) {
                            _selectedRestrictions.add(restriction);
                          } else {
                            _selectedRestrictions.remove(restriction);
                          }
                        });
                        
                        // Salvar automaticamente no perfil
                        _saveDietaryRestrictionsToProfile();
                      },
                      selectedColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                      checkmarkColor: AppTheme.primaryColor,
                      side: BorderSide(
                        color: isSelected 
                            ? AppTheme.primaryColor 
                            : Colors.grey.shade300,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                
                // Campo de texto para restrições customizadas
                TextField(
                  controller: _customRestrictionsController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Outras restrições alimentares',
                    hintText: 'Descreva outras alergias, intolerâncias ou restrições...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    helperText: 'Ex: Alergia a corantes, restrição de sódio, etc.',
                  ),
                  textInputAction: TextInputAction.newline,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
              ),
              child: const Text('Confirmar'),
            ),
          ],
        ),
      ),
    );
  }

}
