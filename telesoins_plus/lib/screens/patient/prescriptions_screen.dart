import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:telesoins_plus/config/theme.dart';
import 'package:telesoins_plus/models/prescription.dart';
import 'package:telesoins_plus/services/consultation_service.dart';
import 'package:telesoins_plus/widgets/common/app_bar.dart';
import 'package:telesoins_plus/widgets/common/nav_drawer.dart';
import 'package:telesoins_plus/widgets/common/loading_indicator.dart';
import 'package:telesoins_plus/widgets/common/error_display.dart';

class PrescriptionsScreen extends StatefulWidget {
  const PrescriptionsScreen({Key? key}) : super(key: key);

  @override
  State<PrescriptionsScreen> createState() => _PrescriptionsScreenState();
}

class _PrescriptionsScreenState extends State<PrescriptionsScreen> with SingleTickerProviderStateMixin {
  final ConsultationService _consultationService = ConsultationService();
  bool _isLoading = false;
  String? _errorMessage;
  List<Prescription> _prescriptions = [];
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPrescriptions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPrescriptions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prescriptions = await _consultationService.getPatientPrescriptions();
      setState(() {
        _prescriptions = prescriptions;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Impossible de charger les ordonnances: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Prescription> _getActivePrescriptions() {
    final now = DateTime.now();
    return _prescriptions
        .where((prescription) => !prescription.isExpired)
        .toList()
      ..sort((a, b) => b.issueDate.compareTo(a.issueDate));
  }

  List<Prescription> _getInactivePrescriptions() {
    return _prescriptions
        .where((prescription) => prescription.isExpired)
        .toList()
      ..sort((a, b) => b.issueDate.compareTo(a.issueDate));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Mes Ordonnances',
        type: AppBarType.patient,
      ),
      drawer: const NavDrawer(activeRoute: '/patient/prescriptions'),
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            labelColor: AppTheme.primaryColor,
            unselectedLabelColor: AppTheme.textSecondaryColor,
            indicatorColor: AppTheme.primaryColor,
            tabs: const [
              Tab(text: 'Actives'),
              Tab(text: 'Archivées'),
            ],
          ),
          Expanded(
            child: _isLoading
                ? const LoadingIndicator()
                : _errorMessage != null
                    ? ErrorDisplay(
                        message: 'Erreur de chargement',
                        details: _errorMessage,
                        onRetry: _loadPrescriptions,
                      )
                    : RefreshIndicator(
                        onRefresh: _loadPrescriptions,
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            // Onglet des ordonnances actives
                            _buildPrescriptionsList(
                              _getActivePrescriptions(),
                              emptyMessage: 'Aucune ordonnance active',
                            ),
                            // Onglet des ordonnances archivées
                            _buildPrescriptionsList(
                              _getInactivePrescriptions(),
                              emptyMessage: 'Aucune ordonnance archivée',
                            ),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrescriptionsList(List<Prescription> prescriptions, {required String emptyMessage}) {
    if (prescriptions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long,
              size: 64,
              color: AppTheme.textSecondaryColor.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondaryColor.withOpacity(0.8),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: prescriptions.length,
      itemBuilder: (context, index) {
        final prescription = prescriptions[index];
        return _buildPrescriptionCard(prescription);
      },
    );
  }

  Widget _buildPrescriptionCard(Prescription prescription) {
    final dateFormat = DateFormat.yMMMMd('fr');
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          // Naviguer vers les détails de l'ordonnance
          Navigator.pushNamed(
            context,
            '/patient/prescription_details',
            arguments: prescription.id,
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(
                color: prescription.isExpired 
                    ? AppTheme.textSecondaryColor.withOpacity(0.1)
                    : AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Dr. ${prescription.medecin.lastName} - ${prescription.medecin.speciality ?? 'Médecin'}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: prescription.isExpired
                            ? AppTheme.textSecondaryColor
                            : AppTheme.primaryColor,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: prescription.isExpired 
                          ? Colors.grey
                          : AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      prescription.isExpired ? 'Expirée' : 'Active',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: AppTheme.textSecondaryColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Délivrée le ${dateFormat.format(prescription.issueDate)}',
                        style: const TextStyle(
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.timelapse,
                        size: 16,
                        color: AppTheme.textSecondaryColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Valable jusqu\'au ${dateFormat.format(prescription.expiryDate)}',
                        style: const TextStyle(
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (prescription.diagnosis != null)
                    Text(
                      'Diagnostic: ${prescription.diagnosis}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  const SizedBox(height: 8),
                  const Text(
                    'Médicaments:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ...prescription.medications.take(3).map((medication) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.medication,
                            size: 16,
                            color: AppTheme.primaryColor,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${medication.name} - ${medication.dosage} - ${medication.frequency}',
                              style: const TextStyle(
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  if (prescription.medications.length > 3)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '+ ${prescription.medications.length - 3} autres médicaments',
                        style: const TextStyle(
                          color: AppTheme.textSecondaryColor,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (prescription.pdfUrl != null)
                        OutlinedButton.icon(
                          onPressed: () {
                            // TODO: Télécharger le PDF
                          },
                          icon: const Icon(Icons.download),
                          label: const Text('PDF'),
                        ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            '/patient/prescription_details',
                            arguments: prescription.id,
                          );
                        },
                        icon: const Icon(Icons.visibility),
                        label: const Text('Détails'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}