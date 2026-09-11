import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api.config.dart';

// =======================================================================
// 🟢 หน้าจัดการเมนูอาหาร (MerchantMenu)
// =======================================================================
class MerchantMenu extends StatefulWidget {
  final dynamic merchantId;

  const MerchantMenu({super.key, required this.merchantId});

  @override
  State<MerchantMenu> createState() => _MerchantMenuState();
}

class _MerchantMenuState extends State<MerchantMenu> {
  final List<Map<String, dynamic>> _menuItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMenus();
  }

  Future<void> _loadMenus() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.merchantMenus(widget.merchantId)),
      );
      final body = jsonDecode(response.body);
      if (response.statusCode != 200 || body['success'] != true)
        throw Exception();
      final items = List<Map<String, dynamic>>.from(
        (body['data'] as List).map((raw) {
          final item = Map<String, dynamic>.from(raw);
          item['price'] = double.tryParse(item['price'].toString()) ?? 0;
          item['isAvailable'] =
              item['is_available'] == 1 || item['is_available'] == true;
          item['image'] = item['image_url'] ?? '';
          item['optionGroups'] = item['option_groups'] is String
              ? List<Map<String, dynamic>>.from(
                  jsonDecode(item['option_groups']),
                )
              : <Map<String, dynamic>>[];
          return item;
        }),
      );
      if (!mounted) return;
      setState(() {
        _menuItems
          ..clear()
          ..addAll(items);
        _isLoading = false;
      });
    } catch (error) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<String?> _uploadImage(File image) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConfig.baseUrl}/api/orders/upload-image'),
    );
    request.files.add(await http.MultipartFile.fromPath('image', image.path));
    final response = await request.send();
    if (response.statusCode != 200) return null;
    final body = jsonDecode(await response.stream.bytesToString());
    return body['url']?.toString() ??
        body['imageUrl']?.toString() ??
        body['image_url']?.toString();
  }

  void _confirmDelete(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'ลบเมนู',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'คุณต้องการลบเมนู "${_menuItems[index]['name']}" ใช่หรือไม่?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'ยกเลิก',
              style: TextStyle(color: Colors.black45),
            ),
          ),
          TextButton(
            onPressed: () async {
              final item = _menuItems[index];
              final response = await http.delete(
                Uri.parse(
                  '${ApiConfig.merchantMenus(widget.merchantId)}/${item['id']}',
                ),
              );
              if (response.statusCode != 200 || !mounted) return;
              setState(() => _menuItems.removeAt(index));
              Navigator.pop(context); // ปิด Dialog ลบ
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('ลบเมนูสำเร็จ'),
                  backgroundColor: Colors.redAccent,
                ),
              );
            },
            child: const Text(
              'ลบ',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // 🟢 ฟังก์ชันแสดงฟอร์มเพิ่ม/แก้ไขเมนูพร้อมเลือกรูปภาพ
  void _showMenuForm({Map<String, dynamic>? item, int? index}) {
    final nameController = TextEditingController(text: item?['name'] ?? '');
    final priceController = TextEditingController(
      text: item != null ? item['price'].toStringAsFixed(0) : '',
    );
    final quantityController = TextEditingController(
      text: item != null ? item['quantity'].toString() : '',
    );

    bool isAvailable = item?['isAvailable'] ?? true;
    File? selectedImage = item?['localImage']; // เก็บไฟล์รูประหว่างแก้ฟอร์ม

    // 🟢 แปลงข้อมูล "ตัวเลือกเสริม/รายการเมนูย่อย" (เช่น ระดับความเผ็ด, ขนาด) ของเมนูเดิมให้มี TextEditingController
    // สำหรับแก้ไขในฟอร์มนี้ — ถ้าเป็นการเพิ่มเมนูใหม่จะเริ่มต้นด้วยลิสต์ว่าง
    List<Map<String, dynamic>> optionGroups =
        item != null && item['optionGroups'] != null
        ? (item['optionGroups'] as List).map<Map<String, dynamic>>((g) {
            return {
              'nameController': TextEditingController(text: g['groupName']),
              'required': g['required'] ?? true,
              'options': (g['options'] as List).map<Map<String, dynamic>>((o) {
                return {
                  'nameController': TextEditingController(text: o['name']),
                  'priceController': TextEditingController(
                    text: (o['price'] as num).toStringAsFixed(0),
                  ),
                };
              }).toList(),
            };
          }).toList()
        : <Map<String, dynamic>>[];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 12.0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const SizedBox(width: 40),
                          Text(
                            item == null ? 'เพิ่มเมนูใหม่' : 'แก้ไขเมนู',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.grey),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),

                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 🟢 กล่องแก้ไขรูปภาพ (เพิ่ม image_picker เลือกจากเครื่องได้)
                            GestureDetector(
                              onTap: () async {
                                final picker = ImagePicker();
                                final pickedFile = await picker.pickImage(
                                  source: ImageSource.gallery,
                                );
                                if (pickedFile != null) {
                                  setModalState(() {
                                    selectedImage = File(
                                      pickedFile.path,
                                    ); // เซ็ตภาพใหม่ที่เลือก
                                  });
                                }
                              },
                              child: Center(
                                child: Stack(
                                  alignment: Alignment.bottomCenter,
                                  children: [
                                    Container(
                                      width: 120,
                                      height: 120,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: const Color(0xFFCBD5E1),
                                          width: 2,
                                        ),
                                        // แสดงรูป local ก่อน ถ้าไม่มีโชว์รูปลิงก์
                                        image: selectedImage != null
                                            ? DecorationImage(
                                                image: FileImage(
                                                  selectedImage!,
                                                ),
                                                fit: BoxFit.cover,
                                              )
                                            : (item != null &&
                                                  item['image'] != null)
                                            ? DecorationImage(
                                                image: NetworkImage(
                                                  item['image'],
                                                ),
                                                fit: BoxFit.cover,
                                              )
                                            : null,
                                      ),
                                      child:
                                          (selectedImage == null &&
                                              item == null)
                                          ? Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: const [
                                                Icon(
                                                  Icons.camera_alt_outlined,
                                                  color: Color(0xFF64748B),
                                                  size: 32,
                                                ),
                                                SizedBox(height: 8),
                                                Text(
                                                  'เพิ่มรูปภาพ',
                                                  style: TextStyle(
                                                    color: Color(0xFF64748B),
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            )
                                          : null,
                                    ),
                                    // 🟢 ป้ายดำโปร่งแสงด้านล่าง "แก้ไขรูปภาพ"
                                    if (selectedImage != null || item != null)
                                      Container(
                                        width: 120,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.6),
                                          borderRadius:
                                              const BorderRadius.vertical(
                                                bottom: Radius.circular(14),
                                              ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: const [
                                            Icon(
                                              Icons.camera_alt_outlined,
                                              color: Colors.white,
                                              size: 14,
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              'แก้ไขรูปภาพ',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            _buildInputField(
                              'ชื่อเมนู',
                              nameController,
                              Icons.restaurant_menu,
                            ),
                            const SizedBox(height: 16),
                            _buildInputField(
                              'ราคา (บาท)',
                              priceController,
                              null,
                              isNumber: true,
                              prefixText: '฿',
                            ),
                            const SizedBox(height: 16),
                            _buildInputField(
                              'ยอดคงเหลือ (ชิ้น)',
                              quantityController,
                              Icons.inventory_2_outlined,
                              isNumber: true,
                            ),
                            const SizedBox(height: 24),

                            // 🟢 ส่วนจัดการ "ตัวเลือกเสริม / รายการเมนูย่อย" เช่น ระดับความเผ็ด, ขนาด, ท็อปปิ้ง
                            const Text(
                              'ตัวเลือกเสริม (ไม่บังคับ)',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'เช่น ระดับความเผ็ด ขนาด หรือท็อปปิ้ง ที่ให้ลูกค้าเลือกตอนสั่งอาหาร',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 12),

                            ...optionGroups.asMap().entries.map((groupEntry) {
                              final int gIndex = groupEntry.key;
                              final Map<String, dynamic> group =
                                  groupEntry.value;
                              final TextEditingController groupNameController =
                                  group['nameController'];
                              final List<Map<String, dynamic>> options =
                                  group['options'];

                              return Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8F9FA),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextField(
                                            controller: groupNameController,
                                            decoration: InputDecoration(
                                              hintText:
                                                  'ชื่อกลุ่มตัวเลือก เช่น ระดับความเผ็ด',
                                              isDense: true,
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 12,
                                                  ),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                borderSide: BorderSide(
                                                  color: Colors.grey.shade300,
                                                ),
                                              ),
                                              filled: true,
                                              fillColor: Colors.white,
                                            ),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete_outline,
                                            color: Colors.redAccent,
                                          ),
                                          onPressed: () {
                                            setModalState(() {
                                              optionGroups.removeAt(gIndex);
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Checkbox(
                                          value: group['required'] as bool,
                                          activeColor: const Color(0xFF00C7E6),
                                          materialTapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                          onChanged: (val) {
                                            setModalState(() {
                                              group['required'] = val ?? true;
                                            });
                                          },
                                        ),
                                        const SizedBox(width: 4),
                                        const Text(
                                          'บังคับให้ลูกค้าเลือก 1 รายการ',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFF475569),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),

                                    ...options.asMap().entries.map((optEntry) {
                                      final int oIndex = optEntry.key;
                                      final Map<String, dynamic> option =
                                          optEntry.value;
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 8,
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              flex: 3,
                                              child: TextField(
                                                controller:
                                                    option['nameController'],
                                                decoration: InputDecoration(
                                                  hintText:
                                                      'ชื่อตัวเลือก เช่น เผ็ดน้อย',
                                                  isDense: true,
                                                  contentPadding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 10,
                                                      ),
                                                  border: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                    borderSide: BorderSide(
                                                      color:
                                                          Colors.grey.shade300,
                                                    ),
                                                  ),
                                                  filled: true,
                                                  fillColor: Colors.white,
                                                ),
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              flex: 2,
                                              child: TextField(
                                                controller:
                                                    option['priceController'],
                                                keyboardType:
                                                    const TextInputType.numberWithOptions(
                                                      decimal: false,
                                                    ),
                                                decoration: InputDecoration(
                                                  hintText: '+฿0',
                                                  isDense: true,
                                                  contentPadding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 10,
                                                      ),
                                                  border: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                    borderSide: BorderSide(
                                                      color:
                                                          Colors.grey.shade300,
                                                    ),
                                                  ),
                                                  filled: true,
                                                  fillColor: Colors.white,
                                                ),
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ),
                                            IconButton(
                                              padding: EdgeInsets.zero,
                                              constraints:
                                                  const BoxConstraints(),
                                              icon: const Icon(
                                                Icons.close,
                                                color: Colors.grey,
                                                size: 20,
                                              ),
                                              onPressed: () {
                                                setModalState(() {
                                                  options.removeAt(oIndex);
                                                });
                                              },
                                            ),
                                          ],
                                        ),
                                      );
                                    }),

                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: TextButton.icon(
                                        onPressed: () {
                                          setModalState(() {
                                            options.add({
                                              'nameController':
                                                  TextEditingController(),
                                              'priceController':
                                                  TextEditingController(
                                                    text: '0',
                                                  ),
                                            });
                                          });
                                        },
                                        style: TextButton.styleFrom(
                                          padding: EdgeInsets.zero,
                                          minimumSize: const Size(0, 32),
                                        ),
                                        icon: const Icon(
                                          Icons.add,
                                          size: 18,
                                          color: Color(0xFF00C7E6),
                                        ),
                                        label: const Text(
                                          'เพิ่มตัวเลือกย่อย',
                                          style: TextStyle(
                                            color: Color(0xFF00C7E6),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),

                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton.icon(
                                onPressed: () async {
                                  setModalState(() {
                                    optionGroups.add({
                                      'nameController': TextEditingController(),
                                      'required': true,
                                      'options': <Map<String, dynamic>>[],
                                    });
                                  });
                                },
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(0, 32),
                                ),
                                icon: const Icon(
                                  Icons.add_circle_outline,
                                  size: 18,
                                  color: Color(0xFF1E293B),
                                ),
                                label: const Text(
                                  'เพิ่มกลุ่มตัวเลือก',
                                  style: TextStyle(
                                    color: Color(0xFF1E293B),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8F9FA),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        isAvailable
                                            ? Icons.check_circle_outline
                                            : Icons.cancel_outlined,
                                        color: isAvailable
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'สถานะ: ${isAvailable ? "มีของ (พร้อมขาย)" : "ของหมด"}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Switch(
                                    value: isAvailable,
                                    activeColor: Colors.white,
                                    activeTrackColor: Colors.green,
                                    inactiveThumbColor: Colors.white,
                                    inactiveTrackColor: Colors.red,
                                    onChanged: (val) {
                                      setModalState(() {
                                        isAvailable = val;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 32),

                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF00C7E6),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                ),
                                onPressed: () async {
                                  if (nameController.text.isNotEmpty &&
                                      priceController.text.isNotEmpty &&
                                      quantityController.text.isNotEmpty) {
                                    // 🟢 แปลงกลุ่มตัวเลือกเสริม (optionGroups) จากฟอร์มกลับเป็นข้อมูลธรรมดาก่อนบันทึก
                                    // ข้ามกลุ่ม/ตัวเลือกที่ยังไม่ได้ตั้งชื่อ (ผู้ค้ากดเพิ่มไว้แต่ยังไม่กรอก)
                                    final List<Map<String, dynamic>>
                                    savedOptionGroups = optionGroups
                                        .where(
                                          (g) =>
                                              (g['nameController']
                                                      as TextEditingController)
                                                  .text
                                                  .trim()
                                                  .isNotEmpty,
                                        )
                                        .map((g) {
                                          final List<Map<String, dynamic>>
                                          savedOptions =
                                              (g['options']
                                                      as List<
                                                        Map<String, dynamic>
                                                      >)
                                                  .where(
                                                    (o) =>
                                                        (o['nameController']
                                                                as TextEditingController)
                                                            .text
                                                            .trim()
                                                            .isNotEmpty,
                                                  )
                                                  .map(
                                                    (o) => {
                                                      'name':
                                                          (o['nameController']
                                                                  as TextEditingController)
                                                              .text
                                                              .trim(),
                                                      'price':
                                                          double.tryParse(
                                                            (o['priceController']
                                                                    as TextEditingController)
                                                                .text
                                                                .trim(),
                                                          ) ??
                                                          0.0,
                                                    },
                                                  )
                                                  .toList();
                                          return {
                                            'groupName':
                                                (g['nameController']
                                                        as TextEditingController)
                                                    .text
                                                    .trim(),
                                            'required': g['required'] as bool,
                                            'options': savedOptions,
                                          };
                                        })
                                        .toList();

                                    String imageUrl = item?['image'] ?? '';
                                    if (selectedImage != null) {
                                      imageUrl =
                                          await _uploadImage(selectedImage!) ??
                                          imageUrl;
                                    }
                                    final data = {
                                      'name': nameController.text.trim(),
                                      'price':
                                          double.tryParse(
                                            priceController.text,
                                          ) ??
                                          0.0,
                                      'quantity':
                                          int.tryParse(
                                            quantityController.text,
                                          ) ??
                                          0,
                                      'is_available': isAvailable,
                                      'image_url': imageUrl,
                                      'option_groups': savedOptionGroups,
                                    };
                                    final url = item == null
                                        ? ApiConfig.merchantMenus(
                                            widget.merchantId,
                                          )
                                        : '${ApiConfig.merchantMenus(widget.merchantId)}/${item['id']}';
                                    final response = item == null
                                        ? await http.post(
                                            Uri.parse(url),
                                            headers: {
                                              'Content-Type':
                                                  'application/json',
                                            },
                                            body: jsonEncode(data),
                                          )
                                        : await http.put(
                                            Uri.parse(url),
                                            headers: {
                                              'Content-Type':
                                                  'application/json',
                                            },
                                            body: jsonEncode(data),
                                          );
                                    if (response.statusCode != 200 &&
                                        response.statusCode != 201)
                                      return;
                                    Navigator.pop(context);
                                    await _loadMenus();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          item == null
                                              ? 'เพิ่มเมนูใหม่สำเร็จ'
                                              : 'แก้ไขเมนูสำเร็จ',
                                        ),
                                        backgroundColor: const Color(
                                          0xFF00C7E6,
                                        ),
                                      ),
                                    );
                                  }
                                },
                                child: const Text(
                                  'บันทึก',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),

                            if (item != null) ...[
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: TextButton(
                                  style: TextButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                  ),
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _confirmDelete(index!);
                                  },
                                  child: const Text(
                                    'ลบเมนู',
                                    style: TextStyle(
                                      color: Colors.redAccent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInputField(
    String label,
    TextEditingController controller,
    IconData? icon, {
    bool isNumber = false,
    String? prefixText,
  }) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        // 🟢 ถ้ามี prefixText (เช่น "฿") ให้แสดงเป็นตัวอักษรแทนไอคอน เพราะ Flutter ไม่มีไอคอนสัญลักษณ์บาทให้ใช้
        prefixIcon: prefixText != null
            ? SizedBox(
                width: 24,
                child: Center(
                  child: Text(
                    prefixText,
                    style: const TextStyle(
                      color: Color(0xFF00C7E6),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              )
            : Icon(icon, color: const Color(0xFF00C7E6)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF00C7E6), width: 2),
        ),
        filled: true,
        fillColor: const Color(0xFFF8F9FA),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Color(0xFF0B1A30),
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'จัดการเมนูอาหาร',
          style: TextStyle(
            color: Color(0xFF0B1A30),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _menuItems.isEmpty
          ? const Center(
              child: Text(
                'ยังไม่มีเมนูอาหาร',
                style: TextStyle(color: Colors.black45, fontSize: 16),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: 80,
              ),
              itemCount: _menuItems.length,
              itemBuilder: (context, index) {
                final item = _menuItems[index];

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // 🟢 โชว์รูปภาพในลิสต์รายการ (แยกระหว่างรูปจากเครื่อง กับ รูปจากเน็ต)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: item['localImage'] != null
                            ? Image.file(
                                item['localImage'],
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              )
                            : (item['image']?.toString().isEmpty ?? true)
                            ? Container(
                                width: 80,
                                height: 80,
                                color: const Color(0xFFF4F5F7),
                                child: const Icon(
                                  Icons.restaurant_menu,
                                  color: Color(0xFF64748B),
                                ),
                              )
                            : Image.network(
                                item['image'],
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                      width: 80,
                                      height: 80,
                                      color: const Color(0xFFF4F5F7),
                                      child: const Icon(
                                        Icons.restaurant_menu,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                              ),
                      ),
                      const SizedBox(width: 16),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['name'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Color(0xFF0B1A30),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '฿${item['price'].toStringAsFixed(0)}',
                              style: const TextStyle(
                                color: Color(0xFF00C7E6),
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item['isAvailable']
                                  ? 'ยอดคงเหลือ ${item['quantity']} ชิ้น'
                                  : 'สินค้าหมด',
                              style: TextStyle(
                                color: item['isAvailable']
                                    ? Colors.black54
                                    : Colors.red,
                                fontSize: 13,
                                fontWeight: item['isAvailable']
                                    ? FontWeight.normal
                                    : FontWeight.bold,
                              ),
                            ),
                            // 🟢 แสดงจำนวนกลุ่มตัวเลือกเสริม/รายการเมนูย่อย ถ้าเมนูนี้มีการตั้งค่าไว้
                            if (item['optionGroups'] != null &&
                                (item['optionGroups'] as List).isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                '${(item['optionGroups'] as List).length} ตัวเลือกเสริม',
                                style: const TextStyle(
                                  color: Color(0xFF00C7E6),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(
                          Icons.edit_outlined,
                          color: Color(0xFF64748B),
                          size: 28,
                        ),
                        onPressed: () =>
                            _showMenuForm(item: item, index: index),
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00C7E6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              elevation: 2,
            ),
            onPressed: () => _showMenuForm(), // เปิดฟอร์ม
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text(
              'เพิ่มเมนูใหม่',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
