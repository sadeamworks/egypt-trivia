/// Trivia categories with Arabic names and icons
class Category {
  final String id;
  final String nameAr;
  final String icon;

  const Category({
    required this.id,
    required this.nameAr,
    required this.icon,
  });
}

class Categories {
  Categories._();

  static const List<Category> all = [
    Category(
      id: 'history',
      nameAr: 'تاريخ مصر',
      icon: '🏛️',
    ),
    // Additional categories for future slices
    Category(
      id: 'geography',
      nameAr: 'جغرافيا',
      icon: '🗺️',
    ),
    Category(
      id: 'islamic',
      nameAr: 'إسلاميات',
      icon: '🕌',
    ),
    Category(
      id: 'culture',
      nameAr: 'ثقافة شعبية',
      icon: '🎭',
    ),
    Category(
      id: 'cinema',
      nameAr: 'أفلام مصرية',
      icon: '🎬',
    ),
    Category(
      id: 'football',
      nameAr: 'كرة قدم',
      icon: '⚽',
    ),
    Category(
      id: 'monuments',
      nameAr: 'أهرامات وآثار',
      icon: '🏜️',
    ),
    Category(
      id: 'proverbs',
      nameAr: 'أمثال شعبية',
      icon: '🗣️',
    ),
  ];

  static Category get history => all.firstWhere((c) => c.id == 'history');
}
