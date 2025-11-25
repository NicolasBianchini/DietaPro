import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../models/user_profile.dart';
import '../models/food_item.dart';
import '../utils/nutrition_calculator.dart';
import '../utils/food_database.dart';
import '../services/gemini_service.dart';

class DietCalculatorScreen extends StatefulWidget {
  final UserProfile? userProfile;

  const DietCalculatorScreen({
    super.key,
    this.userProfile,
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

  // Alimentos por refeição
  final Map<String, List<MealFood>> _meals = {
    'breakfast': [],
    'morning_snack': [],
    'lunch': [],
    'afternoon_snack': [],
    'dinner': [],
  };

  // Controllers de busca por refeição
  final Map<String, TextEditingController> _searchControllers = {
    'breakfast': TextEditingController(),
    'morning_snack': TextEditingController(),
    'lunch': TextEditingController(),
    'afternoon_snack': TextEditingController(),
    'dinner': TextEditingController(),
  };

  // Resultados de busca por refeição
  final Map<String, List<FoodItem>> _searchResults = {
    'breakfast': [],
    'morning_snack': [],
    'lunch': [],
    'afternoon_snack': [],
    'dinner': [],
  };

  @override
  void initState() {
    super.initState();
    // Preencher com dados do perfil se disponível
    if (widget.userProfile != null) {
      if (widget.userProfile!.height != null) {
        _heightController.text = widget.userProfile!.height!.toStringAsFixed(0);
      }
      if (widget.userProfile!.weight != null) {
        _weightController.text = widget.userProfile!.weight!.toStringAsFixed(1);
      }
    }

    // Adicionar listeners para busca
    for (final entry in _searchControllers.entries) {
      entry.value.addListener(() {
        _performSearch(entry.key, entry.value.text);
      });
    }
  }

  @override
  void dispose() {
    _dietNameController.dispose();
    _descriptionController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _searchControllers.values.forEach((controller) => controller.dispose());
    super.dispose();
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

      // Gerar plano alimentar usando TACO
      final mealPlanData = await GeminiService.instance.generateMealPlanFromTACO(
        dailyCalories: (nutritionData['calories'] as double).round(),
        protein: nutritionData['protein'] as double,
        carbs: nutritionData['carbs'] as double,
        fats: nutritionData['fats'] as double,
        gender: genderText,
        age: widget.userProfile!.age!,
        activityLevel: activityText,
        goal: goalText,
        mealsPerDay: 5,
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
              
              if (_meals.containsKey(mealType)) {
                _meals[mealType]!.add(mealFood);
              }
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
      body: SingleChildScrollView(
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
              const SizedBox(height: 32),
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
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _calculateNutrition,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          shadowColor: AppTheme.primaryColor.withValues(alpha: 0.3),
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                'Calcular Necessidades Nutricionais',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
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
                const SizedBox(height: 32),
                _buildMealSection('breakfast', 'Café da Manhã', Icons.wb_sunny_outlined),
                const SizedBox(height: 24),
                _buildMealSection('morning_snack', 'Lanche da Manhã', Icons.cookie_outlined),
                const SizedBox(height: 24),
                _buildMealSection('lunch', 'Almoço', Icons.lunch_dining_outlined),
                const SizedBox(height: 24),
                _buildMealSection('afternoon_snack', 'Lanche da Tarde', Icons.cookie_outlined),
                const SizedBox(height: 24),
                _buildMealSection('dinner', 'Jantar', Icons.dinner_dining_outlined),
                const SizedBox(height: 32),
                // Resumo Total do Plano
                _buildTotalPlanSummary(),
                const SizedBox(height: 24),
                // Botão de confirmar
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Plano alimentar salvo com sucesso!'),
                          backgroundColor: AppTheme.primaryColor,
                        ),
                      );
                    },
                    icon: const Icon(Icons.check, color: Colors.white),
                    label: const Text(
                      'Confirmar Plano Alimentar',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
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

}
