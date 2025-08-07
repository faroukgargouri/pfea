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
}
