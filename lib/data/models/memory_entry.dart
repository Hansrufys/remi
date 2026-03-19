
enum EntryType {
  actionable, // task
  insight,    // personal/social fact
  pattern,    // recurring thought
  unknown
}

class MemoryEntry {
  final int? id;
  final String uuid;
  final String rawText;
  final EntryType type;
  final String summary;
  final List<String> tags;
  final String? personMentioned;
  final DateTime createdAt;
  final bool isCompleted;
  final String? taskDescription;
  final String? timeHint;
  final String? insightDetail;
  final bool isProcessing;
  final String? spinoReaction; // pin | catch | glow
  final String? spinoNotification;
  final DateTime? remindAt;

  MemoryEntry({
    required this.uuid,
    this.id,
    required this.rawText,
    required this.type,
    required this.summary,
    required this.createdAt,
    this.isCompleted = false,
    this.personMentioned,
    this.tags = const [],
    this.taskDescription,
    this.timeHint,
    this.insightDetail,
    this.isProcessing = false,
    this.spinoReaction,
    this.spinoNotification,
    this.remindAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'uuid': uuid,
      'raw_text': rawText,
      'type': type.name,
      'summary': summary,
      'created_at': createdAt.toIso8601String(),
      'is_completed': isCompleted ? 1 : 0,
      'person_mentioned': personMentioned,
      'tags': tags.join(','),
      'task_description': taskDescription,
      'time_hint': timeHint,
      'insight_detail': insightDetail,
      'is_processing': isProcessing ? 1 : 0,
      'spino_reaction': spinoReaction,
      'spino_notification': spinoNotification,
      'remind_at': remindAt?.toIso8601String(),
    };
  }

  factory MemoryEntry.fromMap(Map<String, dynamic> map) {
    return MemoryEntry(
      id: map['id'],
      uuid: map['uuid'],
      rawText: map['raw_text'],
      type: EntryType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => EntryType.unknown,
      ),
      summary: map['summary'],
      createdAt: DateTime.parse(map['created_at']),
      isCompleted: (map['is_completed'] ?? 0) == 1,
      personMentioned: map['person_mentioned'],
      tags: (map['tags'] as String?)?.split(',').where((t) => t.isNotEmpty).toList() ?? [],
      taskDescription: map['task_description'],
      timeHint: map['time_hint'],
      insightDetail: map['insight_detail'],
      isProcessing: (map['is_processing'] ?? 0) == 1,
      spinoReaction: map['spino_reaction'],
      spinoNotification: map['spino_notification'],
      remindAt: map['remind_at'] != null ? DateTime.tryParse(map['remind_at']) : null,
    );
  }

  MemoryEntry copyWith({
    int? id,
    String? uuid,
    String? rawText,
    EntryType? type,
    String? summary,
    DateTime? createdAt,
    bool? isCompleted,
    String? personMentioned,
    List<String>? tags,
    String? taskDescription,
    String? timeHint,
    String? insightDetail,
    bool? isProcessing,
    String? spinoReaction,
    String? spinoNotification,
    DateTime? remindAt,
  }) {
    return MemoryEntry(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      rawText: rawText ?? this.rawText,
      type: type ?? this.type,
      summary: summary ?? this.summary,
      createdAt: createdAt ?? this.createdAt,
      isCompleted: isCompleted ?? this.isCompleted,
      personMentioned: personMentioned ?? this.personMentioned,
      tags: tags ?? this.tags,
      taskDescription: taskDescription ?? this.taskDescription,
      timeHint: timeHint ?? this.timeHint,
      insightDetail: insightDetail ?? this.insightDetail,
      isProcessing: isProcessing ?? this.isProcessing,
      spinoReaction: spinoReaction ?? this.spinoReaction,
      spinoNotification: spinoNotification ?? this.spinoNotification,
      remindAt: remindAt ?? this.remindAt,
    );
  }
}
