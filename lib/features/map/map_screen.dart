import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../settings/settings_screen.dart';
import '../aichat/aichat_service.dart';

// Допоміжна структура для зберігання даних про місто
class CityLocation {
  final String name;
  final LatLng center;
  final double zoom;

  const CityLocation({
    required this.name,
    required this.center,
    this.zoom = 13.0,
  });
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final AiAgentService _aiAgent = AiAgentService();
  final TextEditingController _aiQueryController = TextEditingController();

  // Список міст з їхніми реальними центральними координатами та зумом
  final List<CityLocation> _cities = [
    CityLocation(name: 'Львів', center: LatLng(49.8397, 24.0297)),
    CityLocation(name: 'Київ', center: LatLng(50.450254, 30.524287)),
    CityLocation(name: 'Одеса', center: LatLng(46.4825, 30.7233)),
    CityLocation(name: 'Дніпро', center: LatLng(48.4647, 35.0462)),
    CityLocation(name: 'Харків', center: LatLng(49.9935, 36.2304)),
    CityLocation(name: 'Вінниця', center: LatLng(49.2331, 28.4682)),
    CityLocation(name: 'Ужгород', center: LatLng(48.6208, 22.2879)),
    CityLocation(name: 'Івано-Франківськ', center: LatLng(48.9226, 24.7111)),
    CityLocation(name: 'Чернівці', center: LatLng(48.2921, 25.9358)),
    CityLocation(name: 'Варшава', center: LatLng(52.231965, 21.006072)),
  ];

  late CityLocation _selectedCity;

  @override
  void initState() {
    super.initState();
    _selectedCity = _cities.first;
    _aiAgent.initAgent(); // Ініціалізуємо агента при старті екрану
  }

  @override
  void dispose() {
    // Прибираємо _aiAgent.dispose(), оскільки сервіс не має цього методу
    _aiQueryController.dispose();
    super.dispose();
  }

  // Стани для фільтрів (чекбокси)
  bool _filterCafe = true;
  bool _filterRestaurant = true;
  bool _filterFastFood = false;

  // Масив значень радіусу (у кілометрах)
  final List<double> _radiusSteps = [
    0.05, 0.075, 0.1, 0.15, 0.2, 0.3, 0.5, 0.75,
    1.0, 1.5, 2.0, 3.0, 5.0, 7.5, 10.0, 15.0,
    20.0, 25.0, 28.0, 30.0
  ];

  int _radiusIndex = 8; // 1 км за замовчуванням

  String _formatRadius(double value) {
    if (value < 1.0) {
      return '${(value * 1000).toInt()} м';
    } else {
      return '$value км';
    }
  }

