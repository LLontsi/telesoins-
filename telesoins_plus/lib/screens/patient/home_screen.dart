import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:telesoins_plus/config/theme.dart';
import 'package:telesoins_plus/models/appointment.dart';
import 'package:telesoins_plus/services/auth_service.dart';
import 'package:telesoins_plus/services/consultation_service.dart';
import 'package:telesoins_plus/widgets/common/app_bar.dart';
import 'package:telesoins_plus/widgets/common/loading_indicator.dart';
import 'package:telesoins_plus/widgets/common/error_display.dart';
import 'package:telesoins_plus/widgets/appointment_card.dart';
import 'package:telesoins_plus/widgets/offline_banner.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ConsultationService _consultationService = ConsultationService();
  bool _isLoading = false;
  bool _isOffline = false;
  String? _errorMessage;
  List<Appointment> _upcomingAppointments = [];
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Charger les rendez-vous à venir
      final appointments = await _consultationService.getAppointments();
      // Filtrer pour ne prendre que les rendez-vous confirmés/en attente et futurs
      _upcomingAppointments = appointments
          .where((appointment) =>
              (appointment.status == AppointmentStatus.confirmed ||
                  appointment.status == AppointmentStatus.pending) &&
              appointment.dateTime.isAfter(DateTime.now()))
          .toList();
      // Trier par date
      _upcomingAppointments.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    } catch (e) {
      setState(() {
        _errorMessage = 'Impossible de charger les données: ${e.toString()}';
        _isOffline = true; // Supposons que l'erreur est due à une perte de connexion
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthService>(context).currentUser;
    final now = DateTime.now();
    final greeting = _getGreeting(now.hour);
    final dateFormat = DateFormat.yMMMMEEEEd('fr');

    return Scaffold(
      appBar: AppBar(
        title: const Text('TéléSoins+'),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        actions: [
          // Icône de notification
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () {
                  Navigator.pushNamed(
                    context, 
                    '/notifications',
                    arguments: {'userType': 'patient'}
                  ); // Naviguer vers l'écran des notifications
               },
              ),
              // Badge pour les notifications non lues
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: const Text(
                    '3', // Nombre de notifications
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
          // Avatar de l'utilisateur
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, '/profile');
              },
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white,
                backgroundImage: user?.profilePhotoUrl != null
                    ? NetworkImage(user!.profilePhotoUrl!)
                    : null,
                child: user?.profilePhotoUrl == null
                    ? Text(
                        _getInitials(user?.firstName ?? '', user?.lastName ?? ''),
                        style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: Column(
          children: [
            // Bannière hors-ligne si applicable
            if (_isOffline)
              OfflineBanner(
                onReconnect: _loadData,
              ),
            Expanded(
              child: _isLoading
                  ? const LoadingIndicator()
                  : _errorMessage != null && _upcomingAppointments.isEmpty
                      ? ErrorDisplay(
                          message: 'Impossible de charger les données',
                          details: _errorMessage,
                          onRetry: _loadData,
                          isFullScreen: true,
                        )
                      : SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // En-tête avec salutation
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '$greeting, ${user?.firstName ?? "Patient"}',
                                            style: const TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            dateFormat.format(now),
                                            style: const TextStyle(
                                              color: AppTheme.textSecondaryColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Bouton d'urgence
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        Navigator.pushNamed(context, '/patient/emergency');
                                      },
                                      icon: const Icon(Icons.emergency),
                                      label: const Text('Urgence'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.urgentColor,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                // Prochains rendez-vous
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Prochains rendez-vous',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        // Naviguer vers les rendez-vous ou changer d'onglet
                                        setState(() {
                                          _currentIndex = 1; // Onglet Rendez-vous
                                        });
                                      },
                                      child: const Text('Voir tout'),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                _upcomingAppointments.isEmpty
                                    ? const Card(
                                        child: Padding(
                                          padding: EdgeInsets.all(16),
                                          child: Center(
                                            child: Text(
                                              'Aucun rendez-vous à venir',
                                              style: TextStyle(
                                                color: AppTheme.textSecondaryColor,
                                              ),
                                            ),
                                          ),
                                        ),
                                      )
                                    : Column(
                                        children: _upcomingAppointments
                                            .take(3) // Limiter à 3 rendez-vous
                                            .map((appointment) => AppointmentCard(
                                                  appointment: appointment,
                                                  onTap: () {
                                                    // Navigation vers les détails du rendez-vous
                                                    Navigator.pushNamed(
                                                      context,
                                                      '/patient/appointment_details',
                                                      arguments: appointment.id,
                                                    );
                                                  },
                                                  onCancel: () {
                                                    // Afficher une boîte de dialogue de confirmation
                                                    _showCancelDialog(appointment);
                                                  },
                                                ))
                                            .toList(),
                                      ),
                                const SizedBox(height: 24),
                                // Accès rapides
                                const Text(
                                  'Accès rapides',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _buildQuickAccessGrid(),
                                const SizedBox(height: 24),
                                // Statistiques ou informations
                                const Text(
                                  'Suivi médical',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      children: [
                                        const Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text('Dernière consultation:'),
                                            Text('15/02/2025'), // À remplacer par des données réelles
                                          ],
                                        ),
                                        const Divider(),
                                        const Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text('Prescriptions actives:'),
                                            Text('3'), // À remplacer par des données réelles
                                          ],
                                        ),
                                        const Divider(),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            ElevatedButton(
                                              onPressed: () {
                                                Navigator.pushNamed(context, '/patient/medical_history');
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: AppTheme.medicalBlue,
                                              ),
                                              child: const Text('Voir mon dossier médical'),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                // Espace supplémentaire en bas pour éviter que le FAB ne cache du contenu
                                const SizedBox(height: 80),
                              ],
                            ),
                          ),
                        ),
            ),
          ],
        ),
      ),
      // Bouton d'action flottant pour ajouter un rendez-vous
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/patient/book_appointment');
        },
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      // Barre de navigation en bas
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          
          // Navigation basée sur l'onglet sélectionné
          switch (index) {
            case 1: // Rendez-vous
              Navigator.pushNamed(context, '/patient/appointments');
              break;
            case 2: // Premiers secours
              Navigator.pushNamed(context, '/patient/first_aid');
              break;
            case 3: // Prescriptions
              Navigator.pushNamed(context, '/patient/prescriptions');
              break;
          }
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            activeIcon: Icon(Icons.calendar_today),
            label: 'Rendez-vous',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.medical_services_outlined),
            activeIcon: Icon(Icons.medical_services),
            label: 'Premiers secours',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_outlined),
            activeIcon: Icon(Icons.receipt),
            label: 'Prescriptions',
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccessGrid() {
    // Le code reste inchangé...
    final quickAccess = [
      {
        'title': 'Nouveau RDV',
        'icon': Icons.calendar_today,
        'route': '/patient/book_appointment',
        'color': AppTheme.primaryColor,
      },
      {
        'title': 'Premiers secours',
        'icon': Icons.healing,
        'route': '/patient/first_aid',
        'color': AppTheme.urgentColor,
      },
      {
        'title': 'Ordonnances',
        'icon': Icons.receipt,
        'route': '/patient/prescriptions',
        'color': AppTheme.medicalBlue,
      },
      {
        'title': 'Messages',
        'icon': Icons.message,
        'route': '/patient/messaging',
        'color': AppTheme.medicalGreen,
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.5,
      ),
      itemCount: quickAccess.length,
      itemBuilder: (context, index) {
        final item = quickAccess[index];
        return Card(
          child: InkWell(
            onTap: () {
              Navigator.pushNamed(context, item['route'] as String);
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    item['icon'] as IconData,
                    size: 32,
                    color: item['color'] as Color,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item['title'] as String,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _getGreeting(int hour) {
    // Le code reste inchangé...
    if (hour < 12) {
      return 'Bonjour';
    } else if (hour < 18) {
      return 'Bon après-midi';
    } else {
      return 'Bonsoir';
    }
  }
  
  String _getInitials(String firstName, String lastName) {
    String initials = '';
    if (firstName.isNotEmpty) {
      initials += firstName[0];
    }
    if (lastName.isNotEmpty) {
      initials += lastName[0];
    }
    return initials.toUpperCase();
  }

  Future<void> _showCancelDialog(Appointment appointment) async {
    // Le code reste inchangé...
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Annuler le rendez-vous'),
          content: const Text(
            'Êtes-vous sûr de vouloir annuler ce rendez-vous ? Cette action ne peut pas être annulée.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Non'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  setState(() {
                    _isLoading = true;
                  });
                  await _consultationService.cancelAppointment(appointment.id);
                  // Recharger les données
                  await _loadData();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Rendez-vous annulé avec succès'),
                        backgroundColor: AppTheme.successColor,
                      ),
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
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorColor,
              ),
              child: const Text('Oui, annuler'),
            ),
          ],
        );
      },
    );
  }
}