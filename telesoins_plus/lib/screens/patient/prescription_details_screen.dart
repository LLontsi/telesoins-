import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:telesoins_plus/config/theme.dart';
import 'package:telesoins_plus/models/prescription.dart';
import 'package:telesoins_plus/services/consultation_service.dart';
import 'package:telesoins_plus/widgets/common/app_bar.dart';
import 'package:telesoins_plus/widgets/common/loading_indicator.dart';
import 'package:telesoins_plus/widgets/common/error_display.dart';

class PrescriptionDetailsScreen extends StatefulWidget {
  final int prescriptionId;

  const PrescriptionDetailsScreen({
    Key? key,
    required this.prescriptionId,
  }) : super(key: key);

  @override
  State<PrescriptionDetailsScreen> createState() => _PrescriptionDetailsScreenState();
}

class _PrescriptionDetailsScreenState extends State<PrescriptionDetailsScreen> {
  final ConsultationService _consultationService = ConsultationService();
  bool _isLoading = true;
  String? _errorMessage;
  late Prescription _prescription;

  @override
  void initState() {
    super.initState();
    _loadPrescriptionDetails();
  }

  Future<void> _loadPrescriptionDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prescription = await _consultationService.getPrescriptionDetails(widget.prescriptionId);
      setState(() {
        _prescription = prescription;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Impossible de charger les détails de l\'ordonnance: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _downloadPrescription() async {
    // Implémenter le téléchargement du PDF
    // API: GET /api/prescriptions/{prescriptionId}/download/
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('L\'ordonnance a été téléchargée'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _sharePrescription() async {
    final String shareText = 'Ordonnance du Dr. ${_prescription.medecin.lastName} du '
        '${DateFormat.yMMMMd('fr').format(_prescription.issueDate)}';
    
    await Share.share(shareText, subject: 'Mon ordonnance TéléSoins+');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Détails de l\'ordonnance',
        type: AppBarType.patient,
      ),
      body: _isLoading
          ? const LoadingIndicator()
          : _errorMessage != null
              ? ErrorDisplay(
                  message: 'Erreur',
                  details: _errorMessage,
                  onRetry: _loadPrescriptionDetails,
                )
              : _buildPrescriptionDetails(),
      bottomNavigationBar: _isLoading || _errorMessage != null
          ? null
          : BottomAppBar(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (_prescription.pdfUrl != null)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _downloadPrescription,
                        icon: const Icon(Icons.download),
                        label: const Text('Télécharger'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _sharePrescription,
                      icon: const Icon(Icons.share),
                      label: const Text('Partager'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildPrescriptionDetails() {
    final dateFormat = DateFormat.yMMMMd('fr');
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec informations de base
          _buildHeaderCard(),
          
          const SizedBox(height: 24),
          
          // Informations du médecin
          _buildDoctorInfo(),
          
          const SizedBox(height: 24),
          
          // Informations du patient
          _buildPatientInfo(),
          
          const SizedBox(height: 24),
          
          // Diagnostic
          if (_prescription.diagnosis != null) ...[
            _buildSectionTitle('Diagnostic'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  _prescription.diagnosis!,
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
          
          // Liste des médicaments
          _buildSectionTitle('Médicaments prescrits'),
          _buildMedicationsList(),
          
          const SizedBox(height: 24),
          
          // Instructions supplémentaires
          if (_prescription.additionalInstructions != null) ...[
            _buildSectionTitle('Instructions complémentaires'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  _prescription.additionalInstructions!,
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
          
          // Statut d'exécution
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    _prescription.isFilled ? Icons.check_circle : Icons.pending_actions,
                    color: _prescription.isFilled ? Colors.green : Colors.orange,
                    size: 24,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      _prescription.isFilled 
                          ? 'Cette ordonnance a été exécutée en pharmacie'
                          : 'Cette ordonnance n\'a pas encore été exécutée en pharmacie',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _prescription.isFilled ? Colors.green : Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Avertissement de validité
          if (_prescription.isExpired)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Cette ordonnance est expirée depuis le ${dateFormat.format(_prescription.expiryDate)}',
                      style: const TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildHeaderCard() {
    final dateFormat = DateFormat.yMMMMd('fr');
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Ordonnance médicale',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _prescription.isExpired ? Colors.grey : AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _prescription.isExpired ? 'Expirée' : 'Active',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              Icons.calendar_today,
              'Délivrée le',
              dateFormat.format(_prescription.issueDate),
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.timelapse,
              'Valable jusqu\'au',
              dateFormat.format(_prescription.expiryDate),
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.numbers,
              'Référence',
              'ORD-${_prescription.id}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Médecin prescripteur',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Dr. ${_prescription.medecin.firstName} ${_prescription.medecin.lastName}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            if (_prescription.medecin.speciality != null)
              Text(
                _prescription.medecin.speciality!,
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
            const SizedBox(height: 8),
            if (_prescription.medecin.licenseNumber != null)
              Text(
                'Numéro RPPS: ${_prescription.medecin.licenseNumber}',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Patient',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${_prescription.patient.firstName} ${_prescription.patient.lastName}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            if (_prescription.patient.dateOfBirth != null)
              Text(
                'Né(e) le ${DateFormat.yMMMMd('fr').format(_prescription.patient.dateOfBirth!)}',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicationsList() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _prescription.medications.map((medication) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.medication,
                      color: AppTheme.primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            medication.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Dosage: ${medication.dosage}',
                            style: const TextStyle(
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Fréquence: ${medication.frequency}',
                            style: const TextStyle(
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Durée: ${medication.durationDays} jour${medication.durationDays > 1 ? 's' : ''}',
                            style: const TextStyle(
                              fontSize: 14,
                            ),
                          ),
                          if (medication.specialInstructions != null) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                medication.specialInstructions!,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                if (_prescription.medications.last != medication)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Divider(
                      color: Colors.grey.withOpacity(0.3),
                    ),
                  ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: AppTheme.textSecondaryColor,
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            color: AppTheme.textSecondaryColor,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}