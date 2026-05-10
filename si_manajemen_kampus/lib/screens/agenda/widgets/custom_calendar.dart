import 'package:flutter/material.dart';

class CustomCalendar extends StatefulWidget {
  const CustomCalendar({super.key});

  @override
  State<CustomCalendar> createState() => _CustomCalendarState();
}

class _CustomCalendarState extends State<CustomCalendar> {
  // Variabel untuk menyimpan tanggal yang dipilih (default tgl 17)
  String selectedDay = "17";

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.purple.shade100),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            "Oktober 2024",
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w400),
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 10),

          // Header Nama Hari
          _buildDaysHeader(),
          const SizedBox(height: 20),

          // Grid Tanggal
          _buildDatesGrid(),
        ],
      ),
    );
  }

  Widget _buildDaysHeader() {
    const days = [
      "Senin",
      "Selasa",
      "Rabu",
      "Kamis",
      "Jumat",
      "Sabtu",
      "Minggu",
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children:
          days
              .map(
                (d) => Expanded(
                  child: Center(
                    child: Text(
                      d,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
    );
  }

  Widget _buildDatesGrid() {
    return Column(
      children: [
        _calendarRow([
          "29",
          "30",
          "1",
          "2",
          "3",
          "4",
          "5",
        ], isMonthPadding: true),
        _calendarRow(["6", "7", "8", "9", "10", "11", "12"]),
        _calendarRow(["13", "14", "15", "16", "17", "18", "19"]),
        _calendarRow(["20", "21", "22", "23", "24", "25", "26"]),
        _calendarRow(["27", "28", "29", "30", "31", "1", "2"]),
      ],
    );
  }

  Widget _calendarRow(List<String> dates, {bool isMonthPadding = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children:
            dates.map((d) {
              // Logika untuk menentukan apakah ini tanggal dari bulan lain (padding)
              // (Sederhananya: di baris pertama 29-30 adalah bulan lalu)
              bool isGrey = isMonthPadding && (d == "29" || d == "30");
              if (dates.last == "2" && (d == "1" || d == "2")) isGrey = true;

              bool isActive = selectedDay == d && !isGrey;

              return Expanded(
                child: GestureDetector(
                  onTap:
                      isGrey
                          ? null
                          : () {
                            setState(() {
                              selectedDay = d; // Mengubah tanggal yang dipilih
                            });
                            // Di sini nanti bisa ditambah logika untuk memfilter list agenda
                            print("Tanggal $d diklik");
                          },
                  child: MouseRegion(
                    cursor:
                        isGrey
                            ? SystemMouseCursors.basic
                            : SystemMouseCursors.click,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            isActive
                                ? Colors.purple.withOpacity(0.05)
                                : Colors.transparent,
                        border: Border.all(
                          color:
                              isActive
                                  ? Colors.purple.shade300
                                  : Colors.transparent,
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          d,
                          style: TextStyle(
                            color:
                                isGrey
                                    ? Colors.grey.shade300
                                    : (isActive
                                        ? Colors.purple
                                        : Colors.black87),
                            fontWeight:
                                isActive ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }
}
