class PolicyDocument {
  final String name;
  final String displayName;
  final String category;
  final String downloadUrl;

  PolicyDocument({
    required this.name,
    required this.displayName,
    required this.category,
    required this.downloadUrl,
  });

  factory PolicyDocument.fromGitHub(Map<String, dynamic> json) {
    final name = json['name'] as String;
    final displayName = name.replaceAll('.pdf', '').replaceAll('.docx', '');
    final category = _categorize(name);
    final downloadUrl = json['download_url'] as String? ?? '';

    return PolicyDocument(
      name: name,
      displayName: displayName,
      category: category,
      downloadUrl: downloadUrl,
    );
  }

  static String _categorize(String name) {
    final upper = name.toUpperCase();
    if (upper.startsWith('NPCJ')) return 'NPCJ';
    if (upper.startsWith('JCF')) return 'JCF';
    if (upper.startsWith('TMMD')) return 'TMMD';
    if (upper.startsWith('PMMD')) return 'PMMD';
    if (upper.startsWith('CIB')) return 'CIB';
    if (upper.startsWith('PECC')) return 'PECC';
    if (upper.startsWith('PRDB')) return 'PRDB';
    if (upper.startsWith('SIMU')) return 'SIMU';
    if (upper.startsWith('CCN')) return 'CCN';
    if (upper.startsWith('PMAS')) return 'PMAS';
    if (upper.startsWith('FLPD')) return 'FLPD';
    if (upper.startsWith('FIPT')) return 'FIPT';
    if (upper.startsWith('DWTT')) return 'DWTT';
    if (upper.startsWith('FIBUA')) return 'FIBUA';
    if (upper.startsWith('PPMU')) return 'PPMU';
    if (upper.startsWith('ICTD')) return 'ICTD';
    if (upper.startsWith('ICT')) return 'ICT';
    if (upper.startsWith('SOP')) return 'SOPs';
    if (upper.startsWith('NATIONAL')) return 'NPCJ';
    if (upper.contains('JAMAICA_CONSTABULARY') || upper.contains('JAMAICA CONSTABULARY')) return 'JCF';
    return 'General';
  }
}
