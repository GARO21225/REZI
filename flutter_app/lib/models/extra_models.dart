class Reservation {
  final String id;
  final String residenceId;
  final String residenceTitre;
  final DateTime dateDebut;
  final DateTime dateFin;
  final double montant;
  final String statut; // en_attente, confirmee, refusee, annulee, terminee

  Reservation({
    required this.id,
    required this.residenceId,
    required this.residenceTitre,
    required this.dateDebut,
    required this.dateFin,
    required this.montant,
    required this.statut,
  });

  factory Reservation.fromJson(Map<String, dynamic> json) => Reservation(
        id: json['id'].toString(),
        residenceId: (json['residence_id'] ?? '').toString(),
        residenceTitre: json['residence_titre'] ?? json['titre'] ?? '',
        dateDebut: DateTime.parse(json['date_debut']),
        dateFin: DateTime.parse(json['date_fin']),
        montant: (json['montant'] ?? 0).toDouble(),
        statut: json['statut'] ?? 'en_attente',
      );
}

class Avis {
  final String id;
  final String auteur;
  final int note;
  final String commentaire;
  final DateTime date;

  Avis({
    required this.id,
    required this.auteur,
    required this.note,
    required this.commentaire,
    required this.date,
  });

  factory Avis.fromJson(Map<String, dynamic> json) => Avis(
        id: json['id'].toString(),
        auteur: json['auteur'] ?? json['user_name'] ?? 'Utilisateur',
        note: (json['note'] ?? 0).toInt(),
        commentaire: json['commentaire'] ?? '',
        date: DateTime.tryParse(json['date'] ?? json['created_at'] ?? '') ?? DateTime.now(),
      );
}

class Conversation {
  final String id;
  final String autreUtilisateur;
  final String? dernierMessage;
  final DateTime? dernierMessageDate;
  final int nonLus;

  Conversation({
    required this.id,
    required this.autreUtilisateur,
    this.dernierMessage,
    this.dernierMessageDate,
    this.nonLus = 0,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) => Conversation(
        id: json['id'].toString(),
        autreUtilisateur: json['autre_utilisateur'] ?? json['nom'] ?? '',
        dernierMessage: json['dernier_message'],
        dernierMessageDate: json['dernier_message_date'] != null
            ? DateTime.tryParse(json['dernier_message_date'])
            : null,
        nonLus: (json['non_lus'] ?? 0).toInt(),
      );
}

class ChatMessage {
  final String id;
  final String expediteurId;
  final String contenu;
  final DateTime date;
  final bool lu;

  ChatMessage({
    required this.id,
    required this.expediteurId,
    required this.contenu,
    required this.date,
    required this.lu,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id'].toString(),
        expediteurId: (json['expediteur_id'] ?? '').toString(),
        contenu: json['contenu'] ?? '',
        date: DateTime.tryParse(json['date'] ?? json['created_at'] ?? '') ?? DateTime.now(),
        lu: json['lu'] ?? false,
      );
}
