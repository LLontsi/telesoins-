import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:telesoins_plus/config/theme.dart';
import 'package:telesoins_plus/models/appointment.dart';
import 'package:telesoins_plus/services/auth_service.dart';
import 'package:telesoins_plus/services/consultation_service.dart';
import 'package:telesoins_plus/widgets/common/app_bar.dart';
import 'package:telesoins_plus/widgets/common/nav_drawer.dart';
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
  List<Appointment> _todayAppointments = [];
  int _totalPatients = 0;
  int _pendingAppointments = 0;
  int _selectedIndex = 0; // Pour la navigation en bas

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
      // Charger les rendez-vous d'aujourd'hui
      final appointments = await _consultationService.getAppointments();
      final now = DateTime.now();
      
      // Filtrer les rendez-vous pour aujourd'hui
      _todayAppointments = appointments
          .where((appointment) =>
              appointment.dateTime.year == now.year &&
              appointment.dateTime.month == now.month &&
              appointment.dateTime.day == now.day)
          .toList();
      
      // Trier par heure
      _todayAppointments.sort((a, b) => a.dateTime.compareTo(b.dateTime));
      
      // Compter les patients uniques (simulation)
      _totalPatients = 45; // À remplacer par une requête API réelle
      
      // Compter les rendez-vous en attente
      _pendingAppointments = appointments
          .where((appointment) => appointment.status == AppointmentStatus.pending)
          .length;
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

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    
    // Navigation basée sur l'index sélectionné
    switch (index) {
      case 0: // Accueil - déjà sur cette page
        break;
      case 1: // Patients
        Navigator.pushNamed(context, '/medecin/patients');
        break;
      case 2: // Consultations
        Navigator.pushNamed(context, '/medecin/appointments');
        break;
      case 3: // Messages
        Navigator.pushNamed(context, '/medecin/messaging');
        break;
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
      title: Row(
        children: [
         /* Image.asset(
            'assets/images/logo.png', 
            height: 30,
          ),*/
          const SizedBox(width: 8),
          const Text(
            'TéléSoins+',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
              fontSize: 22,
            ),
          ),
        ],
      ),
      backgroundColor: Colors.white,
      elevation: 2,
      automaticallyImplyLeading: false,
      iconTheme: const IconThemeData(color: AppTheme.primaryColor),
      actions: [
        // Icône de notification
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () {
                Navigator.pushNamed(
                  context, 
                  '/notifications',
                  arguments: {'userType': 'medecin'}
                );
              },
            ),
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
                  '3',
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
        // Icône de profil
        Container(
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.primaryColor, width: 2),
          ),
          child: CircleAvatar(
            radius: 18,
            backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
            child: IconButton(
              icon: const Icon(
                Icons.person_outline, 
                size: 20,
                color: AppTheme.primaryColor,
              ),
              onPressed: () {
                Navigator.pushNamed(context, '/profile');
              },
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
                : _errorMessage != null
                    ? ErrorDisplay(
                        message: 'Impossible de charger les données',
                        details: _errorMessage,
                        onRetry: _loadData,
                        isFullScreen: true,
                      )
                    : SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // En-tête avec salutation et statut
                            Container(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppTheme.primaryColor.withOpacity(0.05),
                                    Colors.white,
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '$greeting, Dr. ${user?.lastName ?? ""}',
                                              style: const TextStyle(
                                                fontSize: 24,
                                                fontWeight: FontWeight.bold,
                                                color: AppTheme.primaryColor,
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
                                      // Statut de disponibilité
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: AppTheme.successColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(
                                            color: AppTheme.successColor,
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 10,
                                              height: 10,
                                              decoration: const BoxDecoration(
                                                color: AppTheme.successColor,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            const Text(
                                              'Disponible',
                                              style: TextStyle(
                                                color: AppTheme.successColor,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Switch(
                                              value: true,
                                              onChanged: (value) {
                                                // TODO: Mettre à jour le statut
                                              },
                                              activeColor: AppTheme.successColor,
                                              activeTrackColor: AppTheme.successColor.withOpacity(0.3),
                                              
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            
                            // Statistiques avec style amélioré
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: _buildStatisticsRow(),
                            ),
                            
                            const SizedBox(height: 24),
                            
                            // Rendez-vous du jour avec style amélioré
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_today,
                                        color: AppTheme.primaryColor,
                                        size: 20,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Consultations du jour',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  TextButton.icon(
                                    onPressed: () {
                                      Navigator.pushNamed(context, '/medecin/appointments');
                                    },
                                    icon: const Icon(Icons.arrow_forward, size: 16),
                                    label: const Text('Voir tout'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: AppTheme.primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 8),
                            
                            // Liste des rendez-vous
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: _todayAppointments.isEmpty
                                  ? Card(
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        side: BorderSide(
                                          color: Colors.grey.withOpacity(0.2),
                                        ),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          children: [
                                            Icon(
                                              Icons.event_available,
                                              size: 48,
                                              color: Colors.grey.withOpacity(0.5),
                                            ),
                                            const SizedBox(height: 12),
                                            const Text(
                                              'Aucune consultation programmée aujourd\'hui',
                                              style: TextStyle(
                                                color: AppTheme.textSecondaryColor,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                            const SizedBox(height: 8),
                                            OutlinedButton(
                                              onPressed: () {
                                                Navigator.pushNamed(context, '/medecin/new_consultation');
                                              },
                                              child: const Text('Programmer une consultation'),
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: AppTheme.primaryColor,
                                                side: const BorderSide(color: AppTheme.primaryColor),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                  : Column(
                                      children: _todayAppointments
                                          .map((appointment) => AppointmentCard(
                                                appointment: appointment,
                                                isPatientView: false,
                                                onTap: () {
                                                  Navigator.pushNamed(
                                                    context,
                                                    '/medecin/appointment_details',
                                                    arguments: appointment.id,
                                                  );
                                                },
                                              ))
                                          .toList(),
                                    ),
                            ),
                            
                            const SizedBox(height: 24),
                            
                            // Accès rapides avec style amélioré
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.flash_on,
                                    color: AppTheme.primaryColor,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Accès rapides',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Grille d'accès rapide améliorée
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: _buildQuickAccessGrid(),
                            ),
                            
                            // Espace pour le bas de l'écran
                            const SizedBox(height: 80),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    ),
    bottomNavigationBar: BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      elevation: 8,
      selectedFontSize: 12,
      unselectedFontSize: 12,
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Accueil',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.people_outline),
          activeIcon: Icon(Icons.people),
          label: 'Patients',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today_outlined),
          activeIcon: Icon(Icons.calendar_today),
          label: 'RDV',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.message_outlined),
          activeIcon: Icon(Icons.message),
          label: 'Messages',
        ),
      ],
      currentIndex: _selectedIndex,
      selectedItemColor: AppTheme.primaryColor,
      unselectedItemColor: Colors.grey,
      onTap: _onItemTapped,
    ),
    floatingActionButton: FloatingActionButton(
      onPressed: () {
        Navigator.pushNamed(context, '/medecin/new_consultation');
      },
      backgroundColor: AppTheme.primaryColor,
      child: const Icon(Icons.add),
      elevation: 4,
    ),
  );
}

Widget _buildStatisticsRow() {
  return Container(
    margin: const EdgeInsets.only(top: 16),
    child: Row(
      children: [
        Expanded(
          child: _buildStatisticCard(
            title: 'Patients',
            value: _totalPatients.toString(),
            icon: Icons.people,
            color: AppTheme.medicalBlue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatisticCard(
            title: 'En attente',
            value: _pendingAppointments.toString(),
            icon: Icons.pending_actions,
            color: AppTheme.warningColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatisticCard(
            title: 'Aujourd\'hui',
            value: _todayAppointments.length.toString(),
            icon: Icons.today,
            color: AppTheme.primaryColor,
          ),
        ),
      ],
    ),
  );
}

Widget _buildStatisticCard({
  required String title,
  required String value,
  required IconData icon,
  required Color color,
}) {
  return Card(
    elevation: 1,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.1),
            Colors.white,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 22,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Flexible(
            child: Text(
              title,
              style: const TextStyle(
                color: AppTheme.textSecondaryColor,
                fontSize: 12,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildQuickAccessGrid() {
  final quickAccess = [
    {
      'title': 'Mes patients',
      'icon': Icons.people,
      'route': '/medecin/patients',
      'color': AppTheme.medicalBlue,
    },
    {
      'title': 'RDV en attente',
      'icon': Icons.pending_actions,
      'route': '/medecin/pending_appointments',
      'color': AppTheme.warningColor,
    },
    {
      'title': 'Rédiger une ordonnance',
      'icon': Icons.receipt,
      'route': '/medecin/new_prescription',
      'color': AppTheme.primaryColor,
    },
    {
      'title': 'Messages',
      'icon': Icons.message,
      'route': '/medecin/messaging',
      'color': AppTheme.medicalGreen,
    },
  ];

  return GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.3,
    ),
    itemCount: quickAccess.length,
    itemBuilder: (context, index) {
      final item = quickAccess[index];
      final color = item['color'] as Color;
      
      return Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: () {
            Navigator.pushNamed(context, item['route'] as String);
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withOpacity(0.1),
                  Colors.white,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    item['icon'] as IconData,
                    size: 24,
                    color: color,
                  ),
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: Text(
                    item['title'] as String,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
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
    if (hour < 12) {
      return 'Bonjour';
    } else if (hour < 18) {
      return 'Bon après-midi';
    } else {
      return 'Bonsoir';
    }
  }
}