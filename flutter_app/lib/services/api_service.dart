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

  // ── Inscription (avec vérification OTP par email) ──
  Future<void> demanderOtpInscription({
    required String email,
    required String motDePasse,
    required String nom,
    required String prenom,
    String telephone = '',
  }) async {
    final req = http.MultipartRequest('POST', Uri.parse('$baseUrl/auth/register/request-otp'))
      ..fields['email'] = email
      ..fields['mot_de_passe'] = motDePasse
      ..fields['nom'] = nom
      ..fields['prenom'] = prenom
      ..fields['role'] = 'usager'
      ..fields['telephone'] = telephone;
    final streamed = await req.send();
    final res = await http.Response.fromStream(streamed);
    if (res.statusCode != 200) {
      final data = jsonDecode(res.body);
      throw Exception(data['detail'] ?? 'Erreur lors de la demande de code');
    }
  }

  Future<String> verifierOtpInscription(String email, String code) async {
    final req = http.MultipartRequest('POST', Uri.parse('$baseUrl/auth/register/verify-otp'))
      ..fields['email'] = email
      ..fields['code'] = code;
    final streamed = await req.send();
    final res = await http.Response.fromStream(streamed);
    if (res.statusCode != 200) {
      final data = jsonDecode(res.body);
      throw Exception(data['detail'] ?? 'Code incorrect');
    }
    final data = jsonDecode(res.body);
    final token = data['access_token'] as String;
    await _storage.write(key: 'jwt_token', value: token);
    return token;
  }

  /// Inscription directe sans OTP (fallback si l'API OTP est indisponible,
  /// comme dans le site web — voir index.html registerDirect()).
  Future<String> registerDirect({
    required String email,
    required String motDePasse,
    required String nom,
    required String prenom,
    String telephone = '',
  }) async {
    final req = http.MultipartRequest('POST', Uri.parse('$baseUrl/auth/register'))
      ..fields['email'] = email
      ..fields['mot_de_passe'] = motDePasse
      ..fields['nom'] = nom
      ..fields['prenom'] = prenom
      ..fields['role'] = 'usager'
      ..fields['telephone'] = telephone;
    final streamed = await req.send();
    final res = await http.Response.fromStream(streamed);
    if (res.statusCode != 200) {
      final data = jsonDecode(res.body);
      throw Exception(data['detail'] ?? 'Erreur lors de l\'inscription');
    }
    final data = jsonDecode(res.body);
    final token = data['access_token'] as String;
    await _storage.write(key: 'jwt_token', value: token);
    return token;
  }

  // ── Mot de passe ──
  Future<void> motDePasseOublie(String email) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/forgot-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
    if (res.statusCode != 200) throw Exception('Erreur lors de l\'envoi du lien de réinitialisation');
  }

  Future<void> changerMotDePasse(String ancien, String nouveau) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/change-password'),
      headers: _headers(await _token),
      body: jsonEncode({'ancien_mot_de_passe': ancien, 'nouveau_mot_de_passe': nouveau}),
    );
    if (res.statusCode != 200) throw Exception('Erreur lors du changement de mot de passe');
  }

  // ── Espace propriétaire ──
  Future<void> demandeProprietaire() async {
    final res = await http.post(
      Uri.parse('$baseUrl/users/demande-proprietaire'),
      headers: _headers(await _token),
    );
    if (res.statusCode != 200) throw Exception('Erreur lors de la demande');
  }

  Future<Residence> creerResidence(Map<String, String> champs, List<String> photoPaths) async {
    final req = http.MultipartRequest('POST', Uri.parse('$baseUrl/residences/'));
    final token = await _token;
    if (token != null) req.headers['Authorization'] = 'Bearer $token';
    req.fields.addAll(champs);
    for (final p in photoPaths) {
      req.files.add(await http.MultipartFile.fromPath('photos', p));
    }
    final streamed = await req.send();
    final res = await http.Response.fromStream(streamed);
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('Erreur création résidence (${res.statusCode})');
    }
    return Residence.fromJson(jsonDecode(utf8.decode(res.bodyBytes)));
  }

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
  /// Recherche géographique de suggestions (autocomplete d'adresse) — Photon/Komoot,
  /// limité à la Côte d'Ivoire, comme dans le site.
  Future<List<Map<String, dynamic>>> suggestionsAdresse(String q) async {
    if (q.trim().isEmpty) return [];
    final uri = Uri.parse(
      'https://photon.komoot.io/api/?q=${Uri.encodeComponent(q)}&limit=8&lang=fr&bbox=-8.6,4.3,-2.5,10.7',
    );
    final res = await http.get(uri).timeout(const Duration(seconds: 6));
    if (res.statusCode != 200) return [];
    final data = jsonDecode(utf8.decode(res.bodyBytes));
    final features = (data['features'] as List?) ?? [];
    return features.map((f) {
      final props = f['properties'] as Map<String, dynamic>;
      final coords = (f['geometry']['coordinates'] as List);
      return {
        'nom': props['name'] ?? props['street'] ?? '',
        'ville': props['city'] ?? '',
        'longitude': coords[0],
        'latitude': coords[1],
      };
    }).toList().cast<Map<String, dynamic>>();
  }

  Uri messagesWebSocketUrl(String userId, String token) {
    final isSecure = baseUrl.startsWith('https');
    final host = baseUrl.replaceFirst(RegExp(r'^https?://'), '');
    return Uri.parse('${isSecure ? 'wss' : 'ws'}://$host/api/messages/ws/$userId?token=$token');
  }
}
