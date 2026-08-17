import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/residence.dart';

/// Client HTTP vers le backend FastAPI existant (docker-compose: rezi_backend).
/// En prod (Hetzner), l'API tourne derrière le même nginx que le site, port 8081.
/// Ajuste [baseUrl] selon l'environnement (--dart-define=API_BASE_URL=...).
class ApiService {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://204.168.229.74:8081',
  );

  final _storage = const FlutterSecureStorage();

  Future<String?> get _token async => _storage.read(key: 'jwt_token');

  Map<String, String> _headers(String? token) => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Future<List<Residence>> fetchResidences({
    String? type,
    double? prixMax,
    double? lat,
    double? lng,
    double? rayonKm,
  }) async {
    final qp = <String, String>{
      if (type != null) 'type': type,
      if (prixMax != null) 'prix_max': prixMax.toString(),
      if (lat != null) 'lat': lat.toString(),
      if (lng != null) 'lng': lng.toString(),
      if (rayonKm != null) 'rayon_km': rayonKm.toString(),
    };
    final uri = Uri.parse('$baseUrl/residences').replace(queryParameters: qp);
    final res = await http.get(uri, headers: _headers(await _token));
    if (res.statusCode != 200) {
      throw Exception('Erreur chargement résidences (${res.statusCode})');
    }
    final data = jsonDecode(utf8.decode(res.bodyBytes)) as List;
    return data.map((e) => Residence.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Residence> fetchResidence(String id) async {
    final res = await http.get(
      Uri.parse('$baseUrl/residences/$id'),
      headers: _headers(await _token),
    );
    if (res.statusCode != 200) {
      throw Exception('Résidence introuvable (${res.statusCode})');
    }
    return Residence.fromJson(jsonDecode(utf8.decode(res.bodyBytes)));
  }

  Future<String> login(String email, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (res.statusCode != 200) {
      throw Exception('Identifiants invalides');
    }
    final data = jsonDecode(res.body);
    final token = data['access_token'] as String;
    await _storage.write(key: 'jwt_token', value: token);
    return token;
  }

  Future<void> logout() => _storage.delete(key: 'jwt_token');

  Future<bool> get isLoggedIn async => (await _token) != null;
}
