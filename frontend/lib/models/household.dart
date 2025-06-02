// models/household.dart

class Household {
  final int id;
  final String name;
  final DateTime createdAt;
  final List<HouseholdMember> members;

  Household({
    required this.id,
    required this.name,
    required this.createdAt,
    this.members = const [],
  });

  factory Household.fromJson(Map<String, dynamic> json) {
    return Household(
      id: json['id'],
      name: json['name'],
      createdAt: DateTime.parse(json['created_at']),
      members: (json['members'] as List<dynamic>?)
              ?.map((member) => HouseholdMember.fromJson(member))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'created_at': createdAt.toIso8601String(),
      'members': members.map((member) => member.toJson()).toList(),
    };
  }
}

class HouseholdSummary {
  final int id;
  final String name;
  final DateTime? createdAt;

  HouseholdSummary({
    required this.id,
    required this.name,
    this.createdAt,
  });

  factory HouseholdSummary.fromJson(Map<String, dynamic> json) {
    return HouseholdSummary(
      id: json['id'],
      name: json['name'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }
}

class HouseholdMember {
  final int id;
  final String username;
  final String email;
  final String role;
  final DateTime joinedAt;

  HouseholdMember({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    required this.joinedAt,
  });

  factory HouseholdMember.fromJson(Map<String, dynamic> json) {
    return HouseholdMember(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      role: json['role'] ?? 'member',
      joinedAt: DateTime.parse(json['joined_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'role': role,
      'joined_at': joinedAt.toIso8601String(),
    };
  }

  bool get isAdmin => role == 'admin';
}

class HouseholdCreate {
  final String name;

  HouseholdCreate({required this.name});

  Map<String, dynamic> toJson() {
    return {'name': name};
  }
}

class HouseholdUpdate {
  final String name;

  HouseholdUpdate({required this.name});

  Map<String, dynamic> toJson() {
    return {'name': name};
  }
}

class HouseholdInvitation {
  final int id;
  final int householdId;
  final int invitedById;
  final int invitedUserId;
  final String status;
  final DateTime createdAt;
  final DateTime? respondedAt;
  final HouseholdSummary? household;
  final UserSummary? invitedBy;
  final UserSummary? invitedUser;

  HouseholdInvitation({
    required this.id,
    required this.householdId,
    required this.invitedById,
    required this.invitedUserId,
    required this.status,
    required this.createdAt,
    this.respondedAt,
    this.household,
    this.invitedBy,
    this.invitedUser,
  });

  factory HouseholdInvitation.fromJson(Map<String, dynamic> json) {
    return HouseholdInvitation(
      id: json['id'],
      householdId: json['household_id'],
      invitedById: json['invited_by_id'],
      invitedUserId: json['invited_user_id'],
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
      respondedAt: json['responded_at'] != null
          ? DateTime.parse(json['responded_at'])
          : null,
      household: json['household'] != null
          ? HouseholdSummary.fromJson(json['household'])
          : null,
      invitedBy: json['invited_by'] != null
          ? UserSummary.fromJson(json['invited_by'])
          : null,
      invitedUser: json['invited_user'] != null
          ? UserSummary.fromJson(json['invited_user'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'household_id': householdId,
      'invited_by_id': invitedById,
      'invited_user_id': invitedUserId,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      if (respondedAt != null) 'responded_at': respondedAt!.toIso8601String(),
      if (household != null) 'household': household!.toJson(),
      if (invitedBy != null) 'invited_by': invitedBy!.toJson(),
      if (invitedUser != null) 'invited_user': invitedUser!.toJson(),
    };
  }

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isRejected => status == 'rejected';
  bool get isCancelled => status == 'cancelled';
}

class UserSummary {
  final int id;
  final String username;
  final String email;

  UserSummary({
    required this.id,
    required this.username,
    required this.email,
  });

  factory UserSummary.fromJson(Map<String, dynamic> json) {
    return UserSummary(
      id: json['id'],
      username: json['username'],
      email: json['email'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
    };
  }
}

class InvitationCreate {
  final String email;

  InvitationCreate({required this.email});

  Map<String, dynamic> toJson() {
    return {'email': email};
  }
}
