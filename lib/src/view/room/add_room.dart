import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:booking_desktop/src/controllers/hotel_controller.dart';

class AddRoomPage extends StatefulWidget {
  final Map<String, dynamic>? editRoom;
  const AddRoomPage({super.key, this.editRoom});

  @override
  State<AddRoomPage> createState() => _AddRoomPageState();
}

class _AddRoomPageState extends State<AddRoomPage> {
  final _form = GlobalKey<FormState>();
  final HotelController hc = HotelController.to;

  final numberC = TextEditingController();
  final typeC = TextEditingController();
  final priceC = TextEditingController();
  final bedsC = TextEditingController(text: '1');
  final descC = TextEditingController();
  final amenitiesC = TextEditingController();

  final List<String> categories = [
    'Standard King Room',
    'Deluxe Suite',
    'Family Room',
  ];

  bool ac = false;
  bool active = true;
  List<String> images = [];
  int selectedImageIndex = 0;
  late PageController pageController;

  @override
  void initState() {
    super.initState();
    pageController = PageController(initialPage: 0);

    if (widget.editRoom != null) {
      final r = widget.editRoom!;
      numberC.text = r['number'] ?? '';
      typeC.text = r['type'] ?? '';
      priceC.text = (r['price'] ?? '').toString();
      bedsC.text = (r['beds'] ?? 1).toString();
      descC.text = r['description'] ?? '';
      amenitiesC.text = (r['amenities'] ?? '').split(';').join(', ');
      ac = r['ac'] == 1;
      active = r['active'] == 1;
      images =
          (r['images'] as String? ?? '')
              .split(';')
              .where((e) => e.isNotEmpty)
              .toList();
    }
  }

  @override
  void dispose() {
    pageController.dispose();
    numberC.dispose();
    typeC.dispose();
    priceC.dispose();
    bedsC.dispose();
    descC.dispose();
    amenitiesC.dispose();
    super.dispose();
  }

