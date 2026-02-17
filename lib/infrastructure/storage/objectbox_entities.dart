import 'package:objectbox/objectbox.dart';

@Entity()
class ChatSessionEntity {
  @Id()
  int id = 0;
  
  String title;
  @Property(type: PropertyType.date)
  DateTime createdAt;
  String selectedModel;
  String selectedProvider;

  @Backlink('session')
  final messages = ToMany<ChatMessageEntity>();

  ChatSessionEntity({
    this.title = 'New Chat',
    DateTime? createdAt,
    required this.selectedModel,
    required this.selectedProvider,
  }) : createdAt = createdAt ?? DateTime.now();
}

@Entity()
class AppSettingsEntity {
  @Id()
  int id = 0;

  double budgetLimit;
  bool blockOnLimit;

  AppSettingsEntity({
    this.budgetLimit = 0.0,
    this.blockOnLimit = false,
  });
}

@Entity()
class ChatMessageEntity {
  @Id()
  int id = 0;

  String content;
  String role; // 'user', 'assistant', 'system'
  @Property(type: PropertyType.date)
  DateTime timestamp;
  int? estimatedTokens;
  double? estimatedCost;

  final session = ToOne<ChatSessionEntity>();

  ChatMessageEntity({
    required this.content,
    required this.role,
    DateTime? timestamp,
    this.estimatedTokens,
    this.estimatedCost,
  }) : timestamp = timestamp ?? DateTime.now();
}
