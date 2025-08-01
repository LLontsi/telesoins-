import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:telesoins_plus/config/theme.dart';
import 'package:telesoins_plus/models/user.dart';
import 'package:telesoins_plus/services/auth_service.dart';
import 'package:telesoins_plus/widgets/common/app_bar.dart';
import 'package:telesoins_plus/widgets/common/nav_drawer.dart';
import 'package:telesoins_plus/widgets/common/loading_indicator.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  
  bool _isLoading = false;
  bool _isEditing = false;
  File? _profileImage;
  
  // Contrôleurs pour les champs de formulaire
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  
  // Champs spécifiques au patient
  final TextEditingController _allergiesController = TextEditingController();
  final TextEditingController _chronicConditionsController = TextEditingController();
  String? _bloodGroup;
  DateTime? _dateOfBirth;
  
  // Champs spécifiques au médecin
  final TextEditingController _specialityController = TextEditingController();
  final TextEditingController _licenseNumberController = TextEditingController();
  final TextEditingController _workingHoursController = TextEditingController();
  List<String> _workingDays = [];
  bool _isAvailableForEmergency = false;

  @override
  void initState() {
    super.initState();
    _initializeFormFields();
  }
  
  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _allergiesController.dispose();
    _chronicConditionsController.dispose();
    _specialityController.dispose();
    _licenseNumberController.dispose();
    _workingHoursController.dispose();
    super.dispose();
  }

  void _initializeFormFields() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;
    
    if (user != null) {
      _firstNameController.text = user.firstName;
      _lastNameController.text = user.lastName;
      _phoneController.text = user.phoneNumber;
      _emailController.text = user.email;
      _addressController.text = user.address ?? '';
      
      if (user is Patient) {
        _dateOfBirth = user.dateOfBirth;
        _bloodGroup = user.bloodGroup;
        _allergiesController.text = user.allergies?.join(', ') ?? '';
        _chronicConditionsController.text = user.chronicConditions?.join(', ') ?? '';
      } else if (user is Medecin) {
        _specialityController.text = user.speciality ?? '';
        _licenseNumberController.text = user.licenseNumber ?? '';
        _workingHoursController.text = user.workingHours ?? '';
        _workingDays = user.workingDays ?? [];
        _isAvailableForEmergency = user.isAvailableForEmergency;
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _profileImage = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la sélection de l\'image: ${e.toString()}'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  void _toggleEditMode() {
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.currentUser;
      
      if (user == null) return;
      
      // Préparer les données communes
      final Map<String, dynamic> userData = {
        'first_name': _firstNameController.text,
        'last_name': _lastNameController.text,
        'phone_number': _phoneController.text,
        'address': _addressController.text,
      };
      
      // Ajouter les données spécifiques au type d'utilisateur
      if (user is Patient) {
        userData['blood_group'] = _bloodGroup;
        userData['date_of_birth'] = _dateOfBirth?.toIso8601String();
        userData['allergies'] = _allergiesController.text.isEmpty 
            ? [] 
            : _allergiesController.text.split(',').map((e) => e.trim()).toList();
        userData['chronic_conditions'] = _chronicConditionsController.text.isEmpty 
            ? [] 
            : _chronicConditionsController.text.split(',').map((e) => e.trim()).toList();
      } else if (user is Medecin) {
        userData['speciality'] = _specialityController.text;
        userData['license_number'] = _licenseNumberController.text;
        userData['working_hours'] = _workingHoursController.text;
        userData['working_days'] = _workingDays;
        userData['is_available_for_emergency'] = _isAvailableForEmergency;
      }
      
      // Mettre à jour le profil
      await authService.updateUserProfile(userData);
      
      // Gérer l'image de profil si modifiée
      if (_profileImage != null) {
        // TODO: Implémenter le téléchargement de l'image
      }
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil mis à jour avec succès'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        setState(() {
          _isEditing = false;
        });
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
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;
    final isPatient = authService.isPatient;
    final isMedecin = authService.isMedecin;
    
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Mon Profil',
        type: isPatient ? AppBarType.patient : AppBarType.medecin,
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.close : Icons.edit),
            onPressed: _toggleEditMode,
          ),
        ],
      ),
      drawer: const NavDrawer(activeRoute: '/profile'),
      body: _isLoading
          ? const LoadingIndicator()
          : user == null
              ? const Center(
                  child: Text('Utilisateur non connecté'),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Photo de profil
                        Center(
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 60,
                                backgroundColor: AppTheme.primaryColor,
                                backgroundImage: _profileImage != null
                                  ? FileImage(_profileImage!) as ImageProvider<Object>
                                  : (user.profilePhotoUrl != null
                                      ? NetworkImage(user.profilePhotoUrl!) as ImageProvider<Object>
                                      : null),

                                child: _profileImage == null && user.profilePhotoUrl == null
                                    ? Text(
                                        _getInitials('${user.firstName} ${user.lastName}'),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 36,
                                        ),
                                      )
                                    : null,
                              ),
                              if (_isEditing)
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryColor,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                    padding: const EdgeInsets.all(8),
                                    child: GestureDetector(
                                      onTap: _pickImage,
                                      child: const Icon(
                                        Icons.camera_alt,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Nom d'utilisateur
                        Center(
                          child: Text(
                            '${user.firstName} ${user.lastName}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Center(
                          child: Text(
                            isPatient ? 'Patient' : isMedecin ? 'Médecin' : 'Utilisateur',
                            style: TextStyle(
                              fontSize: 16,
                              color: isPatient 
                                  ? AppTheme.primaryColor 
                                  : AppTheme.medicalBlue,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Informations personnelles
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Informations personnelles',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                const Divider(),
                                _buildTextField(
                                  label: 'Prénom',
                                  controller: _firstNameController,
                                  enabled: _isEditing,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Veuillez entrer votre prénom';
                                    }
                                    return null;
                                  },
                                ),
                                _buildTextField(
                                  label: 'Nom',
                                  controller: _lastNameController,
                                  enabled: _isEditing,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Veuillez entrer votre nom';
                                    }
                                    return null;
                                  },
                                ),
                                _buildTextField(
                                  label: 'Email',
                                  controller: _emailController,
                                  enabled: false, // Email non modifiable
                                  keyboardType: TextInputType.emailAddress,
                                ),
                                _buildTextField(
                                  label: 'Téléphone',
                                  controller: _phoneController,
                                  enabled: _isEditing,
                                  keyboardType: TextInputType.phone,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Veuillez entrer votre numéro de téléphone';
                                    }
                                    return null;
                                  },
                                ),
                                _buildTextField(
                                  label: 'Adresse',
                                  controller: _addressController,
                                  enabled: _isEditing,
                                ),
                                
                                // Date de naissance (pour patients)
                                if (isPatient)
                                  _buildDateField(
                                    label: 'Date de naissance',
                                    value: _dateOfBirth,
                                    enabled: _isEditing,
                                    onSelect: (date) {
                                      setState(() {
                                        _dateOfBirth = date;
                                      });
                                    },
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Informations médicales (pour patients)
                        if (isPatient)
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Informations médicales',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  const Divider(),
                                  _buildDropdownField<String>(
                                    label: 'Groupe sanguin',
                                    value: _bloodGroup,
                                    items: const ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'],
                                    enabled: _isEditing,
                                    onChanged: (value) {
                                      setState(() {
                                        _bloodGroup = value;
                                      });
                                    },
                                  ),
                                  _buildTextField(
                                    label: 'Allergies (séparées par des virgules)',
                                    controller: _allergiesController,
                                    enabled: _isEditing,
                                  ),
                                  _buildTextField(
                                    label: 'Maladies chroniques (séparées par des virgules)',
                                    controller: _chronicConditionsController,
                                    enabled: _isEditing,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        
                        // Informations professionnelles (pour médecins)
                        if (isMedecin)
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Informations professionnelles',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  const Divider(),
                                  _buildTextField(
                                    label: 'Spécialité',
                                    controller: _specialityController,
                                    enabled: _isEditing,
                                  ),
                                  _buildTextField(
                                    label: 'Numéro de licence',
                                    controller: _licenseNumberController,
                                    enabled: _isEditing,
                                  ),
                                  _buildTextField(
                                    label: 'Horaires de travail',
                                    controller: _workingHoursController,
                                    enabled: _isEditing,
                                  ),
                                  if (_isEditing)
                                    _buildWorkingDaysSelector(),
                                  if (!_isEditing)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Jours de travail',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.textSecondaryColor,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _workingDays.isEmpty
                                                ? 'Non spécifié'
                                                : _workingDays.join(', '),
                                          ),
                                        ],
                                      ),
                                    ),
                                  SwitchListTile(
                                    title: const Text('Disponible pour urgences'),
                                    value: _isAvailableForEmergency,
                                    onChanged: _isEditing
                                        ? (value) {
                                            setState(() {
                                              _isAvailableForEmergency = value;
                                            });
                                          }
                                        : null,
                                    activeColor: AppTheme.medicalBlue,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        
                        const SizedBox(height: 24),
                        
                        // Boutons d'action
                        if (_isEditing)
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _toggleEditMode,
                                  child: const Text('Annuler'),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _saveProfile,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isPatient
                                        ? AppTheme.primaryColor
                                        : AppTheme.medicalBlue,
                                  ),
                                  child: const Text('Enregistrer'),
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 16),
                        
                        // Bouton de déconnexion
                        if (!_isEditing)
                          OutlinedButton.icon(
                            onPressed: () {
                              _showLogoutDialog();
                            },
                            icon: const Icon(Icons.exit_to_app, color: AppTheme.errorColor),
                            label: const Text('Déconnexion'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.errorColor,
                              side: const BorderSide(color: AppTheme.errorColor),
                              minimumSize: const Size(double.infinity, 48),
                            ),
                          ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    bool enabled = true,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: enabled ? const OutlineInputBorder() : InputBorder.none,
          filled: !enabled,
          fillColor: enabled ? null : Colors.grey.shade100,
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? value,
    required Function(DateTime) onSelect,
    bool enabled = true,
  }) {
    final dateFormat = DateFormat.yMMMMd('fr');
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: enabled
                ? () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: value ?? DateTime.now(),
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      onSelect(picked);
                    }
                  }
                : null,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                border: enabled
                    ? Border.all(color: Colors.grey)
                    : null,
                borderRadius: BorderRadius.circular(4),
                color: enabled ? Colors.transparent : Colors.grey.shade100,
              ),
              width: double.infinity,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    value != null
                        ? dateFormat.format(value)
                        : 'Non spécifiée',
                  ),
                  if (enabled)
                    const Icon(Icons.calendar_today),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField<T>({
    required String label,
    required T? value,
    required List<T> items,
    required Function(T?) onChanged,
    bool enabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: enabled
                  ? Border.all(color: Colors.grey)
                  : null,
              borderRadius: BorderRadius.circular(4),
              color: enabled ? Colors.transparent : Colors.grey.shade100,
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<T>(
                value: value,
                items: items.map((item) {
                  return DropdownMenuItem<T>(
                    value: item,
                    child: Text(item.toString()),
                  );
                }).toList(),
                onChanged: enabled ? onChanged : null,
                isExpanded: true,
                hint: const Text('Sélectionner'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkingDaysSelector() {
    final days = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Jours de travail',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: days.map((day) {
              final isSelected = _workingDays.contains(day);
              
              return FilterChip(
                label: Text(day),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _workingDays.add(day);
                    } else {
                      _workingDays.remove(day);
                    }
                  });
                },
                selectedColor: AppTheme.medicalBlue.withOpacity(0.2),
                checkmarkColor: AppTheme.medicalBlue,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() {
                _isLoading = true;
              });
              
              try {
                final authService = Provider.of<AuthService>(context, listen: false);
                await authService.logout();
                
                if (context.mounted) {
                  Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
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
            child: const Text('Déconnexion'),
          ),
        ],
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