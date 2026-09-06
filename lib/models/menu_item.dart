class MenuItem {
  final int? id;
  final int venueId; // ID закладу на карті
  final String name; // Назва (напр. "Латте великий")
  final String category; // Категорія (напр. "Кава")
  final double price; // Ціна у гривнях
  final String source; // 'photo', 'pdf' або 'manual'

  MenuItem({
    this.id,
    required this.venueId,
    required this.name,
    required this.category,
    required this.price,
    required this.source,
  });

  // Конвертація для збереження в базу
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'venueId': venueId,
      'name': name,
      'category': category,
      'price': price,
      'source': source,
    };
  }

  // Створення об'єкта з рядка бази даних
  factory MenuItem.fromMap(Map<String, dynamic> map) {
    return MenuItem(
      id: map['id'],
      venueId: map['venueId'],
      name: map['name'],
      category: map['category'],
      price: map['price'],
      source: map['source'],
    );
  }
}