import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_settings.dart';
import '../models/game_settings.dart';
import '../models/game_state.dart';
import '../models/player.dart';

class StorageService {
  final SharedPreferences _prefs;

  StorageService(this._prefs);

  // Player methods
  Future<void> savePlayers(List<Player> players) async {
    final String data = jsonEncode(players.map((p) => p.toJson()).toList());
    await _prefs.setString('players', data);
  }

  Future<List<Player>> loadPlayers() async {
    final String? data = _prefs.getString('players');
    if (data == null) return [];
    final List<dynamic> jsonList = jsonDecode(data);
    return jsonList.map((json) => Player.fromJson(json)).toList();
  }

  // Last game settings methods
  Future<void> saveLastGame(GameSettings settings) async {
    print("saveGame: ${settings.toJson()}");
    await _prefs.setString('_lastGame', jsonEncode(settings.toJson()));
  }

  Future<GameSettings?> loadLastGame() async {
    final String? data = _prefs.getString('_lastGame');
    if (data == null) return null;
    return GameSettings.fromJson(jsonDecode(data));
  }

  // Game state methods
  Future<void> saveGameState(GameState state) async {
    await _prefs.setString('_gameState', jsonEncode(state.toJson()));
  }

  Future<GameState?> loadGameState() async {
    final String? data = _prefs.getString('_gameState');
    if (data == null) return null;
    return GameState.fromJson(jsonDecode(data));
  }

  Future<void> clearGameState() async {
    await _prefs.remove('_gameState');
  }

  Future<void> saveAppSettings(AppSettings settings) async {
    await _prefs.setString('appSettings', jsonEncode(settings.toJson()));
  }

  Future<AppSettings> loadAppSettings() async {
    final String? data = _prefs.getString('appSettings');
    if (data == null) return AppSettings();
    return AppSettings.fromJson(jsonDecode(data));
  }
}
