import 'package:flutter/material.dart';
import '../../shared/app_colors.dart';
import '../../shared/responsive_scaffold.dart';
import 'agenda_add_screen.dart';

class PembuatanAgendaScreen extends StatelessWidget {
  final String role;
  const PembuatanAgendaScreen({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    String title =
        role.toLowerCase() == 'pimpinan'
            ? "Pembuatan Agenda Pribadi"
            : "Pembuatan Agenda";

    return ResponsiveScaffold(
      role: role,
      child: Container(
        color: Colors.white,
        padding: ResponsiveScaffold.pagePadding(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textTealDark,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed:
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => AgendaAddScreen(role: role),
                              ),
                            ),
                        icon: const Icon(Icons.add, color: Colors.white),
                        label: const Text(
                          "Tambahkan Agenda Baru",
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondaryPurple,
                          padding: const EdgeInsets.all(20),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    role.toUpperCase(),
                    style: const TextStyle(color: AppColors.textTealLight),
                  ),
                  const SizedBox(height: 50),
                  _buildTableHeader(),
                  _buildRow(
                    "1",
                    "Rapat Rutin Pimpinan",
                    "17 Mei 2026",
                    "Dekan, Wakil Dekan, KTU",
                  ),
                  _buildRow(
                    "2",
                    "Seminar Internasional",
                    "18 Mei 2026",
                    "Dekan",
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildTableHeader() {
    return Row(
      children: [
        _h("No", 1),
        _h("Kegiatan", 5),
        _h("Tanggal", 2),
        _h("Undangan", 4),
        _h("Aksi", 2),
      ],
    );
  }

  Widget _h(String t, int f) => Expanded(
    flex: f,
    child: Container(
      margin: const EdgeInsets.all(2),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey[400],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        t,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white),
      ),
    ),
  );

  Widget _buildRow(String no, String keg, String tgl, String und) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.black12)),
      ),
      child: Row(
        children: [
          Expanded(flex: 1, child: Text(no, textAlign: TextAlign.center)),
          Expanded(flex: 5, child: Text(keg, textAlign: TextAlign.center)),
          Expanded(flex: 2, child: Text(tgl, textAlign: TextAlign.center)),
          Expanded(flex: 4, child: Text(und, textAlign: TextAlign.center)),
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.delete_outline, color: Colors.grey[700]),
                const SizedBox(width: 10),
                Icon(Icons.edit_outlined, color: Colors.grey[700]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
