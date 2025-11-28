import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../models/user_profile.dart';
import '../services/firestore_service.dart';

class StatisticsScreen extends StatefulWidget {
  final UserProfile? userProfile;

  const StatisticsScreen({
    super.key,
    this.userProfile,
  });

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = true;
  
  // Estatísticas
  int _totalMealsCompleted = 0;
  int _totalCaloriesConsumed = 0;
  double _averageWaterConsumed = 0.0;
  int _weightRecordsCount = 0;
  double? _weightChange;
  int _daysTracked = 0;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
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
      final today = DateTime.now();
      
      // Carregar refeições e água dos últimos 30 dias em paralelo
      int totalMeals = 0;
      int totalCalories = 0;
      double totalWater = 0.0;
      int waterDays = 0;
      Set<String> daysWithData = {};
      
      // Processar os últimos 30 dias
      final futures = <Future>[];
      for (int i = 0; i < 30; i++) {
        final date = today.subtract(Duration(days: i));
        futures.add(_processDay(date, widget.userProfile!.id!));
      }
      
      final results = await Future.wait(futures);
      
      // Processar resultados
      for (final result in results) {
        final dayData = result as Map<String, dynamic>;
        
        // Processar refeições
        final meals = dayData['meals'] as List<Map<String, dynamic>>;
        for (final meal in meals) {
          if (meal['isCompleted'] == true) {
            totalMeals++;
            totalCalories += meal['calories'] as int? ?? 0;
          }
        }
        
        // Processar água
        final water = dayData['water'] as double;
        if (water > 0) {
          totalWater += water;
          waterDays++;
        }
        
        // Verificar se houve dados no dia
        if (meals.isNotEmpty || water > 0) {
          daysWithData.add(dayData['dateKey'] as String);
        }
      }
      
      // Carregar registros de peso
      final weightRecords = await _firestoreService.getWeightRecords(widget.userProfile!.id!);
      double? weightChange;
      if (weightRecords.isNotEmpty) {
        // Ordenar por data (mais antigo primeiro)
        final sortedRecords = List<Map<String, dynamic>>.from(weightRecords);
        sortedRecords.sort((a, b) {
          final aDate = a['date'];
          final bDate = b['date'];
          if (aDate == null || bDate == null) return 0;
          
          DateTime aDateTime;
          DateTime bDateTime;
          
          if (aDate is DateTime) {
            aDateTime = aDate;
          } else if (aDate is Timestamp) {
            aDateTime = aDate.toDate();
          } else {
            return 0;
          }
          
          if (bDate is DateTime) {
            bDateTime = bDate;
          } else if (bDate is Timestamp) {
            bDateTime = bDate.toDate();
          } else {
            return 0;
          }
          
          return aDateTime.compareTo(bDateTime);
        });
        
        final firstWeight = (sortedRecords.first['weight'] as num?)?.toDouble();
        final lastWeight = (sortedRecords.last['weight'] as num?)?.toDouble();
        
        if (firstWeight != null && lastWeight != null) {
          weightChange = lastWeight - firstWeight;
        }
      }

      setState(() {
        _totalMealsCompleted = totalMeals;
        _totalCaloriesConsumed = totalCalories;
        _averageWaterConsumed = waterDays > 0 ? totalWater / waterDays : 0.0;
        _weightRecordsCount = weightRecords.length;
        _weightChange = weightChange;
        _daysTracked = daysWithData.length;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Erro ao carregar estatísticas: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<Map<String, dynamic>> _processDay(DateTime date, String userId) async {
    final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    
    // Carregar refeições e água em paralelo
    final mealsFuture = _firestoreService.getDailyMeals(userId: userId, date: date);
    final waterFuture = _firestoreService.getDailyWater(userId: userId, date: date);
    
    final results = await Future.wait([mealsFuture, waterFuture]);
    
    return {
      'dateKey': dateKey,
      'meals': results[0] as List<Map<String, dynamic>>,
      'water': results[1] as double,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Estatísticas'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStatistics,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStatistics,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Últimos 30 dias',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Grid de estatísticas
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.restaurant,
                            label: 'Refeições',
                            value: '$_totalMealsCompleted',
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.local_fire_department,
                            label: 'Calorias',
                            value: '$_totalCaloriesConsumed',
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.water_drop,
                            label: 'Água Média',
                            value: '${_averageWaterConsumed.toStringAsFixed(1)}L',
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.calendar_today,
                            label: 'Dias',
                            value: '$_daysTracked',
                            color: Colors.purple,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    
                    // Seção de Peso
                    if (_weightRecordsCount > 0) ...[
                      Text(
                        'Acompanhamento de Peso',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 16),
                      Container(
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
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildWeightStat(
                                  label: 'Registros',
                                  value: '$_weightRecordsCount',
                                ),
                                _buildWeightStat(
                                  label: 'Variação',
                                  value: _weightChange != null
                                      ? '${_weightChange! > 0 ? '+' : ''}${_weightChange!.toStringAsFixed(1)} kg'
                                      : 'N/A',
                                  color: _weightChange != null && _weightChange! < 0
                                      ? Colors.green
                                      : _weightChange != null && _weightChange! > 0
                                          ? Colors.orange
                                          : Colors.grey,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                    
                    // Resumo
                    Text(
                      'Resumo',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Container(
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
                          _buildSummaryRow('Refeições completas', '$_totalMealsCompleted'),
                          const Divider(),
                          _buildSummaryRow('Total de calorias', '$_totalCaloriesConsumed kcal'),
                          const Divider(),
                          _buildSummaryRow('Média de água/dia', '${_averageWaterConsumed.toStringAsFixed(1)}L'),
                          const Divider(),
                          _buildSummaryRow('Dias acompanhados', '$_daysTracked/30'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
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
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
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
      ),
    );
  }

  Widget _buildWeightStat({
    required String label,
    required String value,
    Color? color,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color ?? Colors.grey.shade900,
          ),
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

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade700,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

