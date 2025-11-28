import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../theme/app_theme.dart';
import '../models/user_profile.dart';
import '../models/food_item.dart';
import '../services/firestore_service.dart';

class MealsListScreen extends StatefulWidget {
  final UserProfile? userProfile;

  const MealsListScreen({
    super.key,
    this.userProfile,
  });

  @override
  State<MealsListScreen> createState() => _MealsListScreenState();
}

class _MealsListScreenState extends State<MealsListScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  List<Map<String, dynamic>> _meals = [];
  bool _isLoading = true;
  bool _isSaving = false;
  String? _selectedDietId;
  List<Map<String, dynamic>> _availableDiets = [];
  StreamSubscription<List<Map<String, dynamic>>>? _mealsSubscription;

  @override
  void initState() {
    super.initState();
    _loadMealPlans();
  }

  @override
  void dispose() {
    _mealsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadMealPlans() async {
    if (widget.userProfile == null || widget.userProfile!.id == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      final mealPlans = await _firestoreService.getUserMealPlans(widget.userProfile!.id!);
      
      if (mealPlans.isNotEmpty) {
        setState(() {
          _availableDiets = mealPlans;
          _selectedDietId = mealPlans.first['id'] as String;
        });
        await _loadMealsFromPlan(mealPlans.first);
        _startMealsStream();
      } else {
        setState(() {
          _meals = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar planos alimentares: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _loadMealsFromPlan(Map<String, dynamic> mealPlan) async {
    try {
      final mealsData = mealPlan['meals'] as Map<String, dynamic>?;
      if (mealsData == null) {
        debugPrint('⚠️ mealsData é null no plano: ${mealPlan['dietName']}');
        setState(() {
          _meals = [];
          _isLoading = false;
        });
        return;
      }
      
      debugPrint('📋 Carregando plano: ${mealPlan['dietName']}');
      debugPrint('🍽️ Refeições disponíveis no plano: ${mealsData.keys.toList()}');
      debugPrint('👤 mealsPerDay do usuário: ${widget.userProfile?.mealsPerDayOrDefault ?? 5}');

      final List<Map<String, dynamic>> mealsList = [];
      
      // Obter o número de refeições do perfil do usuário
      final mealsPerDay = widget.userProfile?.mealsPerDayOrDefault ?? 5;
      
      // Mapear mealType para informações de exibição
      final mealTypeMap = {
        'breakfast': {'name': 'Café da Manhã', 'time': '08:00', 'icon': Icons.wb_sunny_outlined},
        'morning_snack': {'name': 'Lanche da Manhã', 'time': '10:30', 'icon': Icons.cookie_outlined},
        'lunch': {'name': 'Almoço', 'time': '13:00', 'icon': Icons.lunch_dining_outlined},
        'afternoon_snack': {'name': 'Lanche da Tarde', 'time': '16:00', 'icon': Icons.cookie_outlined},
        'dinner': {'name': 'Jantar', 'time': '19:00', 'icon': Icons.dinner_dining_outlined},
        'evening_snack': {'name': 'Ceia', 'time': '21:00', 'icon': Icons.nightlight_outlined},
        'late_snack': {'name': 'Lanche Noturno', 'time': '23:00', 'icon': Icons.bedtime_outlined},
      };

      // Definir a ordem das refeições baseada no número de refeições por dia
      final mealConfigs = <int, List<String>>{
        3: ['breakfast', 'lunch', 'dinner'],
        4: ['breakfast', 'lunch', 'afternoon_snack', 'dinner'],
        5: ['breakfast', 'morning_snack', 'lunch', 'afternoon_snack', 'dinner'],
        6: ['breakfast', 'morning_snack', 'lunch', 'afternoon_snack', 'dinner', 'evening_snack'],
        7: ['breakfast', 'morning_snack', 'lunch', 'afternoon_snack', 'dinner', 'evening_snack', 'late_snack'],
      };
      
      // Obter a ordem de refeições correspondente ao mealsPerDay
      final mealOrder = mealConfigs[mealsPerDay] ?? mealConfigs[5]!;
      
      // Processar apenas as refeições que correspondem ao mealsPerDay
      for (final mealType in mealOrder) {
        if (mealsData.containsKey(mealType)) {
          final mealFoodsData = mealsData[mealType] as List<dynamic>;
          if (mealFoodsData.isNotEmpty) {
            final mealInfo = mealTypeMap[mealType] ?? {'name': mealType, 'time': '12:00', 'icon': Icons.restaurant};
            
            // Converter MealFood para formato da lista
            final foods = mealFoodsData.map((mfData) {
              // Verificar se mfData é um Map antes de tentar fazer fromMap
              if (mfData is! Map<String, dynamic>) {
                // Se não for Map, pode ser que já esteja no formato esperado
                return {
                  'name': mfData['name'] ?? 'Alimento desconhecido',
                  'quantity': '${(mfData['quantity'] ?? 0).toStringAsFixed(0)}g',
                  'calories': ((mfData['calories'] ?? 0) as num).toInt(),
                };
              }
              
              try {
                final mealFood = MealFood.fromMap(mfData as Map<String, dynamic>);
                return {
                  'name': mealFood.food.name,
                  'quantity': '${mealFood.quantity.toStringAsFixed(0)}g',
                  'calories': mealFood.totalCalories.round(),
                };
              } catch (e) {
                // Se falhar ao fazer fromMap, tentar extrair dados diretamente
                final foodData = mfData['food'] as Map<String, dynamic>?;
                if (foodData != null) {
                  return {
                    'name': foodData['name'] ?? 'Alimento desconhecido',
                    'quantity': '${(mfData['quantity'] ?? 0).toStringAsFixed(0)}g',
                    'calories': ((foodData['calories'] ?? 0) * ((mfData['quantity'] ?? 100) / 100)).round(),
                  };
                }
                return {
                  'name': 'Alimento desconhecido',
                  'quantity': '0g',
                  'calories': 0,
                };
              }
            }).toList();

            // Calcular total de calorias da refeição
            final totalCalories = foods.fold<int>(0, (sum, food) => sum + (food['calories'] as int));

            mealsList.add({
              'id': '${mealType}_${_selectedDietId}',
              'name': mealInfo['name'] as String,
              'time': mealInfo['time'] as String,
              'calories': totalCalories,
              'foods': foods,
              'isCompleted': false,
              'icon': mealInfo['icon'] as IconData,
            });
          }
        }
      }

      debugPrint('✅ Refeições processadas: ${mealsList.length}');
      for (var meal in mealsList) {
        debugPrint('  - ${meal['name']}: ${meal['foods'].length} alimentos, ${meal['calories']} kcal');
      }

      // Carregar dados salvos do Firestore (horários e status)
      await _loadSavedMealData(mealsList);

      setState(() {
        _meals = mealsList;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      debugPrint('❌ Erro ao processar plano alimentar: $e');
      debugPrint('Stack trace: $stackTrace');
      
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao processar plano alimentar: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  // Dados mockados antigos (removidos - agora carregamos do Firestore)
  /*
  final List<Map<String, dynamic>> _meals = [
    {
      'id': '1',
      'name': 'Café da Manhã',
      'time': '08:00',
      'calories': 350,
      'foods': [
        {'name': 'Ovos mexidos', 'quantity': '2 unidades', 'calories': 155},
        {'name': 'Pão integral', 'quantity': '2 fatias', 'calories': 120},
        {'name': 'Suco de laranja', 'quantity': '200ml', 'calories': 75},
      ],
      'isCompleted': true,
      'icon': Icons.wb_sunny_outlined,
    },
    {
      'id': '2',
      'name': 'Lanche da Manhã',
      'time': '10:30',
      'calories': 150,
      'foods': [
        {'name': 'Banana', 'quantity': '1 unidade', 'calories': 89},
        {'name': 'Iogurte natural', 'quantity': '100g', 'calories': 59},
      ],
      'isCompleted': false,
      'icon': Icons.cookie_outlined,
    },
    {
      'id': '3',
      'name': 'Almoço',
      'time': '13:00',
      'calories': 650,
      'foods': [
        {'name': 'Peito de frango grelhado', 'quantity': '150g', 'calories': 248},
        {'name': 'Arroz integral', 'quantity': '100g', 'calories': 111},
        {'name': 'Brócolis cozido', 'quantity': '150g', 'calories': 52},
        {'name': 'Salada verde', 'quantity': '100g', 'calories': 20},
        {'name': 'Azeite de oliva', 'quantity': '1 colher', 'calories': 119},
      ],
      'isCompleted': true,
      'icon': Icons.lunch_dining_outlined,
    },
    {
      'id': '4',
      'name': 'Lanche da Tarde',
      'time': '16:00',
      'calories': 200,
      'foods': [
        {'name': 'Maçã', 'quantity': '1 unidade', 'calories': 52},
        {'name': 'Amendoim', 'quantity': '30g', 'calories': 180},
      ],
      'isCompleted': false,
      'icon': Icons.cookie_outlined,
    },
    {
      'id': '5',
      'name': 'Jantar',
      'time': '19:00',
      'calories': 450,
      'foods': [
        {'name': 'Salmão grelhado', 'quantity': '150g', 'calories': 309},
        {'name': 'Batata doce', 'quantity': '150g', 'calories': 129},
        {'name': 'Salada verde', 'quantity': '100g', 'calories': 20},
      ],
      'isCompleted': false,
      'icon': Icons.dinner_dining_outlined,
    },
  ];
  */

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    final totalCalories = _meals.fold<int>(
      0,
      (sum, meal) => sum + (meal['calories'] as int),
    );

    final completedMeals = _meals.where((meal) => meal['isCompleted'] == true).length;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Refeições do Dia'),
        elevation: 0,
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
          if (_availableDiets.isNotEmpty)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (dietId) async {
                setState(() {
                  _selectedDietId = dietId;
                });
                final selectedDiet = _availableDiets.firstWhere((d) => d['id'] == dietId);
                await _loadMealsFromPlan(selectedDiet);
                _startMealsStream();
              },
              itemBuilder: (context) => _availableDiets.map((diet) {
                return PopupMenuItem<String>(
                  value: diet['id'] as String,
                  child: Text(diet['dietName'] as String? ?? 'Dieta sem nome'),
                );
              }).toList(),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _meals.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.restaurant_menu,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Nenhum plano alimentar encontrado',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Crie um plano na Calculadora de Dieta',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey.shade500,
                            ),
                      ),
                    ],
                  ),
                )
              : Column(
        children: [
          // Resumo do dia
          Container(
            margin: const EdgeInsets.all(16),
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem(
                  icon: Icons.restaurant_menu,
                  label: 'Refeições',
                  value: '${_meals.length}',
                ),
                _buildSummaryItem(
                  icon: Icons.check_circle,
                  label: 'Concluídas',
                  value: '$completedMeals',
                ),
                _buildSummaryItem(
                  icon: Icons.local_fire_department,
                  label: 'Total',
                  value: '$totalCalories kcal',
                ),
              ],
            ),
          ),
          // Lista de refeições
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _meals.length,
              itemBuilder: (context, index) {
                final meal = _meals[index];
                return _buildMealCard(meal, index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildMealCard(Map<String, dynamic> meal, int index) {
    final isCompleted = meal['isCompleted'] as bool;
    final foods = meal['foods'] as List<Map<String, dynamic>>;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCompleted
              ? AppTheme.primaryColor.withValues(alpha: 0.3)
              : Colors.grey.shade200,
          width: isCompleted ? 2 : 1,
        ),
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? AppTheme.primaryColor.withValues(alpha: 0.1)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    meal['icon'] as IconData,
                    color: isCompleted
                        ? AppTheme.primaryColor
                        : Colors.grey.shade600,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        meal['name'] as String,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            meal['time'] as String,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () => _editMealTime(index),
                            child: Icon(
                              Icons.edit_outlined,
                              size: 16,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Checkbox para marcar como concluída
                Checkbox(
                  value: isCompleted,
                  onChanged: (value) async {
                    setState(() {
                      _meals[index]['isCompleted'] = value ?? false;
                    });
                    
                    // Salvar automaticamente após mudar status
                    await _saveMealsToFirestore();
                  },
                  activeColor: AppTheme.primaryColor,
                ),
              ],
            ),
          ),
          // Lista de alimentos
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(16),
              ),
            ),
            child: Column(
              children: [
                ...foods.map((food) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Icon(
                                Icons.circle,
                                size: 6,
                                color: AppTheme.primaryColor,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  food['name'] as String,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${food['quantity']} • ${food['calories']} kcal',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey.shade600,
                              ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 8),
                // Total da refeição
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total da refeição',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      Text(
                        '${meal['calories']} kcal',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Carrega dados salvos do Firestore (horários e status de conclusão)
  Future<void> _loadSavedMealData(List<Map<String, dynamic>> mealsList) async {
    if (widget.userProfile?.id == null) return;

    try {
      final today = DateTime.now();
      final savedMeals = await _firestoreService.getDailyMeals(
        userId: widget.userProfile!.id!,
        date: today,
      );

      if (savedMeals.isNotEmpty) {
        // Criar um mapa para busca rápida por ID da refeição
        final savedMealsMap = <String, Map<String, dynamic>>{};
        for (final savedMeal in savedMeals) {
          final mealId = savedMeal['id'] as String?;
          if (mealId != null) {
            savedMealsMap[mealId] = savedMeal;
          }
        }

        // Atualizar refeições com dados salvos
        for (int i = 0; i < mealsList.length; i++) {
          final mealId = mealsList[i]['id'] as String;
          if (savedMealsMap.containsKey(mealId)) {
            final savedMeal = savedMealsMap[mealId]!;
            if (savedMeal['time'] != null) {
              mealsList[i]['time'] = savedMeal['time'] as String;
            }
            if (savedMeal['isCompleted'] != null) {
              mealsList[i]['isCompleted'] = savedMeal['isCompleted'] as bool;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Erro ao carregar dados salvos: $e');
      // Não mostrar erro ao usuário, apenas usar valores padrão
    }
  }

  /// Salva as refeições no Firestore
  Future<void> _saveMealsToFirestore() async {
    if (widget.userProfile?.id == null || _isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final today = DateTime.now();
      
      // Preparar dados para salvar
      final mealsToSave = _meals.map((meal) => {
        'id': meal['id'] as String,
        'name': meal['name'] as String,
        'time': meal['time'] as String,
        'calories': meal['calories'] as int,
        'isCompleted': meal['isCompleted'] as bool,
        'foods': meal['foods'] as List<Map<String, dynamic>>,
      }).toList();

      await _firestoreService.saveDailyMeals(
        userId: widget.userProfile!.id!,
        date: today,
        meals: mealsToSave,
      );

      if (mounted) {
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Dados salvos com sucesso!'),
              ],
            ),
            backgroundColor: AppTheme.primaryColor,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('Erro ao salvar refeições: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Erro ao salvar: ${e.toString().replaceFirst('Exception: ', '')}',
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.errorColor,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  /// Inicia o stream para sincronização automática
  void _startMealsStream() {
    if (widget.userProfile?.id == null) return;

    _mealsSubscription?.cancel();
    
    final today = DateTime.now();
    _mealsSubscription = _firestoreService.streamDailyMeals(
      userId: widget.userProfile!.id!,
      date: today,
    ).listen(
      (savedMeals) {
        if (savedMeals.isNotEmpty && mounted) {
          // Atualizar apenas se houver mudanças externas
          _syncMealsWithFirestore(savedMeals);
        }
      },
      onError: (error) {
        debugPrint('Erro no stream de refeições: $error');
      },
    );
  }

  /// Sincroniza refeições locais com dados do Firestore
  void _syncMealsWithFirestore(List<Map<String, dynamic>> savedMeals) {
    final savedMealsMap = <String, Map<String, dynamic>>{};
    for (final savedMeal in savedMeals) {
      final mealId = savedMeal['id'] as String?;
      if (mealId != null) {
        savedMealsMap[mealId] = savedMeal;
      }
    }

    bool hasChanges = false;
    for (int i = 0; i < _meals.length; i++) {
      final mealId = _meals[i]['id'] as String;
      if (savedMealsMap.containsKey(mealId)) {
        final savedMeal = savedMealsMap[mealId]!;
        if (savedMeal['time'] != null && _meals[i]['time'] != savedMeal['time']) {
          _meals[i]['time'] = savedMeal['time'] as String;
          hasChanges = true;
        }
        if (savedMeal['isCompleted'] != null && 
            _meals[i]['isCompleted'] != savedMeal['isCompleted']) {
          _meals[i]['isCompleted'] = savedMeal['isCompleted'] as bool;
          hasChanges = true;
        }
      }
    }

    if (hasChanges && mounted) {
      setState(() {});
    }
  }

  Future<void> _editMealTime(int index) async {
    final meal = _meals[index];
    final currentTime = meal['time'] as String;
    
    // Converter string de hora (HH:mm) para TimeOfDay
    final timeParts = currentTime.split(':');
    final initialTime = TimeOfDay(
      hour: int.parse(timeParts[0]),
      minute: int.parse(timeParts[1]),
    );

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      helpText: 'Selecione o horário',
      cancelText: 'Cancelar',
      confirmText: 'Confirmar',
    );

    if (picked != null) {
      setState(() {
        final formattedTime = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
        _meals[index]['time'] = formattedTime;
      });
      
      // Salvar automaticamente após editar horário
      await _saveMealsToFirestore();
    }
  }
}

