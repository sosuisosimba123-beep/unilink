class NameMatcher {
  static bool matches(String timetableInstructor, String dbLecturerName) {
    if (timetableInstructor.isEmpty || dbLecturerName.isEmpty) return false;
    
    final tClean = _normalize(timetableInstructor);
    final dClean = _normalize(dbLecturerName);

    // Exact match after normalization
    if (tClean == dClean) return true;

    // Substring match (e.g., "bakari" matches "dr. bakari" or "j. mwita" matches "johness mwita")
    final tParts = tClean.split(' ').where((p) => p.isNotEmpty).toList();
    final dParts = dClean.split(' ').where((p) => p.isNotEmpty).toList();

    if (tParts.isEmpty || dParts.isEmpty) return false;

    // Compare last names
    final String tLast = tParts.last;
    final String dLast = dParts.last;

    if (tLast == dLast) {
      // Compare first initial
      if (tParts.first[0] == dParts.first[0]) {
        return true;
      }
    }

    return tClean.contains(dClean) || dClean.contains(tClean);
  }

  static String _normalize(String name) {
    return name
        .toLowerCase()
        .replaceAll('dr.', '')
        .replaceAll('prof.', '')
        .replaceAll('mr.', '')
        .replaceAll('ms.', '')
        .replaceAll('eng.', '')
        .replaceAll('.', '')
        .trim();
  }
}
