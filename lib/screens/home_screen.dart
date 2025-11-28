import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../theme/app_theme.dart';
import '../models/user_profile.dart';
import '../services/firestore_service.dart';
import 'login_screen.dart';
import 'diet_calculator_screen.dart';
import 'meals_list_screen.dart';
import 'edit_profile_screen.dart';
import 'help_screen.dart';
import 'settings_screen.dart';
import 'statistics_screen.dart';
import 'water_tracking_screen.dart';
import 'weight_tracking_screen.dart';
import 'meal_plans_list_screen.dart';

class HomeScreen extends StatefulWidget {
  final UserProfile? userProfile;

  const HomeScreen({
    super.key,
    this.userProfile,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  
  // Dados reais do Firestore
  int _caloriesConsumed = 0;
  int _caloriesGoal = 0;
  double _protein = 0.0;
  double _proteinGoal = 0.0;
  double _carbs = 0.0;
  double _carbsGoal = 0.0;
  double _fats = 0.0;
  double _fatsGoal = 0.0;
  
  int _currentIndex = 1; // Índice inicial (meio = Home)
  bool _isLoading = true;
  
  // Refeições do dia - carregadas do Firestore
  List<Map<String, dynamic>> _todayMeals = [];
  Map<String, dynamic>? _currentMealPlan;
  StreamSubscription<List<Map<String, dynamic>>>? _mealsSubscription;
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _mealsSubscription?.cancel();
    super.dispose();
  }

  /// Carrega todos os dados necessários
  Future<void> _loadData() async {
    if (widget.userProfile?.id == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _loadMealPlan();
      await _loadTodayMeals();
      _calculateNutrition();
      _startMealsStream();
    } catch (e) {
      debugPrint('Erro ao carregar dados: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Carrega o plano alimentar atual
  Future<void> _loadMealPlan() async {
    if (widget.userProfile?.id == null) return;

    try {
      final mealPlans = await _firestoreService.getUserMealPlans(widget.userProfile!.id!);
      
      if (mealPlans.isNotEmpty) {
        // Usar o plano mais recente
        _currentMealPlan = mealPlans.first;
        
        // Carregar metas nutricionais do plano
        if (_currentMealPlan!['nutritionData'] != null) {
          final nutritionData = _currentMealPlan!['nutritionData'] as Map<String, dynamic>;
          _caloriesGoal = (nutritionData['calories'] as num?)?.toInt() ?? 0;
          _proteinGoal = (nutritionData['protein'] as num?)?.toDouble() ?? 0.0;
          _carbsGoal = (nutritionData['carbs'] as num?)?.toDouble() ?? 0.0;
          _fatsGoal = (nutritionData['fats'] as num?)?.toDouble() ?? 0.0;
        }
      }
    } catch (e) {
      debugPrint('Erro ao carregar plano alimentar: $e');
    }
  }

  /// Carrega as refeições do dia atual
  Future<void> _loadTodayMeals() async {
    if (widget.userProfile?.id == null || _currentMealPlan == null) {
      _todayMeals = [];
      return;
    }

    try {
      final today = DateTime.now();
      final savedMeals = await _firestoreService.getDailyMeals(
        userId: widget.userProfile!.id!,
        date: today,
      );

      // Se há refeições salvas, usar elas e garantir que têm ícones
      if (savedMeals.isNotEmpty) {
        _todayMeals = _ensureMealsHaveIcons(savedMeals);
      } else {
        // Caso contrário, criar refeições baseadas no plano
        _todayMeals = _createMealsFromPlan();
      }
    } catch (e) {
      debugPrint('Erro ao carregar refeições do dia: $e');
      _todayMeals = _createMealsFromPlan();
    }
  }

  /// Garante que todas as refeições têm ícones válidos
  List<Map<String, dynamic>> _ensureMealsHaveIcons(List<Map<String, dynamic>> meals) {
    final mealTypeMap = {
      'breakfast': Icons.wb_sunny_outlined,
      'morning_snack': Icons.cookie_outlined,
      'lunch': Icons.lunch_dining_outlined,
      'afternoon_snack': Icons.cookie_outlined,
      'dinner': Icons.dinner_dining_outlined,
      'evening_snack': Icons.nightlight_outlined,
      'late_snack': Icons.bedtime_outlined,
    };

    return meals.map((meal) {
      // Se já tem ícone válido, manter
      if (meal['icon'] != null && meal['icon'] is IconData) {
        return meal;
      }

      // Tentar determinar o tipo de refeição pelo nome ou ID
      final mealName = (meal['name'] as String? ?? meal['meal'] as String? ?? '').toLowerCase();
      final mealId = meal['id'] as String? ?? '';
      
      IconData? icon;
      
      // Verificar pelo ID primeiro
      for (final entry in mealTypeMap.entries) {
        if (mealId.contains(entry.key)) {
          icon = entry.value;
          break;
        }
      }
      
      // Se não encontrou pelo ID, tentar pelo nome
      if (icon == null) {
        if (mealName.contains('café') || mealName.contains('manhã')) {
          icon = Icons.wb_sunny_outlined;
        } else if (mealName.contains('almoço')) {
          icon = Icons.lunch_dining_outlined;
        } else if (mealName.contains('jantar')) {
          icon = Icons.dinner_dining_outlined;
        } else if (mealName.contains('lanche') || mealName.contains('snack')) {
          icon = Icons.cookie_outlined;
        } else if (mealName.contains('ceia')) {
          icon = Icons.nightlight_outlined;
        } else {
          icon = Icons.restaurant; // Ícone padrão
        }
      }

      return {
        ...meal,
        'icon': icon,
      };
    }).toList();
  }

  /// Cria lista de refeições baseada no plano alimentar
  List<Map<String, dynamic>> _createMealsFromPlan() {
    if (_currentMealPlan == null) return [];

    final mealsData = _currentMealPlan!['meals'] as Map<String, dynamic>?;
    if (mealsData == null) return [];

    final mealTypeMap = {
      'breakfast': {'name': 'Café da Manhã', 'time': '08:00', 'icon': Icons.wb_sunny_outlined},
      'morning_snack': {'name': 'Lanche da Manhã', 'time': '10:30', 'icon': Icons.cookie_outlined},
      'lunch': {'name': 'Almoço', 'time': '13:00', 'icon': Icons.lunch_dining_outlined},
      'afternoon_snack': {'name': 'Lanche da Tarde', 'time': '16:00', 'icon': Icons.cookie_outlined},
      'dinner': {'name': 'Jantar', 'time': '19:00', 'icon': Icons.dinner_dining_outlined},
      'evening_snack': {'name': 'Ceia', 'time': '21:00', 'icon': Icons.nightlight_outlined},
      'late_snack': {'name': 'Lanche Noturno', 'time': '23:00', 'icon': Icons.bedtime_outlined},
    };

    final mealsList = <Map<String, dynamic>>[];
    final mealsPerDay = widget.userProfile?.mealsPerDayOrDefault ?? 5;
    
    final mealConfigs = <int, List<String>>{
      3: ['breakfast', 'lunch', 'dinner'],
      4: ['breakfast', 'lunch', 'afternoon_snack', 'dinner'],
      5: ['breakfast', 'morning_snack', 'lunch', 'afternoon_snack', 'dinner'],
      6: ['breakfast', 'morning_snack', 'lunch', 'afternoon_snack', 'dinner', 'evening_snack'],
      7: ['breakfast', 'morning_snack', 'lunch', 'afternoon_snack', 'dinner', 'evening_snack', 'late_snack'],
    };

    final mealOrder = mealConfigs[mealsPerDay] ?? mealConfigs[5]!;

    for (final mealType in mealOrder) {
      if (mealsData.containsKey(mealType)) {
        final mealFoodsData = mealsData[mealType] as List<dynamic>;
        if (mealFoodsData.isNotEmpty) {
          int totalCalories = 0;
          for (var foodData in mealFoodsData) {
            final calories = (foodData['calories'] as num?)?.toDouble() ?? 0.0;
            totalCalories += calories.round();
          }

          final mealInfo = mealTypeMap[mealType] ?? {'name': mealType, 'time': '12:00', 'icon': Icons.restaurant};
          
          mealsList.add({
            'id': '${mealType}_${_currentMealPlan!['id']}',
            'name': mealInfo['name'] as String,
            'time': mealInfo['time'] as String,
            'calories': totalCalories,
            'isCompleted': false,
            'icon': mealInfo['icon'] as IconData,
          });
        }
      }
    }

    return mealsList;
  }

  /// Calcula os macros consumidos baseado nas refeições completadas
  void _calculateNutrition() {
    _caloriesConsumed = 0;
    _protein = 0.0;
    _carbs = 0.0;
    _fats = 0.0;

    for (final meal in _todayMeals) {
      if (meal['isCompleted'] == true) {
        // Adicionar calorias
        _caloriesConsumed += (meal['calories'] as num?)?.toInt() ?? 0;
        
        // Se há macros diretos na refeição, usar eles
        if (meal['protein'] != null || meal['carbs'] != null || meal['fats'] != null) {
          _protein += (meal['protein'] as num?)?.toDouble() ?? 0.0;
          _carbs += (meal['carbs'] as num?)?.toDouble() ?? 0.0;
          _fats += (meal['fats'] as num?)?.toDouble() ?? 0.0;
        } 
        // Caso contrário, calcular a partir dos alimentos
        else if (meal['foods'] != null) {
          final foods = meal['foods'] as List<dynamic>;
          for (var foodData in foods) {
            // Se o alimento já tem macros calculados, usar direto
            if (foodData['protein'] != null || foodData['carbs'] != null || foodData['fats'] != null) {
              _protein += (foodData['protein'] as num?)?.toDouble() ?? 0.0;
              _carbs += (foodData['carbs'] as num?)?.toDouble() ?? 0.0;
              _fats += (foodData['fats'] as num?)?.toDouble() ?? 0.0;
            } 
            // Caso contrário, tentar calcular a partir dos dados do alimento
            else {
              final food = foodData['food'] as Map<String, dynamic>?;
              if (food != null) {
                // Extrair quantidade (pode estar como "100g" ou 100)
                var quantity = 100.0;
                final quantityStr = foodData['quantity'];
                if (quantityStr is num) {
                  quantity = quantityStr.toDouble();
                } else if (quantityStr is String) {
                  final numStr = quantityStr.replaceAll(RegExp(r'[^0-9.]'), '');
                  quantity = double.tryParse(numStr) ?? 100.0;
                }
                
                final baseProtein = (food['protein'] as num?)?.toDouble() ?? 0.0;
                final baseCarbs = (food['carbs'] as num?)?.toDouble() ?? 0.0;
                final baseFats = (food['fats'] as num?)?.toDouble() ?? 0.0;
                
                // Calcular valores proporcionais à quantidade
                final multiplier = quantity / 100.0;
                _protein += baseProtein * multiplier;
                _carbs += baseCarbs * multiplier;
                _fats += baseFats * multiplier;
              }
            }
          }
        }
      }
    }

    // Se não há metas definidas, usar valores padrão baseados em calorias
    if (_caloriesGoal == 0) {
      _caloriesGoal = 2000; // Valor padrão
    }
    if (_proteinGoal == 0) {
      _proteinGoal = _caloriesGoal * 0.25 / 4; // 25% de proteína
    }
    if (_carbsGoal == 0) {
      _carbsGoal = _caloriesGoal * 0.45 / 4; // 45% de carboidratos
    }
    if (_fatsGoal == 0) {
      _fatsGoal = _caloriesGoal * 0.30 / 9; // 30% de gorduras
    }
  }

  /// Inicia stream para sincronização automática
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
          setState(() {
            _todayMeals = savedMeals;
            _calculateNutrition();
          });
        }
      },
      onError: (error) {
        debugPrint('Erro no stream de refeições: $error');
      },
    );
  }
  
