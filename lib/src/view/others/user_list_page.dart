import 'dart:io';

import 'package:booking_desktop/src/controllers/hotel_controller.dart';
import 'package:booking_desktop/src/view/others/edit_user_page.dart';
import 'package:booking_desktop/src/view/others/user_deatils_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class UsersListPage extends StatelessWidget {
  const UsersListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final hc = HotelController.to;
    return Scaffold(
      appBar: AppBar(title: Text('Guests')),
      body: Obx(() {
        final list = hc.users;
        if (list.isEmpty) return Center(child: Text('No guests'));
        return ListView.separated(
          padding: EdgeInsets.all(12),
          itemCount: list.length,
          itemBuilder: (_, i) {
            final u = list[i];
            return Card(
              child: ListTile(
                leading:
                    u['idImagePath'] != null &&
                            (u['idImagePath'] as String).isNotEmpty
                        ? CircleAvatar(
                          backgroundImage: FileImage(File(u['idImagePath'])),
                        )
                        : CircleAvatar(child: Icon(Icons.person)),
                title: Text(u['name'] ?? ''),
                subtitle: Text(u['phone'] ?? ''),
                trailing: PopupMenuButton<String>(
                  onSelected: (v) async {
                    if (v == 'edit') Get.to(() => UserEditPage(editUser: u));
                    if (v == 'delete') await hc.deleteUser(u['id'] as int);
                  },
                  itemBuilder:
                      (_) => [
                        PopupMenuItem(value: 'edit', child: Text('Edit')),
                        PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                ),
                onTap: () => Get.to(() => UserDetailPage(user: u)),
              ),
            );
          },
          separatorBuilder: (_, __) => SizedBox(height: 8),
        );
      }),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () => Get.to(() => UserEditPage()),
      ),
    );
  }
}
