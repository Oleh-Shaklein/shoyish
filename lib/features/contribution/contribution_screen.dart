import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:mapmenu/core/network/database_service.dart';
import 'package:mapmenu/models/menu_item.dart';
import 'package:mapmenu/models/venue.dart';
import 'package:mapmenu/features/map/location_picker_screen.dart'; // Або відносний: import 'location_picker_screen.dart';

class ContributionScreen extends StatefulWidget {
  final LatLng initialCenter;

  const ContributionScreen({super.key, required this.initialCenter});

  @override
  State<ContributionScreen> createState() => _ContributionScreenState();
}

class _ContributionScreenState extends State<ContributionScreen> {
  final _venueNameController = TextEditingController();
  LatLng? _selectedLocation;
  final List<MenuItem> _tempMenuItems = [];

  // Контролери для тимчасового додавання позиції меню
  final _itemNameController = TextEditingController();
  final _itemCategoryController = TextEditingController();
  final _itemPriceController = TextEditingController();

  @override
  void dispose() {
    _venueNameController.dispose();
    _itemNameController.dispose();
    _itemCategoryController.dispose();
    _itemPriceController.dispose();
    super.dispose();
  }

  void _addTempMenuItem() {
    final name = _itemNameController.text;
    final category = _itemCategoryController.text;
    final price = double.tryParse(_itemPriceController.text) ?? 0.0;

    if (name.isNotEmpty && price > 0) {
      setState(() {
        _tempMenuItems.add(
          MenuItem(
            venueId: 0, // Тимчасовий ID, оскільки заклад ще не збережено
            name: name,
            category: category.isNotEmpty ? category : 'Інше',
            price: price,
            source: 'manual',
          ),
        );
        _itemNameController.clear();
        _itemCategoryController.clear();
        _itemPriceController.clear();
      });
    }
  }

  Future<void> _saveContribution() async {
    final venueName = _venueNameController.text;

    if (venueName.isEmpty || _selectedLocation == null || _tempMenuItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введіть назву, оберіть локацію та додайте хоча б одну позицію меню!')),
      );
      return;
    }

    // 1. Створюємо заклад зі статусом 'pending' (на модерацію)
    final newVenue = Venue(
      name: venueName,
      latitude: _selectedLocation!.latitude,
      longitude: _selectedLocation!.longitude,
      status: 'pending',
    );

    // Зберігаємо заклад і отримуємо його згенерований ID
    final venueId = await DatabaseService.instance.insertVenue(newVenue);

    // 2. Зберігаємо всі позиції меню, прив'язуючи їх до цього venueId
    for (var item in _tempMenuItems) {
      final finalItem = MenuItem(
        venueId: venueId,
        name: item.name,
        category: item.category,
        price: item.price,
        source: item.source,
      );
      await DatabaseService.instance.insertMenuItem(finalItem);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Заклад та меню успішно надіслано на модерацію!')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Додати новий заклад та меню')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('1. Інформація про заклад', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _venueNameController,
              decoration: const InputDecoration(
                labelText: 'Назва закладу (напр. Кав\'ярня "Фділь")',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Кнопка вибору локації на карті
            ElevatedButton.icon(
              onPressed: () async {
                final LatLng? result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LocationPickerScreen(initialCenter: widget.initialCenter),
                  ),
                );
                if (result != null) {
                  setState(() {
                    _selectedLocation = result;
                  });
                }
              },
              icon: const Icon(Icons.map),
              label: Text(_selectedLocation == null
                  ? 'Обрати локацію на карті'
                  : 'Локація обрана: ${_selectedLocation!.latitude.toStringAsFixed(3)}, ${_selectedLocation!.longitude.toStringAsFixed(3)}'),
            ),
            const Divider(height: 32),

            const Text('2. Додати позиції меню', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _itemNameController,
              decoration: const InputDecoration(labelText: 'Назва позиції (напр. Флет Вейт)'),
            ),
            TextField(
              controller: _itemCategoryController,
              decoration: const InputDecoration(labelText: 'Категорія (напр. Кава)'),
            ),
            TextField(
              controller: _itemPriceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Ціна (грн)'),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: _addTempMenuItem,
                icon: const Icon(Icons.add),
                label: const Text('Додати до списку'),
              ),
            ),
            const SizedBox(height: 16),

            // Список доданих позицій
            if (_tempMenuItems.isNotEmpty) ...[
              const Text('Сформоване меню:', style: TextStyle(fontWeight: FontWeight.bold)),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _tempMenuItems.length,
                itemBuilder: (context, index) {
                  final item = _tempMenuItems[index];
                  return ListTile(
                    title: Text(item.name),
                    subtitle: Text(item.category),
                    trailing: Text('${item.price} грн'),
                  );
                },
              ),
            ],

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                onPressed: _saveContribution,
                child: const Text('Надіслати на перевірку (Pending)'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}