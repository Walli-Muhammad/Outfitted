import 'outfit_suggestion.dart';

class WeatherInfo {
  final String city;
  final int tempC;
  final String condition;
  final int humidity;

  const WeatherInfo({
    required this.city,
    required this.tempC,
    required this.condition,
    required this.humidity,
  });

  factory WeatherInfo.fromJson(Map<String, dynamic> json) {
    return WeatherInfo(
      city: json['city'] as String? ?? '',
      tempC: (json['temp_c'] as num?)?.toInt() ?? 25,
      condition: json['condition'] as String? ?? 'clear',
      humidity: (json['humidity'] as num?)?.toInt() ?? 60,
    );
  }
}

class OutfitResponse {
  final WeatherInfo weather;
  final List<OutfitSuggestion> suggestions;
  final String? message;

  const OutfitResponse({
    required this.weather,
    required this.suggestions,
    this.message,
  });

  factory OutfitResponse.fromJson(Map<String, dynamic> json) {
    final weatherJson = json['weather'] as Map<String, dynamic>? ?? {};
    final rawSuggestions = json['suggestions'] as List? ?? [];

    return OutfitResponse(
      weather: WeatherInfo.fromJson(weatherJson),
      suggestions: rawSuggestions
          .map((s) => OutfitSuggestion.fromJson(s as Map<String, dynamic>))
          .toList(),
      message: json['message'] as String?,
    );
  }
}
