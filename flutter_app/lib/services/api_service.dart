import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/residence.dart';
import '../models/extra_models.dart';

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

  // ── Avis (reviews) ──
  Future<List<Avis>> fetchAvis(String residenceId) async {
    final res = await http.get(Uri.parse('$baseUrl/residences/$residenceId/avis'));
    if (res.statusCode != 200) throw Exception('Erreur chargement avis');
    final data = jsonDecode(utf8.decode(res.bodyBytes)) as List;
    return data.map((e) => Avis.fromJson(e)).toList();
  }

  Future<List<DateTime>> fetchDatesReservees(String residenceId) async {
    final res = await http.get(Uri.parse('$baseUrl/residences/$residenceId/dates-reservees'));
    if (res.statusCode != 200) throw Exception('Erreur chargement disponibilités');
    final data = jsonDecode(utf8.decode(res.bodyBytes)) as List;
    return data.map((e) => DateTime.parse(e.toString())).toList();
  }

  // ── Favoris ──
  Future<List<Residence>> fetchFavoris() async {
    final res = await http.get(Uri.parse('$baseUrl/favoris'), headers: _headers(await _token));
    if (res.statusCode != 200) throw Exception('Erreur chargement favoris');
    final data = jsonDecode(utf8.decode(res.bodyBytes)) as List;
    return data.map((e) => Residence.fromJson(e)).toList();
  }

  Future<void> toggleFavori(String residenceId, bool add) async {
    final uri = Uri.parse('$baseUrl/favoris/$residenceId');
    final res = add
        ? await http.post(uri, headers: _headers(await _token))
        : await http.delete(uri, headers: _headers(await _token));
    if (res.statusCode >= 400) throw Exception('Erreur mise à jour favori');
  }

  // ── Réservations ──
  Future<Reservation> creerReservation({
    required String residenceId,
    required DateTime debut,
    required DateTime fin,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/reservations/'),
      headers: _headers(await _token),
      body: jsonEncode({
        'residence_id': residenceId,
        'date_debut': debut.toIso8601String(),
        'date_fin': fin.toIso8601String(),
      }),
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('Réservation refusée (${res.statusCode})');
    }
    return Reservation.fromJson(jsonDecode(utf8.decode(res.bodyBytes)));
  }

  Future<List<Reservation>> mesReservations() async {
    final res = await http.get(
      Uri.parse('$baseUrl/reservations/mes-reservations'),
      headers: _headers(await _token),
    );
    if (res.statusCode != 200) throw Exception('Erreur chargement réservations');
    final data = jsonDecode(utf8.decode(res.bodyBytes)) as List;
    return data.map((e) => Reservation.fromJson(e)).toList();
  }

  Future<List<Reservation>> reservationsProprietaire() async {
    final res = await http.get(
      Uri.parse('$baseUrl/reservations/proprietaire'),
      headers: _headers(await _token),
    );
    if (res.statusCode != 200) throw Exception('Erreur chargement réservations propriétaire');
    final data = jsonDecode(utf8.decode(res.bodyBytes)) as List;
    return data.map((e) => Reservation.fromJson(e)).toList();
  }

  Future<void> majStatutReservation(String id, String statut) async {
    final res = await http.put(
      Uri.parse('$baseUrl/reservations/$id/statut?statut=$statut'),
      headers: _headers(await _token),
    );
    if (res.statusCode >= 400) throw Exception('Erreur mise à jour statut');
  }

  // ── Paiement ──
  Future<Map<String, dynamic>> initierPaiement(String reservationId) async {
    final res = await http.post(
      Uri.parse('$baseUrl/paiements/initier'),
      headers: _headers(await _token),
      body: jsonEncode({'reservation_id': reservationId}),
    );
    if (res.statusCode != 200) throw Exception('Erreur initiation paiement');
    return jsonDecode(utf8.decode(res.bodyBytes));
  }

  Future<String> statutPaiement(String paiementId) async {
    final res = await http.get(
      Uri.parse('$baseUrl/paiements/$paiementId/statut'),
      headers: _headers(await _token),
    );
    if (res.statusCode != 200) throw Exception('Erreur statut paiement');
    final data = jsonDecode(utf8.decode(res.bodyBytes));
    return data['statut'] as String;
  }

  // ── Messagerie ──
  Future<List<Conversation>> fetchConversations() async {
    final res = await http.get(
      Uri.parse('$baseUrl/messages/conversations'),
      headers: _headers(await _token),
    );
    if (res.statusCode != 200) throw Exception('Erreur chargement conversations');
    final data = jsonDecode(utf8.decode(res.bodyBytes)) as List;
    return data.map((e) => Conversation.fromJson(e)).toList();
  }

  Future<List<ChatMessage>> fetchMessages(String conversationId) async {
    final res = await http.get(
      Uri.parse('$baseUrl/messages/conversations/$conversationId/messages'),
      headers: _headers(await _token),
    );
    if (res.statusCode != 200) throw Exception('Erreur chargement messages');
    final data = jsonDecode(utf8.decode(res.bodyBytes)) as List;
    return data.map((e) => ChatMessage.fromJson(e)).toList();
  }

  /// URL du WebSocket temps réel (ws:// en dev http, wss:// si backend en https).
  Uri messagesWebSocketUrl(String userId, String token) {
    final isSecure = baseUrl.startsWith('https');
    final host = baseUrl.replaceFirst(RegExp(r'^https?://'), '');
    return Uri.parse('${isSecure ? 'wss' : 'ws'}://$host/api/messages/ws/$userId?token=$token');
  }
}