  // Модальне вікно вибору міст
  void _showCitySelectionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          height: 400,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text('Виберіть місто', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  itemCount: _cities.length,
                  itemBuilder: (context, index) {
                    final city = _cities[index];
                    final isSelected = city.name == _selectedCity.name;
                    return ListTile(
                      leading: Icon(Icons.location_city, color: isSelected ? Colors.orange : Colors.grey),
                      title: Text(
                        city.name,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Colors.orange : Colors.black87,
                        ),
                      ),
                      trailing: isSelected ? const Icon(Icons.check, color: Colors.orange) : null,
                      onTap: () {
                        setState(() {
                          _selectedCity = city;
                          // Переміщуємо камеру карти на центр вибраного міста
                          _mapController.move(city.center, city.zoom);
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Вікно фільтрів
  void _showFiltersBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            return Container(
              padding: const EdgeInsets.all(20),
              height: 320,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Фільтр закладу', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Divider(),
                  CheckboxListTile(
                    title: const Text('Кафе / Кав\'ярні'),
                    value: _filterCafe,
                    onChanged: (val) {
                      setStateModal(() => _filterCafe = val ?? true);
                      setState(() {});
                    },
                  ),
                  CheckboxListTile(
                    title: const Text('Ресторани / Піцерії'),
                    value: _filterRestaurant,
                    onChanged: (val) {
                      setStateModal(() => _filterRestaurant = val ?? true);
                      setState(() {});
                    },
                  ),
                  CheckboxListTile(
                    title: const Text('Забігайлівки / Фастфуд'),
                    value: _filterFastFood,
                    onChanged: (val) {
                      setStateModal(() => _filterFastFood = val ?? false);
                      setState(() {});
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Вікно радіусу
  void _showRadiusBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            double currentVal = _radiusSteps[_radiusIndex];
            return Container(
              padding: const EdgeInsets.all(20),
              height: 220,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Радіус пошуку: ${_formatRadius(currentVal)}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Slider(
                    value: _radiusIndex.toDouble(),
                    min: 0,
                    max: (_radiusSteps.length - 1).toDouble(),
                    divisions: _radiusSteps.length - 1,
                    label: _formatRadius(currentVal),
                    onChanged: (value) {
                      setStateModal(() {
                        _radiusIndex = value.toInt();
                      });
                      setState(() {});
                    },
                  ),
                  const Text(
                    'Оптимальний вибір дистанції пошуку для ШІ',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. ВЕКТОРНИЙ СТИЛЬ / ОДНОМАНІТНІСТЬ КОЛЬОРУ ЧЕРЕЗ ФІЛЬТР
          ColorFiltered(
            colorFilter: const ColorFilter.matrix(<double>[
              0.2126, 0.7152, 0.0722, 0, 0,
              0.2126, 0.7152, 0.0722, 0, 0,
              0.2126, 0.7152, 0.0722, 0, 0,
              0,      0,      0,      1, 0,
            ]),
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _selectedCity.center,
                initialZoom: _selectedCity.zoom,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.mapmenu',
                ),
              ],
            ),
          ),

          // 2. ВЕРХНЯ ПАНЕЛЬ (Вхід, Вибір міста з шторкою, Налаштування)
          Positioned(
            top: 45,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Кнопка входу
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.key, size: 18),
                  label: const Text('Вхід'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                  ),
                ),

                // Компактний селектор міст (викликає шторку _showCitySelectionSheet)
                GestureDetector(
                  onTap: () => _showCitySelectionSheet(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))
                      ],
                    ),
                    child: Row(
                      children: [
                        const Text('📍 ', style: TextStyle(fontSize: 14)),
                        Text(
                          _selectedCity.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_drop_down, size: 20, color: Colors.black54),
                      ],
                    ),
                  ),
                ),

                // Кнопка налаштувань
                IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SettingsScreen()),
                    );
                  },
                  icon: const Icon(Icons.settings),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                  ),
                ),
              ],
            ),
          ),

          // 3. ЛІВА ПАНЕЛЬ НАВІГАЦІЇ (Масштабування)
          Positioned(
            left: 16,
            top: 120,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'zoom_in',
                  onPressed: () {
                    final newZoom = _mapController.camera.zoom + 1;
                    _mapController.move(_mapController.camera.center, newZoom);
                  },
                  child: const Icon(Icons.add),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'zoom_out',
                  onPressed: () {
                    final newZoom = _mapController.camera.zoom - 1;
                    _mapController.move(_mapController.camera.center, newZoom);
                  },
                  child: const Icon(Icons.remove),
                ),
              ],
            ),
          ),

          // 4. НИЖНЯ ПАНЕЛЬ: Кнопки винесені НАД рядок ШІ (зліва та справа)
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Рядок швидких кнопок над полем вводу (зліва — фільтри, справа — радіус)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Кнопка фільтрів
                      FloatingActionButton.extended(
                        heroTag: 'filter_btn',
                        onPressed: () => _showFiltersBottomSheet(context),
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black87,
                        elevation: 4,
                        icon: const Icon(Icons.tune, size: 18, color: Colors.orange),
                        label: const Text('Фільтри', style: TextStyle(fontSize: 12)),
                      ),

                      // Кнопка радіусу (показує поточний обраний радіус)
                      FloatingActionButton.extended(
                        heroTag: 'radius_btn',
                        onPressed: () => _showRadiusBottomSheet(context),
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black87,
                        elevation: 4,
                        icon: const Icon(Icons.radar, size: 18, color: Colors.orange),
                        label: Text(_formatRadius(_radiusSteps[_radiusIndex]), style: const TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ),

                // Центральний рядок ШІ-запиту на всю ширину
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: const [
                      BoxShadow(color: Colors.black38, blurRadius: 6, offset: Offset(0, 3))
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.auto_awesome, color: Colors.orange),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _aiQueryController, // Тільки один контролер
                          decoration: const InputDecoration(
                            hintText: 'Запит ШІ (напр. найдешевше латте)...',
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () async {
                          final query = _aiQueryController.text;
                          if (query.isNotEmpty) {
                            // Показуємо індикатор завантаження або просто чекаємо відповідь
                            final result = await _aiAgent.askAgent(query, _selectedCity.name);

                            // Очищаємо поле вводу
                            _aiQueryController.clear();

                            // Закриваємо клавіатуру
                            FocusScope.of(context).unfocus();

                            // Викликаємо шторку з результатом
                            if (mounted) {
                              _showAiResponseSheet(context, result);
                            }
                          }
                        },
                        icon: const Icon(Icons.send, color: Colors.orange),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAiResponseSheet(BuildContext context, String responseText) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_awesome, color: Colors.orange),
                  const SizedBox(width: 8),
                  const Text(
                    'Відповідь агента MapMenu',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 8),
              // Сам текст відповіді від LLM
              Text(
                responseText,
                style: const TextStyle(fontSize: 16, height: 1.4),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

}