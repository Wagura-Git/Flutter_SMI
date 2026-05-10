import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../shared/app_colors.dart';
import '../../shared/responsive_scaffold.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';

class AgendaAddScreen extends StatefulWidget {
  final String role;
  const AgendaAddScreen({super.key, required this.role});

  @override
  State<AgendaAddScreen> createState() => _AgendaAddScreenState();
}

class _AgendaAddScreenState extends State<AgendaAddScreen> {
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final locationController = TextEditingController();
  final purposeController = TextEditingController();

  DateTime? selectedDate;
  TimeOfDay? selectedTimeStart;
  TimeOfDay? selectedTimeEnd;

  String invitationType = '30'; // Nilai notifikasi
  String invitationUnit = 'Menit'; // Unit notifikasi
  String? selectedDocument; // Nama dokumen yang diupload
  PlatformFile? pickedFile; // File yang dipilih
  String? attachmentPath; // Path dokumen di server setelah upload
  List<User> allUsers = []; // Daftar semua user dari API
  List<User> selectedUsers = []; // Pengguna yang dipilih sebagai penerima agenda
  int? selectedRecipientUserId; // ID user yang dipilih di dropdown tujuan

  bool isLoading = false;
  bool isLoadingUsers = false;
  bool isUploadingFile = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      isLoadingUsers = true;
    });

    try {
      final token = await AuthService.getToken();
      if (token == null) return;

      final result = await ApiService.getUsers(token);
      if (result['success']) {
        setState(() {
          allUsers = result['users'] as List<User>;
          isLoadingUsers = false;
        });
      } else {
        setState(() {
          isLoadingUsers = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoadingUsers = false;
      });
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    locationController.dispose();
    purposeController.dispose();
    super.dispose();
  }

  void _submitAgenda() async {
    if (titleController.text.isEmpty ||
        selectedDate == null ||
        selectedTimeStart == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Judul, tanggal, dan waktu harus diisi')),
      );
      return;
    }

    // Validasi harus memiliki penerima/tujuan
    if (selectedUsers.isEmpty && selectedRecipientUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih minimal satu penerima agenda')),
      );
      return;
    }

    // Jika ada selected recipient dari dropdown, tambahkan ke selectedUsers jika belum ada
    if (selectedRecipientUserId != null) {
      final recipientUser = allUsers.firstWhere(
        (user) => user.id == selectedRecipientUserId,
        orElse: () => User(
          id: selectedRecipientUserId!,
          name: 'Unknown',
          email: '',
          role: 'user',
        ),
      );
      if (!selectedUsers.any((user) => user.id == recipientUser.id)) {
        selectedUsers.add(recipientUser);
      }
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final token = await AuthService.getToken();
      if (token == null) {
        setState(() {
          errorMessage = 'Token tidak ditemukan';
          isLoading = false;
        });
        return;
      }

      final dateStr =
          '${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}';
      final timeStartStr =
          '${selectedTimeStart!.hour.toString().padLeft(2, '0')}:${selectedTimeStart!.minute.toString().padLeft(2, '0')}:00';
      final timeEndStr =
          selectedTimeEnd != null
              ? '${selectedTimeEnd!.hour.toString().padLeft(2, '0')}:${selectedTimeEnd!.minute.toString().padLeft(2, '0')}:00'
              : null;

      final recipientIds = selectedUsers.map((user) => user.id).toList();

      final result = await ApiService.createAgenda(
        token: token,
        title: titleController.text,
        date: dateStr,
        timeStart: timeStartStr,
        timeEnd: timeEndStr,
        description:
            descriptionController.text.isNotEmpty
                ? descriptionController.text
                : null,
        location:
            locationController.text.isNotEmpty ? locationController.text : null,
        category: 'meeting',
        agendaType: selectedUsers.isNotEmpty ? 'umum' : 'pribadi',
        recipientUserIds: recipientIds.isNotEmpty ? recipientIds : null,
        notifValue: invitationType,
        notifUnit: invitationUnit,
        attachmentPath: attachmentPath,
      );

      setState(() {
        isLoading = false;
      });

      if (result['success']) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Agenda berhasil dibuat')));
        Navigator.pop(context, true);
      } else {
        setState(() {
          errorMessage = result['message'] ?? 'Gagal membuat agenda';
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorMessage!)));
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: ${e.toString()}';
        isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage!)));
    }
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (date != null) {
      setState(() {
        selectedDate = date;
      });
    }
  }

  Future<void> _selectTimeStart() async {
    final time = await showTimePicker(
      context: context,
      initialTime: selectedTimeStart ?? TimeOfDay.now(),
    );
    if (time != null) {
      setState(() {
        selectedTimeStart = time;
      });
    }
  }

  Future<void> _selectTimeEnd() async {
    final time = await showTimePicker(
      context: context,
      initialTime: selectedTimeEnd ?? TimeOfDay.now(),
    );
    if (time != null) {
      setState(() {
        selectedTimeEnd = time;
      });
    }
  }

  void _uploadDocument() async {
    try {
      // Pick file
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'txt', 'jpg', 'jpeg', 'png'],
        withData: true,
      );

      if (result != null && result.files.single.size <= 10 * 1024 * 1024) {
        final file = result.files.single;

        setState(() {
          isUploadingFile = true;
        });

        final token = await AuthService.getToken();
        if (token == null) {
          setState(() {
            isUploadingFile = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Token tidak ditemukan')),
          );
          return;
        }

        final uploadResult = await ApiService.uploadAgendaDocument(
          token: token,
          file: file,
        );

        setState(() {
          isUploadingFile = false;
        });

        if (uploadResult['success']) {
          setState(() {
            pickedFile = file;
            selectedDocument = file.name;
            attachmentPath = uploadResult['file_path'];
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Dokumen berhasil diupload: ${file.name}')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal upload dokumen: ${uploadResult['message']}')),
          );
        }
      } else if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File terlalu besar (max 10MB)')),
        );
      }
    } catch (e) {
      setState(() {
        isUploadingFile = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveScaffold.isMobile(context);

    return ResponsiveScaffold(
      role: widget.role,
      child: Container(
        color: Colors.white,
        padding: ResponsiveScaffold.pagePadding(context),
        child: SingleChildScrollView(
          child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // HEADER
                    _buildHeader(isMobile),
                    const SizedBox(height: 40),

                    // INPUT JUDUL
                    const Text(
                      "Judul Agenda",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    TextField(
                      controller: titleController,
                      style: const TextStyle(fontSize: 24),
                      decoration: const InputDecoration(
                        hintText: "Tambahkan Judul Disini",
                        border: InputBorder.none,
                      ),
                    ),
                    const Divider(),
                    const SizedBox(height: 20),

                    // DATE TIME PICKERS
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 15,
                      children: [
                        GestureDetector(
                          onTap: _selectDate,
                          child: _buildChip(
                            selectedDate != null
                                ? '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'
                                : 'Pilih Tanggal',
                          ),
                        ),
                        GestureDetector(
                          onTap: _selectTimeStart,
                          child: _buildChip(
                            selectedTimeStart != null
                                ? selectedTimeStart!.format(context)
                                : 'Pilih Waktu',
                          ),
                        ),
                        const Text(
                          "Sampai",
                          style: TextStyle(color: Colors.black54),
                        ),
                        GestureDetector(
                          onTap: _selectTimeEnd,
                          child: _buildChip(
                            selectedTimeEnd != null
                                ? selectedTimeEnd!.format(context)
                                : 'Pilih Waktu',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 50),

                    // DETAIL ACARA
                    Text(
                      "Detail Acara",
                      style: TextStyle(
                        fontSize: 22,
                        color: AppColors.textTealLight,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Divider(endIndent: isMobile ? 0 : 400),
                    const SizedBox(height: 30),

                    _buildInputRow(
                      Icons.location_on,
                      "Lokasi Kegiatan",
                      "Tambahkan Lokasi...",
                      locationController,
                    ),
                    const SizedBox(height: 20),

                    // TUJUAN AGENDA
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.people, size: 40),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Tujuan Agenda",
                                style: TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                              const SizedBox(height: 5),
                              if (isLoadingUsers)
                                const Padding(
                                  padding: EdgeInsets.all(12.0),
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                )
                              else if (allUsers.isEmpty)
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'Tidak ada user tersedia',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                )
                              else
                                DropdownButton<int>(
                                  value: selectedRecipientUserId,
                                  isExpanded: true,
                                  hint: const Text('Pilih Penerima Agenda'),
                                  items: allUsers
                                      .map(
                                        (user) => DropdownMenuItem<int>(
                                          value: user.id,
                                          child: Text('${user.name} (${user.role})'),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (userId) {
                                    setState(() {
                                      selectedRecipientUserId = userId;
                                    });
                                  },
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // SELECTED RECIPIENTS DISPLAY
                    if (selectedUsers.isNotEmpty)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.check_circle, size: 40, color: Colors.green),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Penerima yang Dipilih",
                                  style: TextStyle(fontSize: 11, color: Colors.grey),
                                ),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: selectedUsers
                                      .map(
                                        (user) => Chip(
                                          avatar: CircleAvatar(
                                            child: Text(
                                              user.name.substring(0, 1).toUpperCase(),
                                            ),
                                          ),
                                          label: Text(user.name),
                                          onDeleted: () {
                                            setState(() {
                                              selectedUsers.removeWhere(
                                                (u) => u.id == user.id,
                                              );
                                            });
                                          },
                                          backgroundColor:
                                              AppColors.bgTeal.withOpacity(0.3),
                                        ),
                                      )
                                      .toList(),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 20),

                    // ADD RECIPIENT BUTTON
                    if (selectedRecipientUserId != null)
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              if (selectedRecipientUserId != null) {
                                final selectedUser = allUsers.firstWhere(
                                  (user) => user.id == selectedRecipientUserId,
                                );
                                if (!selectedUsers.any(
                                  (user) => user.id == selectedUser.id,
                                )) {
                                  setState(() {
                                    selectedUsers.add(selectedUser);
                                    selectedRecipientUserId = null;
                                  });
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('User sudah dipilih'),
                                    ),
                                  );
                                }
                              }
                            },
                            icon: const Icon(Icons.add),
                            label: const Text("Tambah Penerima"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.secondaryPurple,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 20),

                    _buildInputRow(
                      Icons.notes,
                      "Deskripsi Kegiatan",
                      "Tambahkan Deskripsi...",
                      descriptionController,
                      isTextArea: true,
                    ),
                    const SizedBox(height: 20),

                    // NOTIFIKASI
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.notifications, size: 40),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Notifikasi",
                                style: TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                              const SizedBox(height: 5),
                              Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: TextField(
                                      onChanged: (value) {
                                        setState(() {
                                          invitationType = value;
                                        });
                                      },
                                      controller: TextEditingController(text: invitationType),
                                      decoration: InputDecoration(
                                        hintText: "Nilai",
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        contentPadding: const EdgeInsets.all(12),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    flex: 1,
                                    child: DropdownButton<String>(
                                      value: invitationUnit,
                                      isExpanded: true,
                                      items: ['Menit', 'Jam', 'Hari']
                                          .map(
                                            (option) => DropdownMenuItem(
                                              value: option,
                                              child: Text(option),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: (value) {
                                        if (value != null) {
                                          setState(() {
                                            invitationUnit = value;
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),

                    // UPLOAD DOKUMEN
                    _buildUploadDocumentSection(),
                  ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.bgTeal,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text),
    );
  }

  Widget _buildHeader(bool isMobile) {
    final title = Text(
      "Penambahan Agenda",
      style: TextStyle(
        fontSize: isMobile ? 28 : 32,
        fontWeight: FontWeight.bold,
        color: AppColors.textTealDark,
      ),
    );
    final saveButton = ElevatedButton(
      onPressed: isLoading ? null : _submitAgenda,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.secondaryPurple.withValues(alpha: 0.7),
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
      ),
      child:
          isLoading
              ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
              : const Text("Simpan", style: TextStyle(color: Colors.white)),
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          title,
          const SizedBox(height: 14),
          SizedBox(width: double.infinity, child: saveButton),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [title, saveButton],
    );
  }

  Widget _buildInputRow(
    IconData icon,
    String label,
    String hint,
    TextEditingController controller, {
    bool isTextArea = false,
    bool isDropdown = false,
    String? dropdownValue,
    List<String>? dropdownOptions,
    Function(String)? onDropdownChanged,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 40),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
              const SizedBox(height: 5),
              if (isDropdown && dropdownOptions != null)
                DropdownButton<String>(
                  value: dropdownValue,
                  isExpanded: true,
                  items:
                      dropdownOptions
                          .map(
                            (option) => DropdownMenuItem(
                              value: option.toLowerCase(),
                              child: Text(option),
                            ),
                          )
                          .toList(),
                  onChanged: (value) {
                    if (value != null && onDropdownChanged != null) {
                      onDropdownChanged(value);
                    }
                  },
                )
              else
                TextField(
                  controller: controller,
                  maxLines: isTextArea ? 5 : 1,
                  decoration: InputDecoration(
                    hintText: hint,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUploadDocumentSection() {
    final isMobile = ResponsiveScaffold.isMobile(context);
    final selectedFileBox = Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        selectedDocument ?? "Belum ada dokumen dipilih",
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: selectedDocument != null ? Colors.black : Colors.grey,
        ),
      ),
    );
    final uploadButton = ElevatedButton.icon(
      onPressed: isUploadingFile ? null : _uploadDocument,
      icon:
          isUploadingFile
              ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
              : const Icon(Icons.add),
      label: Text(isUploadingFile ? "Uploading..." : "Upload"),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.secondaryPurple,
      ),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.upload_file, size: 40),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Upload Dokumen",
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
              const SizedBox(height: 5),
              if (isMobile)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    selectedFileBox,
                    const SizedBox(height: 10),
                    uploadButton,
                  ],
                )
              else
                Row(
                  children: [
                    Expanded(child: selectedFileBox),
                    const SizedBox(width: 10),
                    uploadButton,
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}
