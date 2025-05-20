import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/theme_toggle.dart';
import '../../utils/theme.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = false;

  // Mock data for shopping list summary
  // In a real app, this would come from an API or provider
  final List<Map<String, dynamic>> _shoppingLists = [
    {'id': 1, 'name': 'Groceries', 'itemCount': 5, 'completed': 2},
    {'id': 2, 'name': 'Hardware Store', 'itemCount': 3, 'completed': 0},
    {'id': 3, 'name': 'Birthday Party', 'itemCount': 8, 'completed': 5},
  ];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    // Simulate API call delay
    await Future.delayed(const Duration(milliseconds: 800));

    // In a real app, you would fetch data from your backend here
    // Example:
    // final authProvider = Provider.of<AuthProvider>(context, listen: false);
    // final token = authProvider.token;
    // final response = await yourService.getShoppingLists(token);

    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          ThemeToggle(),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authProvider.logout();
              if (!mounted) return;
              Navigator.of(context).pushReplacementNamed('/login');
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User welcome card
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome back,',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            Text(
                              user?.username ?? 'User',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Dashboard stats
                    _buildStatsSection(),

                    const SizedBox(height: 24),

                    // Shopping lists
                    Text(
                      'Your Shopping Lists',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),

                    ..._buildShoppingLists(isDark),

                    const SizedBox(height: 80), // Bottom padding for FAB
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to create shopping list screen
          // This would be implemented in future stories
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Create new shopping list (to be implemented)')),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStatsSection() {
    // Calculate summary stats
    int totalLists = _shoppingLists.length;
    int totalItems =
        _shoppingLists.fold(0, (sum, list) => sum + (list['itemCount'] as int));
    int completedItems =
        _shoppingLists.fold(0, (sum, list) => sum + (list['completed'] as int));

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Lists',
            totalLists.toString(),
            Icons.list_alt,
            AppTheme.primaryColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Items',
            totalItems.toString(),
            Icons.shopping_cart,
            AppTheme.secondaryColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Completed',
            '$completedItems/$totalItems',
            Icons.check_circle_outline,
            AppTheme.success,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildShoppingLists(bool isDark) {
    if (_shoppingLists.isEmpty) {
      return [
        Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              children: [
                Icon(
                  Icons.shopping_bag_outlined,
                  size: 64,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
                const SizedBox(height: 16),
                Text(
                  'No shopping lists yet',
                  style: TextStyle(
                    fontSize: 18,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Create your first list using the + button',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white54 : Colors.black45,
                  ),
                ),
              ],
            ),
          ),
        ),
      ];
    }

    return _shoppingLists.map((list) {
      double completionPercentage =
          list['itemCount'] > 0 ? (list['completed'] / list['itemCount']) : 0.0;

      return Card(
        margin: const EdgeInsets.only(top: 12),
        child: InkWell(
          onTap: () {
            // Navigate to list details (to be implemented)
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content:
                      Text('View list: ${list['name']} (to be implemented)')),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        list['name'],
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${list['completed']}/${list['itemCount']} items',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: completionPercentage,
                  backgroundColor: isDark ? Colors.grey[800] : Colors.grey[300],
                  color: _getProgressColor(completionPercentage),
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  Color _getProgressColor(double percentage) {
    if (percentage >= 1.0) return AppTheme.success;
    if (percentage > 0.5) return AppTheme.info;
    if (percentage > 0.0) return AppTheme.warning;
    return AppTheme.error;
  }
}
