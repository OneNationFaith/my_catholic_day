class Prayer {
  const Prayer({
    required this.id,
    required this.title,
    required this.category,
    required this.scripture,
    required this.scriptureReference,
    required this.reflection,
    required this.prayer,
    required this.action,
    this.image = '',
    this.audio = '',
    this.tags = const [],
    this.favorite = false,
    this.liturgicalSeason = '',
  });

  final String id;
  final String title;
  final String category;
  final String scripture;
  final String scriptureReference;
  final String reflection;
  final String prayer;
  final String action;

  final String image;
  final String audio;
  final List<String> tags;
  final bool favorite;
  final String liturgicalSeason;

  Prayer copyWith({
    String? id,
    String? title,
    String? category,
    String? scripture,
    String? scriptureReference,
    String? reflection,
    String? prayer,
    String? action,
    String? image,
    String? audio,
    List<String>? tags,
    bool? favorite,
    String? liturgicalSeason,
  }) {
    return Prayer(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      scripture: scripture ?? this.scripture,
      scriptureReference: scriptureReference ?? this.scriptureReference,
      reflection: reflection ?? this.reflection,
      prayer: prayer ?? this.prayer,
      action: action ?? this.action,
      image: image ?? this.image,
      audio: audio ?? this.audio,
      tags: tags ?? this.tags,
      favorite: favorite ?? this.favorite,
      liturgicalSeason: liturgicalSeason ?? this.liturgicalSeason,
    );
  }
}