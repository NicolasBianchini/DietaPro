import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../models/user_profile.dart';
import 'login_screen.dart';
import 'diet_calculator_screen.dart';
import 'meals_list_screen.dart';

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
  // Dados mockados - em produção, viriam de um serviço/backend
  int _caloriesConsumed = 1200;
  int _caloriesGoal = 2000;
  double _protein = 80.0;
  double _carbs = 150.0;
  double _fats = 60.0;
  
  int _currentIndex = 1; // Índice inicial (meio = Home)
  
  // Refeições do dia - agora mutáveis
  final List<Map<String, dynamic>> _todayMeals = [
    {
      'icon': Icons.wb_sunny_outlined,
      'meal': 'Café da Manhã',
      'calories': 350,
      'time': '08:00',
      'isCompleted': true,
    },
    {
      'icon': Icons.cookie_outlined,
      'meal': 'Lanche da Manhã',
      'calories': 150,
      'time': '10:30',
      'isCompleted': false,
    },
    {
      'icon': Icons.lunch_dining_outlined,
      'meal': 'Almoço',
      'calories': 650,
      'time': '13:00',
      'isCompleted': true,
    },
    {
      'icon': Icons.cookie_outlined,
      'meal': 'Lanche da Tarde',
      'calories': 200,
      'time': '16:00',
      'isCompleted': false,
    },
    {
      'icon': Icons.dinner_dining_outlined,
      'meal': 'Jantar',
      'calories': 200,
      'time': '19:00',
      'isCompleted': false,
    },
  ];
  
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
        return const MealsListScreen();
      case 1:
        return SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              // TODO: Implementar refresh dos dados
              await Future.delayed(const Duration(seconds: 1));
            },
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
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Funcionalidade em desenvolvimento'),
                  ),
                );
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
                );
              },
            ),
            const SizedBox(height: 16),
            _buildProfileMenuItem(
              icon: Icons.settings_outlined,
              title: 'Configurações',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Tela de configurações em desenvolvimento'),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildProfileMenuItem(
              icon: Icons.bar_chart_outlined,
              title: 'Estatísticas',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Tela de estatísticas em desenvolvimento'),
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajuda'),
        content: const Text(
          'Bem-vindo ao DietaPro!\n\n'
          'Aqui você pode gerenciar sua dieta, acompanhar suas calorias e macronutrientes, e muito mais.\n\n'
          'Para mais informações, entre em contato com o suporte.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
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
                  value: '${_protein}g',
                  icon: Icons.fitness_center,
                  color: Colors.blue,
                  progress: 0.7,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMacroCard(
                  label: 'Carboidratos',
                  value: '${_carbs}g',
                  icon: Icons.breakfast_dining,
                  color: Colors.orange,
                  progress: 0.6,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMacroCard(
                  label: 'Gorduras',
                  value: '${_fats}g',
                  icon: Icons.water_drop,
                  color: Colors.purple,
                  progress: 0.5,
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
                    _showWaterDialog();
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
                    _showAddMealDialog();
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
                    _showWeightDialog();
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
                      builder: (_) => const MealsListScreen(),
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
                m['meal'] == meal['meal'] && m['time'] == meal['time']
              );
              return Padding(
                padding: EdgeInsets.only(bottom: index < nextMeals.length - 1 ? 16 : 0),
                child: _buildMealItem(
                  icon: meal['icon'] as IconData,
                  meal: meal['meal'] as String,
                  calories: meal['calories'] as int,
                  time: meal['time'] as String,
                  isCompleted: meal['isCompleted'] as bool,
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

  void _showAddMealDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Adicionar Refeição'),
        content: const Text('Funcionalidade em desenvolvimento'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showWaterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Registrar Água'),
        content: const Text('Funcionalidade em desenvolvimento'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showWeightDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Registrar Peso'),
        content: const Text('Funcionalidade em desenvolvimento'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _editMealTime(int index) async {
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
      setState(() {
        final formattedTime = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
        _todayMeals[index]['time'] = formattedTime;
      });
    }
  }
}

