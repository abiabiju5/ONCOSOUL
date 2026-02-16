class AppUser {
  final String name;
  final String userId;
  final String role;
  bool isActive;

  AppUser({
    required this.name,
    required this.userId,
    required this.role,
    this.isActive = true,
  });
}

class UserData {
  static List<AppUser> users = [

    // ✅ SUPER ADMIN
    AppUser(
      name: 'Super Admin',
      userId: 'S0001',
      role: 'Super Admin',
    ),

    // ✅ ADMIN USER
    AppUser(
      name: 'System Admin',
      userId: 'A1001',
      role: 'Admin',
    ),

    // ✅ PATIENT USER
    AppUser(
      name: 'Ananya R.',
      userId: 'P1001',
      role: 'Patient',
    ),

    // ✅ DOCTOR USER
    AppUser(
      name: 'Dr. Rahul Verma',
      userId: 'D2001',
      role: 'Doctor',
    ),

    // ✅ MEDICAL STAFF USER
    AppUser(
      name: 'Nurse Meera',
      userId: 'M3001',
      role: 'Medical Staff',
    ),
  ];

  static AppUser? findUser(String userId) {
    try {
      return users.firstWhere(
        (user) => user.userId.toUpperCase() ==
            userId.trim().toUpperCase(),
      );
    } catch (e) {
      return null;
    }
  }
}