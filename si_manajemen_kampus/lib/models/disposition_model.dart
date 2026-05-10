class Disposition {
  final int id;
  final int senderId;
  final String? letterNumber;
  final String? letterDate;
  final String letterSubject;
  final String? letterContent;
  final String? documentFile;
  final String priority;
  final String status;
  final String? notes;
  final String createdAt;
  final String updatedAt;
  final String senderName;
  final List<DispositionRecipient> recipients;
  final List<DispositionUpdate> updates;

  Disposition({
    required this.id,
    required this.senderId,
    this.letterNumber,
    this.letterDate,
    required this.letterSubject,
    this.letterContent,
    this.documentFile,
    required this.priority,
    required this.status,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    required this.senderName,
    this.recipients = const [],
    this.updates = const [],
  });

  factory Disposition.fromJson(Map<String, dynamic> json) {
    var recipientsList = <DispositionRecipient>[];
    if (json['recipients'] != null) {
      recipientsList = List<DispositionRecipient>.from(
        (json['recipients'] as List).map(
          (item) => DispositionRecipient.fromJson(item),
        ),
      );
    }

    var updatesList = <DispositionUpdate>[];
    if (json['updates'] != null) {
      updatesList = List<DispositionUpdate>.from(
        (json['updates'] as List).map(
          (item) => DispositionUpdate.fromJson(item),
        ),
      );
    }

    return Disposition(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      senderId: json['sender_id'] is int
          ? json['sender_id']
          : int.parse(json['sender_id'].toString()),
      letterNumber: json['letter_number'] as String?,
      letterDate: json['letter_date'] as String?,
      letterSubject: json['letter_subject'] as String,
      letterContent: json['letter_content'] as String?,
      documentFile: json['document_file'] as String?,
      priority: json['priority'] as String? ?? 'normal',
      status: json['status'] as String? ?? 'pending',
      notes: json['notes'] as String?,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
      senderName: json['sender_name'] as String? ?? 'Unknown',
      recipients: recipientsList,
      updates: updatesList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_id': senderId,
      'letter_number': letterNumber,
      'letter_date': letterDate,
      'letter_subject': letterSubject,
      'letter_content': letterContent,
      'document_file': documentFile,
      'priority': priority,
      'status': status,
      'notes': notes,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'sender_name': senderName,
    };
  }

  bool get isPending => status == 'pending';
  bool get isInProgress => status == 'in_progress';
  bool get isCompleted => status == 'completed';
  bool get isReassigned => status == 'reassigned';
  bool get isUrgent => priority == 'urgent';
  bool get isHighPriority => priority == 'high';
}

class DispositionRecipient {
  final int id;
  final int recipientUserId;
  final String recipientName;
  final String? recipientRole;
  final String assignedAt;

  DispositionRecipient({
    required this.id,
    required this.recipientUserId,
    required this.recipientName,
    this.recipientRole,
    required this.assignedAt,
  });

  factory DispositionRecipient.fromJson(Map<String, dynamic> json) {
    return DispositionRecipient(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      recipientUserId: json['recipient_user_id'] is int
          ? json['recipient_user_id']
          : int.parse(json['recipient_user_id'].toString()),
      recipientName: json['recipient_name'] as String? ?? 'Unknown',
      recipientRole: json['role_at_assignment'] as String?,
      assignedAt: json['assigned_at'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'recipient_user_id': recipientUserId,
      'recipient_name': recipientName,
      'role_at_assignment': recipientRole,
      'assigned_at': assignedAt,
    };
  }
}

class DispositionUpdate {
  final int id;
  final int dispositionId;
  final int updatedBy;
  final String updatedByName;
  final String? oldStatus;
  final String? newStatus;
  final String? updateNotes;
  final String createdAt;

  DispositionUpdate({
    required this.id,
    required this.dispositionId,
    required this.updatedBy,
    required this.updatedByName,
    this.oldStatus,
    this.newStatus,
    this.updateNotes,
    required this.createdAt,
  });

  factory DispositionUpdate.fromJson(Map<String, dynamic> json) {
    return DispositionUpdate(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      dispositionId: json['disposition_id'] is int
          ? json['disposition_id']
          : int.parse(json['disposition_id'].toString()),
      updatedBy: json['updated_by'] is int
          ? json['updated_by']
          : int.parse(json['updated_by'].toString()),
      updatedByName: json['updated_by_name'] as String? ?? 'Unknown',
      oldStatus: json['old_status'] as String?,
      newStatus: json['new_status'] as String?,
      updateNotes: json['update_notes'] as String?,
      createdAt: json['created_at'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'disposition_id': dispositionId,
      'updated_by': updatedBy,
      'updated_by_name': updatedByName,
      'old_status': oldStatus,
      'new_status': newStatus,
      'update_notes': updateNotes,
      'created_at': createdAt,
    };
  }
}
