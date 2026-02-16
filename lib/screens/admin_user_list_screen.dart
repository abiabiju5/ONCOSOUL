import 'package:flutter/material.dart';
import '../models/user_model.dart';

class AdminUserListScreen extends StatefulWidget {
  const AdminUserListScreen({super.key});

  @override
  State<AdminUserListScreen> createState() =>
      _AdminUserListScreenState();
}

class _AdminUserListScreenState
    extends State<AdminUserListScreen> {

  final Color deepBlue =
      const Color(0xFF0D47A1);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Registered Users'),
      ),
      body: ListView.builder(
        padding:
            const EdgeInsets.all(16),
        itemCount:
            UserData.users.length,
        itemBuilder:
            (context, index) {

          final user =
              UserData.users[index];

          return Card(
            child: ListTile(
              leading:
                  CircleAvatar(
                backgroundColor:
                    deepBlue
                        .withOpacity(
                            0.15),
                child: Text(
                  user.role[0],
                  style:
                      TextStyle(
                    color:
                        deepBlue,
                    fontWeight:
                        FontWeight
                            .bold,
                  ),
                ),
              ),
              title:
                  Text(user.name),
              subtitle: Text(
                'ID: ${user.userId}\nRole: ${user.role}',
              ),
              isThreeLine: true,

              trailing: Switch(
                value:
                    user.isActive,
                activeColor:
                    Colors.green,
                onChanged:
                    (value) {
                  setState(() {
                    user.isActive =
                        value;
                  });
                },
              ),
            ),
          );
        },
      ),
    );
  }
}