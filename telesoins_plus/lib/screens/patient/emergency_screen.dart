import 'package:flutter/material.dart';
import 'package:telesoins_plus/config/theme.dart';
import 'package:telesoins_plus/models/user.dart';
import 'package:telesoins_plus/widgets/common/app_bar.dart';
import 'package:telesoins_plus/widgets/common/loading_indicator.dart';
import 'package:url_launcher/url_launcher.dart';

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({Key? key}) : super(key: key);

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> {
  bool _isLoading = false;
  List<Medecin> _availableMedecins = [];

  @override
  void initState() {
    super.initState();
    _loadAvailableMedecins();
  }

  Future<void> _loadAvailableMedecins() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Appel API réel
      // Simulation de médecins disponibles
      await Future.delayed(const Duration(seconds: 1));
      
      setState(() {
        _availableMedecins = List.generate(
          3,
          (index) => Medecin(
            id: index + 1,
            email: 'medecin${index + 1}@example.com',
            firstName: 'Dr. Prénom${index + 1}',
            lastName: 'Nom${index + 1}',
            phoneNumber: '+33 6 12 34 56 78',
            speciality: ['Urgentiste', 'Généraliste', 'Cardiologue'][index],
            isAvailableForEmergency: true,
          ),
        );
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _callEmergencyServices(String number) async {
    final Uri uri = Uri.parse('tel:$number');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Impossible d\'appeler le $number'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _startUrgentConsultation(Medecin medecin) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Implémenter l'appel API réel
      await Future.delayed(const Duration(seconds: 2));
      
      if (context.mounted) {
        Navigator.pushNamed(
          context,
          '/patient/consultation',
          arguments: 999, // ID de consultation simulé
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
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
        title: 'Urgence',
        type: AppBarType.patient,
      ),
      body: _isLoading
          ? const LoadingIndicator()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Bannière d'alerte
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.urgentColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.warning,
                              color: Colors.white,
                              size: 32,
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                'EN CAS D\'URGENCE VITALE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Si vous ou quelqu\'un autour de vous est en danger immédiat, contactez immédiatement les services d\'urgence.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildEmergencyButton(
                              '119',
                              'SAMU',
                              Icons.local_hospital,
                              () => _callEmergencyServices('119'),
                            ),
                            _buildEmergencyButton(
                              '118',
                              'Pompiers',
                              Icons.local_fire_department,
                              () => _callEmergencyServices('118'),
                            ),
                            _buildEmergencyButton(
                              '1510',
                              'Covid 19',
                              Icons.emergency,
                              () => _callEmergencyServices('1510'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Médecins disponibles
                  const Text(
                    'Médecins disponibles maintenant',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _availableMedecins.isEmpty
                      ? const Card(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(
                              child: Text(
                                'Aucun médecin disponible actuellement',
                                style: TextStyle(
                                  color: AppTheme.textSecondaryColor,
                                ),
                              ),
                            ),
                          ),
                        )
                      : Column(
                          children: _availableMedecins.map((medecin) {
                            return Card(
                              margin: const EdgeInsets.only(bottom: 16),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: AppTheme.medicalBlue,
                                      radius: 30,
                                      child: Text(
                                        _getInitials('${medecin.firstName} ${medecin.lastName}'),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${medecin.firstName} ${medecin.lastName}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          Text(
                                            medecin.speciality ?? 'Médecin',
                                            style: const TextStyle(
                                              color: AppTheme.textSecondaryColor,
                                            ),
                                          ),
                                         Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.circle,
                                                color: AppTheme.successColor,
                                                size: 12,
                                              ),
                                              const SizedBox(width: 4),
                                              const Flexible(
                                                child: Text(
                                                  'Disponible maintenant',
                                                  style: TextStyle(
                                                    color: AppTheme.successColor,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    ElevatedButton.icon(
                                      onPressed: () => _startUrgentConsultation(medecin),
                                      icon: const Icon(Icons.videocam),
                                      label: const Text('Consulter'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.urgentColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                  const SizedBox(height: 24),
                  
                  // Guides de premiers secours
                  const Text(
                    'Guides de premiers secours',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.8,
                    children: [
                      _buildFirstAidGuideCard(
                        'Arrêt cardiaque',
                        Icons.favorite,
                        Colors.red,
                        '/patient/first_aid/module?id=1',
                      ),
                      _buildFirstAidGuideCard(
                        'Hémorragie',
                        Icons.opacity,
                        Colors.redAccent,
                        '/patient/first_aid/module?id=2',
                      ),
                      _buildFirstAidGuideCard(
                        'Étouffement',
                        Icons.air,
                        Colors.blue,
                        '/patient/first_aid/module?id=4',
                      ),
                      _buildFirstAidGuideCard(
                        'Brûlures',
                        Icons.whatshot,
                        Colors.orange,
                        '/patient/first_aid/module?id=3',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, '/patient/first_aid');
                    },
                    icon: const Icon(Icons.medical_services),
                    label: const Text('Tous les guides'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.medicalBlue,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildEmergencyButton(String number, String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    color: AppTheme.urgentColor,
                    size: 24,
                  ),
                  Text(
                    number,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.urgentColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFirstAidGuideCard(String title, IconData icon, Color color, String route) {
    return Card(
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(context, route);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48,
                color: color,
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Guide rapide',
                style: TextStyle(
                  color: AppTheme.textSecondaryColor,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getInitials(String fullName) {
    List<String> names = fullName.split(' ');
    String initials = '';
    if (names.isNotEmpty) {
      initials += names[0][0];
      if (names.length > 1) {
        initials += names[names.length - 1][0];
      }
    }
    return initials.toUpperCase();
  }
}