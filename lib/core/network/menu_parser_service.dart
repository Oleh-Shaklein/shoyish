import 'dart:convert';

// Модель для окремої страви або позиції меню
class MenuItemModel {
  final String name;
  final double price;
  final String? description;
  final String category;

  MenuItemModel({
    required this.name,
    required this.price,
    this.description,
    required this.category,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'price': price,
    'description': description,
    'category': category,
  };

  factory MenuItemModel.fromJson(Map<String, dynamic> json) {
    return MenuItemModel(
      name: json['name'] ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      description: json['description'],
      category: json['category'] ?? 'general',
    );
  }
}

class MenuParserService {
  /// Конвертує сирий текстовий рядок (наприклад, скопійований з сайту чи отриманий з фото)
  /// у структурований список об'єктів MenuItemModel за допомогою регулярних виразів.
  List<MenuItemModel> parseTextToMenu(String rawText, {String defaultCategory = 'Основне'}) {
    final List<MenuItemModel> parsedItems = [];
    final lines = rawText.split('\n');

    // Регулярний вираз для пошуку назви та ціни в одному рядку (напр., "Еспресо ... 45 грн" або "Латте - 65")
    final regex = RegExp(r'^(.*?)\s*[\.\-\–:]+\s*(\d+[\.,]?\d*)\s*(грн|UAH|₴)?$', caseSensitive: false);

    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;

      final match = regex.firstMatch(line);
      if (match != null) {
        final name = match.group(1)?.trim() ?? 'Страва';
        final priceStr = match.group(2)?.replaceAll(',', '.') ?? '0';
        final price = double.tryParse(priceStr) ?? 0.0;

        parsedItems.add(MenuItemModel(
          name: name,
          price: price,
          category: defaultCategory,
        ));
      } else {
        // Якщо ціну не знайдено, але рядок схожий на назву страви
        if (line.length > 2 && !line.toLowerCase().contains('меню')) {
          parsedItems.add(MenuItemModel(
            name: line,
            price: 0.0, // Ціну можна буде уточнити пізніше
            category: defaultCategory,
          ));
        }
      }
    }

    return parsedItems;
  }

  /// Імітація конвертації через майбутній LLM/Vision API (у вигляді JSON-структури)
  Future<List<MenuItemModel>> simulateAiParsingFromImage(String imagePath) async {
    // Тут у майбутньому буде надсилання фото на Gemini Vision API
    await Future.delayed(const Duration(seconds: 1)); // Імітація мережевої затримки

    // Повертаємо тестовий структурований результат розпізнавання меню
    return [
      MenuItemModel(name: 'Капучино велике', price: 65.0, description: 'Подвійний еспресо з молочною піною', category: 'Кава'),
      MenuItemModel(name: 'Флет Вайт', price: 70.0, description: 'На основі подвійного рістрето', category: 'Кава'),
      MenuItemModel(name: 'Круасан класичний', price: 55.0, description: 'Французька випічка', category: 'Випічка'),
    ];
  }
}