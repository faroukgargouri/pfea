// lib/models/client.dart
import 'dart:convert';

class Client {
  final int id;
  final String bpcnum;
  final String bpcnam;
  final String adresseDefaut;
  final String email;
  final String tel;
  final String latitudeClient;   // raw string as received
  final String longitudeClient;  // raw string as received
  final String idRep;
  final String idRep1;
  final String gouvernerat;
  final String site;
  final String adresseLiv;
  final String regimeTaxe;
  final String conditionPayement;
  final double encoursAutorise;
  final String controlEncours;
  final double totalEncours;
  final String matriculeFiscale;
  final String familleClient;
  final String refCommandeClient;
  final DateTime? dateCommandeClient;
  final String nCommande;
  final double mtLigneHT;
  final double mtLigneTTC;
  final double cmdEncorsNonSoldeeNonLivree;

  const Client({
    required this.id,
    required this.bpcnum,
    required this.bpcnam,
    required this.adresseDefaut,
    required this.email,
    required this.tel,
    required this.latitudeClient,
    required this.longitudeClient,
    required this.idRep,
    required this.idRep1,
    required this.gouvernerat,
    required this.site,
    required this.adresseLiv,
    required this.regimeTaxe,
    required this.conditionPayement,
    required this.encoursAutorise,
    required this.controlEncours,
    required this.totalEncours,
    required this.matriculeFiscale,
    required this.familleClient,
    required this.refCommandeClient,
    required this.dateCommandeClient,
    required this.nCommande,
    required this.mtLigneHT,
    required this.mtLigneTTC,
    required this.cmdEncorsNonSoldeeNonLivree,
  });

  /// Computed doubles that tolerate comma or dot as decimal separator
  double get latitudeClientDec => _parseDoubleFlexible(latitudeClient);
  double get longitudeClientDec => _parseDoubleFlexible(longitudeClient);

  Client copyWith({
    int? id,
    String? bpcnum,
    String? bpcnam,
    String? adresseDefaut,
    String? email,
    String? tel,
    String? latitudeClient,
    String? longitudeClient,
    String? idRep,
    String? idRep1,
    String? gouvernerat,
    String? site,
    String? adresseLiv,
    String? regimeTaxe,
    String? conditionPayement,
    double? encoursAutorise,
    String? controlEncours,
    double? totalEncours,
    String? matriculeFiscale,
    String? familleClient,
    String? refCommandeClient,
    DateTime? dateCommandeClient,
    String? nCommande,
    double? mtLigneHT,
    double? mtLigneTTC,
    double? cmdEncorsNonSoldeeNonLivree,
  }) {
    return Client(
      id: id ?? this.id,
      bpcnum: bpcnum ?? this.bpcnum,
      bpcnam: bpcnam ?? this.bpcnam,
      adresseDefaut: adresseDefaut ?? this.adresseDefaut,
      email: email ?? this.email,
      tel: tel ?? this.tel,
      latitudeClient: latitudeClient ?? this.latitudeClient,
      longitudeClient: longitudeClient ?? this.longitudeClient,
      idRep: idRep ?? this.idRep,
      idRep1: idRep1 ?? this.idRep1,
      gouvernerat: gouvernerat ?? this.gouvernerat,
      site: site ?? this.site,
      adresseLiv: adresseLiv ?? this.adresseLiv,
      regimeTaxe: regimeTaxe ?? this.regimeTaxe,
      conditionPayement: conditionPayement ?? this.conditionPayement,
      encoursAutorise: encoursAutorise ?? this.encoursAutorise,
      controlEncours: controlEncours ?? this.controlEncours,
      totalEncours: totalEncours ?? this.totalEncours,
      matriculeFiscale: matriculeFiscale ?? this.matriculeFiscale,
      familleClient: familleClient ?? this.familleClient,
      refCommandeClient: refCommandeClient ?? this.refCommandeClient,
      dateCommandeClient: dateCommandeClient ?? this.dateCommandeClient,
      nCommande: nCommande ?? this.nCommande,
      mtLigneHT: mtLigneHT ?? this.mtLigneHT,
      mtLigneTTC: mtLigneTTC ?? this.mtLigneTTC,
      cmdEncorsNonSoldeeNonLivree:
          cmdEncorsNonSoldeeNonLivree ?? this.cmdEncorsNonSoldeeNonLivree,
    );
  }

