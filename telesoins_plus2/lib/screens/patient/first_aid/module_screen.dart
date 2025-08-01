import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:telesoins_plus2/config/api_constants.dart';
import 'package:telesoins_plus2/config/theme.dart';
import 'package:telesoins_plus2/main.dart';
import 'package:telesoins_plus2/models/first_aid.dart';
import 'package:telesoins_plus2/services/api_service.dart';
import 'package:telesoins_plus2/widgets/common/loading_indicator.dart';

class ModuleScreen extends StatefulWidget {
  final String moduleId;

  const ModuleScreen({
    Key? key,
    required this.moduleId,
  }) : super(key: key);

  @override
  _ModuleScreenState createState() => _ModuleScreenState();
}

class _ModuleScreenState extends State<ModuleScreen> {
  final ApiService _apiService = getIt<ApiService>();
  bool _isLoading = true;
  FirstAidModule? _module;
  List<QuizResult>? _quizResults;

  @override
  void initState() {
    super.initState();
    _loadModuleDetails();
  }

  Future<void> _loadModuleDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Charger les détails du module
      final response = await _apiService.get(
        '${ApiConstants.firstAidModules}${widget.moduleId}/',
      );

      // Charger les résultats des quiz pour ce module
      final quizResultsResponse = await _apiService.get(
        '${ApiConstants.quizResults}by_module/?module_id=${widget.moduleId}',
      );

