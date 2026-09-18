import 'package:flutter/material.dart';
import 'package:mapmenu/models/menu_item.dart'; // Підключіть вашу модель

class ManualMenuScreen extends StatefulWidget {
  const ManualMenuScreen({super.key});

  @override
  State<ManualMenuScreen> createState() => _ManualMenuScreenState();
}

class _ManualMenuScreenState extends State<ManualMenuScreen> {
  final List<MenuItem> _tempMenuItems = []; // Використовуємо вашу модель MenuItem
  final _itemNameController = TextEditingController();
  final _itemCategoryController = TextEditingController();
  final _itemPriceController = TextEditingController();

  @override
  void dispose() {
    _itemNameController.dispose();
    _itemCategoryController.dispose();
    _itemPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ручне введення меню'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () => Navigator.pop(context, _tempMenuItems), // Повертаємо List<MenuItem>
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _itemNameController, decoration: const InputDecoration(labelText: 'Назва позиції')),
            TextField(controller: _itemCategoryController, decoration: const InputDecoration(labelText: 'Категорія')),
            TextField(controller: _itemPriceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Ціна')),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                final name = _itemNameController.text;
                final category = _itemCategoryController.text;
                final price = double.tryParse(_itemPriceController.text) ?? 0.0;

                if (name.isNotEmpty && price > 0) {
                  setState(() {
                    _tempMenuItems.add(
                      MenuItem(
                        venueId: 0,
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
              },
              child: const Text('Додати позицію'),
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
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
            ),
          ],
        ),
      ),
    );
  }
}