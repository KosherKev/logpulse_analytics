class ApiConnectionProfile {
  final String id;
  final String name;
  final String baseUrl;
  final String apiKey;

  ApiConnectionProfile({
    required this.id,
    required this.name,
    required this.baseUrl,
    required this.apiKey,
  });

  factory ApiConnectionProfile.fromJson(Map<String, dynamic> json) {
    return ApiConnectionProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      baseUrl: json['baseUrl'] as String,
      apiKey: json['apiKey'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'baseUrl': baseUrl,
      'apiKey': apiKey,
    };
  }

  ApiConnectionProfile copyWith({
    String? id,
    String? name,
    String? baseUrl,
    String? apiKey,
  }) {
    return ApiConnectionProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      baseUrl: baseUrl ?? this.baseUrl,
      apiKey: apiKey ?? this.apiKey,
    );
  }
}

