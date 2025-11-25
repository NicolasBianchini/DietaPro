import 'package:flutter/material.dart';
import '../../models/user_profile.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';

class OnboardingStep4Goals extends StatefulWidget {
  final UserProfile userProfile;
  final Function(UserProfile) onComplete;
  final VoidCallback onBack;

  const OnboardingStep4Goals({
    super.key,
    required this.userProfile,
    required this.onComplete,
    required this.onBack,
  });

  @override
  State<OnboardingStep4Goals> createState() => _OnboardingStep4GoalsState();
}

class _OnboardingStep4GoalsState extends State<OnboardingStep4Goals> {
  Goal? _selectedGoal;

  @override
  void initState() {
    super.initState();
    _selectedGoal = widget.userProfile.goal;
  }

  Future<void> _handleComplete() async {
    if (_selectedGoal != null) {
      final updatedProfile = UserProfile(
        id: widget.userProfile.id,
        email: widget.userProfile.email,
        name: widget.userProfile.name,
        gender: widget.userProfile.gender,
        dateOfBirth: widget.userProfile.dateOfBirth,
        height: widget.userProfile.height,
        weight: widget.userProfile.weight,
        activityLevel: widget.userProfile.activityLevel,
        goal: _selectedGoal,
        createdAt: widget.userProfile.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Salvar no Firestore
      try {
        final firestoreService = FirestoreService();
        final userId = await firestoreService.saveUserProfile(updatedProfile);
        final savedProfile = UserProfile(
          id: userId,
          email: updatedProfile.email,
          name: updatedProfile.name,
          gender: updatedProfile.gender,
          dateOfBirth: updatedProfile.dateOfBirth,
          height: updatedProfile.height,
          weight: updatedProfile.weight,
          activityLevel: updatedProfile.activityLevel,
          goal: updatedProfile.goal,
          createdAt: updatedProfile.createdAt,
          updatedAt: updatedProfile.updatedAt,
        );
        widget.onComplete(savedProfile);
      } catch (e) {
        // Se houver erro, continua mesmo assim
        widget.onComplete(updatedProfile);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          Text(
            'Seu Objetivo',
            style: Theme.of(context).textTheme.displayMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'O que você deseja alcançar com o DietaPro?',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 40),
          // Opções de objetivos
          _GoalOption(
            goal: Goal.loseWeight,
            title: 'Perder Peso',
            description: 'Criar um déficit calórico para emagrecer de forma saudável',
            icon: Icons.trending_down_outlined,
            color: Colors.blue,
            isSelected: _selectedGoal == Goal.loseWeight,
            onTap: () {
              setState(() {
                _selectedGoal = Goal.loseWeight;
              });
            },
          ),
          const SizedBox(height: 16),
          _GoalOption(
            goal: Goal.gainWeight,
            title: 'Ganhar Peso',
            description: 'Aumentar o peso corporal de forma saudável',
            icon: Icons.trending_up_outlined,
            color: Colors.green,
            isSelected: _selectedGoal == Goal.gainWeight,
            onTap: () {
              setState(() {
                _selectedGoal = Goal.gainWeight;
              });
            },
          ),
          const SizedBox(height: 16),
          _GoalOption(
            goal: Goal.gainMuscle,
            title: 'Ganhar Massa Muscular',
            description: 'Aumentar massa magra com dieta rica em proteínas',
            icon: Icons.trending_up_outlined,
            color: Colors.orange,
            isSelected: _selectedGoal == Goal.gainMuscle,
            onTap: () {
              setState(() {
                _selectedGoal = Goal.gainMuscle;
              });
            },
          ),
          const SizedBox(height: 16),
          _GoalOption(
            goal: Goal.maintain,
            title: 'Manutenção',
            description: 'Manter o peso atual e hábitos saudáveis',
            icon: Icons.balance_outlined,
            color: AppTheme.primaryColor,
            isSelected: _selectedGoal == Goal.maintain,
            onTap: () {
              setState(() {
                _selectedGoal = Goal.maintain;
              });
            },
          ),
          const SizedBox(height: 16),
          _GoalOption(
            goal: Goal.eatBetter,
            title: 'Comer Melhor',
            description: 'Melhorar a qualidade da alimentação e criar hábitos saudáveis',
            icon: Icons.restaurant_menu_outlined,
            color: Colors.purple,
            isSelected: _selectedGoal == Goal.eatBetter,
            onTap: () {
              setState(() {
                _selectedGoal = Goal.eatBetter;
              });
            },
          ),
          const SizedBox(height: 40),
          // Botões
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onBack,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: AppTheme.primaryColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Voltar'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _selectedGoal != null ? () => _handleComplete() : null,
                  child: const Text('Finalizar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GoalOption extends StatelessWidget {
  final Goal goal;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _GoalOption({
    required this.goal,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.1)
              : Colors.grey.shade50,
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? color : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey.shade700,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected ? color : Colors.grey.shade900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: color,
              ),
          ],
        ),
      ),
    );
  }
}