  Future<void> pickImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(imageQuality: 80);
    if (picked != null) {
      setState(() => images.addAll(picked.map((e) => e.path)));
    }
  }

  void removeImage(int index) {
    setState(() {
      images.removeAt(index);
      if (selectedImageIndex >= images.length)
        selectedImageIndex = images.length - 1;
      pageController.jumpToPage(selectedImageIndex);
    });
  }

  Future<void> save() async {
    if (!_form.currentState!.validate()) return;
    final map = {
      'number': numberC.text.trim(),
      'type': typeC.text.trim(),
      'price': double.tryParse(priceC.text.trim()) ?? 0,
      'beds': int.tryParse(bedsC.text.trim()) ?? 1,
      'ac': ac ? 1 : 0,
      'active': active ? 1 : 0,
      'description': descC.text.trim(),
      'amenities': amenitiesC.text
          .trim()
          .split(',')
          .map((e) => e.trim())
          .join(';'),
      'images': images.join(';'),
    };

    if (widget.editRoom != null) {
      await hc.updateRoom(
        int.tryParse(widget.editRoom!['id'] ?? '0') ?? 0,
        map,
      );
      Get.back();
    } else {
      await hc.addRoom(map);
      _clearForm();
      Get.snackbar('Saved', 'Room added', snackPosition: SnackPosition.BOTTOM);
    }
  }

  void _clearForm() {
    numberC.clear();
    typeC.clear();
    priceC.clear();
    bedsC.text = '1';
    descC.clear();
    amenitiesC.clear();
    ac = false;
    active = true;
    images.clear();
    selectedImageIndex = 0;
    pageController.jumpToPage(0);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 1200;
        return Scaffold(
          appBar: AppBar(
            title: Text(widget.editRoom != null ? 'Edit Room' : 'Add Room'),
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isDesktop ? 1200 : 600),
                child: isDesktop ? _desktopLayout() : _mobileLayout(),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _desktopLayout() => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(flex: 3, child: _formCard()),
      SizedBox(width: 24),
      Expanded(flex: 2, child: _previewCard()),
    ],
  );

  Widget _mobileLayout() =>
      Column(children: [_formCard(), SizedBox(height: 16), _previewCard()]);

  Widget _formCard() => Card(
    elevation: 4,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: Padding(
      padding: EdgeInsets.all(24),
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('Room Information'),
            SizedBox(height: 12),
            _buildTextField(
              numberC,
              'Room Number',
              keyboard: TextInputType.number,
              isRequired: true,
            ),
            SizedBox(height: 12),
            _buildTextField(typeC, 'Type (e.g Deluxe)'),
            SizedBox(height: 12),
            _buildTextField(
              priceC,
              'Price per night',
              keyboard: TextInputType.number,
            ),
            SizedBox(height: 12),
            _buildTextField(
              bedsC,
              'Number of Beds',
              keyboard: TextInputType.number,
            ),
            SizedBox(height: 12),
            _buildTextField(descC, 'Description', maxLines: 3),
            SizedBox(height: 12),
            _buildTextField(
              amenitiesC,
              'Amenities (comma separated)',
              maxLines: 2,
            ),
            SizedBox(height: 12),
            Row(
              children: [
                _buildSwitch('AC Included', ac, (v) => setState(() => ac = v)),
                SizedBox(width: 24),
                _buildSwitch(
                  'Active Status',
                  active,
                  (v) => setState(() => active = v),
                ),
              ],
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: save,
              icon: Icon(Icons.save),
              label: Text(
                widget.editRoom != null ? 'Update Room' : 'Save Room',
              ),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _previewCard() => Card(
    elevation: 4,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionTitle('Room Preview'),
          SizedBox(height: 12),
          if (images.isNotEmpty)
            Container(
              height: 250,
              child: Stack(
                children: [
                  PageView.builder(
                    controller: pageController,
                    itemCount: images.length,
                    onPageChanged:
                        (index) => setState(() => selectedImageIndex = index),
                    itemBuilder:
                        (_, index) => ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            File(images[index]),
                            fit: BoxFit.cover,
                          ),
                        ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => removeImage(selectedImageIndex),
                      child: Container(
                        padding: EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.delete,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              height: 250,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Center(
                child: TextButton.icon(
                  onPressed: pickImages,
                  icon: Icon(Icons.upload_file),
                  label: Text('Upload Image'),
                ),
              ),
            ),
          if (images.length > 1) ...[
            SizedBox(height: 8),
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: images.length,
                separatorBuilder: (_, __) => SizedBox(width: 8),
                itemBuilder:
                    (_, index) => GestureDetector(
                      onTap: () {
                        pageController.jumpToPage(index);
                        setState(() => selectedImageIndex = index);
                      },
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(images[index]),
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                          ),
                          if (index == selectedImageIndex)
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.blueAccent,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
              ),
            ),
          ],
          SizedBox(height: 16),
          _roomDetailRow('Number', numberC.text),
          _roomDetailRow('Type', typeC.text),
          _roomDetailRow('Price', '₨ ${priceC.text}'),
          _roomDetailRow('Beds', bedsC.text),
          _roomDetailRow('AC', ac ? 'Yes' : 'No'),
          _roomDetailRow('Active', active ? 'Yes' : 'No'),
        ],
      ),
    ),
  );

  Widget _roomDetailRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: [
        Text('$label: ', style: TextStyle(fontWeight: FontWeight.bold)),
        Expanded(child: Text(value)),
      ],
    ),
  );

  Widget _sectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      title,
      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
    ),
  );

  Widget _buildTextField(
    TextEditingController controller,
    String hint, {
    TextInputType keyboard = TextInputType.text,
    int maxLines = 1,
    bool isRequired = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      maxLines: maxLines,
      validator:
          (v) => isRequired && (v == null || v.isEmpty) ? 'Required' : null,
      decoration: InputDecoration(
        hintText: hint,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }

  Widget _buildSwitch(String label, bool value, ValueChanged<bool> onChanged) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [Text(label), Switch(value: value, onChanged: onChanged)],
    );
  }
}