      if (mounted) {
        setState(() {
          _module = FirstAidModule.fromJson(response);
          _quizResults = (quizResultsResponse as List)
              .map((result) => QuizResult.fromJson(result))
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
            content: Text('Erreur lors du chargement du module: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isLoading ? 'Module' : _module!.title),
      ),
      body: _isLoading
          ? const LoadingIndicator()
          : _module == null
              ? const Center(
                  child: Text('Module non trouvé'),
                )
              : RefreshIndicator(
                  onRefresh: _loadModuleDetails,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // En-tête du module
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: _getDifficultyColor(_module!.difficultyLevel).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      _getDifficultyIcon(_module!.difficultyLevel),
                                      color: _getDifficultyColor(_module!.difficultyLevel),
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _module!.title,
                                          style: const TextStyle(
                                            fontSize: 20,
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
                                                color: _getDifficultyColor(_module!.difficultyLevel).withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                _module!.difficultyLabel,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: _getDifficultyColor(_module!.difficultyLevel),
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.grey[200],
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                _module!.category,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[700],
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _module!.description,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Contenu du module
                      const Text(
                        'Contenu du module',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_module!.contents == null || _module!.contents!.isEmpty)
                        Card(
                          child: const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(
                              child: Text(
                                'Aucun contenu disponible',
                                style: TextStyle(
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ),
                        )
                      else
                        ..._module!.contents!.map((content) {
                          // Icône en fonction du type de contenu
                          IconData contentIcon;
                          switch (content.contentType) {
                            case 'video':
                              contentIcon = Icons.videocam_outlined;
                              break;
                            case 'image':
                              contentIcon = Icons.image_outlined;
                              break;
                            case 'audio':
                              contentIcon = Icons.headphones_outlined;
                              break;
                            case 'text':
                              contentIcon = Icons.article_outlined;
                              break;
                            case 'checklist':
                              contentIcon = Icons.checklist_outlined;
                              break;
                            default:
                              contentIcon = Icons.insert_drive_file_outlined;
                          }

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: InkWell(
                              onTap: () {
                                // Naviguer vers le contenu
                                _showContentDialog(content);
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryLight,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        contentIcon,
                                        color: AppTheme.primaryColor,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            content.title,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            content.contentTypeLabel,
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 14,
                                            ),
                                          ),
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
                          );
                        }).toList(),
                      const SizedBox(height: 24),

                      // Quiz
                      const Text(
                        'Évaluations',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_module!.quizzes == null || _module!.quizzes!.isEmpty)
                        Card(
                          child: const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(
                              child: Text(
                                'Aucun quiz disponible',
                                style: TextStyle(
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ),
                        )
                      else
                        ..._module!.quizzes!.map((quiz) {
                          // Vérifier si l'utilisateur a déjà passé ce quiz
                          final result = _quizResults?.firstWhere(
                            (r) => r.quizId == quiz.id,
                            orElse: () => QuizResult(
                              id: '',
                              userId: '',
                              quizId: quiz.id,
                              quizTitle: quiz.title,
                              score: 0,
                              completedAt: DateTime.now(),
                              passed: false,
                            ),
                          );
                          final bool hasCompleted = result?.id.isNotEmpty ?? false;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: AppTheme.secondaryColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                          Icons.quiz_outlined,
                                          color: AppTheme.secondaryColor,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              quiz.title,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            if (quiz.description != null && quiz.description!.isNotEmpty)
                                              Text(
                                                quiz.description!,
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: 14,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (hasCompleted) ...[
                                    const SizedBox(height: 12),
                                    LinearProgressIndicator(
                                      value: result!.score / 100,
                                      backgroundColor: Colors.grey[200],
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        result.passed
                                            ? AppTheme.successColor
                                            : AppTheme.warningColor,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Score: ${result.score}%',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: result.passed
                                                ? AppTheme.successColor.withOpacity(0.1)
                                                : AppTheme.warningColor.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            result.passed ? 'Réussi' : 'Échoué',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: result.passed
                                                  ? AppTheme.successColor
                                                  : AppTheme.warningColor,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        // Naviguer vers le quiz
                                        context.push('/patient/first-aid/quiz/${quiz.id}');
                                      },
                                      icon: Icon(
                                        hasCompleted ? Icons.refresh : Icons.play_arrow,
                                      ),
                                      label: Text(
                                        hasCompleted ? 'Reprendre le quiz' : 'Commencer le quiz',
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.secondaryColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                    ],
                  ),
                ),
    );
  }

  // Couleur en fonction du niveau de difficulté
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

  // Icône en fonction du niveau de difficulté
  IconData _getDifficultyIcon(int difficultyLevel) {
    switch (difficultyLevel) {
      case 1:
        return Icons.emoji_events_outlined; // Facile
      case 2:
        return Icons.school_outlined; // Intermédiaire
      case 3:
        return Icons.warning_amber_outlined; // Avancé
      default:
        return Icons.help_outline;
    }
  }

  // Afficher le contenu dans une boîte de dialogue
  void _showContentDialog(FirstAidContent content) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.9,
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                content.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                content.contentTypeLabel,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              const Divider(height: 24),
              Flexible(
                child: SingleChildScrollView(
                  child: _buildContentDisplay(content),
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Fermer'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Afficher le contenu en fonction du type
  Widget _buildContentDisplay(FirstAidContent content) {
    switch (content.contentType) {
      case 'text':
        return Text(
          content.content ?? 'Aucun contenu disponible',
          style: const TextStyle(fontSize: 16),
        );
      case 'checklist':
        final items = content.content?.split('\n') ?? [];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: items.map((item) {
            final trimmedItem = item.trim();
            if (trimmedItem.isEmpty) return const SizedBox.shrink();
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle_outline, size: 20, color: AppTheme.successColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      trimmedItem,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      case 'image':
        return content.fileUrl != null
            ? Image.network(
                content.fileUrl!,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Text('Impossible de charger l\'image'),
                  );
                },
              )
            : const Center(
                child: Text('Aucune image disponible'),
              );
      case 'video':
        // Idéalement, utiliser un lecteur vidéo ici
        return content.fileUrl != null
            ? Center(
                child: Column(
                  children: [
                    const Icon(
                      Icons.videocam_outlined,
                      size: 64,
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        // Ouvrir le lecteur vidéo
                      },
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Lire la vidéo'),
                    ),
                  ],
                ),
              )
            : const Center(
                child: Text('Aucune vidéo disponible'),
              );
      case 'audio':
        // Idéalement, utiliser un lecteur audio ici
        return content.fileUrl != null
            ? Center(
                child: Column(
                  children: [
                    const Icon(
                      Icons.headphones_outlined,
                      size: 64,
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        // Ouvrir le lecteur audio
                      },
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Écouter l\'audio'),
                    ),
                  ],
                ),
              )
            : const Center(
                child: Text('Aucun audio disponible'),
              );
      default:
        return const Center(
          child: Text('Type de contenu non pris en charge'),
        );
    }
  }
}