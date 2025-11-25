import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

class MealsListScreen extends StatefulWidget {
  const MealsListScreen({super.key});

  @override
  State<MealsListScreen> createState() => _MealsListScreenState();
}

class _MealsListScreenState extends State<MealsListScreen> {
  // Dados mockados - em produção, viriam de um serviço/backend
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
      ),
      body: Column(
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
                  onChanged: (value) {
                    setState(() {
                      _meals[index]['isCompleted'] = value ?? false;
                    });
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
    }
  }
}

