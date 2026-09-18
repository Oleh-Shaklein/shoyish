import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../settings/settings_screen.dart';
import '../aichat/aichat_service.dart';
import '../auth/auth_screen.dart';
import 'package:geolocator/geolocator.dart';

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
  bool _isAiPanelExpanded = false;
  String _aiResponseText = '';

  // Додайте ці змінні у _MapScreenState:
  LatLng? _userLocation;
  bool _isLoadingLocation = false;

// Метод для отримання поточного положення
  Future<void> _getUserLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Увімкніть службові геолокації (GPS)')),
        );
        setState(() => _isLoadingLocation = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _isLoadingLocation = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() => _isLoadingLocation = false);
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
        _isLoadingLocation = false;
      });

      // Центруємо карту на користувача та наближаємо
      _mapController.move(_userLocation!, 15.0);

    } catch (e) {
      setState(() => _isLoadingLocation = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Помилка отримання GPS: $e')),
      );
    }
  }

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

  // Вікно з інформацією про вибраний заклад
  void _showVenueDetails(BuildContext context, PlaceModel place) {
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
                  Icon(
                    place.category == 'cafe'
                        ? Icons.coffee
                        : place.category == 'restaurant'
                        ? Icons.restaurant
                        : Icons.fastfood,
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      place.name,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 4),
              Text(
                'Категорія: ${place.category.toUpperCase()}',
                style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Text(
                'Теги: ${place.tags.join(', ')}',
                style: const TextStyle(color: Colors.black87, fontSize: 14),
              ),
              const SizedBox(height: 20),

              // Кнопка переходу до меню
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context); // Закриваємо шторку карти

                    // ТУТ ПЕРЕХІД ДО ЕКРАНУ МЕНЮ
                    // Наприклад: Navigator.push(context, MaterialPageRoute(builder: (c) => MenuScreen(place: place)));

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Перехід до меню закладу: ${place.name}')),
                    );
                  },
                  icon: const Icon(Icons.menu_book, size: 18),
                  label: const Text('Переглянути меню', style: TextStyle(fontSize: 15)),
                ),
              ),
            ],
          ),
        );
      },
    );
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

                // ШАР МАРКЕРІВ З БАЗИ ДАНИХ ШІ АГЕНТА
                MarkerLayer(
                    markers: [
                    // 👉 ДОДАЙТЕ ЦЕЙ УСІЧЕНИЙ БЛОК НА ПОЧАТАК МАСИВУ МАРКЕРІВ:
                    if (_userLocation != null)
                      Marker(
                      point: _userLocation!,
                      width: 30,
                      height: 30,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: const [
                            BoxShadow(blurRadius: 6, color: Colors.black26, offset: Offset(0, 2))
                          ],
                        ),
                      ),
                    ),
                  ..._aiAgent.searchVenues('', _selectedCity.name)
                      .where((place) {
                    // Фільтрація за категоріями з чекбоксів
                    if (place.category == 'cafe' && !_filterCafe) return false;
                    if (place.category == 'restaurant' && !_filterRestaurant) return false;
                    if (place.category == 'fastfood' && !_filterFastFood) return false;
                    return true;
                  })
                      .map((place) {
                    // Визначаємо іконку та колір залежно від категорії у PlaceModel
                    IconData iconData = Icons.restaurant;
                    Color markerColor = Colors.orange;

                    if (place.category == 'cafe') {
                      iconData = Icons.coffee;
                      markerColor = Colors.brown;
                    } else if (place.category == 'fastfood') {
                      iconData = Icons.fastfood;
                      markerColor = Colors.redAccent;
                    }

                    return Marker(
                      point: LatLng(place.lat, place.lng),
                      width: 40,
                      height: 40,
                      child: GestureDetector(
                        onTap: () {
                          // ЗАМІСТЬ SnackBar викликаємо наше нове вікно закладу:
                          _showVenueDetails(context, place);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: const [
                              BoxShadow(blurRadius: 4, color: Colors.black26, offset: Offset(0, 2))
                            ],
                          ),
                          child: Icon(iconData, color: markerColor, size: 20),
                        ),
                      ),
                    );
                  })
                      .toList(),]
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
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AuthScreen(currentCenter: _selectedCity.center),
                      ),
                    );
                  },
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
// У секції 3 (ЛІВА ПАНЕЛЬ НАВІГАЦІЇ) додайте кнопку GPS під кнопками зуму:
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
                const SizedBox(height: 8),
                // 📍 КНОПКА ГЕОЛОКАЦІЇ КОРИСТУВАЧА
                FloatingActionButton.small(
                  heroTag: 'my_location',
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.orange,
                  onPressed: _getUserLocation,
                  child: _isLoadingLocation
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.my_location),
                ),
              ],
            ),
          ),

          // 4. НИЖНЯ ПАНЕЛЬ: Кнопки винесені НАД рядок ШІ (зліва та справа)
