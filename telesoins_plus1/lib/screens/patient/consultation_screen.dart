import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:telesoins_plus/config/api_constants.dart';
import 'package:telesoins_plus/config/theme.dart';
import 'package:telesoins_plus/main.dart';
import 'package:telesoins_plus/models/consultation.dart';
import 'package:telesoins_plus/services/api_service.dart';
import 'package:telesoins_plus/widgets/common/loading_indicator.dart';

class ConsultationScreen extends StatefulWidget {
  final String consultationId;

  const ConsultationScreen({
    Key? key,
    required this.consultationId,
  }) : super(key: key);

  @override
  _ConsultationScreenState createState() => _ConsultationScreenState();
}

class _ConsultationScreenState extends State<ConsultationScreen> {
  final ApiService _apiService = getIt<ApiService>();
  bool _isLoading = true;
  Consultation? _consultation;

  @override
  void initState() {
    super.initState();
    _loadConsultation();
  }

  Future<void> _loadConsultation() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _apiService.get(
        '${ApiConstants.consultations}${widget.consultationId}/',
      );

      if (mounted) {
        setState(() {
          _consultation = Consultation.fromJson(response);
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
            content: Text('Erreur lors du chargement de la consultation: $e'),
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
        title: const Text('Détails de la consultation'),
      ),
      body: _isLoading
          ? const LoadingIndicator()
          : _consultation == null
              ? const Center(
                  child: Text('Consultation non trouvée'),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildConsultationHeader(),
                      const SizedBox(height: 24),
                      _buildSummarySection(),
                      const SizedBox(height: 24),
                      _buildPrescriptionsSection(),
                      const SizedBox(height: 24),
                      _buildMessagesSection(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildConsultationHeader() {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.medical_services, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Consultation ${_consultation!.typeDisplay}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Infos médecin
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppTheme.secondaryColor,
                  backgroundImage: _consultation!.medecin.profilePhotoUrl != null
                      ? NetworkImage(_consultation!.medecin.profilePhotoUrl!)
                      : null,
                  child: _consultation!.medecin.profilePhotoUrl == null
                      ? Text(
                          _consultation!.medecin.firstName.isNotEmpty
                              ? _consultation!.medecin.firstName[0].toUpperCase()
                              : 'M',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dr. ${_consultation!.medecin.lastName} ${_consultation!.medecin.firstName}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        DateFormat('dd MMMM yyyy à HH:mm', 'fr_FR')
                            .format(_consultation!.startTime),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _consultation!.endTime != null
                        ? AppTheme.successColor.withOpacity(0.1)
                        : AppTheme.warningColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _consultation!.endTime != null
                          ? AppTheme.successColor
                          : AppTheme.warningColor,
                    ),
                  ),
                  child: Text(
                    _consultation!.endTime != null ? 'Terminée' : 'En cours',
                    style: TextStyle(
                      color: _consultation!.endTime != null
                          ? AppTheme.successColor
                          : AppTheme.warningColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            if (_consultation!.endTime != null) ...[
              const SizedBox(height: 8),
              Text(
                'Terminée le ${DateFormat('dd MMMM yyyy à HH:mm', 'fr_FR').format(_consultation!.endTime!)}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummarySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Résumé et diagnostic',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_consultation!.summary != null &&
                    _consultation!.summary!.isNotEmpty) ...[
                  const Text(
                    'Résumé:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(_consultation!.summary!),
                  const SizedBox(height: 16),
                ],
                if (_consultation!.diagnosis != null &&
                    _consultation!.diagnosis!.isNotEmpty) ...[
                  const Text(
                    'Diagnostic:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(_consultation!.diagnosis!),
                ],
                if ((_consultation!.summary == null ||
                        _consultation!.summary!.isEmpty) &&
                    (_consultation!.diagnosis == null ||
                        _consultation!.diagnosis!.isEmpty))
                  const Text(
                    'Aucun résumé ou diagnostic disponible pour cette consultation.',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Colors.grey,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrescriptionsSection() {
    final prescriptions = _consultation!.prescriptions ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Prescriptions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (prescriptions.isNotEmpty)
              TextButton(
                onPressed: () => context.push('/patient/prescriptions'),
                child: const Text('Voir toutes'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        prescriptions.isEmpty
            ? Card(
                margin: EdgeInsets.zero,
                child: const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(
                    child: Text(
                      'Aucune prescription pour cette consultation.',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: prescriptions.length,
                itemBuilder: (context, index) {
                  final prescription = prescriptions[index];
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
                                DateFormat('dd/MM/yyyy')
                                    .format(prescription.createdAt),
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(prescription.details),
                          if (prescription.validUntil != null) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.calendar_today_outlined,
                                    size: 16, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(
                                  'Valide jusqu\'au: ${DateFormat('dd/MM/yyyy').format(prescription.validUntil!)}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
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

  Widget _buildMessagesSection() {
    final messages = _consultation!.messages ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Messages',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => context.push(
                  '/patient/messaging/${_consultation!.id}'),
              icon: const Icon(Icons.chat_outlined),
              label: const Text('Messagerie'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.secondaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        messages.isEmpty
            ? Card(
                margin: EdgeInsets.zero,
                child: const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(
                    child: Text(
                      'Aucun message pour cette consultation.',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
              )
            : Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Derniers messages:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: messages.length > 3 ? 3 : messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          return Container(
                            padding: const EdgeInsets.all(8),
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: message.sender.role == 'medecin'
                                  ? Colors.grey[100]
                                  : AppTheme.primaryLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      message.sender.fullName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      DateFormat('dd/MM HH:mm')
                                          .format(message.timestamp),
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(message.content),
                              ],
                            ),
                          );
                        },
                      ),
                      Center(
                        child: TextButton(
                          onPressed: () => context.push(
                              '/patient/messaging/${_consultation!.id}'),
                          child: const Text('Voir tous les messages'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ],
    );
  }
}