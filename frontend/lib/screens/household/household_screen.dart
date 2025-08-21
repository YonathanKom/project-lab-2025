// screens/household/household_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../api/services/household_service.dart';
import '../../models/household.dart';
import '../../utils/constants.dart';
import '../../widgets/common/app_drawer.dart';
import '../../widgets/theme_toggle.dart';
import '../../utils/validators.dart';

class HouseholdScreen extends StatefulWidget {
  const HouseholdScreen({super.key});

  @override
  State<HouseholdScreen> createState() => _HouseholdScreenState();
}

class _HouseholdScreenState extends State<HouseholdScreen>
    with TickerProviderStateMixin {
  late HouseholdService _householdService;
  late TabController _tabController;

  bool _isLoading = false;
  String? _errorMessage;

  List<Household> _households = [];
  List<HouseholdInvitation> _receivedInvitations = [];
  List<HouseholdInvitation> _sentInvitations = [];

  int? _selectedHouseholdId;
  Household? _selectedHousehold;

  @override
  void initState() {
    super.initState();
    _householdService = HouseholdService(baseUrl);
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await Future.wait([
        _loadHouseholds(),
        _loadReceivedInvitations(),
        _loadSentInvitations(),
      ]);
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadHouseholds() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    if (token == null) return;

    final result = await _householdService.getUserHouseholds(token);
    if (result['success']) {
      final householdList = result['data'] as List;
      final newHouseholds =
          householdList.map((h) => Household.fromJson(h)).toList();

      setState(() {
        _households = newHouseholds;

        // Check if currently selected household still exists
        if (_selectedHouseholdId != null) {
          final stillExists =
              _households.any((h) => h.id == _selectedHouseholdId);
          if (!stillExists) {
            // Reset selection if current household no longer exists
            _selectedHouseholdId = null;
            _selectedHousehold = null;
          }
        }

        // Set default selection if none selected and households exist
        if (_households.isNotEmpty && _selectedHouseholdId == null) {
          _selectedHouseholdId = _households.first.id;
          _selectedHousehold = _households.first;
        }

        // Update selected household object if ID is valid
        if (_selectedHouseholdId != null) {
          try {
            _selectedHousehold =
                _households.firstWhere((h) => h.id == _selectedHouseholdId);
          } catch (e) {
            // If household not found, reset selection
            _selectedHouseholdId = null;
            _selectedHousehold = null;
            if (_households.isNotEmpty) {
              _selectedHouseholdId = _households.first.id;
              _selectedHousehold = _households.first;
            }
          }
        }
      });
    } else {
      throw Exception(result['error']);
    }
  }

  Future<void> _loadReceivedInvitations() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    if (token == null) return;

    final result = await _householdService.getReceivedInvitations(token);
    if (result['success']) {
      final invitationList = result['data'] as List;
      setState(() {
        _receivedInvitations = invitationList
            .map((i) => HouseholdInvitation.fromJson(i))
            .where((i) => i.isPending)
            .toList();
      });
    }
  }

  Future<void> _loadSentInvitations() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    if (token == null) return;

    final result = await _householdService.getSentInvitations(token);
    if (result['success']) {
      final invitationList = result['data'] as List;
      setState(() {
        _sentInvitations =
            invitationList.map((i) => HouseholdInvitation.fromJson(i)).toList();
      });
    }
  }

  Future<void> _createHousehold() async {
    final nameController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Create Household'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Household Name',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter a household name';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(dialogContext, true);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (result == true) {
      if (!mounted) return;

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (token == null) return;

      try {
        final creationResult = await _householdService.createHousehold(
          nameController.text.trim(),
          token,
        );

        if (creationResult['success']) {
          await _loadHouseholds();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Household created successfully!')),
            );
          }
        } else {
          throw Exception(creationResult['error'] ?? 'Unknown error');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to create household: $e')),
          );
        }
      }
    }
  }

  Future<void> _inviteMember() async {
    if (_selectedHousehold == null) return;

    final emailController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text('Invite to ${_selectedHousehold!.name}'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: emailController,
            decoration: const InputDecoration(
              labelText: 'Email Address',
              border: OutlineInputBorder(),
            ),
            validator: Validators.validateEmail,
            keyboardType: TextInputType.emailAddress,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(dialogContext, true);
              }
            },
            child: const Text('Send Invite'),
          ),
        ],
      ),
    );

    if (result == true) {
      if (!mounted) return;

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (token == null) return;

      try {
        final inviteResult = await _householdService.inviteToHousehold(
          _selectedHousehold!.id,
          emailController.text.trim(),
          token,
        );

        if (inviteResult['success']) {
          await _loadSentInvitations();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Invitation sent successfully!')),
            );
          }
        } else {
          throw Exception(inviteResult['error'] ?? 'Unknown error');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to send invitation: $e')),
          );
        }
      }
    }
  }

  Future<void> _respondToInvitation(
      HouseholdInvitation invitation, bool accept) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    if (token == null) return;

    try {
      final result = accept
          ? await _householdService.acceptInvitation(invitation.id, token)
          : await _householdService.rejectInvitation(invitation.id, token);

      if (result['success']) {
        await _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text(accept ? 'Invitation accepted!' : 'Invitation rejected'),
            ),
          );
        }
      } else {
        throw Exception(result['error']);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to respond to invitation: $e')),
        );
      }
    }
  }

  Future<void> _cancelInvitation(HouseholdInvitation invitation) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    if (token == null) return;

    try {
      final result =
          await _householdService.cancelInvitation(invitation.id, token);

      if (result['success']) {
        await _loadSentInvitations();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invitation cancelled')),
          );
        }
      } else {
        throw Exception(result['error']);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to cancel invitation: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Households'),
        actions: const [ThemeToggle()],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              text: 'My Households',
              icon: Badge(
                isLabelVisible: _households.isNotEmpty,
                label: Text('${_households.length}'),
                child: const Icon(Icons.home),
              ),
            ),
            Tab(
              text: 'Invitations',
              icon: Badge(
                isLabelVisible: _receivedInvitations.isNotEmpty,
                label: Text('${_receivedInvitations.length}'),
                child: const Icon(Icons.mail),
              ),
            ),
            Tab(
              text: 'Sent Invites',
              icon: Badge(
                isLabelVisible: _sentInvitations.isNotEmpty,
                label: Text('${_sentInvitations.length}'),
                child: const Icon(Icons.send),
              ),
            ),
          ],
        ),
      ),
      drawer: const AppDrawer(),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? _buildErrorState()
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildHouseholdsTab(),
                      _buildInvitationsTab(),
                      _buildSentInvitesTab(),
                    ],
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createHousehold,
        tooltip: 'Create Household',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Error loading data',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? 'Unknown error occurred',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadData,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildHouseholdsTab() {
    if (_households.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.home_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'No Households Yet',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text('Create your first household to get started'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _createHousehold,
              child: const Text('Create Household'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        if (_households.length > 1)
          Container(
            padding: const EdgeInsets.all(16),
            child: DropdownButtonFormField<int>(
              value: _selectedHouseholdId,
              decoration: const InputDecoration(
                labelText: 'Select Household',
                border: OutlineInputBorder(),
              ),
              items: _households.map((household) {
                return DropdownMenuItem(
                  value: household.id,
                  child: Text(household.name),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedHouseholdId = value;
                  _selectedHousehold =
                      _households.firstWhere((h) => h.id == value);
                });
              },
            ),
          ),
        Expanded(
          child: _selectedHousehold != null
              ? _buildHouseholdDetails(_selectedHousehold!)
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildHouseholdDetails(Household household) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.user?.id;
    final isAdmin = household.members
        .where((m) => m.id == currentUserId)
        .any((m) => m.isAdmin);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.home,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          household.name,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                      if (isAdmin)
                        IconButton(
                          onPressed: _inviteMember,
                          icon: const Icon(Icons.person_add),
                          tooltip: 'Invite Member',
                        ),
                      PopupMenuButton(
                        icon: const Icon(Icons.more_vert),
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'leave',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.exit_to_app,
                                  color: Theme.of(context).colorScheme.error,
                                ),
                                const SizedBox(width: 8),
                                const Text('Leave Household'),
                              ],
                            ),
                          ),
                        ],
                        onSelected: (value) {
                          if (value == 'leave') {
                            _leaveHousehold(household);
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Created ${_formatDate(household.createdAt)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${household.members.length} member${household.members.length != 1 ? 's' : ''}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Members',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ...household.members.map(
              (member) => _buildMemberCard(member, isAdmin, currentUserId)),
        ],
      ),
    );
  }

  Widget _buildMemberCard(
      HouseholdMember member, bool isAdmin, int? currentUserId) {
    final isCurrentUser = member.id == currentUserId;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: member.isAdmin
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.secondary,
          child: Text(
            member.username.substring(0, 1).toUpperCase(),
            style: TextStyle(
              color: member.isAdmin
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(context).colorScheme.onSecondary,
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(child: Text(member.username)),
            if (member.isAdmin)
              Chip(
                label: const Text('Admin'),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            if (isCurrentUser)
              Chip(
                label: const Text('You'),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(member.email),
            Text(
              'Joined ${_formatDate(member.joinedAt)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        trailing: isAdmin && !isCurrentUser
            ? PopupMenuButton(
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'remove',
                    child: Row(
                      children: [
                        Icon(Icons.remove_circle, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Remove Member'),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) async {
                  if (value == 'remove') {
                    await _removeMember(member);
                  }
                },
              )
            : null,
      ),
    );
  }

  Widget _buildInvitationsTab() {
    if (_receivedInvitations.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.mail_outline, size: 64),
            SizedBox(height: 16),
            Text('No pending invitations'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _receivedInvitations.length,
      itemBuilder: (context, index) {
        final invitation = _receivedInvitations[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      child: Icon(Icons.home),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            invitation.household?.name ?? 'Unknown Household',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Invited by ${invitation.invitedBy?.username ?? 'Unknown'}',
                            style: Theme.of(context).textTheme.bodyMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Received ${_formatDate(invitation.createdAt)}',
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => _respondToInvitation(invitation, false),
                      child: const Text('Decline'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => _respondToInvitation(invitation, true),
                      child: const Text('Accept'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSentInvitesTab() {
    if (_sentInvitations.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.send_outlined, size: 64),
            SizedBox(height: 16),
            Text('No sent invitations'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _sentInvitations.length,
      itemBuilder: (context, index) {
        final invitation = _sentInvitations[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getStatusColor(invitation.status),
              child: Icon(
                _getStatusIcon(invitation.status),
                color: Colors.white,
              ),
            ),
            title: Text(invitation.household?.name ?? 'Unknown Household'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sent to ${invitation.invitedUser?.email ?? 'Unknown'}'),
                Text(
                  'Status: ${invitation.status.toUpperCase()}',
                  style: TextStyle(
                    color: _getStatusColor(invitation.status),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Sent ${_formatDate(invitation.createdAt)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            trailing: invitation.isPending
                ? TextButton(
                    onPressed: () => _cancelInvitation(invitation),
                    child: const Text('Cancel'),
                  )
                : null,
          ),
        );
      },
    );
  }

  Future<void> _leaveHousehold(Household household) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.user?.id;
    final isLastMember = household.members.length == 1;
    final isAdmin = household.members
        .where((m) => m.id == currentUserId)
        .any((m) => m.isAdmin);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Leave Household'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to leave "${household.name}"?'),
            const SizedBox(height: 16),
            if (isAdmin || isLastMember)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(dialogContext).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning,
                      color: Theme.of(dialogContext).colorScheme.error,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isAdmin
                            ? 'Since you are the admin, this household and all its shopping lists will be permanently deleted for all members.'
                            : 'Since you are the last member, this household and all its shopping lists will be permanently deleted.',
                        style: TextStyle(
                          color: Theme.of(dialogContext)
                              .colorScheme
                              .onErrorContainer,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            child:
                Text((isAdmin || isLastMember) ? 'Delete Household' : 'Leave'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (!mounted) return;

      final token = authProvider.token;
      if (token == null) return;

      try {
        final result = await _householdService.leaveHousehold(
          household.id,
          token,
        );

        if (result['success']) {
          await _loadData();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content:
                      Text(result['message'] ?? 'Left household successfully')),
            );
          }
        } else {
          throw Exception(result['error'] ?? 'Unknown error');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to leave household: $e')),
          );
        }
      }
    }
  }

  Future<void> _removeMember(HouseholdMember member) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Remove Member'),
        content: Text(
          'Are you sure you want to remove ${member.username} from this household?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm == true && _selectedHousehold != null) {
      if (!mounted) return;

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (token == null) return;

      try {
        final result = await _householdService.removeMember(
          _selectedHousehold!.id,
          member.id,
          token,
        );

        if (result['success']) {
          await _loadHouseholds();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${member.username} removed from household'),
              ),
            );
          }
        } else {
          throw Exception(result['error'] ?? 'Unknown error');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to remove member: $e')),
          );
        }
      }
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 30) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays != 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours != 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.schedule;
      case 'accepted':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      case 'cancelled':
        return Icons.block;
      default:
        return Icons.help;
    }
  }
}
