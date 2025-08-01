import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:telesoins_plus/config/api_constants.dart';
import 'package:telesoins_plus/config/theme.dart';
import 'package:telesoins_plus/main.dart';
import 'package:telesoins_plus/models/first_aid.dart';
import 'package:telesoins_plus/services/api_service.dart';
import 'package:telesoins_plus/widgets/common/loading_indicator.dart';

class FirstAidMenuScreen extends StatefulWidget {
  const FirstAidMenuScreen({Key? key}) : super(key: key);

  @override
  _FirstAidMenuScreenState createState() => _FirstAidMenuScreenState();
}

class _FirstAidMenuScreenState extends State<FirstAidMenuScreen> {
  final ApiService _apiService = getIt<ApiService>();
  bool _isLoading = true;
  Map<String, List<FirstAidModule>> _modulesByCategory = {};
  List<ModuleProgress> _progress = [];
  
  @override
  void initState() {
    super.initState();
    _loadModules();
  }
  
  Future<void> _loadModules() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Charger les modules par catégorie
      final modulesResponse = await _apiService.get(
        ApiConstants.firstAidModulesByCategory,
      );
      
      // Charger la progression de l'utilisateur
      final progressResponse = await _apiService.get(
        ApiConstants.quizResultsSummary,
      );
      
      if (mounted) {
        setState(() {
          // Convertir la réponse en map de modules
          _modulesByCategory = {};
          (modulesResponse as Map<String, dynamic>).forEach((category, modules) {
            _modulesByCategory[category] = (modules as List)
                .map((module) => FirstAidModule.fromJson(module))
                .toList();
          });
          
          // Convertir la réponse en liste de progression
          _progress = (progressResponse as List)
              .map((item) => ModuleProgress.fromJson(item))
              .toList();
          
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement des modules: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  ModuleProgress? _getProgressForModule(String moduleId) {
    return _progress.firstWhere(
      (p) => p.moduleId == moduleId,
      orElse: () => ModuleProgress(
        moduleId: moduleId,
        moduleTitle: '',
        moduleCategory: '',
        moduleDifficulty: '',
        completed: false,
        score: 0,
        passed: false,
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Premiers secours'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Implémenter la recherche de modules
            },
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingIndicator()
          : RefreshIndicator(
              onRefresh: _loadModules,
              child: _modulesByCategory.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.medical_services_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Aucun module de premiers secours disponible',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        // En-tête avec texte explicatif
                        const Text(
                          'Apprenez les gestes qui sauvent',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Explorez nos modules de formation aux premiers secours pour être prêt en cas d\'urgence.',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Liste des modules par catégorie
                        ..._modulesByCategory.entries.map((entry) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.key,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ...entry.value.map((module) {
                                final progress = _getProgressForModule(module.id);
                                
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: InkWell(
                                    onTap: () => context.push(
                                      '/patient/first-aid/module/${module.id}',
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              // Icône de difficulté
                                              Container(
                                                padding: const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: _getDifficultyColor(module.difficultyLevel).withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Icon(
                                                  _getDifficultyIcon(module.difficultyLevel),
                                                  color: _getDifficultyColor(module.difficultyLevel),
                                                  size: 24,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              
                                              // Titre et badge de difficulté
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      module.title,
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Row(
                                                      children: [
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(
                                                            horizontal: 8,
                                                            vertical: 2,
                                                          ),
                                                          decoration: BoxDecoration(
                                                            color: _getDifficultyColor(module.difficultyLevel).withOpacity(0.1),
                                                            borderRadius: BorderRadius.circular(4),
                                                          ),
                                                          child: Text(
                                                            module.difficultyLabel,
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              color: _getDifficultyColor(module.difficultyLevel),
                                                              fontWeight: FontWeight.bold,
                                                            ),
                                                          ),
                                                        ),
                                                        if (progress?.completed == true) ...[
                                                          const SizedBox(width: 8),
                                                          Container(
                                                            padding: const EdgeInsets.symmetric(
                                                              horizontal: 8,
                                                              vertical: 2,
                                                            ),
                                                            decoration: BoxDecoration(
                                                              color: progress?.passed == true
                                                                  ? AppTheme.successColor.withOpacity(0.1)
                                                                  : AppTheme.warningColor.withOpacity(0.1),
                                                              borderRadius: BorderRadius.circular(4),
                                                            ),
                                                            child: Text(
                                                              progress?.passed == true? 'Réussi' : 'À revoir',
                                                              style: TextStyle(
                                                                fontSize: 12,
                                                                color: progress?.passed == true
                                                                    ? AppTheme.successColor
                                                                    : AppTheme.warningColor,
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
                                              
                                              // Flèche pour naviguer
                                              const Icon(
                                                Icons.arrow_forward_ios,
                                                size: 16,
                                                color: Colors.grey,
                                              ),
                                            ],
                                          ),
                                          
                                          // Barre de progression
                                          if (progress?.completed == true) ...[
                                            const SizedBox(height: 12),
                                            LinearProgressIndicator(
                                              value: progress!.score / 100,
                                              backgroundColor: Colors.grey[200],
                                              valueColor: AlwaysStoppedAnimation<Color>(
                                                progress.passed == true
                                                    ? AppTheme.successColor
                                                    : AppTheme.warningColor,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Score: ${progress.score}%',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                              ),
                                              textAlign: TextAlign.right,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                              const SizedBox(height: 24),
                            ],
                          );
                        }).toList(),
                      ],
                    ),
            ),
    );
  }
  
  Color _getDifficultyColor(int difficultyLevel) {
    switch (difficultyLevel) {
      case 1:
        return AppTheme.successColor;
      case 2:
        return AppTheme.warningColor;
      case 3:
        return AppTheme.dangerColor;
      default:
        return Colors.grey;
    }
  }
  
  IconData _getDifficultyIcon(int difficultyLevel) {
    switch (difficultyLevel) {
      case 1:
        return Icons.emoji_events_outlined;  // Facile
      case 2:
        return Icons.school_outlined;  // Intermédiaire
      case 3:
        return Icons.warning_amber_outlined;  // Avancé
      default:
        return Icons.help_outline;
    }
  }
}