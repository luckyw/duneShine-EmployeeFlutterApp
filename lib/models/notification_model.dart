/// Model class representing a notification item
class NotificationModel {
  final int id;
  final String title;
  final String message;
  final String time;
  final bool isRead;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.time,
    this.isRead = false,
  });

  /// Creates a NotificationModel from JSON data
  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      time: json['time'] ?? '',
      isRead: json['isRead'] ?? false,
    );
  }

  /// Creates a copy of this notification with updated fields
  NotificationModel copyWith({
    int? id,
    String? title,
    String? message,
    String? time,
    bool? isRead,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      time: time ?? this.time,
      isRead: isRead ?? this.isRead,
    );
  }
}
