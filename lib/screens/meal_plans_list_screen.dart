import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../models/user_profile.dart';
import '../models/food_item.dart';
import '../services/firestore_service.dart';
import 'diet_calculator_screen.dart';

class MealPlansListScreen extends StatefulWidget {
  final UserProfile? userProfile;

  const MealPlansListScreen({
    super.key,
    this.userProfile,
  });

  @override
  State<MealPlansListScreen> createState() => _MealPlansListScreenState();
}

class _MealPlansListScreenState extends State<MealPlansListScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  List<Map<String, dynamic>> _mealPlans = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMealPlans();
  }

  Future<void> _loadMealPlans() async {
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
      final plans = await _firestoreService.getUserMealPlans(widget.userProfile!.id!);
      setState(() {
        _mealPlans = plans;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Erro ao carregar planos alimentares: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteMealPlan(String mealPlanId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Plano Alimentar'),
        content: const Text(
          'Tem certeza que deseja excluir este plano alimentar? Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.errorColor,
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _firestoreService.deleteMealPlan(mealPlanId);
        await _loadMealPlans();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Plano alimentar excluído com sucesso!'),
              backgroundColor: AppTheme.primaryColor,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao excluir: ${e.toString()}'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'Data não disponível';
    
    try {
      if (date is Timestamp) {
        final dateTime = date.toDate();
        return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
      } else if (date is String) {
        final dateTime = DateTime.parse(date);
        return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
      }
    } catch (e) {
      debugPrint('Erro ao formatar data: $e');
    }
    
    return 'Data não disponível';
  }

  int _calculateTotalCalories(Map<String, dynamic> mealPlan) {
    final meals = mealPlan['meals'] as Map<String, dynamic>?;
    if (meals == null) return 0;
    
    int total = 0;
    meals.forEach((mealType, mealFoods) {
      if (mealFoods is List) {
        for (var mf in mealFoods) {
          if (mf is Map<String, dynamic>) {
            final food = mf['food'] as Map<String, dynamic>?;
            final quantity = (mf['quantity'] as num?)?.toDouble() ?? 0.0;
            if (food != null) {
              final calories = (food['calories'] as num?)?.toDouble() ?? 0.0;
              total += ((calories * quantity) / 100).round();
            }
          }
        }
      }
    });
    
    return total;
  }

  /// Conta o número real de refeições (apenas as que têm alimentos)
  int _countMealsWithFoods(Map<String, dynamic> mealPlan) {
    final meals = mealPlan['meals'] as Map<String, dynamic>?;
    if (meals == null) return 0;
    
    int count = 0;
    meals.forEach((mealType, mealFoods) {
      if (mealFoods is List && mealFoods.isNotEmpty) {
        count++;
      }
    });
    
    return count;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Meus Planos Alimentares'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMealPlans,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadMealPlans,
              child: _mealPlans.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.restaurant_menu_outlined,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Nenhum plano alimentar encontrado',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Crie seu primeiro plano na Calculadora de Dieta',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DietCalculatorScreen(
                                    userProfile: widget.userProfile,
                                  ),
                                ),
                              ).then((_) => _loadMealPlans());
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Criar Plano'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: _mealPlans.length,
                      itemBuilder: (context, index) {
                        final plan = _mealPlans[index];
                        final dietName = plan['dietName'] as String? ?? 'Sem nome';
                        final description = plan['description'] as String? ?? '';
                        final createdAt = plan['createdAt'];
                        final totalCalories = _calculateTotalCalories(plan);
                        final nutritionData = plan['nutritionData'] as Map<String, dynamic>?;
                        final targetCalories = (nutritionData?['calories'] as num?)?.toInt() ?? 0;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
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
                              // Header do card
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        Icons.restaurant_menu,
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
                                            dietName,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          if (description.isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              description,
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey.shade600,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                          const SizedBox(height: 4),
                                          Text(
                                            _formatDate(createdAt),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    PopupMenuButton<String>(
                                      onSelected: (value) {
                                        if (value == 'edit') {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => DietCalculatorScreen(
                                                userProfile: widget.userProfile,
                                                mealPlanId: plan['id'] as String,
                                              ),
                                            ),
                                          ).then((_) => _loadMealPlans());
                                        } else if (value == 'delete') {
                                          _deleteMealPlan(plan['id'] as String);
                                        }
                                      },
                                      itemBuilder: (context) => [
                                        const PopupMenuItem(
                                          value: 'edit',
                                          child: Row(
                                            children: [
                                              Icon(Icons.edit, size: 20),
                                              SizedBox(width: 8),
                                              Text('Editar'),
                                            ],
                                          ),
                                        ),
                                        const PopupMenuItem(
                                          value: 'delete',
                                          child: Row(
                                            children: [
                                              Icon(Icons.delete, size: 20, color: AppTheme.errorColor),
                                              SizedBox(width: 8),
                                              Text('Excluir', style: TextStyle(color: AppTheme.errorColor)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              // Informações nutricionais
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: const BorderRadius.vertical(
                                    bottom: Radius.circular(16),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    _buildNutritionInfo(
                                      label: 'Calorias',
                                      value: '$totalCalories',
                                      target: targetCalories > 0 ? '/ $targetCalories' : '',
                                      icon: Icons.local_fire_department,
                                      color: Colors.orange,
                                    ),
                                    Container(
                                      width: 1,
                                      height: 40,
                                      color: Colors.grey.shade300,
                                    ),
                                    _buildNutritionInfo(
                                      label: 'Refeições',
                                      value: '${_countMealsWithFoods(plan)}',
                                      icon: Icons.restaurant,
                                      color: AppTheme.primaryColor,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DietCalculatorScreen(
                userProfile: widget.userProfile,
              ),
            ),
          ).then((_) => _loadMealPlans());
        },
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Novo Plano',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildNutritionInfo({
    required String label,
    required String value,
    String target = '',
    required IconData icon,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            if (target.isNotEmpty)
              Text(
                target,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}

