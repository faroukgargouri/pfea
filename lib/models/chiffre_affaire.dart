
class ChiffreAffaire {
  final String codeClient;
  final String raisonSocial;
  final String currentAnnee;
  final String currentAnnee1;
  final String currentAnnee2;
  final String totalCurrentAnnee;
  final String totalCurrentAnnee1;
  final String totalCurrentAnnee2;
  final String encoursCurrentAnnee;
  final String caq1CurrentAnnee;
  final String caq2CurrentAnnee;
  final String caq3CurrentAnnee;
  final String caq4CurrentAnnee;
  final String caq1CurrentAnnee1;
  final String caq2CurrentAnnee1;
  final String caq3CurrentAnnee1;
  final String caq4CurrentAnnee1;
  final String caq1CurrentAnnee2;
  final String caq2CurrentAnnee2;
  final String caq3CurrentAnnee2;
  final String caq4CurrentAnnee2;

  ChiffreAffaire({
    required this.codeClient,
    required this.raisonSocial,
    required this.currentAnnee,
    required this.currentAnnee1,
    required this.currentAnnee2,
    required this.totalCurrentAnnee,
    required this.totalCurrentAnnee1,
    required this.totalCurrentAnnee2,
    required this.encoursCurrentAnnee,
    required this.caq1CurrentAnnee,
    required this.caq2CurrentAnnee,
    required this.caq3CurrentAnnee,
    required this.caq4CurrentAnnee,
    required this.caq1CurrentAnnee1,
    required this.caq2CurrentAnnee1,
    required this.caq3CurrentAnnee1,
    required this.caq4CurrentAnnee1,
    required this.caq1CurrentAnnee2,
    required this.caq2CurrentAnnee2,
    required this.caq3CurrentAnnee2,
    required this.caq4CurrentAnnee2,
  });

  factory ChiffreAffaire.fromJson(Map<String, dynamic> json) {
    return ChiffreAffaire(
      codeClient: json['codeclient'] as String,
      raisonSocial: json['raisonsocial'] as String,
      currentAnnee: json['currentAnnee'] as String,
      currentAnnee1: json['currentAnnee_1'] as String,
      currentAnnee2: json['currentAnnee_2'] as String,
      totalCurrentAnnee: json['total_CurrentAnnee'] as String,
      totalCurrentAnnee1: json['total_CurrentAnnee_1'] as String,
      totalCurrentAnnee2: json['total_CurrentAnnee_2'] as String,
      encoursCurrentAnnee: json['encours_CurrentAnnee'] as String,
      caq1CurrentAnnee: json['caq1_CurrentAnnee'] as String,
      caq2CurrentAnnee: json['caq2_CurrentAnnee'] as String,
      caq3CurrentAnnee: json['caq3_CurrentAnnee'] as String,
      caq4CurrentAnnee: json['caq4_CurrentAnnee'] as String,
      caq1CurrentAnnee1: json['caq1_CurrentAnnee_1'] as String,
      caq2CurrentAnnee1: json['caq2_CurrentAnnee_1'] as String,
      caq3CurrentAnnee1: json['caq3_CurrentAnnee_1'] as String,
      caq4CurrentAnnee1: json['caq4_CurrentAnnee_1'] as String,
      caq1CurrentAnnee2: json['caq1_CurrentAnnee_2'] as String,
      caq2CurrentAnnee2: json['caq2_CurrentAnnee_2'] as String,
      caq3CurrentAnnee2: json['caq3_CurrentAnnee_2'] as String,
      caq4CurrentAnnee2: json['caq4_CurrentAnnee_2'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'codeclient': codeClient,
      'raisonsocial': raisonSocial,
      'currentAnnee': currentAnnee,
      'currentAnnee_1': currentAnnee1,
      'currentAnnee_2': currentAnnee2,
      'total_CurrentAnnee': totalCurrentAnnee,
      'total_CurrentAnnee_1': totalCurrentAnnee1,
      'total_CurrentAnnee_2': totalCurrentAnnee2,
      'encours_CurrentAnnee': encoursCurrentAnnee,
      'caq1_CurrentAnnee': caq1CurrentAnnee,
      'caq2_CurrentAnnee': caq2CurrentAnnee,
      'caq3_CurrentAnnee': caq3CurrentAnnee,
      'caq4_CurrentAnnee': caq4CurrentAnnee,
      'caq1_CurrentAnnee_1': caq1CurrentAnnee1,
      'caq2_CurrentAnnee_1': caq2CurrentAnnee1,
      'caq3_CurrentAnnee_1': caq3CurrentAnnee1,
      'caq4_CurrentAnnee_1': caq4CurrentAnnee1,
      'caq1_CurrentAnnee_2': caq1CurrentAnnee2,
      'caq2_CurrentAnnee_2': caq2CurrentAnnee2,
      'caq3_CurrentAnnee_2': caq3CurrentAnnee2,
      'caq4_CurrentAnnee_2': caq4CurrentAnnee2,
    };
  }
}
