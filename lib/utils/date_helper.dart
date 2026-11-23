class DateHelper {
  static const List<String> _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  static const List<String> _weekdays = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];

  static String getFormattedDate() {
    final now = DateTime.now();
    final weekday = _weekdays[now.weekday - 1];
    final month = _months[now.month - 1];
    final day = now.day;
    
    String suffix = 'th';
    if (day == 1 || day == 21 || day == 31) {
      suffix = 'st';
    } else if (day == 2 || day == 22) {
      suffix = 'nd';
    } else if (day == 3 || day == 23) {
      suffix = 'rd';
    }

    return '$weekday, $month $day$suffix';
  }

  static String getCurrentSemesterInfo() {
    final now = DateTime.now();
    // MoCU Semester 1: July - December, Semester 2: January - June
    final isSem1 = now.month >= 7 && now.month <= 12;
    final year1 = isSem1 ? now.year : now.year - 1;
    final year2 = year1 + 1;
    final sem = isSem1 ? 'Semester 1' : 'Semester 2';
    
    return 'Academic Year $year1/$year2 • $sem';
  }

  static String getTodayShort() {
    final now = DateTime.now();
    final weekday = _weekdays[now.weekday - 1];
    final month = _months[now.month - 1].substring(0, 3);
    return 'Today, $weekday $month ${now.day}';
  }
}
