class FavoriteAudio {
  final int? id;
  final String name;
  final String filePath;
  final DateTime createdAt;
  final int durationMs;

  const FavoriteAudio({
    this.id,
    required this.name,
    required this.filePath,
    required this.createdAt,
    required this.durationMs,
  });

  Duration get duration => Duration(milliseconds: durationMs);

  String get formattedDuration {
    final d = duration;
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String get formattedDate {
    final day = createdAt.day.toString().padLeft(2, '0');
    final month = createdAt.month.toString().padLeft(2, '0');
    final year = createdAt.year.toString();
    final hour = createdAt.hour.toString().padLeft(2, '0');
    final minute = createdAt.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'file_path': filePath,
      'created_at': createdAt.toIso8601String(),
      'duration_ms': durationMs,
    };
  }

  factory FavoriteAudio.fromMap(Map<String, dynamic> map) {
    return FavoriteAudio(
      id: map['id'] as int?,
      name: map['name'] as String,
      filePath: map['file_path'] as String,
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ??
          DateTime.now(),
      durationMs: (map['duration_ms'] as num?)?.toInt() ?? 0,
    );
  }

  FavoriteAudio copyWith({
    int? id,
    String? name,
    String? filePath,
    DateTime? createdAt,
    int? durationMs,
  }) {
    return FavoriteAudio(
      id: id ?? this.id,
      name: name ?? this.name,
      filePath: filePath ?? this.filePath,
      createdAt: createdAt ?? this.createdAt,
      durationMs: durationMs ?? this.durationMs,
    );
  }
}

