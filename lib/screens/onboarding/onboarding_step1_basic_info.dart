import 'package:flutter/material.dart';
import '../../models/user_profile.dart';
import '../../theme/app_theme.dart';

class OnboardingStep1BasicInfo extends StatefulWidget {
  final UserProfile userProfile;
  final Function(UserProfile) onNext;

  const OnboardingStep1BasicInfo({
    super.key,
    required this.userProfile,
    required this.onNext,
  });

  @override
  State<OnboardingStep1BasicInfo> createState() => _OnboardingStep1BasicInfoState();
}

class _OnboardingStep1BasicInfoState extends State<OnboardingStep1BasicInfo> {
  Gender? _selectedGender;
  DateTime? _selectedDateOfBirth;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _selectedGender = widget.userProfile.gender;
    _selectedDateOfBirth = widget.userProfile.dateOfBirth;
  }

  Future<void> _selectDateOfBirth(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTime firstDate = DateTime(now.year - 120, 1, 1);
    final DateTime lastDate = DateTime(now.year - 1, 12, 31);
    final DateTime initialDate = _selectedDateOfBirth ?? DateTime(now.year - 25, 1, 1);

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: 'Selecione sua data de nascimento',
      cancelText: 'Cancelar',
      confirmText: 'Confirmar',
    );

    if (picked != null && picked != _selectedDateOfBirth) {
      setState(() {
        _selectedDateOfBirth = picked;
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String? _getAgeText() {
    if (_selectedDateOfBirth == null) return null;
    final age = _calculateAge(_selectedDateOfBirth!);
    return '$age anos';
  }

  int _calculateAge(DateTime dateOfBirth) {
    final today = DateTime.now();
    int age = today.year - dateOfBirth.year;
    final monthDifference = today.month - dateOfBirth.month;
    if (monthDifference < 0 || (monthDifference == 0 && today.day < dateOfBirth.day)) {
      age--;
    }
    return age;
  }

  void _handleNext() {
    if (_formKey.currentState!.validate() && _selectedGender != null && _selectedDateOfBirth != null) {
      final updatedProfile = UserProfile(
        id: widget.userProfile.id,
        email: widget.userProfile.email,
        name: widget.userProfile.name,
        gender: _selectedGender,
        dateOfBirth: _selectedDateOfBirth,
        height: widget.userProfile.height,
        weight: widget.userProfile.weight,
        activityLevel: widget.userProfile.activityLevel,
        goal: widget.userProfile.goal,
        createdAt: widget.userProfile.createdAt,
        updatedAt: DateTime.now(),
      );
      widget.onNext(updatedProfile);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            Text(
              'Informações Básicas',
              style: Theme.of(context).textTheme.displayMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Precisamos de algumas informações para personalizar sua experiência',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 40),
            // Seleção de Gênero
            Text(
              'Gênero',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _GenderOption(
                    label: 'Masculino',
                    icon: Icons.male,
                    isSelected: _selectedGender == Gender.male,
                    onTap: () {
                      setState(() {
                        _selectedGender = Gender.male;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _GenderOption(
                    label: 'Feminino',
                    icon: Icons.female,
                    isSelected: _selectedGender == Gender.female,
                    onTap: () {
                      setState(() {
                        _selectedGender = Gender.female;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _GenderOption(
                    label: 'Outro',
                    icon: Icons.person,
                    isSelected: _selectedGender == Gender.other,
                    onTap: () {
                      setState(() {
                        _selectedGender = Gender.other;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            // Campo de Data de Nascimento
            Text(
              'Data de Nascimento',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () => _selectDateOfBirth(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _selectedDateOfBirth != null
                        ? AppTheme.primaryColor
                        : Colors.grey.shade300,
                    width: _selectedDateOfBirth != null ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedDateOfBirth != null
                                ? _formatDate(_selectedDateOfBirth!)
                                : 'Selecione sua data de nascimento',
                            style: TextStyle(
                              fontSize: 16,
                              color: _selectedDateOfBirth != null
                                  ? Colors.black87
                                  : Colors.grey.shade600,
                              fontWeight: _selectedDateOfBirth != null
                                  ? FontWeight.w500
                                  : FontWeight.normal,
                            ),
                          ),
                          if (_selectedDateOfBirth != null && _getAgeText() != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Idade: ${_getAgeText()}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ),
            ),
            if (_selectedDateOfBirth == null)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 16),
                child: Text(
                  'Por favor, selecione sua data de nascimento',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.errorColor,
                      ),
                ),
              ),
            const SizedBox(height: 40),
            // Botão Continuar
            ElevatedButton(
              onPressed: _handleNext,
              child: const Text('Continuar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _GenderOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _GenderOption({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withValues(alpha: 0.1)
              : Colors.grey.shade100,
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryColor
                : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected
                  ? AppTheme.primaryColor
                  : Colors.grey.shade600,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected
                    ? AppTheme.primaryColor
                    : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

