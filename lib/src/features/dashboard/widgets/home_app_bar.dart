import 'package:flutter/material.dart';

class HomeAppBar extends StatelessWidget {
  const HomeAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            // Avatar
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                shape: BoxShape.circle,
                image: const DecorationImage(
                  image: NetworkImage(
                    'https://i.pravatar.cc/150?img=11', // Mock Avatar
                  ),
                  fit: BoxFit.cover,
                ),
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Greeting Text
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Xin chào,',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                ),
                Text(
                  'Khách hàng',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
        // Actions
        Row(
          children: [
            // Notification Icon
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: IconButton(
                onPressed: () {},
                icon: const Icon(Icons.notifications_outlined),
                color: Colors.black87,
              ),
            ),
            const SizedBox(width: 12),
            // Logout Icon
            Container(
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.red.shade100),
              ),
              child: IconButton(
                onPressed: () {
                  // Navigate to LoginScreen and remove all previous routes
                  // Implementation note: Ideally navigate using named routes or a router package
                  // For now we assume LoginScreen is importable or will be fixed if not.
                  // Since we can't easily import a higher level file here without potential circular deps or path issues if not careful,
                  // I will use Navigator.pushAndRemoveUntil with a route builder that uses a dynamic import or assuming it's available.
                  // Actually, to avoid circular dependency (HomeAppBar -> LoginScreen -> MainLayout -> DashboardScreen -> HomeAppBar),
                  // we should use a named route or pass a callback.
                  // BUT for simplicity in this task, I will try to use Navigator with a direct MaterialPageRoute.
                  // I need to import LoginScreen first.
                  Navigator.of(
                    context,
                  ).pushNamedAndRemoveUntil('/', (route) => false);
                },
                icon: const Icon(Icons.logout),
                color: Colors.red,
                tooltip: 'Đăng xuất',
              ),
            ),
          ],
        ),
      ],
    );
  }
}
