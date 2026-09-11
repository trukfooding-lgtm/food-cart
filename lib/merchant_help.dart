import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

// =======================================================================
// หน้าติดต่อช่วยเหลือ (MerchantHelp)
// =======================================================================
class MerchantHelp extends StatelessWidget {
  const MerchantHelp({super.key});

  // 🟢 ฟังก์ชันเปิดลิงก์ภายนอก (เว็บไซต์ช่วยเหลือ, LINE, โทรศัพท์, อีเมล) อย่างปลอดภัย
  Future<void> _launchExternal(BuildContext context, Uri uri) async {
    try {
      final bool launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ไม่สามารถเปิดลิงก์ได้: $uri'), backgroundColor: Colors.redAccent),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Widget _buildSupportTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF00C7E6).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: const Color(0xFF00C7E6), size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B))),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(question, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B))),
          const SizedBox(height: 6),
          Text(answer, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.5)),
        ],
      ),
    );
  }

  // 🟢 แต่ละหัวข้อแสดงเป็นการ์ดสีขาวแยกทีละใบ กดแล้วเปิด Bottom Sheet บอกวิธีทำทีละขั้นตอนพร้อมภาพประกอบ
  Widget _buildFaqTile(BuildContext context, String question, String intro, List<MerchantHelpGuideStep> steps) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showFaqGuideSheet(context, question, intro, steps),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  question,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF1E293B)),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  // 🟢 Bottom Sheet แสดงวิธีทำทีละขั้นตอน (เลื่อนดูได้ถ้าเนื้อหายาว) พร้อมภาพประกอบทุกขั้นตอน
  void _showFaqGuideSheet(BuildContext context, String question, String intro, List<MerchantHelpGuideStep> steps) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  Text(
                    question,
                    style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Color(0xFF0B1A30), height: 1.4),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    intro,
                    style: const TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.6),
                  ),
                  const SizedBox(height: 24),
                  ...steps.asMap().entries.map((entry) => _buildGuideStepSection(entry.key + 1, entry.value)),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // 🟢 แต่ละขั้นตอน: หัวข้อตัวหนา + คำอธิบาย (ถ้ามี) + ภาพจำลองหน้าจอ + กล่องสีฟ้า "วิธีทำ"
  Widget _buildGuideStepSection(int number, MerchantHelpGuideStep step) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$number. ${step.title}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0B1A30)),
          ),
          if (step.description != null) ...[
            const SizedBox(height: 6),
            Text(
              step.description!,
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.6),
            ),
          ],
          const SizedBox(height: 12),
          // 🟢 ภาพจำลองหน้าจอแอปร้านค้าประกอบขั้นตอนนี้ (ถ้ามี)
          if (step.illustration != null) _buildIllustrationPreview(step.illustration!),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF00C7E6).withOpacity(0.06),
              borderRadius: BorderRadius.circular(14),
              border: const Border(left: BorderSide(color: Color(0xFF00C7E6), width: 4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'วิธีทำ',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF00C7E6)),
                ),
                const SizedBox(height: 8),
                ...step.howTo.asMap().entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      '${entry.key + 1}. ${entry.value}',
                      style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B), height: 1.6),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===================================================================
  // 🟢 ภาพจำลองหน้าจอแอปร้านค้า (ทำจากองค์ประกอบ UI จริงของแอป เช่น แถบเมนูล่าง,
  // ไอคอนเมนูจัดการร้านด่วน, ปุ่ม, สวิตช์) ใช้แทนภาพสกรีนช็อตจริง เพื่อชี้ตำแหน่งที่ต้องกด
  // ===================================================================
  Widget _buildIllustrationPreview(HelpIllustration illustration) {
    Widget content;
    switch (illustration.type) {
      case HelpIllustrationType.bottomNav:
        content = _mockBottomNav(illustration.label);
        break;
      case HelpIllustrationType.quickMenu:
        content = _mockQuickMenu(illustration.label);
        break;
      case HelpIllustrationType.settingsRow:
        content = _mockSettingsRow(illustration.label, illustration.icon ?? Icons.settings_outlined);
        break;
      case HelpIllustrationType.buttonChip:
        content = _mockButtonChip(illustration.label, illustration.icon);
        break;
      case HelpIllustrationType.buttonBlock:
        content = _mockButtonBlock(illustration.label);
        break;
      case HelpIllustrationType.toggleSwitch:
        content = _mockToggleRow(illustration.label);
        break;
      case HelpIllustrationType.iconRow:
        content = _mockIconRow();
        break;
      case HelpIllustrationType.filterChip:
        content = _mockFilterChips(illustration.label);
        break;
      case HelpIllustrationType.ratingSummary:
        content = _mockRatingSummary(illustration.label);
        break;
      case HelpIllustrationType.menuItemRow:
        content = _mockMenuItemRow(illustration.label);
        break;
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ตัวอย่างหน้าจอ',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade500, letterSpacing: 0.5),
          ),
          const SizedBox(height: 10),
          content,
        ],
      ),
    );
  }

  // จำลองแถบเมนูด้านล่างของแอป พร้อมไฮไลต์แท็บที่ต้องกด
  Widget _mockBottomNav(String highlightLabel) {
    final items = [
      {'label': 'หน้าหลัก', 'icon': Icons.home_outlined, 'activeIcon': Icons.home},
      {'label': 'คำสั่งซื้อ', 'icon': Icons.receipt_long_outlined, 'activeIcon': Icons.receipt_long},
      {'label': 'รายได้', 'icon': Icons.account_balance_wallet_outlined, 'activeIcon': Icons.account_balance_wallet},
      {'label': 'โปรไฟล์', 'icon': Icons.person_outline, 'activeIcon': Icons.person},
    ];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items.map((item) {
          final bool isActive = item['label'] == highlightLabel;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isActive ? item['activeIcon'] as IconData : item['icon'] as IconData,
                color: isActive ? const Color(0xFF00C7E6) : Colors.grey,
                size: 20,
              ),
              const SizedBox(height: 2),
              Text(
                item['label'] as String,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  color: isActive ? const Color(0xFF00C7E6) : Colors.grey,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  // จำลองแถบ "เมนูจัดการร้านด่วน" ในหน้าหลัก พร้อมไฮไลต์ไอคอนที่ต้องกด
  Widget _mockQuickMenu(String highlightLabel) {
    final items = [
      {'label': 'จัดการออเดอร์', 'icon': Icons.receipt_long},
      {'label': 'แก้ไขเมนู', 'icon': Icons.restaurant_menu},
      {'label': 'สถานะร้านค้า', 'icon': Icons.storefront},
      {'label': 'แผนที่จุดขาย', 'icon': Icons.location_on_outlined},
      {'label': 'ตั้งค่าร้านค้า', 'icon': Icons.settings_outlined},
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: items.map((item) {
          final bool isActive = item['label'] == highlightLabel;
          return Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isActive ? const Color(0xFF00C7E6) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isActive ? const Color(0xFF00C7E6) : Colors.grey.shade300),
                    boxShadow: isActive
                        ? []
                        : [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4)],
                  ),
                  child: Icon(
                    item['icon'] as IconData,
                    size: 20,
                    color: isActive ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: 56,
                  child: Text(
                    item['label'] as String,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                      color: isActive ? const Color(0xFF00C7E6) : const Color(0xFF1E293B),
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // จำลองแถวเมนูในหน้าตั้งค่า (มีขอบสีฟ้าล้อมเพื่อชี้ว่าต้องกดแถวนี้)
  Widget _mockSettingsRow(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF00C7E6), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade300)),
            child: Icon(icon, size: 16, color: const Color(0xFF1E293B)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
          ),
          const Icon(Icons.chevron_right, size: 16, color: Color(0xFF00C7E6)),
        ],
      ),
    );
  }

  // จำลองปุ่มเล็ก (pill) เช่น "เปลี่ยนพิกัด"
  Widget _mockButtonChip(String label, IconData? icon) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF00C7E6), width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: const Color(0xFF00C7E6)),
              const SizedBox(width: 6),
            ],
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF00C7E6))),
          ],
        ),
      ),
    );
  }

  // จำลองปุ่มเต็มความกว้าง (เช่น "อัปเดตตำแหน่งปัจจุบัน", "ถอนเงิน", "เพิ่มเมนูใหม่")
  Widget _mockButtonBlock(String label) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      alignment: Alignment.center,
      decoration: BoxDecoration(color: const Color(0xFF00C7E6), borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
    );
  }

  // จำลองแถวมีสวิตช์ เช่น "สถานะร้าน"
  Widget _mockToggleRow(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
          ),
          Container(
            width: 34,
            height: 20,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(color: const Color(0xFF00C7E6), borderRadius: BorderRadius.circular(20)),
            child: Align(
              alignment: Alignment.centerRight,
              child: Container(width: 16, height: 16, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
            ),
          ),
        ],
      ),
    );
  }

  // จำลองไอคอน Wi-Fi / สัญญาณมือถือ สำหรับขั้นตอนตรวจสอบอินเทอร์เน็ต
  Widget _mockIconRow() {
    return Row(
      children: [
        _iconWithLabel(Icons.wifi, 'Wi-Fi'),
        const SizedBox(width: 24),
        _iconWithLabel(Icons.signal_cellular_alt, 'สัญญาณมือถือ'),
      ],
    );
  }

  Widget _iconWithLabel(IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: const Color(0xFF00C7E6).withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: const Color(0xFF00C7E6), size: 20),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
      ],
    );
  }

  // จำลองแถบตัวกรองสถานะออเดอร์ พร้อมไฮไลต์ตัวที่ต้องกด
  Widget _mockFilterChips(String highlightLabel) {
    final filters = ['ทั้งหมด', 'ใหม่', 'กำลังปรุง', 'เสร็จสิ้น'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((f) {
          final bool isActive = f == highlightLabel;
          return Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFF00C7E6) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isActive ? const Color(0xFF00C7E6) : Colors.grey.shade300),
            ),
            child: Text(
              f,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isActive ? Colors.white : const Color(0xFF1E293B)),
            ),
          );
        }).toList(),
      ),
    );
  }

  // จำลองสรุปคะแนนรีวิว (ดาว + ตัวเลขคะแนน)
  Widget _mockRatingSummary(String scoreLabel) {
    return Row(
      children: [
        Text(scoreLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Color(0xFF1E293B))),
        const SizedBox(width: 8),
        Row(children: List.generate(5, (i) => const Icon(Icons.star, color: Colors.amber, size: 14))),
      ],
    );
  }

  // จำลองแถวรายการเมนูอาหาร 1 รายการ พร้อมไอคอนดินสอสำหรับกดแก้ไข
  Widget _mockMenuItemRow(String label) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: const Color(0xFFF4F5F7), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.restaurant_menu, size: 16, color: Color(0xFF64748B)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
          ),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFF00C7E6))),
            child: const Icon(Icons.edit_outlined, size: 14, color: Color(0xFF00C7E6)),
          ),
        ],
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
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF0B1A30), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'ติดต่อช่วยเหลือ',
          style: TextStyle(color: Color(0xFF0B1A30), fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ติดต่อฝ่ายสนับสนุน',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0B1A30)),
            ),
            const SizedBox(height: 4),
            const Text(
              'ทีมงานพร้อมช่วยเหลือคุณทุกวัน 10:00 - 18:00 น.',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                  _buildSupportTile(
                    icon: Icons.email_outlined,
                    title: 'อีเมลถึงฝ่ายสนับสนุน',
                    subtitle: 'trukfo.support@example.com',
                    onTap: () => _launchExternal(context, Uri.parse('mailto:trukfo.support@example.com')),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            const Text(
              'คำถามที่พบบ่อย',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0B1A30)),
            ),
            const SizedBox(height: 4),
            const Text(
              'กดแต่ละหัวข้อเพื่อดูวิธีทำแบบทีละขั้นตอนพร้อมภาพประกอบ',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 16),

            // 🟢 "ทำไมออเดอร์ถึงไม่เข้ามาในระบบ ?" — อธิบายวิธีตรวจสอบทีละขั้นตอน
            _buildFaqTile(
              context,
              'ทำไมออเดอร์ถึงไม่เข้ามาในระบบ ?',
              'ถ้าลูกค้าสั่งอาหารแล้วแต่ไม่เห็นออเดอร์เข้ามาในแอป ให้ลองตรวจสอบตามขั้นตอนต่อไปนี้ทีละข้อ',
              const [
                MerchantHelpGuideStep(
                  title: 'ตรวจสอบสถานะร้าน',
                  description: 'ออเดอร์จะเข้ามาได้เฉพาะตอนที่ร้านอยู่ในสถานะ "เปิดร้าน" เท่านั้น',
                  illustration: HelpIllustration(
                    type: HelpIllustrationType.toggleSwitch,
                    label: 'สถานะร้าน',
                  ),
                  howTo: [
                    'กดแท็บ "โปรไฟล์" ที่แถบเมนูด้านล่างขวาสุด',
                    'กดเมนู "ตั้งค่าการแจ้งเตือน & บัญชี"',
                    'ในหัวข้อ "สถานะร้าน" ให้ตรวจสอบว่าสวิตช์เปิดอยู่ (สีฟ้า) ถ้าปิดอยู่ให้กดสวิตช์เพื่อเปิดร้าน',
                  ],
                ),
                MerchantHelpGuideStep(
                  title: 'ตรวจสอบการเชื่อมต่ออินเทอร์เน็ต',
                  description: 'ออเดอร์ใหม่ต้องใช้อินเทอร์เน็ตในการแจ้งเตือนแบบเรียลไทม์',
                  illustration: HelpIllustration(
                    type: HelpIllustrationType.iconRow,
                    label: 'อินเทอร์เน็ต',
                  ),
                  howTo: [
                    'ตรวจสอบไอคอน Wi-Fi หรือสัญญาณมือถือที่มุมบนของหน้าจอเครื่อง',
                    'ลองปิด-เปิด Wi-Fi หรือสลับไปใช้เน็ตมือถือชั่วคราว แล้วรีเฟรชหน้าจอ',
                  ],
                ),
                MerchantHelpGuideStep(
                  title: 'ตรวจสอบรายการออเดอร์ทั้งหมดอีกครั้ง',
                  description: 'บางครั้งออเดอร์อาจเข้ามาแล้วแต่ถูกกรองด้วยแท็บสถานะ',
                  illustration: HelpIllustration(
                    type: HelpIllustrationType.filterChip,
                    label: 'ทั้งหมด',
                  ),
                  howTo: [
                    'กดแท็บ "คำสั่งซื้อ" ที่แถบเมนูด้านล่าง',
                    'กดแท็บ "ทั้งหมด" ด้านบนเพื่อดูออเดอร์ทุกสถานะ',
                  ],
                ),
                MerchantHelpGuideStep(
                  title: 'ติดต่อฝ่ายสนับสนุน',
                  description: 'หากทำตามขั้นตอนข้างต้นแล้วยังไม่พบออเดอร์ ให้ติดต่อทีมงานเพื่อตรวจสอบเพิ่มเติม',
                  illustration: HelpIllustration(
                    type: HelpIllustrationType.buttonChip,
                    label: 'อีเมลถึงฝ่ายสนับสนุน',
                    icon: Icons.email_outlined,
                  ),
                  howTo: [
                    'เลื่อนกลับไปด้านบนของหน้านี้ แล้วกด "อีเมลถึงฝ่ายสนับสนุน"',
                  ],
                ),
              ],
            ),

            // 🟢 "เปลี่ยนตำแหน่งจุดขายได้อย่างไร ?"
            _buildFaqTile(
              context,
              'เปลี่ยนตำแหน่งจุดขายได้อย่างไร ?',
              'คุณสามารถเปลี่ยนตำแหน่งจุดขายได้ 2 วิธี คือกรอกพิกัดเอง หรือให้ระบบดึงตำแหน่งปัจจุบันจาก GPS ให้อัตโนมัติ',
              const [
                MerchantHelpGuideStep(
                  title: 'เข้าหน้าแผนที่จุดขาย',
                  illustration: HelpIllustration(
                    type: HelpIllustrationType.quickMenu,
                    label: 'แผนที่จุดขาย',
                  ),
                  howTo: [
                    'จากหน้าหลัก กดไอคอน "แผนที่จุดขาย" ในแถบ "เมนูจัดการร้านด่วน"',
                    'หรือกดแท็บ "โปรไฟล์" > "ตั้งค่าการแจ้งเตือน & บัญชี" > "ตำแหน่งจุดขาย (Selling Location)"',
                  ],
                ),
                MerchantHelpGuideStep(
                  title: 'กรอกพิกัดเอง',
                  description: 'ใช้วิธีนี้ถ้าต้องการระบุตำแหน่งที่แน่นอน',
                  illustration: HelpIllustration(
                    type: HelpIllustrationType.buttonChip,
                    label: 'เปลี่ยนพิกัด',
                    icon: Icons.edit,
                  ),
                  howTo: [
                    'ในหน้าแผนที่จุดขาย กดปุ่มดินสอ "เปลี่ยนพิกัด" ที่มุมขวาของการ์ดตำแหน่ง',
                    'กรอกชื่อสถานที่ ละติจูด และลองจิจูด',
                    'กดปุ่ม "บันทึก" เพื่อยืนยัน',
                  ],
                ),
                MerchantHelpGuideStep(
                  title: 'หรืออัปเดตอัตโนมัติจาก GPS',
                  description: 'ใช้วิธีนี้ถ้าต้องการใช้ตำแหน่งปัจจุบันของเครื่อง',
                  illustration: HelpIllustration(
                    type: HelpIllustrationType.buttonBlock,
                    label: 'อัปเดตตำแหน่งปัจจุบัน',
                  ),
                  howTo: [
                    'กดปุ่มสีฟ้า "อัปเดตตำแหน่งปัจจุบัน" ด้านล่างสุดของหน้าแผนที่จุดขาย',
                    'กด "อนุญาต" เมื่อระบบขอสิทธิ์เข้าถึงตำแหน่ง',
                    'รอสักครู่จนระบบดึงพิกัดและชื่อสถานที่มาให้อัตโนมัติ',
                  ],
                ),
              ],
            ),

            // 🟢 "ต้องรอนานแค่ไหนกว่าจะได้รับเงิน ?"
            _buildFaqTile(
              context,
              'ต้องรอนานแค่ไหนกว่าจะได้รับเงิน ?',
              'ยอดขายของคุณจะสะสมอยู่ในหน้า "รายได้" และสามารถถอนเข้าบัญชีธนาคารได้ตามขั้นตอนนี้',
              const [
                MerchantHelpGuideStep(
                  title: 'ตรวจสอบยอดเงินที่ถอนได้',
                  illustration: HelpIllustration(
                    type: HelpIllustrationType.bottomNav,
                    label: 'รายได้',
                  ),
                  howTo: [
                    'กดแท็บ "รายได้" ที่แถบเมนูด้านล่าง',
                    'ดูตัวเลข "ยอดเงินที่สามารถถอนได้" ในการ์ดสีฟ้าด้านบนสุด',
                  ],
                ),
                MerchantHelpGuideStep(
                  title: 'กดถอนเงิน',
                  illustration: HelpIllustration(
                    type: HelpIllustrationType.buttonBlock,
                    label: 'ถอนเงิน',
                  ),
                  howTo: [
                    'กดปุ่มสีขาว "ถอนเงิน" ในการ์ดยอดเงิน',
                    'เลือกแอปธนาคารที่ต้องการใช้ถอนเงินจากรายการที่แสดงขึ้นมา',
                    'ทำรายการถอนเงินต่อในแอปธนาคารที่เลือก',
                  ],
                ),
                MerchantHelpGuideStep(
                  title: 'ระยะเวลาเงินเข้าบัญชี',
                  description: 'โดยทั่วไปเงินจะเข้าบัญชีภายใน 1-3 วันทำการ ขึ้นอยู่กับรอบการตัดยอดของธนาคารที่เลือก',
                  illustration: HelpIllustration(
                    type: HelpIllustrationType.buttonChip,
                    label: 'อีเมลถึงฝ่ายสนับสนุน',
                    icon: Icons.email_outlined,
                  ),
                  howTo: [
                    'หากเกิน 3 วันทำการแล้วเงินยังไม่เข้า ให้เลื่อนกลับไปด้านบนแล้วกด "อีเมลถึงฝ่ายสนับสนุน"',
                  ],
                ),
              ],
            ),

            // 🟢 "อัปเดตสถานะร้านได้อย่างไร ?"
            _buildFaqTile(
              context,
              'อัปเดตสถานะร้านได้อย่างไร ?',
              'คุณสามารถเปิด-ปิดร้าน หรือแจ้งสถานะร้านให้ลูกค้าทราบได้ 2 จุดในแอป',
              const [
                MerchantHelpGuideStep(
                  title: 'อัปเดตจากหน้าโปรไฟล์',
                  illustration: HelpIllustration(
                    type: HelpIllustrationType.toggleSwitch,
                    label: 'สถานะร้าน',
                  ),
                  howTo: [
                    'กดแท็บ "โปรไฟล์" ที่แถบเมนูด้านล่าง',
                    'กดเมนู "ตั้งค่าการแจ้งเตือน & บัญชี"',
                    'เลื่อนไปหัวข้อ "สถานะร้าน" แล้วกดสวิตช์เพื่อเปิดหรือปิดร้านได้ทันที',
                  ],
                ),
                MerchantHelpGuideStep(
                  title: 'หรืออัปเดตจากหน้าหลัก',
                  description: 'วิธีนี้ให้รายละเอียดสถานะมากกว่า เช่น เปิดร้าน / กำลังย้าย / ปิดร้าน พร้อมส่งแจ้งเตือนลูกค้าอัตโนมัติ',
                  illustration: HelpIllustration(
                    type: HelpIllustrationType.quickMenu,
                    label: 'สถานะร้านค้า',
                  ),
                  howTo: [
                    'จากหน้าหลัก กดไอคอน "สถานะร้านค้า" ในแถบ "เมนูจัดการร้านด่วน"',
                    'เลือกสถานะที่ต้องการ ("เปิดร้าน", "กำลังย้าย" หรือ "ปิดร้าน")',
                    'ระบบจะบันทึกสถานะและส่งแจ้งเตือนไปยังลูกค้าที่ติดตามร้านโดยอัตโนมัติ',
                  ],
                ),
              ],
            ),

            // 🟢 "ดูรีวิวจากลูกค้าได้ที่ไหน ?"
            _buildFaqTile(
              context,
              'ดูรีวิวจากลูกค้าได้ที่ไหน ?',
              'คุณสามารถดูคะแนนเฉลี่ยและความคิดเห็นจากลูกค้าทั้งหมดได้ในที่เดียว',
              const [
                MerchantHelpGuideStep(
                  title: 'เข้าหน้ารีวิวจากลูกค้า',
                  illustration: HelpIllustration(
                    type: HelpIllustrationType.settingsRow,
                    label: 'รีวิวจากลูกค้า',
                    icon: Icons.star_outline_rounded,
                  ),
                  howTo: [
                    'กดแท็บ "โปรไฟล์" ที่แถบเมนูด้านล่าง',
                    'กดเมนู "ตั้งค่าการแจ้งเตือน & บัญชี"',
                    'กดเมนู "รีวิวจากลูกค้า" ในส่วน "เมนูเพิ่มเติม"',
                  ],
                ),
                MerchantHelpGuideStep(
                  title: 'ดูคะแนนและความคิดเห็น',
                  illustration: HelpIllustration(
                    type: HelpIllustrationType.ratingSummary,
                    label: '4.8',
                  ),
                  howTo: [
                    'ดูคะแนนเฉลี่ยของร้านและจำนวนรีวิวทั้งหมดที่ด้านบนของหน้า',
                    'เลื่อนลงเพื่ออ่านความคิดเห็นและคะแนนดาวจากลูกค้าแต่ละคน',
                  ],
                ),
              ],
            ),

            // 🟢 "แก้ไขเมนูอาหารได้อย่างไร ?"
            _buildFaqTile(
              context,
              'แก้ไขเมนูอาหารได้อย่างไร ?',
              'คุณสามารถเพิ่ม แก้ไข หรือลบเมนูอาหาร รวมถึงตัวเลือกเสริมต่างๆ ได้จากหน้าจัดการเมนู',
              const [
                MerchantHelpGuideStep(
                  title: 'เข้าหน้าจัดการเมนูอาหาร',
                  illustration: HelpIllustration(
                    type: HelpIllustrationType.quickMenu,
                    label: 'แก้ไขเมนู',
                  ),
                  howTo: [
                    'จากหน้าหลัก กดไอคอน "แก้ไขเมนู" ในแถบ "เมนูจัดการร้านด่วน"',
                  ],
                ),
                MerchantHelpGuideStep(
                  title: 'แก้ไขเมนูที่มีอยู่แล้ว',
                  illustration: HelpIllustration(
                    type: HelpIllustrationType.menuItemRow,
                    label: 'โรตีใส่ไข่',
                  ),
                  howTo: [
                    'กดไอคอนดินสอ (✎) ที่ด้านขวาของเมนูที่ต้องการแก้ไข',
                    'แก้ไขชื่อ ราคา จำนวนคงเหลือ รูปภาพ หรือตัวเลือกเสริมตามต้องการ',
                    'กดปุ่ม "บันทึก" ด้านล่างสุดเพื่อยืนยันการแก้ไข',
                  ],
                ),
                MerchantHelpGuideStep(
                  title: 'เพิ่มเมนูใหม่',
                  illustration: HelpIllustration(
                    type: HelpIllustrationType.buttonBlock,
                    label: 'เพิ่มเมนูใหม่',
                  ),
                  howTo: [
                    'กดปุ่มสีฟ้า "เพิ่มเมนูใหม่" ที่ด้านล่างของหน้าจัดการเมนูอาหาร',
                    'กรอกชื่อเมนู ราคา จำนวนคงเหลือ และเพิ่มรูปภาพถ้าต้องการ',
                    'กดปุ่ม "บันทึก" เพื่อเพิ่มเมนูใหม่เข้าสู่ร้านค้า',
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// =======================================================================
// 🟢 โมเดลข้อมูล "ภาพจำลองหน้าจอ" ประกอบขั้นตอนวิธีทำ (ใช้องค์ประกอบ UI จริงของแอปร้านค้า
// เช่น แถบเมนูล่าง, ไอคอนเมนูจัดการร้านด่วน, ปุ่ม, สวิตช์ มาจำลอง แทนภาพสกรีนช็อตจริง)
// =======================================================================
enum HelpIllustrationType {
  bottomNav, // แถบเมนูด้านล่างของแอป
  quickMenu, // แถบเมนูจัดการร้านด่วนในหน้าหลัก
  settingsRow, // แถวเมนูในหน้าตั้งค่า
  buttonChip, // ปุ่มเล็กทรงแคปซูล
  buttonBlock, // ปุ่มเต็มความกว้าง
  toggleSwitch, // แถวมีสวิตช์เปิด-ปิด
  iconRow, // แถวไอคอน (เช่น Wi-Fi/สัญญาณมือถือ)
  filterChip, // แถบตัวกรองสถานะ
  ratingSummary, // สรุปคะแนนรีวิว
  menuItemRow, // แถวรายการเมนูอาหาร
}

class HelpIllustration {
  final HelpIllustrationType type;
  final String label;
  final IconData? icon;

  const HelpIllustration({
    required this.type,
    required this.label,
    this.icon,
  });
}

// =======================================================================
// 🟢 โมเดลข้อมูลขั้นตอนวิธีทำ ใช้ร่วมกับ Bottom Sheet วิธีทำในหน้าติดต่อช่วยเหลือ
// =======================================================================
class MerchantHelpGuideStep {
  final String title;
  final String? description;
  final List<String> howTo;
  final HelpIllustration? illustration; // 🟢 ภาพจำลองหน้าจอประกอบขั้นตอนนี้ (ถ้ามี)

  const MerchantHelpGuideStep({
    required this.title,
    this.description,
    required this.howTo,
    this.illustration,
  });
}
