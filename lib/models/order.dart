class Order {
  final int? id;                   
  final String? source;            
  final String? Reference;
  final String codeClient;         
  final String? NomClient;
  final String? AdresseClient;
  final String? CodeRep;
  final String? NomRep;
  final String? note;
  final DateTime dateCommande;     
  final DateTime? dateLivraison;
  final double total;
  final int statut;
  final String? statutString;
  final List<OrderItem> items;

  Order({
    required this.id,
    required this.source,
    required this.Reference,
    required this.codeClient,
    required this.NomClient,
    required this.AdresseClient,
    required this.CodeRep,
    required this.NomRep,
    required this.dateCommande,
    required this.dateLivraison,
    required this.total,
    required this.statut,
    required this.statutString,
    required this.items,
    required this.note,
  
  });

  // helpers
  static String _s(dynamic v) => v == null ? '' : v.toString().trim();
  static double _d(dynamic v) => v is num ? v.toDouble() : double.tryParse(_s(v)) ?? 0.0;
  static int _i(dynamic v) => v is num ? v.toInt() : int.tryParse(_s(v)) ?? 0;
  static DateTime? _dtOrNull(dynamic v) {
    final s = _s(v);
    if (s.isEmpty) return null;
    try {
      final dt = DateTime.parse(s);
      return dt.isUtc ? dt.toLocal() : dt;
    } catch (_) { return null; }
  }
  static DateTime _dt(dynamic v) =>
      _dtOrNull(v) ?? DateTime.fromMillisecondsSinceEpoch(0).toLocal();

  static dynamic _pick(Map j, List<String> keys) {
    for (final k in keys) { if (j.containsKey(k)) return j[k]; }
    return null;
  }

  factory Order.fromJson(Map<String, dynamic> j) {
    final rawItems = (_pick(j, ['Items','items']) as List?) ?? const [];
    return Order(
      id: (() { final v = _pick(j, ['Id','id','OrderId','orderId']); if (v == null) return null; final n = _i(v); return n==0?null:n; })(),
      source: _s(_pick(j, ['Source','source'])),
      note: _s(_pick(j, ['note'])),
      Reference: _s(_pick(j, ['Reference','reference','OrderReference','orderReference'])),
    codeClient: _s(_pick(j, ['Code_Client','codeClient','clientId'])),   // ✅ fix ici
      NomClient: _s(_pick(j, ['Nom_Client','ClientName','clientName'])),
      AdresseClient: _s(_pick(j, ['Adresse_Client','ClientAddress','clientAddress'])),
      CodeRep: _s(_pick(j, ['Code_Rep','RepCode','repCode'])),
      NomRep: _s(_pick(j, ['Nom_Rep','RepName','repName'])),
      dateCommande: _dt(_pick(j, ['Date_commande','OrderDate','CreatedAt','createdAt','orderDate'])),
      dateLivraison: _dtOrNull(_pick(j, ['Date_Livraison','DeliveryDate','dateLivraison'])),
      total: _d(_pick(j, ['Total','total','TotalAmount'])),
      statut: _i(_pick(j, ['StatutCommande','statutCommande','OrderStatus'])),
      statutString: _s(_pick(j, ['StatutCommandeString','statutCommandeString'])),
      items: rawItems.map((e) => OrderItem.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
    );
  }

  int get idOrZero => id ?? 0;
  DateTime get createdAt => dateCommande;
  String get clientId => codeClient;
  String get displayRef => (Reference?.isNotEmpty ?? false) ? Reference! : (id != null ? '#$id' : '#—');
  DateTime get effectiveDate => dateCommande.millisecondsSinceEpoch > 0 ? dateCommande : (dateLivraison ?? dateCommande);
}

class OrderItem {
  final String itmref;
  final int quantity;
  final double unitPrice;
  final double totalPrice;

  OrderItem({required this.itmref, required this.quantity, required this.unitPrice, required this.totalPrice});

  static String _s(dynamic v) => v == null ? '' : v.toString().trim();
  static double _d(dynamic v) => v is num ? v.toDouble() : double.tryParse(_s(v)) ?? 0.0;
  static int _i(dynamic v) => v is num ? v.toInt() : int.tryParse(_s(v)) ?? 0;
  static dynamic _pick(Map j, List<String> keys) { for (final k in keys) { if (j.containsKey(k)) return j[k]; } return null; }

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
    itmref: _s(_pick(json, ['Itmref','itmref','ItemReference','itemReference','sku','SKU'])),
    quantity: _i(_pick(json, ['Quantity','quantity','ItemQuantity','itemQuantity','qty','Qty'])),
    unitPrice: _d(_pick(json, ['UnitPrice','unitPrice','price','Price'])),
    totalPrice: _d(_pick(json, ['TotalPrice','totalPrice','ItemTotal','itemTotal','lineTotal','LineTotal'])),
  );
}
