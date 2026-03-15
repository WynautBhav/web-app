class User {
  final String id;
  final String name;
  final String email;
  final String phoneNumber;
  final String? profileImageUrl;
  final int securityScore;
  final double fraudPrevented;
  final bool isAccountFrozen;
  final double accountBalance;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.phoneNumber,
    this.profileImageUrl,
    required this.securityScore,
    required this.fraudPrevented,
    this.isAccountFrozen = false,
    this.accountBalance = 12450.00,
  });

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? phoneNumber,
    String? profileImageUrl,
    int? securityScore,
    double? fraudPrevented,
    bool? isAccountFrozen,
    double? accountBalance,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      securityScore: securityScore ?? this.securityScore,
      fraudPrevented: fraudPrevented ?? this.fraudPrevented,
      isAccountFrozen: isAccountFrozen ?? this.isAccountFrozen,
      accountBalance: accountBalance ?? this.accountBalance,
    );
  }
}
