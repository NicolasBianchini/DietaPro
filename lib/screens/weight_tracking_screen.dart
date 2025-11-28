import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../models/user_profile.dart';
import '../services/firestore_service.dart';

class WeightTrackingScreen extends StatefulWidget {
  final UserProfile? userProfile;

  const WeightTrackingScreen({
    super.key,
    this.userProfile,
  });

  @override
  State<WeightTrackingScreen> createState() => _WeightTrackingScreenState();
}

class _WeightTrackingScreenState extends State<WeightTrackingScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  List<Map<String, dynamic>> _weightRecords = [];
  bool _isLoading = true;
  String _selectedFrequency = 'weekly'; // weekly, biweekly, monthly

  final TextEditingController _weightController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadWeightData();
  }

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _loadWeightData() async {
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
      final records = await _firestoreService.getWeightRecords(widget.userProfile!.id!);
      setState(() {
        _weightRecords = records;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Erro ao carregar registros de peso: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveWeight() async {
    if (widget.userProfile?.id == null) return;

    try {
      final weight = double.tryParse(_weightController.text);

      if (weight == null || weight <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Peso inválido'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        return;
      }

      await _firestoreService.saveWeightRecord(
        userId: widget.userProfile!.id!,
        weight: weight,
        date: DateTime.now(),
      );

      _weightController.clear();
      await _loadWeightData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Peso registrado: ${weight.toStringAsFixed(1)} kg'),
            backgroundColor: AppTheme.primaryColor,
          ),
        );
      }

      HapticFeedback.mediumImpact();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao registrar peso: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  double? _getLastWeight() {
    if (_weightRecords.isEmpty) return null;
    return (_weightRecords.first['weight'] as num?)?.toDouble();
  }

  double? _getFirstWeight() {
    if (_weightRecords.isEmpty) return null;
    return (_weightRecords.last['weight'] as num?)?.toDouble();
  }

  double? _getWeightDifference() {
    if (_weightRecords.length < 2) return null;
    final last = (_weightRecords[0]['weight'] as num?)?.toDouble();
    final previous = (_weightRecords[1]['weight'] as num?)?.toDouble();
    if (last == null || previous == null) return null;
    return last - previous;
  }

  double? _getTotalWeightChange() {
    if (_weightRecords.length < 2) return null;
    final first = _getFirstWeight();
    final last = _getLastWeight();
    if (first == null || last == null) return null;
    return last - first;
  }

  String _getDaysSinceFirstRecord() {
    if (_weightRecords.isEmpty) return '';
    final firstRecord = _weightRecords.last;
    final firstDate = (firstRecord['date'] as Timestamp?)?.toDate();
    if (firstDate == null) return '';
    final days = DateTime.now().difference(firstDate).inDays;
    if (days == 0) return 'Hoje';
    if (days == 1) return '1 dia';
    return '$days dias';
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    final lastWeight = _getLastWeight();
    final firstWeight = _getFirstWeight();
    final weightDifference = _getWeightDifference();
    final totalChange = _getTotalWeightChange();
    final daysSinceFirst = _getDaysSinceFirstRecord();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Peso'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadWeightData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Card principal de peso atual
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.monitor_weight,
                              color: AppTheme.primaryColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Peso Atual',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                if (lastWeight != null) ...[
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '${lastWeight.toStringAsFixed(1)}',
                                        style: TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey.shade900,
                                          height: 1.0,
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 3, left: 4),
                                        child: Text(
                                          'kg',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.grey.shade600,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ] else
                                  Text(
                                    'Nenhum registro',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey.shade400,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (lastWeight != null && weightDifference != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: weightDifference > 0
                                    ? Colors.orange.shade50
                                    : weightDifference < 0
                                        ? Colors.green.shade50
                                        : Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    weightDifference > 0
                                        ? Icons.trending_up
                                        : weightDifference < 0
                                            ? Icons.trending_down
                                            : Icons.trending_flat,
                                    color: weightDifference > 0
                                        ? Colors.orange.shade700
                                        : weightDifference < 0
                                            ? Colors.green.shade700
                                            : Colors.grey.shade700,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${weightDifference > 0 ? '+' : ''}${weightDifference.toStringAsFixed(1)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: weightDifference > 0
                                          ? Colors.orange.shade700
                                          : weightDifference < 0
                                              ? Colors.green.shade700
                                              : Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Cards de estatísticas
                    if (_weightRecords.isNotEmpty && firstWeight != null && totalChange != null) ...[
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              icon: Icons.start,
                              label: 'Peso Inicial',
                              value: '${firstWeight.toStringAsFixed(1)} kg',
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              icon: totalChange > 0
                                  ? Icons.arrow_upward
                                  : totalChange < 0
                                      ? Icons.arrow_downward
                                      : Icons.remove,
                              label: 'Variação Total',
                              value: '${totalChange > 0 ? '+' : ''}${totalChange.abs().toStringAsFixed(1)} kg',
                              color: totalChange > 0
                                  ? Colors.orange
                                  : totalChange < 0
                                      ? Colors.green
                                      : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      if (daysSinceFirst.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
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
                              Icon(
                                Icons.calendar_today,
                                color: AppTheme.primaryColor,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Acompanhando há $daysSinceFirst',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                    const SizedBox(height: 24),
                    // Formulário de registro
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
                          const Text(
                            'Registrar Peso',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextField(
                            controller: _weightController,
                            decoration: const InputDecoration(
                              labelText: 'Peso (kg)',
                              hintText: 'Ex: 70.5',
                              border: OutlineInputBorder(),
                              suffixText: 'kg',
                              prefixIcon: Icon(Icons.scale),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Lembrete de Registro',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...['weekly', 'biweekly', 'monthly'].map((frequency) {
                            final labels = {
                              'weekly': 'A cada semana',
                              'biweekly': 'A cada duas semanas',
                              'monthly': 'A cada mês',
                            };
                            return RadioListTile<String>(
                              title: Text(labels[frequency]!),
                              value: frequency,
                              groupValue: _selectedFrequency,
                              onChanged: (value) {
                                setState(() {
                                  _selectedFrequency = value!;
                                });
                              },
                              contentPadding: EdgeInsets.zero,
                            );
                          }),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _saveWeight,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Registrar',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Histórico
                    if (_weightRecords.isNotEmpty) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Histórico',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${_weightRecords.length} ${_weightRecords.length == 1 ? 'registro' : 'registros'}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ..._weightRecords.take(10).toList().asMap().entries.map((entry) {
                        final index = entry.key;
                        final record = entry.value;
                        final weight = (record['weight'] as num?)?.toDouble();
                        final date = record['date'] as Timestamp?;
                        final recordId = record['id'] as String?;
                        if (weight == null || date == null) return const SizedBox.shrink();

                        // Calcular diferença com o registro anterior
                        double? diff;
                        if (index < _weightRecords.length - 1) {
                          final prevWeight = (_weightRecords[index + 1]['weight'] as num?)?.toDouble();
                          if (prevWeight != null) {
                            diff = weight - prevWeight;
                          }
                        }

                        final isToday = date.toDate().day == DateTime.now().day &&
                            date.toDate().month == DateTime.now().month &&
                            date.toDate().year == DateTime.now().year;

                        return Dismissible(
                          key: Key(recordId ?? index.toString()),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: AppTheme.errorColor,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            child: const Icon(
                              Icons.delete,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          confirmDismiss: (direction) async {
                            return await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Excluir Registro'),
                                content: const Text('Tem certeza que deseja excluir este registro de peso?'),
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
                            ) ?? false;
                          },
                          onDismissed: (direction) async {
                            if (recordId != null && widget.userProfile?.id != null) {
                              try {
                                await _firestoreService.deleteWeightRecord(
                                  userId: widget.userProfile!.id!,
                                  recordId: recordId,
                                );
                                await _loadWeightData();
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Registro excluído com sucesso'),
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
                          },
                          child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: isToday
                                ? Border.all(color: AppTheme.primaryColor, width: 2)
                                : null,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withValues(alpha: 0.08),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: isToday
                                      ? AppTheme.primaryColor.withValues(alpha: 0.1)
                                      : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  isToday ? Icons.today : Icons.circle,
                                  color: isToday
                                      ? AppTheme.primaryColor
                                      : Colors.grey.shade400,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          '${weight.toStringAsFixed(1)} kg',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        if (diff != null) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: diff > 0
                                                  ? Colors.orange.shade50
                                                  : diff < 0
                                                      ? Colors.green.shade50
                                                      : Colors.grey.shade100,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  diff > 0
                                                      ? Icons.arrow_upward
                                                      : diff < 0
                                                          ? Icons.arrow_downward
                                                          : Icons.remove,
                                                  size: 12,
                                                  color: diff > 0
                                                      ? Colors.orange.shade700
                                                      : diff < 0
                                                          ? Colors.green.shade700
                                                          : Colors.grey.shade600,
                                                ),
                                                const SizedBox(width: 2),
                                                Text(
                                                  '${diff.abs().toStringAsFixed(1)}',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                    color: diff > 0
                                                        ? Colors.orange.shade700
                                                        : diff < 0
                                                            ? Colors.green.shade700
                                                            : Colors.grey.shade600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.calendar_today,
                                          size: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          _formatDate(date),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                        if (isToday) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppTheme.primaryColor,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: const Text(
                                              'Hoje',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            ),
                          ),
                        );
                      }),
                    ],
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
      padding: const EdgeInsets.all(16),
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
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
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
}

