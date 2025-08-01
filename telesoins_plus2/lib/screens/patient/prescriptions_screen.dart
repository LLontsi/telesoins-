import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:telesoins_plus2/config/api_constants.dart';
import 'package:telesoins_plus2/config/theme.dart';
import 'package:telesoins_plus2/main.dart';
import 'package:telesoins_plus2/models/consultation.dart';
import 'package:telesoins_plus2/services/api_service.dart';
import 'package:telesoins_plus2/widgets/common/loading_indicator.dart';

class PrescriptionsScreen extends StatefulWidget {
  const PrescriptionsScreen({Key? key}) : super(key: key);

  @override
  _PrescriptionsScreenState createState() => _PrescriptionsScreenState();
}

class _PrescriptionsScreenState extends State<PrescriptionsScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = getIt<ApiService>();
  late TabController _tabController;
  final List<String> _tabs = ['Actives', 'Toutes'];
  
  bool _isLoading = true;
  List<Prescription> _prescriptions = [];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_handleTabChange);
    _loadPrescriptions();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      _loadPrescriptions();
    }
  }
  
  Future<void> _loadPrescriptions() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      String endpoint;
      switch (_tabController.index) {
        case 0:
          endpoint = ApiConstants.activePrescriptions;
          break;
        case 1:
        default:
          endpoint = ApiConstants.prescriptions;
          break;
      }
      
      final response = await _apiService.get(endpoint);
      
      if (mounted) {
        setState(() {
          _prescriptions = (response as List)
              .map((item) => Prescription.fromJson(item))
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
            content: Text('Erreur lors du chargement des prescriptions: $e'),
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
        title: const Text('Mes prescriptions'),
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
                _buildPrescriptionsList(),
                _buildPrescriptionsList(),
              ],
            ),
    );
  }
  
  Widget _buildPrescriptionsList() {
    if (_prescriptions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune prescription ${_tabController.index == 0 ? 'active' : ''}',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: _loadPrescriptions,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _prescriptions.length,
        itemBuilder: (context, index) {
          final prescription = _prescriptions[index];
          final bool isActive = prescription.validUntil == null || 
              prescription.validUntil!.isAfter(DateTime.now());
          
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
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
                          fontSize: 18,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppTheme.successColor.withOpacity(0.1)
                              : Colors.grey[200],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isActive ? 'Active' : 'Expirée',
                          style: TextStyle(
                            color: isActive
                                ? AppTheme.successColor
                                : Colors.grey[700],
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Date et validité
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Prescrite le ${DateFormat('dd/MM/yyyy').format(prescription.createdAt)}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      if (prescription.validUntil != null) ...[
                        const SizedBox(width: 16),
                        Icon(
                          Icons.access_time_outlined,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Valide jusqu\'au ${DateFormat('dd/MM/yyyy').format(prescription.validUntil!)}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const Divider(height: 24),
                  
                  // Contenu de la prescription
                  const Text(
                    'Détails:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    prescription.details,
                    style: const TextStyle(fontSize: 16),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Boutons d'action
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {
                          // Action pour imprimer ou partager la prescription
                        },
                        icon: const Icon(Icons.share_outlined),
                        label: const Text('Partager'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () {
                          // Action pour télécharger la prescription en PDF
                        },
                        icon: const Icon(Icons.download_outlined),
                        label: const Text('Télécharger'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.secondaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}