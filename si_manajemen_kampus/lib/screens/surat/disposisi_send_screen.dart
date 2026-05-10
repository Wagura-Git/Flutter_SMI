import 'package:flutter/material.dart';
import '../../shared/app_colors.dart';
import '../../shared/responsive_scaffold.dart';
import 'disposisi_create_screen.dart';

class DisposisiSendScreen extends StatefulWidget {
  final String role;

  const DisposisiSendScreen({
    super.key,
    required this.role,
  });

  @override
  State<DisposisiSendScreen> createState() => _DisposisiSendScreenState();
}

class _DisposisiSendScreenState extends State<DisposisiSendScreen> {
  String _selectedTab = 'Semua';
  String _selectedOrder = 'Terbaru';

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      role: widget.role,
      child: Container(
        color: Colors.white,
        padding: ResponsiveScaffold.pagePadding(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- HEADER ATAS ---
                  _buildTopHeader(context),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 20),

                  // --- TAB KATEGORI ---
                  _buildTabs(),
                  const SizedBox(height: 20),

                  // --- FILTER URUTAN ---
                  _buildFilterButton(),
                  const SizedBox(height: 30),

                  // --- TABEL: HEADER ---
                  _buildTableHeader(),

                  // --- TABEL: DATA ---
                  Expanded(
                    child: ListView(
                      children: [
                        _buildTableRow(
                          "1",
                          "Surat Tugas PkM Desa Tonja",
                          "Surat Tugas",
                          "Dekan, Wakil Dekan,...",
                          "15-10-2024",
                        ),
                        _buildTableRow(
                          "2",
                          "Surat Kenaikan Jabatan",
                          "Surat Keputusan",
                          "KTU",
                          "23-04-2024",
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // Widget Header Atas
  Widget _buildTopHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Pengirimman Surat",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppColors.textTealDark,
              ),
            ),
            Text(
              widget.role,
              style: TextStyle(fontSize: 16, color: AppColors.textTealLight),
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DisposisiCreateScreen(role: widget.role),
            ),
          ),
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text(
            "Tambahkan Dokumen Baru",
            style: TextStyle(color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.secondaryPurple,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
        ),
      ],
    );
  }

  // Widget Tab Kategori
  Widget _buildTabs() {
    final tabs = ['Semua', 'Surat Keputusan', 'Surat Tugas', 'Surat Personal', 'Lain-lain'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: tabs.map((tab) {
          bool isSelected = _selectedTab == tab;
          return Padding(
            padding: const EdgeInsets.only(right: 15),
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = tab),
              child: Column(
                children: [
                  Text(
                    tab,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? AppColors.textTealDark : Colors.grey,
                    ),
                  ),
                  if (isSelected)
                    Container(
                      margin: const EdgeInsets.only(top: 5),
                      height: 3,
                      width: 50,
                      decoration: BoxDecoration(
                        color: AppColors.primaryPurple,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // Widget Dropdown Urutan
  Widget _buildFilterButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButton<String>(
        underline: const SizedBox(),
        value: _selectedOrder,
        items: const [
          DropdownMenuItem(value: "Terbaru", child: Text("Terbaru")),
          DropdownMenuItem(value: "Terlama", child: Text("Terlama")),
          DropdownMenuItem(value: "A-Z", child: Text("A-Z")),
        ],
        onChanged: (v) {
          if (v != null) {
            setState(() => _selectedOrder = v);
          }
        },
      ),
    );
  }

  // Header Tabel
  Widget _buildTableHeader() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          _cellHeader("No", flex: 1),
          _cellHeader("Nama Dokumen", flex: 4),
          _cellHeader("Tipe Dokumen", flex: 2),
          _cellHeader("Dikirimkan ke", flex: 3),
          _cellHeader("Tanggal Dokumen", flex: 2),
          _cellHeader("Aksi", flex: 1),
        ],
      ),
    );
  }

  // Fungsi pembantu untuk header tabel
  Widget _cellHeader(String title, {required int flex}) {
    return Expanded(
      flex: flex,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey[400],
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // Baris Data Tabel
  Widget _buildTableRow(
    String no,
    String nama,
    String tipe,
    String dikirimKe,
    String tgl,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.black12)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Text(no, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
          ),
          Expanded(
            flex: 4,
            child: Text(nama, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
          ),
          Expanded(
            flex: 2,
            child: Text(tipe, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
          ),
          Expanded(
            flex: 3,
            child: Text(dikirimKe, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
          ),
          Expanded(
            flex: 2,
            child: Text(tgl, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: SizedBox(
                height: 32,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondaryPurple,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: const Text(
                    "Edit",
                    style: TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
