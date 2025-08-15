class Reclamation {
  final int id;
  final String client;
  final String telephone;
  final String note;
  final String retourLivraison;
  final DateTime dateReclamation;

  Reclamation({
    required this.id,
    required this.client,
    required this.telephone,
    required this.note,
    required this.retourLivraison,
    required this.dateReclamation,
  });

  factory Reclamation.fromJson(Map<String, dynamic> json) {
    return Reclamation(
      id: json['id'],
      client: json['client'],
      telephone: json['telephone'],
      note: json['note'],
      retourLivraison: json['retourLivraison'],
      dateReclamation: DateTime.parse(json['dateReclamation']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'client': client,
      'telephone': telephone,
      'note': note,
      'retourLivraison': retourLivraison,
      'dateReclamation': dateReclamation.toIso8601String(),
    };
  }

  Reclamation copyWith({
    int? id,
    String? client,
    String? telephone,
    String? note,
    String? retourLivraison,
    DateTime? dateReclamation,
  }) {
    return Reclamation(
      id: id ?? this.id,
      client: client ?? this.client,
      telephone: telephone ?? this.telephone,
      note: note ?? this.note,
      retourLivraison: retourLivraison ?? this.retourLivraison,
      dateReclamation: dateReclamation ?? this.dateReclamation,
    );
  }
}
