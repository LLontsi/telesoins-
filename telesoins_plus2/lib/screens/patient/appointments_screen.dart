import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:telesoins_plus2/config/api_constants.dart';
import 'package:telesoins_plus2/config/theme.dart';
import 'package:telesoins_plus2/main.dart';
import 'package:telesoins_plus2/models/appointment.dart';
import 'package:telesoins_plus2/services/api_service.dart';
import 'package:telesoins_plus2/widgets/appointment_card.dart';
import 'package:telesoins_plus2/widgets/common/loading_indicator.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({Key? key}) : super(key: key);

  @override
  _AppointmentsScreenState createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> with SingleTickerProviderStateMixin {
  final ApiService _apiService = getIt<ApiService>();
  bool _isLoading = true;
  
  late TabController _tabController;
  final List<String> _tabs = ['À venir', 'Passés', 'Tous'];
  
  List<Appointment> _appointments = [];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_handleTabChange);
    _loadAppointments();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      _loadAppointments();
    }
  }
  
  Future<void> _loadAppointments() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      String endpoint;
      switch (_tabController.index) {
        case 0:
          endpoint = ApiConstants.appointmentsUpcoming;
          break;
        case 1:
          // Simulons un point de terminaison pour les rendez-vous passés
          endpoint = '${ApiConstants.appointments}?status=completed';
          break;
        case 2:
        default:
          endpoint = ApiConstants.appointments;
          break;
      }
      
      final response = await _apiService.get(endpoint);
      
      if (mounted) {
        setState(() {
          _appointments = (response as List)
              .map((item) => Appointment.fromJson(item))
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
            content: Text('Erreur lors du chargement des rendez-vous: $e'),
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
        title: const Text('Mes rendez-vous'),
        bottom: TabBar(
          controller: _tabController,
          tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppTheme.primaryColor,
        ),
      ),
      body: _isLoading
          ? const LoadingIndicator()
          : TabBarView(
              controller: _tabController,
              children: [
                _buildAppointmentList(),
                _buildAppointmentList(),
                _buildAppointmentList(),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/patient/book-appointment'),
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }
  
  Widget _buildAppointmentList() {
    if (_appointments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun rendez-vous ${_tabController.index == 0 ? 'à venir' : _tabController.index == 1 ? 'passé' : ''}',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.push('/patient/book-appointment'),
              icon: const Icon(Icons.add),
              label: const Text('Prendre rendez-vous'),
            ),
          ],
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: _loadAppointments,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _appointments.length,
        itemBuilder: (context, index) {
          final appointment = _appointments[index];
          return AppointmentCard(
            appointment: appointment,
            onTap: () {
              // Navigation vers détails du rendez-vous
              if (appointment.status == 'completed') {
                // Si le rendez-vous est terminé, il y a probablement une consultation associée
                context.push('/patient/consultation/${appointment.id}');
              } else {
                // Si le rendez-vous n'est pas terminé, afficher ses détails
                // Nous n'avons pas encore créé cet écran
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Détails du rendez-vous (à implémenter)'),
                  ),
                );
              }
            },
          );
        },
      ),
    );
  }
}