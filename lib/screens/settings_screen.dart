import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/user_profile.dart';
import '../services/firestore_service.dart';
import 'help_screen.dart';

class SettingsScreen extends StatefulWidget {
  final UserProfile? userProfile;

  const SettingsScreen({
    super.key,
    this.userProfile,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _notificationsEnabled = true;
  bool _waterRemindersEnabled = true;
  bool _mealRemindersEnabled = true;
  bool _weightRemindersEnabled = true;
  String _language = 'pt-BR';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    if (widget.userProfile?.id == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      // Buscar configurações do Firestore
      final settings = await _firestoreService.getUserSettings(widget.userProfile!.id!);
      
      setState(() {
        _notificationsEnabled = settings['notificationsEnabled'] ?? true;
        _waterRemindersEnabled = settings['waterRemindersEnabled'] ?? true;
        _mealRemindersEnabled = settings['mealRemindersEnabled'] ?? true;
        _weightRemindersEnabled = settings['weightRemindersEnabled'] ?? true;
        _language = settings['language'] ?? 'pt-BR';
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Erro ao carregar configurações: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    if (widget.userProfile?.id == null) return;

    try {
      await _firestoreService.saveUserSettings(
        userId: widget.userProfile!.id!,
        settings: {
          'notificationsEnabled': _notificationsEnabled,
          'waterRemindersEnabled': _waterRemindersEnabled,
          'mealRemindersEnabled': _mealRemindersEnabled,
          'weightRemindersEnabled': _weightRemindersEnabled,
          'language': _language,
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Configurações salvas com sucesso!'),
            backgroundColor: AppTheme.primaryColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar configurações: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Configurações'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Seção de Notificações
                  _buildSectionTitle('Notificações'),
                  const SizedBox(height: 16),
                  _buildSwitchTile(
                    title: 'Notificações',
                    subtitle: 'Receber notificações do app',
                    value: _notificationsEnabled,
                    onChanged: (value) {
                      setState(() {
                        _notificationsEnabled = value;
                      });
                      _saveSettings();
                    },
                    icon: Icons.notifications_outlined,
                  ),
                  const SizedBox(height: 8),
                  _buildSwitchTile(
                    title: 'Lembretes de Água',
                    subtitle: 'Lembrar de beber água',
                    value: _waterRemindersEnabled,
                    onChanged: _notificationsEnabled
                        ? (value) {
                            setState(() {
                              _waterRemindersEnabled = value;
                            });
                            _saveSettings();
                          }
                        : null,
                    icon: Icons.water_drop_outlined,
                  ),
                  const SizedBox(height: 8),
                  _buildSwitchTile(
                    title: 'Lembretes de Refeições',
                    subtitle: 'Lembrar horários das refeições',
                    value: _mealRemindersEnabled,
                    onChanged: _notificationsEnabled
                        ? (value) {
                            setState(() {
                              _mealRemindersEnabled = value;
                            });
                            _saveSettings();
                          }
                        : null,
                    icon: Icons.restaurant_outlined,
                  ),
                  const SizedBox(height: 8),
                  _buildSwitchTile(
                    title: 'Lembretes de Peso',
                    subtitle: 'Lembrar de registrar peso',
                    value: _weightRemindersEnabled,
                    onChanged: _notificationsEnabled
                        ? (value) {
                            setState(() {
                              _weightRemindersEnabled = value;
                            });
                            _saveSettings();
                          }
                        : null,
                    icon: Icons.scale_outlined,
                  ),
                  const SizedBox(height: 32),
                  
                  // Seção de Preferências
                  _buildSectionTitle('Preferências'),
                  const SizedBox(height: 16),
                  _buildListTile(
                    title: 'Idioma',
                    subtitle: _language == 'pt-BR' ? 'Português (Brasil)' : 'English',
                    icon: Icons.language_outlined,
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Selecionar Idioma'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(
                                title: const Text('Português (Brasil)'),
                                leading: Radio<String>(
                                  value: 'pt-BR',
                                  groupValue: _language,
                                  onChanged: (value) {
                                    setState(() {
                                      _language = value!;
                                    });
                                    Navigator.pop(context);
                                    _saveSettings();
                                  },
                                ),
                              ),
                              ListTile(
                                title: const Text('English'),
                                leading: Radio<String>(
                                  value: 'en-US',
                                  groupValue: _language,
                                  onChanged: (value) {
                                    setState(() {
                                      _language = value!;
                                    });
                                    Navigator.pop(context);
                                    _saveSettings();
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                  
                  // Seção de Dados
                  _buildSectionTitle('Dados'),
                  const SizedBox(height: 16),
                  _buildListTile(
                    title: 'Exportar Dados',
                    subtitle: 'Baixar seus dados em formato JSON',
                    icon: Icons.download_outlined,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Funcionalidade em desenvolvimento'),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  _buildListTile(
                    title: 'Excluir Conta',
                    subtitle: 'Remover permanentemente sua conta e dados',
                    icon: Icons.delete_outline,
                    iconColor: AppTheme.errorColor,
                    onTap: () {
                      _showDeleteAccountDialog();
                    },
                  ),
                  const SizedBox(height: 32),
                  
                  // Seção de Ajuda
                  _buildSectionTitle('Ajuda'),
                  const SizedBox(height: 16),
                  _buildListTile(
                    title: 'Ajuda e Suporte',
                    subtitle: 'FAQ, dicas e informações de contato',
                    icon: Icons.help_outline,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const HelpScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SwitchListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        value: value,
        onChanged: onChanged,
        secondary: Icon(icon, color: AppTheme.primaryColor),
        activeColor: AppTheme.primaryColor,
      ),
    );
  }

  Widget _buildListTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        leading: Icon(icon, color: iconColor ?? AppTheme.primaryColor),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Conta'),
        content: const Text(
          'Tem certeza que deseja excluir sua conta? Esta ação não pode ser desfeita e todos os seus dados serão removidos permanentemente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Funcionalidade em desenvolvimento'),
                ),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.errorColor,
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }
}

