import 'package:shared_preferences/shared_preferences.dart';

class WatchTimeHelper {
  static Future<void> saveWatchTime(
      String videoId, double timeInSeconds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('watch_time_$videoId', timeInSeconds);
  }

  static Future<double> loadWatchTime(String videoId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble('watch_time_$videoId') ?? 0.0;
  }
}
