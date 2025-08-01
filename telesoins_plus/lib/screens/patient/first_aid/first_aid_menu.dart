import 'package:flutter/material.dart';
import 'package:telesoins_plus/config/theme.dart';
import 'package:telesoins_plus/models/first_aid.dart';
import 'package:telesoins_plus/services/storage_service.dart';
import 'package:telesoins_plus/widgets/common/app_bar.dart';
import 'package:telesoins_plus/widgets/common/nav_drawer.dart';
import 'package:telesoins_plus/widgets/common/loading_indicator.dart';
import 'package:telesoins_plus/widgets/common/error_display.dart';

class FirstAidMenuScreen extends StatefulWidget {
  const FirstAidMenuScreen({Key? key}) : super(key: key);

  @override
  State<FirstAidMenuScreen> createState() => _FirstAidMenuScreenState();
}

class _FirstAidMenuScreenState extends State<FirstAidMenuScreen> {
  final StorageService _storageService = StorageService();
  bool _isLoading = false;
  String? _errorMessage;
  List<FirstAidModule> _modules = [];
  List<String> _downloadedModuleIds = [];
  TextEditingController _searchController = TextEditingController();
  List<FirstAidModule> _filteredModules = [];

  @override
  void initState() {
    super.initState();
    _loadModules();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadModules() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // TODO: Remplacer par un appel API réel pour charger les modules
      await Future.delayed(const Duration(seconds: 1));
      
      // Modules simulés
      _modules = [
        FirstAidModule(
          id: 1,
          title: 'Réanimation cardio-pulmonaire (RCP)',
          description: 'Apprenez les techniques de base pour réanimer une personne en arrêt cardiaque.',
          iconUrl: 'assets/images/icons/cpr.png',
          level: ModuleLevel.beginner,
          contents: [],
          isDownloadable: true,
          downloadSizeKb: 800,
        ),
        FirstAidModule(
          id: 2,
          title: 'Hémorragies',
          description: 'Comment arrêter un saignement important et éviter les complications.',
          iconUrl: 'assets/images/icons/bleeding.png',
          level: ModuleLevel.beginner,
          contents: [],
          isDownloadable: true,
          downloadSizeKb: 1200,
        ),
        FirstAidModule(
          id: 3,
          title: 'Brûlures',
          description: 'Premiers soins pour différents types de brûlures.',
          iconUrl: 'assets/images/icons/burns.png',
          level: ModuleLevel.beginner,
          contents: [],
          isDownloadable: true,
          downloadSizeKb: 550,
        ),
        FirstAidModule(
          id: 4,
          title: 'Étouffement',
          description: 'Techniques pour aider une personne qui s\'étouffe, incluant la manœuvre de Heimlich.',
          iconUrl: 'assets/images/icons/choking.png',
          level: ModuleLevel.beginner,
          contents: [],
          isDownloadable: true,
          downloadSizeKb: 850,
        ),
        FirstAidModule(
          id: 5,
          title: 'Fractures et entorses',
          description: 'Comment identifier et prendre en charge les blessures osseuses et articulaires.',
          iconUrl: 'assets/images/icons/fracture.png',
          level: ModuleLevel.intermediate,
          contents: [],
          isDownloadable: true,
          downloadSizeKb: 1100,
        ),
        FirstAidModule(
          id: 6,
          title: 'Morsures et piqûres',
          description: 'Traitement des morsures d\'animaux et piqûres d\'insectes.',
          iconUrl: 'assets/images/icons/bite.png',
          level: ModuleLevel.intermediate,
          contents: [],
          isDownloadable: true,
          downloadSizeKb: 980,
        ),
        FirstAidModule(
          id: 7,
          title: 'Urgences pédiatriques',
          description: 'Premiers secours adaptés aux enfants et nourrissons.',
          iconUrl: 'assets/images/icons/pediatric.png',
          level: ModuleLevel.advanced,
          contents: [],
          isDownloadable: true,
          downloadSizeKb: 1800,
        ),
      ];

      // Vérifier quels modules sont déjà téléchargés
      _downloadedModuleIds = await _storageService.getAllSavedFirstAidModules();
      
      _filteredModules = List.from(_modules);
    } catch (e) {
      setState(() {
        _errorMessage = 'Impossible de charger les modules: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterModules(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredModules = List.from(_modules);
      } else {
        _filteredModules = _modules
            .where((module) =>
                module.title.toLowerCase().contains(query.toLowerCase()) ||
                module.description.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  Future<void> _downloadModule(FirstAidModule module) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Simuler le téléchargement
      await Future.delayed(const Duration(seconds: 2));
      
      // Sauvegarder le contenu du module (simplifié pour l'exemple)
      await _storageService.saveFirstAidContent(
        module.id.toString(),
        'Contenu du module ${module.title}',
      );
      
      setState(() {
        _downloadedModuleIds.add(module.id.toString());
      });
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Module "${module.title}" téléchargé avec succès'),
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
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Premiers Secours',
        type: AppBarType.patient,
      ),
      drawer: const NavDrawer(activeRoute: '/patient/first_aid'),
      body: Column(
        children: [
          // Bannière d'urgence
          Container(
            padding: const EdgeInsets.all(16),
            color: AppTheme.urgentColor,
            child: Row(
              children: [
                const Icon(
                  Icons.emergency,
                  color: Colors.white,
                  size: 32,
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'URGENCE',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'En cas d\'urgence vitale, composez le 19 ou le 119',
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    // TODO: Implémenter l'appel d'urgence
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppTheme.urgentColor,
                  ),
                  child: const Text('APPELER'),
                ),
              ],
            ),
          ),
          // Barre de recherche
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher un module...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filterModules('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: _filterModules,
            ),
          ),
          // Liste des modules
          Expanded(
            child: _isLoading
                ? const LoadingIndicator()
                : _errorMessage != null
                    ? ErrorDisplay(
                        message: 'Erreur de chargement',
                        details: _errorMessage,
                        onRetry: _loadModules,
                      )
                    : _filteredModules.isEmpty
                        ? const Center(
                            child: Text(
                              'Aucun module trouvé',
                              style: TextStyle(
                                color: AppTheme.textSecondaryColor,
                                fontSize: 16,
                              ),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadModules,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(8),
                              itemCount: _filteredModules.length,
                              itemBuilder: (context, index) {
                                final module = _filteredModules[index];
                                final isDownloaded = _downloadedModuleIds.contains(module.id.toString());
                                
                                return Card(
                                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                  child: ListTile(
                                    leading: Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.healing,
                                        color: AppTheme.primaryColor,
                                      ),
                                    ),
                                    title: Text(
                                      module.title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 4),
                                        Text(
                                          module.description,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: _getLevelColor(module.level).withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                module.levelText,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: _getLevelColor(module.level),
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            if (isDownloaded)
                                              Flexible(
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    const Icon(
                                                      Icons.check_circle,
                                                      size: 16,
                                                      color: AppTheme.successColor,
                                                    ),
                                                    const SizedBox(width: 2),
                                                    Flexible(
                                                      child: const Text(
                                                        'Disponible hors-ligne',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color: AppTheme.successColor,
                                                        ),
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    trailing: isDownloaded
                                        ? IconButton(
                                            icon: const Icon(Icons.play_arrow),
                                            color: AppTheme.primaryColor,
                                            onPressed: () {
                                              Navigator.pushNamed(
                                                context,
                                                '/patient/first_aid/module',
                                                arguments: module.id,
                                              );
                                            },
                                          )
                                        : IconButton(
                                            icon: const Icon(Icons.download),
                                            color: AppTheme.medicalBlue,
                                            onPressed: () {
                                              _downloadModule(module);
                                            },
                                          ),
                                    onTap: () {
                                      Navigator.pushNamed(
                                        context,
                                        '/patient/first_aid/module',
                                        arguments: module.id,
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Color _getLevelColor(ModuleLevel level) {
    switch (level) {
      case ModuleLevel.beginner:
        return AppTheme.successColor;
      case ModuleLevel.intermediate:
        return AppTheme.warningColor;
      case ModuleLevel.advanced:
        return AppTheme.primaryColor;
    }
  }
}