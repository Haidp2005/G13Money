class CategoryItem {
  final String id;
  final String name;
  final String type;
  final String iconKey;
  final String colorHex;
  final bool isDefault;

  const CategoryItem({
    required this.id,
    required this.name,
    required this.type,
    required this.iconKey,
    required this.colorHex,
    required this.isDefault,
  });

  CategoryItem copyWith({
    String? id,
    String? name,
    String? type,
    String? iconKey,
    String? colorHex,
    bool? isDefault,
  }) {
    return CategoryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      iconKey: iconKey ?? this.iconKey,
      colorHex: colorHex ?? this.colorHex,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}
