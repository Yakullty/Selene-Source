class LiveChannel {
  final String id;
  final String tvgId;
  final String name;
  final String logo;
  final String group;
  final String url;
  final String catchup;
  final String catchupSource;
  final int? catchupDays;
  bool isFavorite;

  LiveChannel({
    required this.id,
    required this.tvgId,
    required this.name,
    required this.logo,
    required this.group,
    required this.url,
    this.catchup = '',
    this.catchupSource = '',
    this.catchupDays,
    this.isFavorite = false,
  });

  factory LiveChannel.fromJson(Map<String, dynamic> json) {
    return LiveChannel(
      id: json['id'] as String? ?? '',
      tvgId: json['tvgId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      logo: json['logo'] as String? ?? '',
      group: json['group'] as String? ?? '',
      url: json['url'] as String? ?? '',
      catchup: json['catchup'] as String? ?? '',
      catchupSource: json['catchupSource'] as String? ?? '',
      catchupDays: json['catchupDays'] as int?,
      isFavorite: json['isFavorite'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tvgId': tvgId,
      'name': name,
      'logo': logo,
      'group': group,
      'url': url,
      'catchup': catchup,
      'catchupSource': catchupSource,
      'catchupDays': catchupDays,
      'isFavorite': isFavorite,
    };
  }

  LiveChannel copyWith({
    String? id,
    String? tvgId,
    String? name,
    String? logo,
    String? group,
    String? url,
    String? catchup,
    String? catchupSource,
    int? catchupDays,
    bool? isFavorite,
  }) {
    return LiveChannel(
      id: id ?? this.id,
      tvgId: tvgId ?? this.tvgId,
      name: name ?? this.name,
      logo: logo ?? this.logo,
      group: group ?? this.group,
      url: url ?? this.url,
      catchup: catchup ?? this.catchup,
      catchupSource: catchupSource ?? this.catchupSource,
      catchupDays: catchupDays ?? this.catchupDays,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}

class LiveChannelGroup {
  final String name;
  final List<LiveChannel> channels;

  LiveChannelGroup({
    required this.name,
    required this.channels,
  });
}
