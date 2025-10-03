import 'package:flutter_application_1/models/reclamationarticle.dart';

class Reclamation {
  final int id;
  final String reclamationNo;  
  final String client;
  final String telephone;
  final String note;
  final String retourLivraison;
  final String echange;
  final DateTime dateReclamation;
  final List<ReclamationArticle> articles; // ✅ new


  Reclamation({
    required this.id,
    required this.reclamationNo,
    required this.client,
    required this.telephone,
    required this.note,
    required this.retourLivraison,
    required this.echange,
    required this.dateReclamation,
    required this.articles
  });

  factory Reclamation.fromJson(Map<String, dynamic> json) {
  return Reclamation(
    id: int.tryParse(json['id'].toString()) ?? 0, // ✅ conversion sûre
    reclamationNo: json['reclamationNo']?.toString() ?? '-',
    client: json['client'] ?? '',
    telephone: json['telephone'] ?? '',
    note: json['note'] ?? '',
    retourLivraison: json['retourLivraison'] ?? '',
    echange: json['echange'] ?? '',
    dateReclamation: DateTime.tryParse(json['dateReclamation']?.toString() ?? '') ?? DateTime.now(),
    articles: (json['articles'] as List<dynamic>? ?? [])
          .map((a) => ReclamationArticle.fromJson(a))
          .toList(),
  );
}


  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reclamationNo': reclamationNo,
      'client': client,
      'telephone': telephone,
      'note': note,
      'retourLivraison': retourLivraison,
      'echange': echange,
      'dateReclamation': dateReclamation.toIso8601String(),
      'articles': articles.map((a) => a.toJson()).toList(),

    };
  }
  
  

}
