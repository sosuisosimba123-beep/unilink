class SupportTicketModel {
  final String id;
  final String userId;
  final String subject;
  final String message;
  final String status; // 'open', 'in progress', 'resolved'
  final String category;
  final DateTime? created;

  SupportTicketModel({
    required this.id,
    required this.userId,
    required this.subject,
    required this.message,
    required this.status,
    required this.category,
    this.created,
  });

  factory SupportTicketModel.fromJson(Map<String, dynamic> json) {
    return SupportTicketModel(
      id: json['id'] ?? '',
      userId: json['user'] ?? '',
      subject: json['subject'] ?? '',
      message: json['message'] ?? '',
      status: json['status'] ?? 'open',
      category: json['category'] ?? 'General',
      created: json['created'] != null ? DateTime.tryParse(json['created']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user': userId,
        'subject': subject,
        'message': message,
        'status': status,
        'category': category,
      };
}
