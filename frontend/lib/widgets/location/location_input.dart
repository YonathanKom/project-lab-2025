import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class LocationInput extends StatefulWidget {
  final Function(double lat, double lon, double radius)? onLocationSet;
  final Function()? onLocationCleared;

  const LocationInput({
    super.key,
    this.onLocationSet,
    this.onLocationCleared,
  });

  @override
  State<LocationInput> createState() => _LocationInputState();
}

class _LocationInputState extends State<LocationInput> {
  double _radiusKm = 10.0;
  double? _userLat;
  double? _userLon;
  bool _isGettingLocation = false;
  String? _locationError;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: _userLat != null && _userLon != null
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).disabledColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Location-Based Filtering',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_locationError != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Theme.of(context).colorScheme.error,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _locationError!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => setState(() => _locationError = null),
                      icon: const Icon(Icons.close, size: 16),
                    ),
                  ],
                ),
              ),
            if (_userLat != null && _userLon != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle,
                        color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Location: ${_userLat!.toStringAsFixed(4)}, ${_userLon!.toStringAsFixed(4)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    TextButton(
                      onPressed: _getCurrentLocation,
                      child: const Text('Update'),
                    ),
                  ],
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isGettingLocation ? null : _getCurrentLocation,
                  icon: _isGettingLocation
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location),
                  label: Text(_isGettingLocation
                      ? 'Getting Location...'
                      : 'Get Current Location'),
                ),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  'Search Radius: ',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  '${_radiusKm.toInt()}km',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
              ],
            ),
            Slider(
              value: _radiusKm,
              min: 1,
              max: 50,
              divisions: 49,
              label: '${_radiusKm.toInt()}km',
              onChanged: (value) {
                setState(() {
                  _radiusKm = value;
                });
                _notifyLocationChange();
              },
            ),
            if (_userLat == null || _userLon == null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Location is required for filtering stores by distance',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isGettingLocation = true;
      _locationError = null;
    });

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception(
            'Location services are disabled. Please enable them in your device settings.');
      }

      // Check permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception(
              'Location permission denied. Please grant location access to use this feature.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception(
            'Location permission permanently denied. Please enable it in app settings.');
      }

      // Get position with timeout
      final position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 15),
        ),
      );

      setState(() {
        _userLat = position.latitude;
        _userLon = position.longitude;
        _isGettingLocation = false;
      });

      _notifyLocationChange();
    } catch (e) {
      setState(() {
        _isGettingLocation = false;
        _locationError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _notifyLocationChange() {
    if (_userLat != null && _userLon != null) {
      widget.onLocationSet?.call(_userLat!, _userLon!, _radiusKm);
    } else {
      widget.onLocationCleared?.call();
    }
  }
}
