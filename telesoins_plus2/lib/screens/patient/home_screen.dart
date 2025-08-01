import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:telesoins_plus2/config/theme.dart';
import 'package:telesoins_plus2/models/appointment.dart';
import 'package:telesoins_plus2/models/consultation.dart';
import 'package:telesoins_plus2/models/first_aid.dart';
import 'package:telesoins_plus2/services/api_service.dart';
import 'package:telesoins_plus2/services/auth_service.dart';
import 'package:telesoins_plus2/config/api_constants.dart';
import 'package:telesoins_plus2/main.dart';
import 'package:telesoins_plus2/widgets/common/loading_indicator.dart';
import 'package:telesoins_plus2/widgets/appointment_card.dart';
//import 'package:telesoins_plus2/widgets/appointment_card.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = getIt<ApiService>();
  bool _isLoading = true;
  
  List<Appointment> _upcomingAppointments = [];
  List<Prescription> _activePrescriptions = [];
  List<Message> _unreadMessages = [];
  List<ModuleProgress> _firstAidProgress = [];
  
  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }
  
  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final dashboardData = await _apiService.get(ApiConstants.patientDashboard);
      
      // Traiter les rendez-vous
      _upcomingAppointments = (dashboardData['upcoming_appointments'] as List)
          .map((item) => Appointment.fromJson(item))
          .toList();
      
      // Traiter les prescriptions
      _activePrescriptions = (dashboardData['active_prescriptions'] as List)
          .map((item) => Prescription.fromJson(item))
          .toList();
      
      // Charger les messages non lus séparément
      final messagesData = await _apiService.get(ApiConstants.unreadMessages);
      _unreadMessages = (messagesData as List)
          .map((item) => Message.fromJson(item))
          .toList();
      
      // Charger le progrès des premiers secours
      final progressData = await _apiService.get(ApiConstants.quizResultsSummary);
      _firstAidProgress = (progressData as List)
          .map((item) => ModuleProgress.fromJson(item))
          .toList();
      
    } catch (e) {
      print('Erreur lors du chargement des données du tableau de bord: $e');
      // Gérer l'erreur (afficher un message, etc.)
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
 @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final user = authService.currentUser;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('TéléSoins+'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // Ouvrir les notifications
            },
            tooltip: 'Notifications',
          ),
          IconButton(
            icon: CircleAvatar(
              radius: 14,
              backgroundImage: user?.profilePhotoUrl != null
                  ? NetworkImage(user!.profilePhotoUrl!)
                  : null,
              child: user?.profilePhotoUrl == null
                  ? Text(
                      user?.firstName.isNotEmpty == true
                          ? user!.firstName[0].toUpperCase()
                          : 'U',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    )
                  : null,
              backgroundColor: AppTheme.primaryColor,
            ),
            onPressed: () {
              context.push('/profile');
            },
            tooltip: 'Profil',
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingIndicator()
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // En-tête avec salutation
                    Text(
                      'Bonjour, ${user?.firstName ?? 'Patient'}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Comment allez-vous aujourd\'hui?',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Actions rapides
                    _buildQuickActions(),
                    const SizedBox(height: 24),
                    
                    // Section des rendez-vous à venir
                    _buildUpcomingAppointments(),
                    const SizedBox(height: 24),
                    
                    // Section des prescriptions actives
                    _buildActivePrescriptions(),
                    const SizedBox(height: 24),
                    
                    // Section des premiers secours
                    _buildFirstAidProgress(),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (index) {
          switch (index) {
            case 0:
              // Déjà sur la page d'accueil
              break;
            case 1:
              context.push('/patient/appointments');
              break;
            case 2:
              context.push('/patient/first-aid');
              break;
            case 3:
              context.push('/patient/prescriptions');
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

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Actions rapides',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.add_circle_outline,
                title: 'Nouveau\nrendez-vous',
                color: AppTheme.primaryColor,
                onTap: () => context.push('/patient/book-appointment'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                icon: Icons.chat_outlined,
                title: 'Messagerie\n${_unreadMessages.isNotEmpty ? "(${_unreadMessages.length})" : ""}',
                color: AppTheme.secondaryColor,
                onTap: () {
                  // Rediriger vers la messagerie
                  if (_unreadMessages.isNotEmpty) {
                    context.push('/patient/messaging/${_unreadMessages.first.consultationId}');
                  } else {
                    // Afficher un message ou rediriger vers une liste des conversations
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Aucun nouveau message"),
                      ),
                    );
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                icon: Icons.emergency_outlined,
                title: 'Urgence\nmédicale',
                color: AppTheme.dangerColor,
                onTap: () {
                  // Afficher un dialogue d'urgence
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Urgence médicale'),
                      content: const Text('En cas d\'urgence vitale, veuillez composer le 15 (SAMU) ou le 112 (numéro d\'urgence européen).'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Fermer'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            context.push('/patient/book-appointment?urgent=true');
                          },
                          child: const Text('Demander un RDV urgent'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: color,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingAppointments() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Rendez-vous à venir',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => context.push('/patient/appointments'),
              child: const Text('Voir tout'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _upcomingAppointments.isEmpty
            ? const Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(
                    child: Text(
                      'Aucun rendez-vous à venir',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _upcomingAppointments.length > 3
                    ? 3
                    : _upcomingAppointments.length,
                itemBuilder: (context, index) {
                  final appointment = _upcomingAppointments[index];
                  return AppointmentCard(
                    appointment: appointment,
                    onTap: () {
                      // Naviguer vers les détails du rendez-vous
                    },
                  );
                },
              ),
      ],
    );
  }

  Widget _buildActivePrescriptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Prescriptions actives',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => context.push('/patient/prescriptions'),
              child: const Text('Voir tout'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _activePrescriptions.isEmpty
            ? const Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(
                    child: Text(
                      'Aucune prescription active',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _activePrescriptions.length > 2
                    ? 2
                    : _activePrescriptions.length,
                itemBuilder: (context, index) {
                  final prescription = _activePrescriptions[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Prescription',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                DateFormat('dd/MM/yyyy').format(prescription.createdAt),
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            prescription.details,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (prescription.validUntil != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Valide jusqu\'au: ${DateFormat('dd/MM/yyyy').format(prescription.validUntil!)}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
      ],
    );
  }

  Widget _buildFirstAidProgress() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Premiers secours',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => context.push('/patient/first-aid'),
              child: const Text('Explorer'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _firstAidProgress.isEmpty
            ? const Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        'Apprenez les gestes qui sauvent',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Découvrez nos modules de formation aux premiers secours pour être prêt en cas d\'urgence.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _firstAidProgress.length > 2
                    ? 2
                    : _firstAidProgress.length,
                itemBuilder: (context, index) {
                  final progress = _firstAidProgress[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  progress.moduleTitle,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: progress.passed
                                      ? AppTheme.successColor
                                      : AppTheme.warningColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  progress.passed ? 'Réussi' : 'En cours',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          LinearProgressIndicator(
                            value: progress.score / 100.0,
                            backgroundColor: Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              progress.passed
                                  ? AppTheme.successColor
                                  : AppTheme.warningColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Score: ${progress.score}%',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ],
    );
  }
}