class Cheque {
  final String codeClient;
  final String raisonSocial;
  final String numReg;
  final String date;
  final String dateEcheance;
  final String numCheq;
  final String agence;
  final String reference;
  final String libelle;
  final double? portefeuille1;
  final double? portefeuille2;
  final double? portefeuille3;
  final double? impayee;
  final String reP1;
  final String reP2;

  Cheque({
    required this.codeClient,
    required this.raisonSocial,
    required this.numReg,
    required this.date,
    required this.dateEcheance,
    required this.numCheq,
    required this.agence,
    required this.reference,
    required this.libelle,
    required this.portefeuille1,
    required this.portefeuille2,
    required this.portefeuille3,
    this.impayee,
    required this.reP1,
    required this.reP2,
  });

  /// Convertit en String quel que soit le type reçu
  static String _asString(dynamic v) => v == null ? '' : v.toString();

  /// Convertit en double quel que soit le type reçu
  static double? _asDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString().replaceAll(',', '.'));
  }

  factory Cheque.fromJson(Map<String, dynamic> json) {
    return Cheque(
      codeClient: _asString(json['codeClient']),
      raisonSocial: _asString(json['raisonSocial']),
      numReg: _asString(json['numReg']),
      date: _asString(json['date']),
      dateEcheance: _asString(json['dateEcheance']),
      numCheq: _asString(json['numCheq']),
      agence: _asString(json['agence']),
      reference: _asString(json['reference']),
      libelle: _asString(json['libelle']),
      portefeuille1: _asDouble(json['portefeuille1']),
      portefeuille2: _asDouble(json['portefeuille2']),
      portefeuille3: _asDouble(json['portefeuille3']),
      impayee: _asDouble(json['impayee']),
      reP1: _asString(json['reP1']),
      reP2: _asString(json['reP2']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'codeClient': codeClient,
      'raisonSocial': raisonSocial,
      'numReg': numReg,
      'date': date,
      'dateEcheance': dateEcheance,
      'numCheq': numCheq,
      'agence': agence,
      'reference': reference,
      'libelle': libelle,
      'portefeuille1': portefeuille1,
      'portefeuille2': portefeuille2,
      'portefeuille3': portefeuille3,
      'impayee': impayee,
      'reP1': reP1,
      'reP2': reP2,
    };
  }
}
