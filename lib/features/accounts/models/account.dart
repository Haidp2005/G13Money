class Account {
	final String id;
	final String name;
	final String type;
	final double balance;
	final String colorHex;
	final bool isArchived;

	const Account({
		required this.id,
		required this.name,
		required this.type,
		required this.balance,
		required this.colorHex,
		required this.isArchived,
	});

	Account copyWith({
		String? id,
		String? name,
		String? type,
		double? balance,
		String? colorHex,
		bool? isArchived,
	}) {
		return Account(
			id: id ?? this.id,
			name: name ?? this.name,
			type: type ?? this.type,
			balance: balance ?? this.balance,
			colorHex: colorHex ?? this.colorHex,
			isArchived: isArchived ?? this.isArchived,
		);
	}
}
