import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

// Модель даних
class PlaceModel {
  final String id;
  final String name;
  final String category;
  final String city;
  final List<String> tags;
  final double lat;
  final double lng;

  PlaceModel({
    required this.id,
    required this.name,
    required this.category,
    required this.city,
    required this.tags,
    required this.lat,
    required this.lng,
  });
}

// Сервіс для роботи з Gemini API та локальною базою
class AiAgentService {
  GenerativeModel? _model;
  ChatSession? _chatSession;

  final List<PlaceModel> _localDatabase = [
    PlaceModel(
      id: '1',
      name: 'Львівська Копальня Кави',
      category: 'cafe',
      city: 'Львів',
      tags: ['кава', 'латте', 'десерти'],
      lat: 49.8415,
      lng: 24.0312,
    ),
    PlaceModel(
      id: '2',
      name: 'Штрудель Видавництво',
      category: 'cafe',
      city: 'Львів',
      tags: ['кава', 'випічка', 'штрудель'],
      lat: 49.8401,
      lng: 24.0305,
    ),
  ];

  void initAgent() {
    const apiKey = String.fromEnvironment(
      'GEMINI_API_KEY',
      defaultValue: '',
    );

    _model = GenerativeModel(
      model: 'gemini-3.6-flash',
      apiKey: apiKey,
      systemInstruction: Content.system(
        'Ти — асистент MapMenu. Завжди спирайся на надані локальні дані і не вигадуй заклади.',
      ),
    );

    _chatSession = _model!.startChat();
  }

  List<PlaceModel> searchVenues(String query, String cityName) {
    final lowerQuery = query.toLowerCase().trim();

    return _localDatabase.where((place) {
      bool matchesCity = place.city.toLowerCase() == cityName.toLowerCase();
      if (lowerQuery.isEmpty) return matchesCity;

      bool matchesKeyword = place.name.toLowerCase().contains(lowerQuery) ||
          place.tags.any((tag) => lowerQuery.contains(tag));

      return matchesCity && matchesKeyword;
    }).toList();
  }

  Future<String> askAgent(String userQuery, String cityName) async {
    if (_chatSession == null) {
      initAgent();
    }

    final foundPlaces = searchVenues(userQuery, cityName);

    String contextData = foundPlaces.isEmpty
        ? "У локальній базі нічого не знайдено за цим запитом."
        : foundPlaces.map((p) => "Заклад: ${p.name}, категорії/теги: ${p.tags.join(', ')}").join('\n');

    final prompt = "Питання користувача: '$userQuery'. "
        "Ось дані з нашої локальної бази даних:\n$contextData\n"
        "Дай відповідь користувачу українською мовою, спираючись ТІЛЬКИ на ці дані.";

    try {
      final response = await _chatSession!.sendMessage(Content.text(prompt));
      print("Відповідь від моделі: ${response.text}");
      return response.text ?? 'Не вдалося отримати відповідь.';
    } catch (e, stackTrace) {
      print("ПОМИЛКА ПРИ ЗАПИТІ: $e");
      print("СТЕК ПОМИЛКИ: $stackTrace");
      return "Сталася помилка при зверненні до штучного інтелекту: $e";
    }
  }
}

// Провайдер для зручного доступу через Riverpod у віджетах
final aiAgentServiceProvider = Provider<AiAgentService>((ref) {
  return AiAgentService();
});