  // ---------- JSON helpers ----------
 factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: _parseInt(json['id']),
      bpcnum: (json['bpcnum'] ?? '').toString(),
      bpcnam: (json['bpcnam'] ?? '').toString(),
      adresseDefaut: (json['adresse_defaut'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      tel: (json['tel'] ?? '').toString(),
      latitudeClient: (json['latitudeClient'] ?? '').toString(),
      
      longitudeClient: (json['longitudeClient'] ?? '').toString(),
     
      idRep: (json['id_rep'] ?? '').toString(),
      idRep1: (json['id_rep1'] ?? '').toString(),
      gouvernerat: (json['gouvernerat'] ?? '').toString(),
      site: (json['site'] ?? '').toString(),
      adresseLiv: (json['adresse_liv'] ?? '').toString(),
      regimeTaxe: (json['regime_Taxe'] ?? '').toString(),
      conditionPayement: (json['condition_Payement'] ?? '').toString(),
      encoursAutorise: _parseDouble(json['encours_Autorise']),
      controlEncours: (json['control_Encours'] ?? '').toString(),
      totalEncours: _parseDouble(json['total_Encours']),
      matriculeFiscale: (json['matricule_Fiscale'] ?? '').toString(),
      familleClient: (json['famille_Client'] ?? '').toString(),
      refCommandeClient: (json['refCommandeClient'] ?? '').toString(),
      dateCommandeClient: _parseDate(json['dateCommandeClient']),
      nCommande: (json['nCommande'] ?? '').toString(),
      mtLigneHT: _parseDouble(json['mtLigneHT']),
      mtLigneTTC: _parseDouble(json['mtLigneTTC']),
      cmdEncorsNonSoldeeNonLivree: _parseDouble(json['cmdEncorsNonSoldeeNonLivree']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'bpcnum': bpcnum,
        'bpcnam': bpcnam,
        'Adresse_defaut': adresseDefaut,
        'Email': email,
        'Tel': tel,
        'LatitudeClient': latitudeClient,
        'LongitudeClient': longitudeClient,
        'id_rep': idRep,
        'id_rep1': idRep1,
        'gouvernerat': gouvernerat,
        'Site': site,
        'Adresse_liv': adresseLiv,
        'Regime_Taxe': regimeTaxe,
        'Condition_Payement': conditionPayement,
        'Encours_Autorise': encoursAutorise,
        'Control_Encours': controlEncours,
        'Total_Encours': totalEncours,
        'Matricule_Fiscale': matriculeFiscale,
        'Famille_Client': familleClient,
        'RefCommandeClient': refCommandeClient,
        'DateCommandeClient': dateCommandeClient?.toIso8601String(),
        'NCommande': nCommande,
        'MtLigneHT': mtLigneHT,
        'MtLigneTTC': mtLigneTTC,
        'CmdEncorsNonSoldeeNonLivree': cmdEncorsNonSoldeeNonLivree,
      };

  // ---------- String / Map helpers ----------
  factory Client.fromJsonString(String source) =>
      Client.fromJson(json.decode(source) as Map<String, dynamic>);

  String toJsonString() => json.encode(toJson());

  // ---------- Parsers ----------
  static int _parseInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    return int.tryParse(v.toString()) ?? 0;
    }

  static double _parseDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    // Try dot then comma
    final s = v.toString().trim();
    return double.tryParse(s) ??
        double.tryParse(s.replaceAll(',', '.')) ??
        0.0;
  }

  /// Parse strings that may use comma or dot for decimals (e.g., "10,25" or "10.25")
  static double _parseDoubleFlexible(String s) {
    final trimmed = s.trim();
    if (trimmed.isEmpty) return 0.0;
    return double.tryParse(trimmed) ??
        double.tryParse(trimmed.replaceAll(',', '.')) ??
        0.0;
  }

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    final s = v.toString();
    // Try ISO first
    try {
      return DateTime.parse(s);
    } catch (_) {}
    // Try common alternatives (e.g., "dd/MM/yyyy" or "yyyy-MM-dd HH:mm:ss")
    // Add more formats if your API uses them.
    final candidates = [
      RegExp(r'^(\d{2})/(\d{2})/(\d{4})$'),              // dd/MM/yyyy
      RegExp(r'^(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2})') // yyyy-MM-dd HH:mm
    ];
    for (final r in candidates) {
      final m = r.firstMatch(s);
      if (m != null) {
        try {
          if (r.pattern.contains('dd/MM/yyyy')) {
            final d = int.parse(m.group(1)!);
            final mo = int.parse(m.group(2)!);
            final y = int.parse(m.group(3)!);
            return DateTime(y, mo, d);
          } else {
            // yyyy-MM-dd HH:mm
            final y = int.parse(m.group(1)!);
            final mo = int.parse(m.group(2)!);
            final d = int.parse(m.group(3)!);
            final h = int.parse(m.group(4)!);
            final mi = int.parse(m.group(5)!);
            return DateTime(y, mo, d, h, mi);
          }
        } catch (_) {}
      }
    }
    return null;
  }
}