// 4. НИЖНЯ ПАНЕЛЬ: Анімована шторка з підтримкою розгортання та згортання
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              height: _isAiPanelExpanded
                  ? MediaQuery.of(context).size.height * 0.45
                  : 140, // Висота у згорнутому стані (фільтри + рядок вводу)
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Індикатор та кнопка згортання/розгортання шторки
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isAiPanelExpanded = !_isAiPanelExpanded;
                      });
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      color: Colors.transparent,
                      child: Center(
                        child: Container(
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Рядок швидких кнопок (фільтри та радіус)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        FloatingActionButton.extended(
                          heroTag: 'filter_btn',
                          onPressed: () => _showFiltersBottomSheet(context),
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black87,
                          elevation: 2,
                          icon: const Icon(Icons.tune, size: 18, color: Colors.orange),
                          label: const Text('Фільтри', style: TextStyle(fontSize: 12)),
                        ),
                        FloatingActionButton.extended(
                          heroTag: 'radius_btn',
                          onPressed: () => _showRadiusBottomSheet(context),
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black87,
                          elevation: 2,
                          icon: const Icon(Icons.radar, size: 18, color: Colors.orange),
                          label: Text(_formatRadius(_radiusSteps[_radiusIndex]), style: const TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 4),

                  // Центральний рядок ШІ-запиту
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.orange.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.auto_awesome, color: Colors.orange, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _aiQueryController,
                              onTap: () {
                                // Автоматично розгортаємо панель, коли користувач торкається поля введення
                                setState(() {
                                  _isAiPanelExpanded = true;
                                });
                              },
                              decoration: const InputDecoration(
                                hintText: 'Запит ШІ (напр. найдешевше латте)...',
                                border: InputBorder.none,
                                hintStyle: TextStyle(fontSize: 14, color: Colors.grey),
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () async {
                              final query = _aiQueryController.text;
                              if (query.isNotEmpty) {
                                // Розгортаємо панель та показуємо стан завантаження
                                setState(() {
                                  _isAiPanelExpanded = true;
                                  _aiResponseText = "Шукаю найкращі варіанти у місті ${_selectedCity.name}...";
                                });

                                _aiQueryController.clear();
                                FocusScope.of(context).unfocus();

                                // Отримуємо відповідь від агента
                                final result = await _aiAgent.askAgent(query, _selectedCity.name);

                                setState(() {
                                  _aiResponseText = result;
                                });
                              }
                            },
                            icon: const Icon(Icons.send, color: Colors.orange, size: 20),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Блок виведення відповіді ШІ (розгортається разом із панеллю)
                  if (_isAiPanelExpanded) ...[
                    const Divider(height: 20),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Відповідь агента:',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.orange),
                                ),
                                const Spacer(),
                                if (_aiResponseText.isNotEmpty)
                                  TextButton.icon(
                                    onPressed: () {
                                      setState(() {
                                        _aiResponseText = '';
                                        _isAiPanelExpanded = false;
                                      });
                                    },
                                    icon: const Icon(Icons.close, size: 16, color: Colors.grey),
                                    label: const Text('Закрити', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _aiResponseText.isEmpty ? '' : _aiResponseText,
                              style: const TextStyle(fontSize: 14, height: 1.4, color: Colors.black87),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
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