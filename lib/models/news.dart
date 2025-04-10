import 'package:logger/logger.dart'; // Add logger package

// Logger instance for debugging
final logger = Logger();

class News {
  final int id;
  final String? title;
  final String? description;
  final String? image;
  final String? video;
  final int? userId;
  final List<Reaction> reactions;
  final List<Comment> comments;
  final String? createdAt;

  News({
    required this.id,
    this.title,
    this.description,
    this.image,
    this.video,
    this.userId,
    required this.reactions,
    required this.comments,
    this.createdAt,
  });

  factory News.fromJson(Map<String, dynamic> json) {
    logger.d('Parsing News JSON: $json'); // Debug log
    return News(
      id: json['id'] as int? ?? 0, // Fallback to 0 if null
      title: json['title'] as String?,
      description: json['description'] as String?,
      image: json['image'] as String?,
      video: json['video'] as String?,
      userId: json['user'] is int
          ? json['user'] as int?
          : json['user'] != null
              ? (json['user'] as Map<String, dynamic>)['id'] as int?
              : null,
      reactions: (json['reactions'] as List<dynamic>? ?? [])
          .map((r) => Reaction.fromJson(r as Map<String, dynamic>))
          .toList(),
      comments: (json['comments'] as List<dynamic>? ?? [])
          .map((c) => Comment.fromJson(c as Map<String, dynamic>))
          .toList(),
      createdAt: json['created_at'] as String?,
    );
  }
}

class Reaction {
  final String type;
  final int? userId; // Made nullable to handle null cases

  Reaction({required this.type, this.userId});

  factory Reaction.fromJson(Map<String, dynamic> json) {
    logger.d('Parsing Reaction JSON: $json'); // Debug log
    return Reaction(
      type: json['type'] as String? ?? 'unknown', // Fallback for type
      userId: json['user_id'] as int?, // Allow null
    );
  }
}

class Comment {
  final String comment;
  final User user; // Add User object to hold user data

  Comment({required this.comment, required this.user});

  factory Comment.fromJson(Map<String, dynamic> json) {
    logger.d('Parsing Comment JSON: $json'); // Debug log
    return Comment(
      comment: json['comment'] as String? ?? '', // Fallback to empty string
      user: User.fromJson(json['commentable'] as Map<String, dynamic>), // Parse user data
    );
  }
}

class User {
  // ignore: non_constant_identifier_names
  final String reg_no;
  final String gender;

  // ignore: non_constant_identifier_names
  User({required this.reg_no, required this.gender});

  factory User.fromJson(Map<String, dynamic> json) {
    logger.d('Parsing User JSON: $json'); // Debug log
    return User(
      reg_no: json['reg_no'] as String? ?? 'Unknown', // Fallback if reg_no is missing
      gender: json['gender'] as String? ?? 'unknown', // Fallback if gender is missing
    );
  }
}