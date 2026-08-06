import 'package:flutter_test/flutter_test.dart';
import 'package:tripnest/src/core/services/air_quality_service.dart';

void main() {
  group('AirQualityData numeric parsing', () {
    test('returns null for the WAQI "-" sentinel rather than 0', () {
      // Two bugs met here. Assigning "-" to `int aqi` threw a TypeError that
      // was swallowed (feature vanished); defaulting it to 0 then made the app
      // render "Good - perfect for outdoor activities" from no measurement.
      expect(AirQualityData.parseInt('-'), isNull);
      expect(AirQualityData.parseDouble('-'), isNull);
    });

    test('returns null for nulls and junk', () {
      expect(AirQualityData.parseInt(null), isNull);
      expect(AirQualityData.parseDouble(null), isNull);
      expect(AirQualityData.parseInt('abc'), isNull);
      expect(AirQualityData.parseDouble(''), isNull);
    });

    test('reads numbers and numeric strings', () {
      expect(AirQualityData.parseInt(42), 42);
      expect(AirQualityData.parseInt('42'), 42);
      expect(AirQualityData.parseInt(42.7), 42);
      // A decimal string used to fail int.tryParse and collapse to 0.
      expect(AirQualityData.parseInt('42.7'), 42);
      expect(AirQualityData.parseDouble('42.5'), 42.5);
      expect(AirQualityData.parseDouble(' 42.5 '), 42.5);
    });
  });

  group('AirQualityData.fromJson', () {
    test('round-trips through toJson', () {
      final original = AirQualityData(
        aqi: 88,
        pm25: 30.5,
        pm10: 44.0,
        cityName: 'Chiang Rai',
        updatedAt: DateTime.parse('2026-08-06T10:00:00.000Z'),
        temperature: 31.2,
      );

      final restored = AirQualityData.fromJson(original.toJson());

      expect(restored.aqi, 88);
      expect(restored.pm25, 30.5);
      expect(restored.cityName, 'Chiang Rai');
      expect(restored.updatedAt, original.updatedAt);
    });

    test('keeps sentinel readings absent instead of inventing zeros', () {
      final data = AirQualityData.fromJson({
        'aqi': '-',
        'pm25': '-',
        'cityName': null,
        'updatedAt': '',
      });

      expect(data.aqi, isNull);
      expect(data.pm25, isNull);
      expect(data.hasAqi, isFalse);
      expect(data.cityName, 'Unknown');
    });

    test('an absent index reads as Unavailable, not Good', () {
      final data = AirQualityData.fromJson({'aqi': '-'});

      expect(data.aqiDisplay, '--');
      expect(data.aqiLevel, 'Unavailable');
      expect(data.colorValue, 0xFF9AA0A6);
      expect(data.healthRecommendation, contains('No air quality reading'));
      // The old behaviour, which is what made this dangerous:
      expect(data.healthRecommendation, isNot(contains('Perfect for outdoor')));
    });

    test('formatReading renders missing values as --', () {
      expect(AirQualityData.formatReading(null), '--');
      expect(AirQualityData.formatReading(12.34), '12.3');
      expect(AirQualityData.formatReading(31.6, decimals: 0), '32');
    });
  });

  group('AQI level thresholds', () {
    test('maps values to the documented bands', () {
      AirQualityData at(int? aqi) => AirQualityData(
            aqi: aqi,
            pm25: null,
            pm10: null,
            cityName: 'x',
            updatedAt: DateTime.now(),
          );

      expect(at(50).aqiLevel, 'Good');
      expect(at(51).aqiLevel, 'Moderate');
      expect(at(101).aqiLevel, 'Unhealthy for Sensitive Groups');
      expect(at(151).aqiLevel, 'Unhealthy');
      expect(at(201).aqiLevel, 'Very Unhealthy');
      expect(at(301).aqiLevel, 'Hazardous');
      expect(at(null).aqiLevel, 'Unavailable');
    });
  });
}
