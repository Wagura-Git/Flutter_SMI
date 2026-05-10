class Notification {
  final int id;
  final int userId;
  final String title;
  final String message;
  final String? type;
  final int? relatedAgendaId;
  final bool isRead;
  final String createdAt;
  final String updatedAt;

  Notification({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    this.type,
    this.relatedAgendaId,
    required this.isRead,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      title: json['title'] as String,
      message: json['message'] as String,
      type: json['type'] as String?,
      relatedAgendaId: json['related_agenda_id'] as int?,
      isRead: (json['is_read'] as int?) == 1 ? true : false,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'message': message,
      'type': type,
      'related_agenda_id': relatedAgendaId,
      'is_read': isRead ? 1 : 0,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
