import 'package:flutter/material.dart';
import 'package:telesoins_plus/config/theme.dart';
import 'package:telesoins_plus/models/first_aid.dart';
import 'package:telesoins_plus/services/storage_service.dart';
import 'package:telesoins_plus/widgets/common/app_bar.dart';
import 'package:telesoins_plus/widgets/common/loading_indicator.dart';
import 'package:telesoins_plus/widgets/common/error_display.dart';
import 'package:telesoins_plus/screens/patient/first_aid/quiz_screen.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class ModuleScreen extends StatefulWidget {
  final int moduleId;

  const ModuleScreen({
    Key? key,
    required this.moduleId,
  }) : super(key: key);

  @override
  State<ModuleScreen> createState() => _ModuleScreenState();
}

class _ModuleScreenState extends State<ModuleScreen> {
  final StorageService _storageService = StorageService();
  bool _isLoading = false;
  bool _isDownloading = false;
  String? _errorMessage;
  FirstAidModule? _module;
  bool _isDownloaded = false;
  bool _showCompleteButton = false;
  
  // Pour la lecture de vidéo
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  int _contentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadModule();
  }
  
  @override
  void dispose() {
    _videoController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  Future<void> _loadModule() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Vérifier si le module est téléchargé
      final downloadedModules = await _storageService.getAllSavedFirstAidModules();
      _isDownloaded = downloadedModules.contains(widget.moduleId.toString());
      
      // TODO: Remplacer par un appel API réel
      // Simuler le chargement des données
      await Future.delayed(const Duration(seconds: 1));
      
      // Simuler un module
      _module = FirstAidModule(
        id: widget.moduleId,
        title: 'Gestes de premiers secours',
        description: 'Apprendre les gestes qui sauvent',
        iconUrl: 'assets/images/icons/first_aid.png',
        level: ModuleLevel.beginner,
        contents: [
          FirstAidContent(
            id: 1,
            title: 'Introduction aux premiers secours',
            type: ContentType.text,
            content: 'Les premiers secours désignent l\'ensemble des techniques et gestes d\'urgence pratiqués sur une personne victime d\'un accident ou d\'un malaise dans l\'attente des secours médicaux. Ils ont pour objectif de préserver la vie de la victime, de limiter l\'aggravation de son état et de favoriser sa récupération. Ils sont accessibles à tous et ne nécessitent pas de matériel particulier.',
            order: 1,
          ),
          FirstAidContent(
            id: 2,
            title: 'Position latérale de sécurité (PLS)',
            type: ContentType.image,
            content: 'La position latérale de sécurité est utilisée lorsqu\'une personne est inconsciente mais respire normalement. Cette position permet d\'éviter l\'obstruction des voies respiratoires par la langue ou par des liquides comme le sang ou les vomissements.',
            order: 2,
            mediaUrl: 'assets/images/first_aid/pls.jpg',
          ),
          FirstAidContent(
            id: 3,
            title: 'Massage cardiaque',
            type: ContentType.video,
            content: 'Le massage cardiaque est une technique de réanimation cardio-pulmonaire qui consiste à exercer des compressions régulières sur le sternum afin de maintenir une circulation sanguine minimale vers le cerveau et les organes vitaux en cas d\'arrêt cardiaque.',
            order: 3,
            mediaUrl: 'assets/videos/first_aid/cpr.mp4',
          ),
          FirstAidContent(
            id: 4,
            title: 'Utilisation d\'un défibrillateur',
            type: ContentType.image,
            content: 'Un défibrillateur automatisé externe (DAE) est un appareil qui permet d\'administrer un choc électrique au cœur d\'une personne en arrêt cardiaque. Il analyse automatiquement l\'activité électrique du cœur et détermine si un choc est nécessaire.',
            order: 4,
            mediaUrl: 'assets/images/first_aid/defibrillator.jpg',
          ),
          FirstAidContent(
            id: 5,
            title: 'Que faire en cas d\'étouffement',
            type: ContentType.checklist,
            content: 'Voici les étapes à suivre en cas d\'étouffement par un corps étranger:',
            order: 5,
            mediaUrl: 'Étapes à suivre:\n1. Demander "Vous étouffez?" pour confirmer\n2. Donner 5 claques vigoureuses dans le dos\n3. Si inefficace, effectuer 5 compressions abdominales (manœuvre de Heimlich)\n4. Alterner 5 claques dans le dos et 5 compressions abdominales jusqu\'à expulsion du corps étranger\n5. Si la personne perd connaissance, allonger la sur le dos et débuter la réanimation cardio-pulmonaire',
          ),
        ],
        quiz: FirstAidQuiz(
          id: 1,
          title: 'Quiz sur les premiers secours',
          description: 'Testez vos connaissances sur les gestes de premiers secours',
          questions: [
            QuizQuestion(
              id: 1,
              question: 'Quel est le numéro d\'urgence européen?',
              options: ['15', '18', '112', '911'],
              correctOption: 2,
              explanation: 'Le numéro d\'urgence européen est le 112, il fonctionne dans tous les pays de l\'Union Européenne.',
            ),
            QuizQuestion(
              id: 2,
              question: 'Que faire en premier lorsque vous arrivez sur les lieux d\'un accident?',
              options: [
                'Secourir immédiatement les victimes',
                'Appeler les secours',
                'Protéger la zone pour éviter un sur-accident',
                'Chercher des témoins'
              ],
              correctOption: 2,
              explanation: 'La première chose à faire est de protéger la zone pour éviter qu\'un nouvel accident ne se produise.',
            ),
            QuizQuestion(
              id: 3,
              question: 'Comment vérifier si une personne inconsciente respire?',
              options: [
                'Placer un miroir devant sa bouche',
                'Regarder, écouter et sentir pendant 10 secondes',
                'Vérifier son pouls uniquement',
                'Tapoter ses joues pour voir si elle réagit'
              ],
              correctOption: 1,
              explanation: 'Pour vérifier la respiration, il faut se pencher sur la victime, regarder si le thorax se soulève, écouter les bruits respiratoires et sentir l\'air expiré sur sa joue.',
            ),
          ],
          passingScore: 70,
        ),
        isDownloadable: true,
        downloadSizeKb: 2500,
      );
      
      // Initialiser le premier contenu s'il s'agit d'une vidéo
      if (_module!.contents.isNotEmpty && _module!.contents[0].type == ContentType.video) {
        _initializeVideoPlayer(_module!.contents[0].mediaUrl);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors du chargement du module: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _downloadModule() async {
    if (_module == null) return;
    
    setState(() {
      _isDownloading = true;
    });
    
    try {
      // Simuler le téléchargement
      await Future.delayed(const Duration(seconds: 2));
      
      // Sauvegarder le contenu du module (simplifié pour l'exemple)
      await _storageService.saveFirstAidContent(
        _module!.id.toString(),
        'Contenu du module ${_module!.title}',
      );
      
      setState(() {
        _isDownloaded = true;
      });
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Module "${_module!.title}" téléchargé avec succès'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du téléchargement: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      setState(() {
        _isDownloading = false;
      });
    }
  }
  
  Future<void> _deleteModule() async {
    if (_module == null) return;
    
    // Afficher une boîte de dialogue de confirmation
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le module'),
        content: const Text('Êtes-vous sûr de vouloir supprimer ce module de votre appareil ? Vous pourrez le télécharger à nouveau ultérieurement.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    
    if (shouldDelete != true) return;
    
    setState(() {
      _isDownloading = true;
    });
    
    try {
      await _storageService.removeOfflineData(_module!.id.toString());
      
      setState(() {
        _isDownloaded = false;
      });
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Module supprimé avec succès'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la suppression: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      setState(() {
        _isDownloading = false;
      });
    }
  }
  
  void _startQuiz() {
    if (_module?.quiz == null) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuizScreen(
          moduleId: _module!.id,
          quiz: _module!.quiz!,
        ),
      ),
    );
  }
  
  void _navigateToContent(int index) {
    if (_module == null || index < 0 || index >= _module!.contents.length) return;
    
    // Libérer les ressources de l'ancien lecteur vidéo si nécessaire
    _videoController?.pause();
    
    setState(() {
      _contentIndex = index;
      
      // Initialiser le lecteur vidéo si nécessaire
      if (_module!.contents[index].type == ContentType.video) {
        _initializeVideoPlayer(_module!.contents[index].mediaUrl);
      } else {
        _videoController?.dispose();
        _videoController = null;
        _chewieController?.dispose();
        _chewieController = null;
      }
      
      // Afficher le bouton pour terminer si c'est le dernier contenu
      _showCompleteButton = index == _module!.contents.length - 1;
    });
  }
  
  Future<void> _initializeVideoPlayer(String? videoUrl) async {
    if (videoUrl == null) return;
    
    // Dans un cas réel, il faudrait utiliser l'URL réelle ou le chemin local
    // Ici, nous utilisons un exemple de chemin local
    final videoPath = 'assets/videos/sample.mp4';
    
    _videoController = VideoPlayerController.asset(videoPath);
    await _videoController!.initialize();
    
    _chewieController = ChewieController(
      videoPlayerController: _videoController!,
      autoPlay: false,
      looping: false,
      aspectRatio: _videoController!.value.aspectRatio,
      allowMuting: true,
      errorBuilder: (context, errorMessage) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error,
                color: AppTheme.errorColor,
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                'Erreur de lecture: $errorMessage',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.errorColor),
              ),
            ],
          ),
        );
      },
    );
    
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: _module?.title ?? 'Module de premiers secours',
        type: AppBarType.patient,
        actions: [
          if (_module != null && _module!.isDownloadable)
            _isDownloaded
                ? IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Supprimer le module',
                    onPressed: _deleteModule,
                  )
                : IconButton(
                    icon: const Icon(Icons.download),
                    tooltip: 'Télécharger le module',
                    onPressed: _downloadModule,
                  ),
          if (_module?.quiz != null)
            IconButton(
              icon: const Icon(Icons.quiz),
              tooltip: 'Quiz',
              onPressed: _startQuiz,
            ),
        ],
      ),
      body: _isLoading
          ? const LoadingIndicator()
          : _errorMessage != null
              ? ErrorDisplay(
                  message: 'Erreur de chargement',
                  details: _errorMessage,
                  onRetry: _loadModule,
                )
              : _module == null
                  ? const Center(child: Text('Module introuvable'))
                  : Column(
                      children: [
                        // Table des matières
                        Container(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: List.generate(
                                _module!.contents.length,
                                (index) => Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  child: ChoiceChip(
                                    label: Text(
                                      'Étape ${index + 1}',
                                      style: TextStyle(
                                        color: _contentIndex == index 
                                            ? Colors.white 
                                            : AppTheme.textPrimaryColor,
                                      ),
                                    ),
                                    selected: _contentIndex == index,
                                    onSelected: (_) => _navigateToContent(index),
                                    selectedColor: AppTheme.primaryColor,
                                    backgroundColor: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        
                        // Contenu du module
                        Expanded(
                          child: _module!.contents.isEmpty
                              ? const Center(
                                  child: Text('Aucun contenu disponible'),
                                )
                              : _buildContent(_module!.contents[_contentIndex]),
                        ),
                        
                        // Navigation entre contenus
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, -2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (_contentIndex > 0)
                                ElevatedButton.icon(
                                  onPressed: () => _navigateToContent(_contentIndex - 1),
                                  icon: const Icon(Icons.arrow_back),
                                  label: const Text('Précédent'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: AppTheme.primaryColor,
                                    side: const BorderSide(color: AppTheme.primaryColor),
                                  ),
                                )
                              else
                                const SizedBox(),
                              
                              if (_contentIndex < _module!.contents.length - 1)
                                ElevatedButton.icon(
                                  onPressed: () => _navigateToContent(_contentIndex + 1),
                                  icon: const Icon(Icons.arrow_forward),
                                  label: const Text('Suivant'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryColor,
                                  ),
                                )
                              else if (_module!.quiz != null)
                                ElevatedButton.icon(
                                  onPressed: _startQuiz,
                                  icon: const Icon(Icons.check),
                                  label: const Text('Aller au quiz'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryColor,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
      // Indicateur de téléchargement
      floatingActionButton: _isDownloading
          ? const FloatingActionButton(
              onPressed: null,
              backgroundColor: Colors.white,
              child: CircularProgressIndicator(),
            )
          : null,
    );
  }
  
  Widget _buildContent(FirstAidContent content) {
    switch (content.type) {
      case ContentType.text:
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                content.title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                content.content,
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
            ],
          ),
        );
        
      case ContentType.image:
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                content.title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                content.content,
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              if (content.mediaUrl != null)
                Center(
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 300),
                    child: Image.asset(
                      'assets/images/placeholder.png', // Dans un cas réel, utiliser content.mediaUrl
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.broken_image,
                        size: 100,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
        
      case ContentType.video:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                content.title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (_chewieController != null && _videoController != null)
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: _videoController!.value.aspectRatio,
                    child: Chewie(controller: _chewieController!),
                  ),
                ),
              )
            else
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                content.content,
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
            ),
          ],
        );
        
      case ContentType.audio:
        // Implémentation simplifiée pour l'audio
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                content.title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                content.content,
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.audiotrack,
                        size: 48,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Fichier audio disponible',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () {
                          // TODO: Implémenter la lecture audio
                        },
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Écouter'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
        
      case ContentType.checklist:
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                content.title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                content.content,
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              if (content.mediaUrl != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    content.mediaUrl!,
                    style: const TextStyle(
                      fontSize: 16,
                    ),
                  ),
                ),
            ],
          ),
        );
    }
  }
}