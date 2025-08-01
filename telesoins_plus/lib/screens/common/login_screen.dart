import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:telesoins_plus/config/theme.dart';
import 'package:telesoins_plus/services/auth_service.dart';
import 'package:telesoins_plus/utils/validators.dart';
import 'package:telesoins_plus/widgets/common/loading_indicator.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await Provider.of<AuthService>(context, listen: false).login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (context.mounted) {
        final authService = Provider.of<AuthService>(context, listen: false);
        
        // Rediriger selon le type d'utilisateur
        if (authService.isPatient) {
          Navigator.pushReplacementNamed(context, '/patient/home');
        } else if (authService.isMedecin) {
          Navigator.pushReplacementNamed(context, '/medecin/home');
        } else {
          Navigator.pushReplacementNamed(context, '/');
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Échec de la connexion: ${e.toString()}';
      });
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
    return Scaffold(
      body: _isLoading
          ? const LoadingIndicator(message: 'Connexion en cours...')
          : SingleChildScrollView(
              child: Container(
                height: MediaQuery.of(context).size.height,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AppTheme.primaryColor, Colors.white],
                    stops: [0.3, 1.0],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 40),
                        // Logo et titre
                        const Column(
                          children: [
                            Icon(
                              Icons.health_and_safety,
                              size: 80,
                              color: Colors.white,
                            ),
                            SizedBox(height: 14),
                            Text(
                              'TéléSoins+',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Télémédecine simplifiée pour zones rurales',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),
                        // Formulaire de connexion
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Text(
                                  'Connexion',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 20),
                                
                                // Message d'erreur
                                if (_errorMessage != null) ...[
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppTheme.errorColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      _errorMessage!,
                                      style: const TextStyle(
                                        color: AppTheme.errorColor,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],
                                
                                // Champ email
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: const InputDecoration(
                                    labelText: 'Adresse email',
                                    prefixIcon: Icon(Icons.email),
                                  ),
                                  validator: Validators.validateEmail,
                                ),
                                const SizedBox(height: 16),
                                
                                // Champ mot de passe
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  decoration: InputDecoration(
                                    labelText: 'Mot de passe',
                                    prefixIcon: const Icon(Icons.lock),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility
                                            : Icons.visibility_off,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                    ),
                                  ),
                                  validator: Validators.validatePassword,
                                ),
                                const SizedBox(height: 4),
                                
                                  // Réorganisation "Se souvenir de moi" et "Mot de passe oublié"
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end, // Aligner à droite
                                    children: [
                                      Checkbox(
                                        value: _rememberMe,
                                        onChanged: (value) {
                                          setState(() {
                                            _rememberMe = value ?? false;
                                          });
                                        },
                                        activeColor: AppTheme.primaryColor,
                                      ),
                                      const Text('Se souvenir de moi'),
                                    ],
                                  ),
                                  const SizedBox(height: 3), // Espace entre les deux éléments
                                  Align(
                                    alignment: Alignment.centerLeft, // Aligner à gauche
                                    child: TextButton(
                                      onPressed: () {
                                        // TODO: Implémentation de la récupération de mot de passe
                                      },
                                      child: const Text('Mot de passe oublié ?'),
                                    ),
                                  ),
                                const SizedBox(height: 12),
                                
                                // Bouton de connexion
                                ElevatedButton(
                                  onPressed: _login,
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  child: const Text('SE CONNECTER'),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Spacer(),
                        
                        // Bouton d'inscription
                        TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/signup');
                          },
                          child: RichText(
                            text: const TextSpan(
                              style: TextStyle(
                                color: AppTheme.textPrimaryColor,
                              ),
                              children: [
                                TextSpan(text: 'Pas encore de compte ? '),
                                TextSpan(
                                  text: 'S\'inscrire',
                                  style: TextStyle(
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}