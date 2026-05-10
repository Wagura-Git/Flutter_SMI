class Document {
  final int id;
  final int userId;
  final String? documentNumber;
  final String title;
  final String? description;
  final String? documentType;
  final String? documentFile;
  final String status;
  final String visibility;
  final String createdAt;
  final String updatedAt;
  final String userName;

  Document({
    required this.id,
    required this.userId,
    this.documentNumber,
    required this.title,
    this.description,
    this.documentType,
    this.documentFile,
    required this.status,
    required this.visibility,
    required this.createdAt,
    required this.updatedAt,
    required this.userName,
  });

  factory Document.fromJson(Map<String, dynamic> json) {
    return Document(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      userId: json['user_id'] is int
          ? json['user_id']
          : int.parse(json['user_id'].toString()),
      documentNumber: json['document_number'] as String?,
      title: json['title'] as String,
      description: json['description'] as String?,
      documentType: json['document_type'] as String?,
      documentFile: json['document_file'] as String?,
      status: json['status'] as String? ?? 'draft',
      visibility: json['visibility'] as String? ?? 'private',
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
      userName: json['user_name'] as String? ?? 'Unknown',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'document_number': documentNumber,
      'title': title,
      'description': description,
      'document_type': documentType,
      'document_file': documentFile,
      'status': status,
      'visibility': visibility,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'user_name': userName,
    };
  }

  bool get isDraft => status == 'draft';
  bool get isPublished => status == 'published';
  bool get isArchived => status == 'archived';
  bool get isPrivate => visibility == 'private';
  bool get isTeamVisible => visibility == 'team';
  bool get isPublic => visibility == 'public';
}

class DocumentAccess {
  final int id;
  final int documentId;
  final int userId;
  final String accessType;
  final String createdAt;
  final String userName;

  DocumentAccess({
    required this.id,
    required this.documentId,
    required this.userId,
    required this.accessType,
    required this.createdAt,
    required this.userName,
  });

  factory DocumentAccess.fromJson(Map<String, dynamic> json) {
    return DocumentAccess(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      documentId: json['document_id'] is int
          ? json['document_id']
          : int.parse(json['document_id'].toString()),
      userId: json['user_id'] is int
          ? json['user_id']
          : int.parse(json['user_id'].toString()),
      accessType: json['access_type'] as String? ?? 'view',
      createdAt: json['created_at'] as String,
      userName: json['user_name'] as String? ?? 'Unknown',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'document_id': documentId,
      'user_id': userId,
      'access_type': accessType,
      'created_at': createdAt,
      'user_name': userName,
    };
  }

  bool get canView => accessType == 'view';
  bool get canEdit => accessType == 'edit';
  bool get canManage => accessType == 'manage';
}
