import 'package:booking_desktop/src/app_config/styles.dart';
import 'package:booking_desktop/src/controllers/hotel_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class UserEditPage extends StatefulWidget {
  final Map<String, dynamic>? editUser;
  const UserEditPage({super.key, this.editUser});
  @override
  State<UserEditPage> createState() => _UserEditPageState();
}

class _UserEditPageState extends State<UserEditPage> {
  final _form = GlobalKey<FormState>();
  final nameC = TextEditingController();
  final phoneC = TextEditingController();
  final emailC = TextEditingController();
  final addressC = TextEditingController();
  String? imagePath;
  final hc = HotelController.to;
  @override
  void initState() {
    super.initState();
    if (widget.editUser != null) {
      final u = widget.editUser!;
      nameC.text = u['name'] ?? '';
      phoneC.text = u['phone'] ?? '';
      emailC.text = u['email'] ?? '';
      addressC.text = u['address'] ?? '';
      imagePath = u['idImagePath'] ?? '';
    }
  }

  @override
  void dispose() {
    nameC.dispose();
    phoneC.dispose();
    emailC.dispose();
    addressC.dispose();
    super.dispose();
  }

  Future<void> pickImage() async {
    final p = ImagePicker();
    final XFile? f = await p.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (f != null) {
      setState(() {
        imagePath = f.path;
      });
    }
  }

  Future<void> save() async {
    if (!_form.currentState!.validate()) return;
    final map = {
      'name': nameC.text.trim(),
      'phone': phoneC.text.trim(),
      'email': emailC.text.trim(),
      'address': addressC.text.trim(),
      'idImagePath': imagePath ?? '',
    };
    if (widget.editUser != null) {
      await hc.updateUser(int.tryParse(widget.editUser!['id']) ?? -1, map);
      Get.back();
    } else {
      await hc.addUser(map);
      nameC.clear();
      phoneC.clear();
      emailC.clear();
      addressC.clear();
      imagePath = null;
      setState(() {});
      Get.snackbar('Saved', 'Guest added', snackPosition: SnackPosition.BOTTOM);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.editUser != null ? 'Edit Guest' : 'Add Guest'),
      ),
      body: Padding(
        padding: EdgeInsets.all(12),
        child: Form(
          key: _form,
          child: Column(
            children: [
              TextFormField(
                controller: nameC,
                decoration: InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              SizedBox(height: 8),
              TextFormField(
                controller: phoneC,
                decoration: InputDecoration(
                  labelText: 'Phone',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              SizedBox(height: 8),
              TextFormField(
                controller: addressC,
                decoration: InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              SizedBox(height: 8),
              TextFormField(
                controller: emailC,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: pickImage,
                    icon: Icon(Icons.image),
                    label: Text('Pick ID Image'),
                  ),
                  SizedBox(width: 12),
                  if (imagePath != null && imagePath!.isNotEmpty)
                    Text(
                      'Selected',
                      style: TextStyle(color: AppColors.checkedIn),
                    ),
                ],
              ),
              SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: save,
                icon: Icon(Icons.save),
                label: Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
