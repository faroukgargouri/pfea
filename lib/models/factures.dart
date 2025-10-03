class Facture {
  final String numeroFacture;
  final String codeClient;
  final String dateFacture;
  final double montant;
  final double montantReste;
  final String echeance;
  final String numCmd;
  final double diffDate;
  final String site;


  Facture({
    required this.numeroFacture,
    required this.codeClient,
    required this.dateFacture,
    required this.montant,
    required this.montantReste,
    required this.echeance,
    required this.numCmd,
    required this.diffDate,
    required this.site,
  });

  factory Facture.fromJson(Map<String, dynamic> json) {
    return Facture(
      numeroFacture: json['numFac']?.toString() ?? '',
      codeClient: json['codeClient']?.toString() ?? '',
      dateFacture: json['dateFac']?.toString() ?? '',
      montant: (json['montantFac'] as num?)?.toDouble() ?? 0.0,
      montantReste: (json['resteReg'] as num?)?.toDouble() ?? 0.0,
      echeance: json['echeance']?.toString() ?? '',
      numCmd: json['numCmd']?.toString() ?? '',
      diffDate: (json['diffDate'] as num?)?.toDouble() ?? 0.0,
      site: json['site']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'numFac': numeroFacture,
      'codeClient': codeClient,
      'dateFac': dateFacture,
      'montantFac': montant,
      'resteReg': montantReste,
      'echeance': echeance,
      'numCmd': numCmd,
      'diffDate': diffDate,
      'site': site,
    };
  }
}
