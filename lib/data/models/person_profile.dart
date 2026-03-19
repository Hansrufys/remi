/// Plain Dart model for person soul profiles (stored in SQLite via sqflite).
class PersonProfile {
  final int? id;
  final String uuid;
  final String name;
  final List<String> insightNotes;
  final List<DateTime> insightDates;
  final DateTime? lastMentionedAt;
  final DateTime createdAt;
  final String? avatarInitial;

  const PersonProfile({
    this.id,
    required this.uuid,
    required this.name,
    this.insightNotes = const [],
    this.insightDates = const [],
    this.lastMentionedAt,
    required this.createdAt,
    this.avatarInitial,
  });

  Map<String, dynamic> toMap() => {
        'uuid': uuid,
        'name': name,
        'insight_notes': insightNotes.join('\u001F'), // unit separator
        'insight_dates':
            insightDates.map((d) => d.toIso8601String()).join(','),
        'last_mentioned_at': lastMentionedAt?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
        'avatar_initial': avatarInitial,
      };

  factory PersonProfile.fromMap(Map<String, dynamic> m) {
    final notesRaw = m['insight_notes'] as String? ?? '';
    final datesRaw = m['insight_dates'] as String? ?? '';
    return PersonProfile(
      id: m['id'] as int?,
      uuid: m['uuid'] as String? ?? '',
      name: m['name'] as String? ?? '',
      insightNotes: notesRaw.isEmpty
          ? []
          : notesRaw.split('\u001F').where((s) => s.isNotEmpty).toList(),
      insightDates: datesRaw.isEmpty
          ? []
          : datesRaw
              .split(',')
              .map((s) => DateTime.tryParse(s) ?? DateTime.now())
              .toList(),
      lastMentionedAt:
          DateTime.tryParse(m['last_mentioned_at'] as String? ?? ''),
      createdAt:
          DateTime.tryParse(m['created_at'] as String? ?? '') ?? DateTime.now(),
      avatarInitial: m['avatar_initial'] as String?,
    );
  }

  PersonProfile copyWithNote(String note) => PersonProfile(
        id: id,
        uuid: uuid,
        name: name,
        insightNotes: [...insightNotes, note],
        insightDates: [...insightDates, DateTime.now()],
        lastMentionedAt: DateTime.now(),
        createdAt: createdAt,
        avatarInitial: avatarInitial ?? (name.isNotEmpty ? name[0].toUpperCase() : '?'),
      );

  PersonProfile removeNoteAtIndex(int index) {
    if (index < 0 || index >= insightNotes.length) return this;
    final newNotes = List<String>.from(insightNotes)..removeAt(index);
    final newDates = List<DateTime>.from(insightDates);
    if (index < newDates.length) newDates.removeAt(index);
    
    return PersonProfile(
      id: id,
      uuid: uuid,
      name: name,
      insightNotes: newNotes,
      insightDates: newDates,
      lastMentionedAt: lastMentionedAt,
      createdAt: createdAt,
      avatarInitial: avatarInitial,
    );
  }
}
