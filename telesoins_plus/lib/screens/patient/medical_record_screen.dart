// Fichier: lib/screens/patient/medical_record_screen.dart

import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../services/api_service.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/error_display.dart';
import 'package:telesoins_plus/services/auth_service.dart';

class MedicalRecordScreen extends StatefulWidget {
  const MedicalRecordScreen({Key? key}) : super(key: key);

  @override
  _MedicalRecordScreenState createState() => _MedicalRecordScreenState();
}


class _MedicalRecordScreenState extends State<MedicalRecordScreen> with SingleTickerProviderStateMixin {
  
  bool _isLoading = true;
  String _errorMessage = '';
  late TabController _tabController;
  
  // Données fictives pour le test du frontend
  Map<String, dynamic> _patientData = {
    'nom': 'Dupont',
    'prenom': 'Marie',
    'dateNaissance': '15/03/1975',
    'groupeSanguin': 'A+',
    'allergies': ['Pénicilline', 'Arachides'],
    'antecedents': [
      {'type': 'Chirurgie', 'description': 'Appendicectomie', 'date': '2015-06-12'},
      {'type': 'Maladie', 'description': 'Hypertension', 'date': '2018-03-20'},
    ],
    'consultationsRecentes': [
      {'date': '2024-11-15', 'medecin': 'Dr. Bernard', 'motif': 'Consultation de routine'},
      {'date': '2025-01-20', 'medecin': 'Dr. Rousseau', 'motif': 'Douleurs lombaires'},
    ],
    'medicaments': [
      {'nom': 'Lisinopril', 'dosage': '10mg', 'frequence': '1 fois par jour', 'dateDebut': '2018-03-20', 'dateFin': 'En cours'},
      {'nom': 'Ibuprofène', 'dosage': '400mg', 'frequence': 'Si douleur', 'dateDebut': '2025-01-20', 'dateFin': '2025-02-20'},
    ],
    'analysesRecentes': [
      {'type': 'Glycémie', 'valeur': '5.2 mmol/L', 'date': '2024-12-10', 'statutNormal': true},
      {'type': 'Cholestérol', 'valeur': '5.8 mmol/L', 'date': '2024-12-10', 'statutNormal': false},
    ]
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    // Dans une application réelle, vous feriez l'appel API ici
    _fetchPatientData();
  }

  Future<void> _fetchPatientData() async {
    // Simulation d'un appel API
    await Future.delayed(const Duration(seconds: 1));
    
    setState(() {
      _isLoading = false;
      // Dans une implémentation réelle, vous utiliseriez:
      // try {
      //   final response = await ApiService().getPatientRecord(widget.patientId);
      //   _patientData = response;
      //   _isLoading = false;
      // } catch (e) {
      //   _errorMessage = 'Impossible de charger le dossier médical.';
      //   _isLoading = false;
      // }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Dossier Médical')),
        body: Center(
          child: Text(_errorMessage, style: const TextStyle(color: Colors.red)),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dossier Médical'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Résumé'),
            Tab(text: 'Antécédents'),
            Tab(text: 'Consultations'),
            Tab(text: 'Médicaments'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSummaryTab(),
          _buildMedicalHistoryTab(),
          _buildConsultationsTab(),
          _buildMedicationsTab(),
        ],
      ),
    );
  }

  Widget _buildSummaryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_patientData['prenom']} ${_patientData['nom']}',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text('Date de naissance: ${_patientData['dateNaissance']}'),
                  Text('Groupe sanguin: ${_patientData['groupeSanguin']}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Allergies', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Card(
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _patientData['allergies'].length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: const Icon(Icons.warning, color: Colors.red),
                  title: Text(_patientData['allergies'][index]),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          const Text('Analyses Récentes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Card(
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _patientData['analysesRecentes'].length,
              itemBuilder: (context, index) {
                final analyse = _patientData['analysesRecentes'][index];
                return ListTile(
                  title: Text(analyse['type']),
                  subtitle: Text('${analyse['valeur']} (${analyse['date']})'),
                  trailing: Icon(
                    analyse['statutNormal'] ? Icons.check_circle : Icons.warning,
                    color: analyse['statutNormal'] ? Colors.green : Colors.orange,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicalHistoryTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _patientData['antecedents'].length,
      itemBuilder: (context, index) {
        final antecedent = _patientData['antecedents'][index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8.0),
          child: ListTile(
            title: Text(antecedent['description']),
            subtitle: Text('${antecedent['type']} - ${antecedent['date']}'),
          ),
        );
      },
    );
  }

  Widget _buildConsultationsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _patientData['consultationsRecentes'].length,
      itemBuilder: (context, index) {
        final consultation = _patientData['consultationsRecentes'][index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8.0),
          child: ListTile(
            title: Text(consultation['motif']),
            subtitle: Text('${consultation['date']} - ${consultation['medecin']}'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              // Navigation vers les détails de la consultation
              // API: GET /api/consultations/{consultationId}/
            },
          ),
        );
      },
    );
  }

  Widget _buildMedicationsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _patientData['medicaments'].length,
      itemBuilder: (context, index) {
        final medicament = _patientData['medicaments'][index];
        final enCours = medicament['dateFin'] == 'En cours';
        
        return Card(
          margin: const EdgeInsets.only(bottom: 8.0),
          child: ListTile(
            title: Text(medicament['nom']),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Dosage: ${medicament['dosage']}'),
                Text('Fréquence: ${medicament['frequence']}'),
                Text('Période: ${medicament['dateDebut']} - ${medicament['dateFin']}'),
              ],
            ),
            isThreeLine: true,
            leading: Icon(
              Icons.medication,
              color: enCours ? Colors.green : Colors.grey,
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}