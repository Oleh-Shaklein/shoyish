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
    // Львів
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
    PlaceModel(
      id: '3',
      name: 'П’яна Вишня',
      category: 'cafe',
      city: 'Львів',
      tags: ['настоянки', 'вишня', 'алкоголь'],
      lat: 49.8413,
      lng: 24.0302,
    ),
    PlaceModel(
      id: '4',
      name: 'Ресторан «Криївка»',
      category: 'restaurant',
      city: 'Львів',
      tags: ['українська кухня', 'м’ясо', 'борщ'],
      lat: 49.8406,
      lng: 24.0309,
    ),
    PlaceModel(
      id: '5',
      name: 'Пузата Хата',
      category: 'fastfood',
      city: 'Львів',
      tags: ['фастфуд', 'комплексні обіди', 'вареники'],
      lat: 49.8420,
      lng: 24.0250,
    ),

    // Київ
    PlaceModel(
      id: '6',
      name: 'Кав’ярня «Жовтень»',
      category: 'cafe',
      city: 'Київ',
      tags: ['кава', 'флет уайт', 'десерти'],
      lat: 50.4645,
      lng: 30.5185,
    ),
    PlaceModel(
      id: '7',
      name: 'Люблю дядю Фраді',
      category: 'restaurant',
      city: 'Київ',
      tags: ['європейська кухня', 'стейки', 'вино'],
      lat: 50.4450,
      lng: 30.5200,
    ),
    PlaceModel(
      id: '8',
      name: 'Пузата Хата (Хрещатик)',
      category: 'fastfood',
      city: 'Київ',
      tags: ['фастфуд', 'обіди', 'котлета по-київськи'],
      lat: 50.4501,
      lng: 30.5234,
    ),

    // Одеса
    PlaceModel(
      id: '9',
      name: 'Компот',
      category: 'cafe',
      city: 'Одеса',
      tags: ['сніданки', 'компот', 'випічка'],
      lat: 46.4845,
      lng: 30.7350,
    ),
    PlaceModel(
      id: '10',
      name: 'Дача',
      category: 'restaurant',
      city: 'Одеса',
      tags: ['одеська кухня', 'риба', 'тераса'],
      lat: 46.4350,
      lng: 30.7510,
    ),
  ];

  void initAgent() {
    const apiKey = String.fromEnvironment(
      'GEMINI_API_KEY',
      defaultValue: 'token',
    );

    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
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
        : foundPlaces.map((p) => "Заклад: ${p.name}, категорія: ${p.category}, теги: ${p.tags.join(', ')}").join('\n');

    final prompt = "Питання користувача: '$userQuery'. "
        "Ось дані з нашої локальної бази даних для міста $cityName:\n$contextData\n"
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