  // Obter próximas refeições pendentes
  List<Map<String, dynamic>> get _nextMeals {
    final now = DateTime.now();
    final currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    
    // Filtrar apenas refeições pendentes e que ainda não passaram
    final pendingMeals = _todayMeals.where((meal) {
      if (meal['isCompleted'] == true) return false;
      final mealTime = meal['time'] as String;
      return mealTime.compareTo(currentTime) >= 0;
    }).toList();
    
    // Ordenar por horário
    pendingMeals.sort((a, b) {
      final timeA = a['time'] as String;
      final timeB = b['time'] as String;
      return timeA.compareTo(timeB);
    });
    
    // Retornar apenas as próximas 3
    return pendingMeals.take(3).toList();
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
      body: _getCurrentScreen(),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _getCurrentScreen() {
    switch (_currentIndex) {
      case 0:
        return MealsListScreen(userProfile: widget.userProfile);
      case 1:
        return _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SafeArea(
                child: RefreshIndicator(
                  onRefresh: _loadData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  _buildGreeting(),
                  _buildCaloriesCard(),
                  _buildMacrosSection(),
                  const SizedBox(height: 28),
                  _buildGenerateMealsButton(),
                  _buildQuickActions(),
                  _buildTodayMeals(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
            );
      case 2:
        return _buildProfileScreen();
      default:
        return const SizedBox();
    }
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: Colors.grey.shade600,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu),
            label: 'Refeições',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Início',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }

  Widget _buildProfileScreen() {
    final userName = widget.userProfile?.name ?? 'Usuário';
    String initials = 'U';
    if (widget.userProfile?.name != null && widget.userProfile!.name.isNotEmpty) {
      final names = widget.userProfile!.name.trim().split(' ');
      if (names.length >= 2) {
        initials = '${names[0][0]}${names[names.length - 1][0]}'.toUpperCase();
      } else if (names.isNotEmpty) {
        initials = names[0][0].toUpperCase();
      }
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 32),
            // Avatar
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 48,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Nome
            Text(
              userName,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.userProfile?.email ?? 'email@exemplo.com',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
            const SizedBox(height: 48),
            // Opções do menu
            _buildProfileMenuItem(
              icon: Icons.person_outline,
              title: 'Editar Perfil',
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditProfileScreen(userProfile: widget.userProfile!),
                  ),
                );
                // Se o perfil foi atualizado, recarregar a tela
                if (result != null && mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HomeScreen(userProfile: result as UserProfile),
                  ),
                );
                }
              },
            ),
            const SizedBox(height: 16),
            _buildProfileMenuItem(
              icon: Icons.calculate,
              title: 'Calculadora de Dieta',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DietCalculatorScreen(userProfile: widget.userProfile),
                  ),
                ).then((_) => _loadData());
              },
            ),
            const SizedBox(height: 16),
            _buildProfileMenuItem(
              icon: Icons.restaurant_menu_outlined,
              title: 'Meus Planos Alimentares',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MealPlansListScreen(userProfile: widget.userProfile),
                  ),
                ).then((_) => _loadData());
              },
            ),
            const SizedBox(height: 16),
            _buildProfileMenuItem(
              icon: Icons.settings_outlined,
              title: 'Configurações',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SettingsScreen(userProfile: widget.userProfile),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildProfileMenuItem(
              icon: Icons.bar_chart_outlined,
              title: 'Estatísticas',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StatisticsScreen(userProfile: widget.userProfile),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildProfileMenuItem(
              icon: Icons.help_outline,
              title: 'Ajuda',
              onTap: _navigateToHelp,
            ),
            const SizedBox(height: 32),
            // Botão de logout
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _handleLogout,
                icon: const Icon(Icons.logout),
                label: const Text('Sair'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.errorColor,
                  side: BorderSide(color: AppTheme.errorColor),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.primaryColor, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'DietaPro',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                _getGreeting(),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          _buildProfileButton(),
        ],
      ),
    );
  }

  Widget _buildProfileButton() {
    // Obter iniciais do nome do usuário para o avatar
    String initials = 'U';
    if (widget.userProfile?.name != null && widget.userProfile!.name.isNotEmpty) {
      final names = widget.userProfile!.name.trim().split(' ');
      if (names.length >= 2) {
        initials = '${names[0][0]}${names[names.length - 1][0]}'.toUpperCase();
      } else if (names.isNotEmpty) {
        initials = names[0][0].toUpperCase();
      }
    }

    return InkWell(
      onTap: () {
        setState(() {
          _currentIndex = 2; // Navegar para a tela de perfil
        });
      },
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppTheme.primaryColor,
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            initials,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToHelp() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const HelpScreen(),
      ),
    );
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sair'),
        content: const Text('Tem certeza que deseja sair da sua conta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implementar lógica de logout
              // Limpar dados do usuário e navegar para tela de login
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (_) => const LoginScreen(),
                ),
                (route) => false,
              );
            },
            child: Text(
              'Sair',
              style: TextStyle(color: AppTheme.errorColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGreeting() {
    final userName = widget.userProfile?.name ?? 'Usuário';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Text(
        'Olá, $userName! 👋',
        style: Theme.of(context).textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildCaloriesCard() {
    final progress = _caloriesConsumed / _caloriesGoal;
    final remaining = _caloriesGoal - _caloriesConsumed;

    return Container(
      margin: const EdgeInsets.all(20.0),
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Calorias de Hoje',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${_caloriesConsumed} / $_caloriesGoal',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Barra de progresso
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress > 1.0 ? 1.0 : progress,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.3),
              valueColor: AlwaysStoppedAnimation<Color>(
                progress > 1.0 ? AppTheme.accentColor : Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem(
                icon: Icons.local_fire_department,
                label: 'Consumidas',
                value: '$_caloriesConsumed',
                color: Colors.white,
              ),
              _buildStatItem(
                icon: Icons.trending_up,
                label: 'Restantes',
                value: '$remaining',
                color: Colors.white,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: color.withValues(alpha: 0.9),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGenerateMealsButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppTheme.accentColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.accentColor.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DietCalculatorScreen(userProfile: widget.userProfile),
                ),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.restaurant_menu,
                    color: Colors.white,
                    size: 28,
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Gerar Plano Alimentar',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Crie seu plano personalizado',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMacrosSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Macronutrientes',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMacroCard(
                  label: 'Proteínas',
                  value: '${_protein.toStringAsFixed(0)}g',
                  icon: Icons.fitness_center,
                  color: Colors.blue,
                  progress: _proteinGoal > 0 ? (_protein / _proteinGoal).clamp(0.0, 1.0) : 0.0,
                  goal: _proteinGoal > 0 ? '${_proteinGoal.toStringAsFixed(0)}g' : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMacroCard(
                  label: 'Carboidratos',
                  value: '${_carbs.toStringAsFixed(0)}g',
                  icon: Icons.breakfast_dining,
                  color: Colors.orange,
                  progress: _carbsGoal > 0 ? (_carbs / _carbsGoal).clamp(0.0, 1.0) : 0.0,
                  goal: _carbsGoal > 0 ? '${_carbsGoal.toStringAsFixed(0)}g' : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMacroCard(
                  label: 'Gorduras',
                  value: '${_fats.toStringAsFixed(0)}g',
                  icon: Icons.water_drop,
                  color: Colors.purple,
                  progress: _fatsGoal > 0 ? (_fats / _fatsGoal).clamp(0.0, 1.0) : 0.0,
                  goal: _fatsGoal > 0 ? '${_fatsGoal.toStringAsFixed(0)}g' : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacroCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required double progress,
    String? goal,
  }) {
    return Container(
      padding: const EdgeInsets.all(16.0),
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
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          if (goal != null) ...[
            const SizedBox(height: 4),
            Text(
              'Meta: $goal',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                    fontSize: 10,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ações Rápidas',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  icon: Icons.water_drop_outlined,
                  label: 'Água',
                  color: Colors.blue,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => WaterTrackingScreen(userProfile: widget.userProfile),
                      ),
                    ).then((_) => _loadData());
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildActionCard(
                  icon: Icons.add_circle_outline,
                  label: 'Adicionar\nRefeição',
                  color: AppTheme.primaryColor,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MealsListScreen(userProfile: widget.userProfile),
                      ),
                    ).then((_) => _loadData());
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildActionCard(
                  icon: Icons.scale_outlined,
                  label: 'Peso',
                  color: AppTheme.accentColor,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => WeightTrackingScreen(userProfile: widget.userProfile),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
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
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayMeals() {
    final nextMeals = _nextMeals;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Próximas Refeições',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MealsListScreen(userProfile: widget.userProfile),
                    ),
                  );
                },
                child: const Text('Ver todas'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (nextMeals.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
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
              child: Center(
                child: Text(
                  'Todas as refeições foram concluídas! 🎉',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                ),
              ),
            )
          else
            ...nextMeals.asMap().entries.map((entry) {
              final index = entry.key;
              final meal = entry.value;
              // Encontrar o índice original na lista completa para editar o horário
              final originalIndex = _todayMeals.indexWhere((m) => 
                (m['name'] == meal['name'] || m['meal'] == meal['meal']) && m['time'] == meal['time']
              );
              // Garantir que sempre temos um ícone válido
              final mealIcon = meal['icon'] as IconData? ?? Icons.restaurant;
              
              return Padding(
                padding: EdgeInsets.only(bottom: index < nextMeals.length - 1 ? 16 : 0),
                child: _buildMealItem(
                  icon: mealIcon,
                  meal: meal['name'] as String? ?? meal['meal'] as String? ?? 'Refeição',
                  calories: meal['calories'] as int? ?? 0,
                  time: meal['time'] as String,
                  isCompleted: meal['isCompleted'] as bool? ?? false,
                  onTimeEdit: originalIndex >= 0 ? () => _editMealTime(originalIndex) : null,
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildMealItem({
    required IconData icon,
    required String meal,
    required int calories,
    required String time,
    bool isCompleted = true,
    VoidCallback? onTimeEdit,
  }) {
    return Container(
      padding: const EdgeInsets.all(16.0),
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: AppTheme.primaryColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meal,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      time,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (onTimeEdit != null) ...[
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: onTimeEdit,
                        child: Icon(
                          Icons.edit_outlined,
                          size: 16,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$calories kcal',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
              ),
              if (!isCompleted)
                Text(
                  'Pendente',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.accentColor,
                      ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Bom dia';
    } else if (hour < 18) {
      return 'Boa tarde';
    } else {
      return 'Boa noite';
    }
  }


  Future<void> _editMealTime(int index) async {
    if (widget.userProfile?.id == null) return;
    
    final meal = _todayMeals[index];
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
      final formattedTime = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      
      setState(() {
        _todayMeals[index]['time'] = formattedTime;
      });

      // Salvar no Firestore
      try {
        final today = DateTime.now();
        await _firestoreService.saveDailyMeals(
          userId: widget.userProfile!.id!,
          date: today,
          meals: _todayMeals,
        );
      } catch (e) {
        debugPrint('Erro ao salvar horário da refeição: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao salvar horário: ${e.toString()}'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    }
  }
}

