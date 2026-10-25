class NotificationModel {
  String id;
  String titre;
  String message;
  DateTime date;
  bool lu;
  String type;
  String userId;
  String? cultureId;

  NotificationModel({
    required this.id,
    required this.titre,
    required this.message,
    required this.date,
    required this.lu,
    required this.type,
    required this.userId,
    this.cultureId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'titre': titre,
      'message': message,
      'date': date.toIso8601String(),
      'lu': lu,
      'type': type,
      'userId': userId,
      'cultureId': cultureId,
    };
  }

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['id'],
      titre: map['titre'],
      message: map['message'],
      date: DateTime.parse(map['date']),
      lu: map['lu'],
      type: map['type'],
      userId: map['userId'],
      cultureId: map['cultureId'],
    );
  }
}
