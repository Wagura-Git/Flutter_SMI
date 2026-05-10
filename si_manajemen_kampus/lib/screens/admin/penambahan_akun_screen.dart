import 'package:flutter/material.dart';
import '../../shared/app_colors.dart';
import '../../shared/responsive_scaffold.dart';

class PenambahanAkunScreen extends StatelessWidget {
  const PenambahanAkunScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveScaffold.isMobile(context);
    final leftFields = Column(
      children: [
        _inputField("Nama Lengkap", "William Agung"),
        _inputField("Nomor Induk Kepegawaian", "2481711011"),
        _dropdownField("Jabatan", "Dekan"),
        _inputField("No. Whatsapp", "081 949 688 889"),
        _inputField("Email", "William4gung@gmail.com"),
      ],
    );
    final rightFields = Column(
      children: [
        _dropdownField("Role/Hirarki Akun", "Pimpinan"),
        _inputField("Input Password", "********", isPass: true),
        _inputField("Ulangi Input Password", "********", isPass: true),
        if (!isMobile) const Spacer(),
        Align(
          alignment: Alignment.bottomRight,
          child: SizedBox(
            width: isMobile ? double.infinity : null,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A1A8A),
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 24 : 60,
                  vertical: isMobile ? 16 : 25,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: const Text(
                "Tambahkan Akun",
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
          ),
        ),
      ],
    );

    return ResponsiveScaffold(
      role: 'Admin',
      child: Container(
        color: Colors.white,
        padding: ResponsiveScaffold.pagePadding(context, desktop: 60),
              child: SingleChildScrollView(
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Penambahan Akun,",
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textTealDark,
                    ),
                  ),
                  const Text(
                    "Admin",
                    style: TextStyle(
                      fontSize: 18,
                      color: AppColors.textTealLight,
                    ),
                  ),
                  const SizedBox(height: 50),

                  if (isMobile)
                    Column(children: [leftFields, rightFields])
                  else
                    SizedBox(
                      height: 560,
                      child: Row(
                        children: [
                          Expanded(child: leftFields),
                          const SizedBox(width: 40),
                          Expanded(child: rightFields),
                        ],
                      ),
                    ),
                ],
              ),
              ),
      ),
    );
  }

  Widget _inputField(String label, String hint, {bool isPass = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 8),
          TextField(
            obscureText: isPass,
            decoration: InputDecoration(
              hintText: hint,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.black12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dropdownField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButton<String>(
              isExpanded: true,
              underline: const SizedBox(),
              value: value,
              items: [DropdownMenuItem(value: value, child: Text(value))],
              onChanged: (v) {},
            ),
          ),
        ],
      ),
    );
  }
}
