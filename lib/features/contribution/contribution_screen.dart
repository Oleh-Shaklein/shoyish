import 'package:flutter/material.dart';
import 'package:mapmenu/features/contribution/manual_menu_screen.dart';
import 'package:latlong2/latlong.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mapmenu/core/network/database_service.dart';
import 'package:mapmenu/models/venue.dart';
import 'package:mapmenu/features/map/location_picker_screen.dart';

// Екран 1: Головний хаб вибору способу додавання
class ContributionScreen extends StatefulWidget {
  final LatLng initialCenter;

  const ContributionScreen({super.key, required this.initialCenter});

  @override
  State<ContributionScreen> createState() => _ContributionScreenState();
}

class _ContributionScreenState extends State<ContributionScreen> {
  final _venueNameController = TextEditingController();
  LatLng? _selectedLocation;

  // Зберігаємо тип обраного джерела та дані
  String _sourceType = ''; // 'manual', 'photo', 'url'
  dynamic _sourceData;     // Тут можуть бути або список MenuItem, або XFile, або String (url)
  String _sourceDescription = 'Не обрано';

  @override
  void dispose() {
    _venueNameController.dispose();
    super.dispose();
  }

  Future<void> _saveContribution() async {
    final venueName = _venueNameController.text;

    if (venueName.isEmpty || _selectedLocation == null || _sourceType.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введіть назву, оберіть локацію та додайте меню будь-яким зручним способом!')),
      );
      return;
    }

    // Створюємо заклад зі статусом 'pending'
    final newVenue = Venue(
      name: venueName,
      latitude: _selectedLocation!.latitude,
      longitude: _selectedLocation!.longitude,
      status: 'pending',
    );

    final venueId = await DatabaseService.instance.insertVenue(newVenue);

    // Обробка залежно від обраного джерела
    if (_sourceType == 'manual') {
      final List items = _sourceData;
      for (var item in items) {
        await DatabaseService.instance.insertMenuItem(item.copyWith(venueId: venueId));
      }
    } else if (_sourceType == 'photo') {
      XFile image = _sourceData;
      // Логіка відправки фото в AI/на сервер
    } else if (_sourceType == 'url') {
      String url = _sourceData;
      // Логіка парсингу сайту за посиланням
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
      appBar: AppBar(title: const Text('Додати новий заклад')),
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
                labelText: 'Назва закладу (напр. Кав\'ярня)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

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

            const Text('2. Спосіб додавання меню', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            // Кнопка 1: Ручне заповнення
            ListTile(
              tileColor: Colors.grey.shade100,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              leading: const Icon(Icons.edit_note, color: Colors.orange),
              title: const Text('Заповнити вручну'),
              subtitle: Text(_sourceType == 'manual' ? _sourceDescription : 'Ввести позиції списком'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ManualMenuScreen()),
                );
                if (result != null) {
                  setState(() {
                    _sourceType = 'manual';
                    _sourceData = result; // Список MenuItem
                    _sourceDescription = 'Додано позицій: ${result.length}';
                  });
                }
              },
            ),
            const SizedBox(height: 8),

            // Кнопка 2: Завантаження фото (Камера / Галерея)
            ListTile(
              tileColor: Colors.grey.shade100,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              leading: const Icon(Icons.camera_alt, color: Colors.orange),
              title: const Text('Завантажити фото меню'),
              subtitle: Text(_sourceType == 'photo' ? _sourceDescription : 'Зробити фото або з галереї'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () async {
                final ImageSource? source = await showModalBottomSheet<ImageSource>(
                  context: context,
                  builder: (context) => SafeArea(
                    child: Wrap(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.camera),
                          title: const Text('Зробити фото'),
                          onTap: () => Navigator.pop(context, ImageSource.camera),
                        ),
                        ListTile(
                          leading: const Icon(Icons.photo_library),
                          title: const Text('Обрати з галереї'),
                          onTap: () => Navigator.pop(context, ImageSource.gallery),
                        ),
                      ],
                    ),
                  ),
                );

                if (source != null) {
                  final picker = ImagePicker();
                  final image = await picker.pickImage(source: source);
                  if (image != null) {
                    setState(() {
                      _sourceType = 'photo';
                      _sourceData = image;
                      _sourceDescription = 'Фото: ${image.name}';
                    });
                  }
                }
              },
            ),
            const SizedBox(height: 8),

            // Кнопка 3: Завантаження посилання (QR / URL)
            ListTile(
              tileColor: Colors.grey.shade100,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              leading: const Icon(Icons.link, color: Colors.orange),
              title: const Text('Посилання на меню (QR-код)'),
              subtitle: Text(_sourceType == 'url' ? _sourceDescription : 'Вставити URL онлайн-меню'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () async {
                final String? url = await showDialog<String>(
                  context: context,
                  builder: (context) {
                    final controller = TextEditingController();
                    return AlertDialog(
                      title: const Text('Введіть посилання на меню'),
                      content: TextField(
                        controller: controller,
                        decoration: const InputDecoration(hintText: 'https://...'),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Скасувати'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, controller.text),
                          child: const Text('Зберегти'),
                        ),
                      ],
                    );
                  },
                );

                if (url != null && url.isNotEmpty) {
                  setState(() {
                    _sourceType = 'url';
                    _sourceData = url;
                    _sourceDescription = url;
                  });
                }
              },
            ),

            const SizedBox(height: 32),
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