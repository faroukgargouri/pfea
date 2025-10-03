class Preavis {
  final String? datePreavis;
  final String agence;
  final String typePaiement;
  final String numCheque;
  final String numReg;
  final double montant;
  final String codeClient;
  final String nomClient;
  final String? dateAnnulationPreavis;
  final String dateImpaye;
  final String? dateRecuperationImpaye;
  final String societe;
  final String site;
  final String status;
  final String rep1;
  final String rep2;

  Preavis({
    this.datePreavis,
    required this.agence,
    required this.typePaiement,
    required this.numCheque,
    required this.numReg,
    required this.montant,
    required this.codeClient,
    required this.nomClient,
    this.dateAnnulationPreavis,
    required this.dateImpaye,
    this.dateRecuperationImpaye,
    required this.societe,
    required this.site,
    required this.status,
    required this.rep1,
    required this.rep2,
  });

  factory Preavis.fromJson(Map<String, dynamic> json) {
    return Preavis(
      datePreavis: json['datePreavis'] as String?,
      agence: json['agence'] ?? '',
      typePaiement: json['typePaiement'] ?? '',
      numCheque: json['numCheque'] ?? '',
      numReg: json['numReg'] ?? '',
      montant: (json['montant'] as num).toDouble(),
      codeClient: json['codeClient'] ?? '',
      nomClient: json['nomClient'] ?? '',
      dateAnnulationPreavis: json['dateAnnulationPreavis'] as String?,
      dateImpaye: json['dateImpaye'] ?? '',
      dateRecuperationImpaye: json['dateRecuperationImpaye'] as String?,
      societe: json['societe'] ?? '',
      site: json['site'] ?? '',
      status: json['status'] ?? '',
      rep1: json['rep1'] ?? '',
      rep2: json['rep2'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'datePreavis': datePreavis,
      'agence': agence,
      'typePaiement': typePaiement,
      'numCheque': numCheque,
      'numReg': numReg,
      'montant': montant,
      'codeClient': codeClient,
      'nomClient': nomClient,
      'dateAnnulationPreavis': dateAnnulationPreavis,
      'dateImpaye': dateImpaye,
      'dateRecuperationImpaye': dateRecuperationImpaye,
      'societe': societe,
      'site': site,
      'status': status,
      'rep1': rep1,
      'rep2': rep2,
    };
  }
}
