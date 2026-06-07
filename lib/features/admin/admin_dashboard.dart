import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:imobareld/features/admin/admin_controller.dart';
import 'package:imobareld/features/auth/auth_controller.dart';
import 'package:imobareld/models/user_model.dart';
import 'package:imobareld/features/admin/views/admin_stats_view.dart';
import 'package:imobareld/features/admin/views/admin_users_view.dart';
import 'package:imobareld/features/admin/views/admin_content_view.dart';
import 'package:imobareld/features/admin/views/admin_verifications_view.dart';
import 'package:imobareld/features/admin/views/admin_ads_view.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _currentIndex = 0;

  final List<Widget> _views = [
    const AdminStatsView(),
    const AdminUsersView(),
    const AdminContentView(),
    const AdminVerificationsView(),
    const AdminAdsView(),
  ];

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthController>(context).currentUser;
    final theme = Theme.of(context);
    
    if (user == null || !user.isAdmin) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: const Center(
          child: Text(
            "Accès refusé.\nVous n'avez pas les droits nécessaires.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, color: Colors.red),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Panneau Administrateur', style: TextStyle(color: theme.primaryColor)),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: theme.primaryColor),
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      body: _views[_currentIndex],
      bottomNavigationBar: FutureBuilder<List<UserModel>>(
        future: Provider.of<AdminController>(context, listen: false).getPendingVerifications(),
        builder: (context, snapshot) {
          final pendingCount = (snapshot.data ?? []).where((u) => u.verificationStatus == 'pending').length;
          return BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            selectedItemColor: theme.primaryColor,
            unselectedItemColor: theme.textTheme.bodySmall?.color ?? Colors.grey,
            backgroundColor: theme.cardColor,
            type: BottomNavigationBarType.fixed,
            items: [
              const BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Stats'),
              const BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Users'),
              const BottomNavigationBarItem(icon: Icon(Icons.apartment), label: 'Immos'),
              BottomNavigationBarItem(
                icon: Badge(
                  isLabelVisible: pendingCount > 0,
                  label: Text('$pendingCount', style: const TextStyle(fontSize: 10, color: Colors.white)),
                  backgroundColor: Colors.red,
                  child: const Icon(Icons.verified_user),
                ),
                label: 'Vérifs',
              ),
              const BottomNavigationBarItem(icon: Icon(Icons.campaign), label: 'Ads'),
            ],
          );
        },
      ),
    );
  }
}
