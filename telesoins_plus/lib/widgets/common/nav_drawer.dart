import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:telesoins_plus/config/theme.dart';
import 'package:telesoins_plus/services/auth_service.dart';

class NavDrawer extends StatelessWidget {
  final String activeRoute;

  const NavDrawer({
    Key? key,
    required this.activeRoute,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;
    final isPatient = authService.isPatient;
    final isMedecin = authService.isMedecin;

    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: AppTheme.primaryColor),
            accountName: Text(
              user?.fullName ?? '',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            accountEmail: Text(
              user?.email ?? '',
              style: const TextStyle(fontSize: 14),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              backgroundImage: user?.profilePhotoUrl != null
                  ? NetworkImage(user!.profilePhotoUrl!)
                  : null,
              child: user?.profilePhotoUrl == null
                  ? Text(
                      _getInitials(user?.fullName ?? ''),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    )
                  : null,
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // Accueil
                _buildNavItem(
                  context,
                  icon: Icons.home,
                  title: 'Accueil',
                  route: isPatient
                      ? '/patient/home'
                      : isMedecin
                          ? '/medecin/home'
                          : '/',
                  activeRoute: activeRoute,
                ),

                // Rendez-vous
                _buildNavItem(
                  context,
                  icon: Icons.calendar_today,
                  title: 'Rendez-vous',
                  route: isPatient
                      ? '/patient/appointments'
                      : isMedecin
                          ? '/medecin/appointments'
                          : '/appointments',
                  activeRoute: activeRoute,
                ),

                // Items spécifiques aux patients
                if (isPatient) ...[
                  _buildNavItem(
                    context,
                    icon: Icons.medical_services,
                    title: 'Prescriptions',
                    route: '/patient/prescriptions',
                    activeRoute: activeRoute,
                  ),
                  _buildNavItem(
                    context,
                    icon: Icons.message,
                    title: 'Messages',
                    route: '/patient/messaging',
                    activeRoute: activeRoute,
                  ),
                  _buildNavItem(
                    context,
                    icon: Icons.healing,
                    title: 'Premiers Secours',
                    route: '/patient/first_aid',
                    activeRoute: activeRoute,
                  ),
                ],

                // Items spécifiques aux médecins
                if (isMedecin) ...[
                  _buildNavItem(
                    context,
                    icon: Icons.people,
                    title: 'Mes Patients',
                    route: '/medecin/patients',
                    activeRoute: activeRoute,
                  ),
                  _buildNavItem(
                    context,
                    icon: Icons.description,
                    title: 'Prescriptions',
                    route: '/medecin/prescriptions',
                    activeRoute: activeRoute,
                  ),
                ],

                // Profil utilisateur
                _buildNavItem(
                  context,
                  icon: Icons.person,
                  title: 'Profil',
                  route: '/profile',
                  activeRoute: activeRoute,
                ),

                const Divider(),

                // Paramètres
                _buildNavItem(
                  context,
                  icon: Icons.settings,
                  title: 'Paramètres',
                  route: '/settings',
                  activeRoute: activeRoute,
                ),

                // À propos
                _buildNavItem(
                  context,
                  icon: Icons.info,
                  title: 'À propos',
                  route: '/about',
                  activeRoute: activeRoute,
                ),

                // Déconnexion
                ListTile(
                  leading: const Icon(Icons.exit_to_app, color: AppTheme.errorColor),
                  title: const Text(
                    'Déconnexion',
                    style: TextStyle(color: AppTheme.errorColor),
                  ),
                  onTap: () => _confirmLogout(context, authService),
                ),
              ],
            ),
          ),
          // Version de l'application
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: const Text(
              'TéléSoins+ v1.0.0',
              style: TextStyle(
                color: AppTheme.textSecondaryColor,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String route,
    required String activeRoute,
  }) {
    final isActive = activeRoute == route;

    return ListTile(
      leading: Icon(
        icon,
        color: isActive ? AppTheme.primaryColor : AppTheme.textPrimaryColor,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isActive ? AppTheme.primaryColor : AppTheme.textPrimaryColor,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isActive,
      selectedTileColor: isActive ? AppTheme.primaryColor.withOpacity(0.1) : null,
      onTap: () {
        Navigator.pop(context); // Fermer le drawer
        if (activeRoute != route) {
          Navigator.pushReplacementNamed(context, route);
        }
      },
    );
  }

  Future<void> _confirmLogout(BuildContext context, AuthService authService) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Déconnexion'),
          content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
          actions: [
            TextButton(
              child: const Text('Annuler'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorColor,
              ),
              child: const Text('Déconnexion'),
              onPressed: () async {
                Navigator.of(context).pop();
                await authService.logout();
                if (context.mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                }
              },
            ),
          ],
        );
      },
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