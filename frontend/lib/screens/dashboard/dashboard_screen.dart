import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/theme_toggle.dart';
import '../../widgets/common/app_drawer.dart';
import '../../utils/routes.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = false;

  // Mock data for shopping lists - TODO: Replace with API service
  final List<Map<String, dynamic>> _shoppingLists = [
    {
      'id': 1,
      'name': 'Weekly Groceries',
      'itemCount': 12,
      'completedCount': 8,
      'createdAt': DateTime.now().subtract(const Duration(days: 2)),
    },
    {
      'id': 2,
      'name': 'Party Supplies',
      'itemCount': 8,
      'completedCount': 3,
      'createdAt': DateTime.now().subtract(const Duration(days: 5)),
    },
    {
      'id': 3,
      'name': 'Household Items',
      'itemCount': 6,
      'completedCount': 6,
      'createdAt': DateTime.now().subtract(const Duration(days: 1)),
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    // TODO: Implement API call to fetch shopping lists
    await Future.delayed(const Duration(seconds: 1)); // Simulate API call

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: const [
          ThemeToggle(),
        ],
      ),
      drawer: const AppDrawer(),
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Welcome Card
            Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                final user = authProvider.user;
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Theme.of(context).primaryColor,
                          child: const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome back, ${user?.username ?? 'User'}!',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Here\'s your shopping overview',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // Stats Section
            _buildStatsSection(),

            const SizedBox(height: 24),

            // Shopping Lists Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Shopping Lists',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pushNamed(Routes.shoppingLists);
                  },
                  child: const Text('View All'),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Shopping Lists
            ..._buildShoppingLists(_isLoading),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Implement navigation to create new shopping list
          Navigator.of(context).pushNamed(Routes.shoppingLists);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStatsSection() {
    final totalLists = _shoppingLists.length;
    final totalItems = _shoppingLists.fold<int>(
      0,
      (sum, list) => sum + (list['itemCount'] as int),
    );
    final completedItems = _shoppingLists.fold<int>(
      0,
      (sum, list) => sum + (list['completedCount'] as int),
    );

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Lists',
            totalLists.toString(),
            Icons.list_alt,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Items',
            totalItems.toString(),
            Icons.shopping_cart,
            Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Completed',
            completedItems.toString(),
            Icons.check_circle,
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildShoppingLists(bool isLoading) {
    if (isLoading) {
      return [
        const Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: CircularProgressIndicator(),
          ),
        ),
      ];
    }

    if (_shoppingLists.isEmpty) {
      return [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Icon(
                  Icons.shopping_cart_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No shopping lists yet',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap the + button to create your first list',
                  style: TextStyle(
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ),
      ];
    }

    return _shoppingLists.map((list) {
      final progress = list['completedCount'] / list['itemCount'];
      final progressColor = _getProgressColor(progress);

      return Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: progressColor.withValues(alpha: 0.1),
            child: Icon(
              Icons.shopping_cart,
              color: progressColor,
            ),
          ),
          title: Text(
            list['name'],
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                '${list['completedCount']}/${list['itemCount']} items completed',
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              ),
            ],
          ),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            // TODO: Navigate to shopping list detail
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Opening ${list['name']} - Coming soon!'),
              ),
            );
          },
        ),
      );
    }).toList();
  }

  Color _getProgressColor(double progress) {
    if (progress >= 1.0) return Colors.green;
    if (progress >= 0.7) return Colors.orange;
    return Colors.blue;
  }
}
