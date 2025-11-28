import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../models/user_profile.dart';
import '../services/firestore_service.dart';

class WaterTrackingScreen extends StatefulWidget {
  final UserProfile? userProfile;

  const WaterTrackingScreen({
    super.key,
    this.userProfile,
  });

  @override
  State<WaterTrackingScreen> createState() => _WaterTrackingScreenState();
}

class _WaterTrackingScreenState extends State<WaterTrackingScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  double? _waterGoal;
  double _consumedWater = 0.0;
  bool _isLoading = true;

  final TextEditingController _goalController = TextEditingController();
  final TextEditingController _consumedController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadWaterData();
  }

  @override
  void dispose() {
    _goalController.dispose();
    _consumedController.dispose();
    super.dispose();
  }

  Future<void> _loadWaterData() async {
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
      final goal = await _firestoreService.getWaterGoal(widget.userProfile!.id!);
      final consumed = await _firestoreService.getDailyWater(
        userId: widget.userProfile!.id!,
        date: today,
      );

      setState(() {
        _waterGoal = goal ?? 2.0;
        _consumedWater = consumed;
        _goalController.text = _waterGoal!.toStringAsFixed(1);
        _consumedController.text = _consumedWater.toStringAsFixed(1);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Erro ao carregar dados de água: $e');
      setState(() {
        _waterGoal = 2.0;
        _consumedWater = 0.0;
        _goalController.text = _waterGoal!.toStringAsFixed(1);
        _consumedController.text = _consumedWater.toStringAsFixed(1);
        _isLoading = false;
      });
    }
  }

  Future<void> _saveWaterData() async {
    if (widget.userProfile?.id == null) return;

    try {
      final goal = double.tryParse(_goalController.text);
      final consumed = double.tryParse(_consumedController.text);

      if (goal == null || goal <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Meta inválida'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        return;
      }

      if (consumed == null || consumed < 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Consumo inválido'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        return;
      }

      await _firestoreService.saveWaterGoal(
        userId: widget.userProfile!.id!,
        goalLiters: goal,
      );

      await _firestoreService.saveDailyWater(
        userId: widget.userProfile!.id!,
        date: DateTime.now(),
        waterAmount: consumed,
      );

      setState(() {
        _waterGoal = goal;
        _consumedWater = consumed;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dados salvos com sucesso!'),
            backgroundColor: AppTheme.primaryColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _addWater(double amount) async {
    if (widget.userProfile?.id == null) return;

    final newConsumed = (_consumedWater + amount).clamp(0.0, double.infinity);
    _consumedController.text = newConsumed.toStringAsFixed(1);

    try {
      await _firestoreService.saveDailyWater(
        userId: widget.userProfile!.id!,
        date: DateTime.now(),
        waterAmount: newConsumed,
      );

      setState(() {
        _consumedWater = newConsumed;
      });

      HapticFeedback.lightImpact();
    } catch (e) {
      debugPrint('Erro ao adicionar água: $e');
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
        title: const Text('Água'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadWaterData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Card de progresso
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.blue.shade400,
                            Colors.blue.shade600,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withValues(alpha: 0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.water_drop,
                            size: 64,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '${_consumedWater.toStringAsFixed(1)} / ${_waterGoal!.toStringAsFixed(1)} L',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${((_consumedWater / _waterGoal!) * 100).toStringAsFixed(0)}% da meta',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: (_consumedWater / _waterGoal!).clamp(0.0, 1.0),
                              minHeight: 12,
                              backgroundColor: Colors.white.withValues(alpha: 0.3),
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Botões rápidos para adicionar água
                    const Text(
                      'Adicionar Água',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildQuickAddButton(
                            amount: 0.25,
                            label: '250ml',
                            icon: Icons.water_drop_outlined,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildQuickAddButton(
                            amount: 0.5,
                            label: '500ml',
                            icon: Icons.water_drop,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildQuickAddButton(
                            amount: 1.0,
                            label: '1L',
                            icon: Icons.water_drop,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    // Formulário de meta e consumo
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
                            'Configurações',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextField(
                            controller: _goalController,
                            decoration: const InputDecoration(
                              labelText: 'Meta Diária',
                              hintText: 'Litros por dia',
                              border: OutlineInputBorder(),
                              suffixText: 'L',
                              prefixIcon: Icon(Icons.flag_outlined),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _consumedController,
                            decoration: const InputDecoration(
                              labelText: 'Consumo de Hoje',
                              hintText: 'Litros consumidos',
                              border: OutlineInputBorder(),
                              suffixText: 'L',
                              prefixIcon: Icon(Icons.local_drink),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _saveWaterData,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Salvar',
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
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildQuickAddButton({
    required double amount,
    required String label,
    required IconData icon,
  }) {
    return InkWell(
      onTap: () => _addWater(amount),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.blue, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

