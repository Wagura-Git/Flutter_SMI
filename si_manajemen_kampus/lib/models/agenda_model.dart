class Agenda {
  final int id;
  final int userId;
  final String title;
  final String? description;
  final String date;
  final String timeStart;
  final String? timeEnd;
  final String? location;
  final String? category;
  final String? agendaType;
  final String status;
  final String createdAt;
  final String updatedAt;
  final List<int>? recipientUserIds;
  final List<Map<String, dynamic>>? recipients;
  final String? attachmentPath;

  Agenda({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.date,
    required this.timeStart,
    this.timeEnd,
    this.location,
    this.category,
    this.agendaType,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.recipientUserIds,
    this.recipients,
    this.attachmentPath,
  });

  factory Agenda.fromJson(Map<String, dynamic> json) {
    return Agenda(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      title: json['title'] as String,
      description: json['description'] as String?,
      date: json['date_start'] as String? ?? json['date'] as String,
      timeStart: json['time_start'] as String,
      timeEnd: json['time_end'] as String?,
      location: json['location'] as String?,
      category: json['category'] as String?,
      agendaType: json['agenda_type'] as String?,
      status: json['status'] as String,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
      recipientUserIds: json['recipients'] != null && json['recipients'] is List
          ? List<int>.from((json['recipients'] as List)
              .where((x) => x is Map && x.containsKey('id'))
              .map((x) => x['id'] as int))
          : null,
      recipients: json['recipients'] != null && json['recipients'] is List
          ? List<Map<String, dynamic>>.from(json['recipients'] as List)
          : null,
      attachmentPath: json['attachment_path'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'date': date,
      'time_start': timeStart,
      'time_end': timeEnd,
      'location': location,
      'category': category,
      'agenda_type': agendaType,
      'status': status,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'recipients': recipientUserIds,
    };
  }
}
