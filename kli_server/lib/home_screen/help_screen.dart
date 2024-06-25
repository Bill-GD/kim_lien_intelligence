import 'package:flutter/material.dart';
import 'package:kli_lib/kli_lib.dart';
import 'package:url_launcher/url_launcher.dart';

import '../global.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  int selectedSectionIndex = -1;
  final helpController = TextEditingController();
  List<String> sectionNames = [
    'Tổng quan',
    'Hình nền & âm thanh',
    'Quản lý dữ liệu',
    'Dữ liệu từ Excel',
    'Kiểm tra dữ liệu',
    'Tạo Server',
  ];

  @override
  void initState() {
    super.initState();
    logHandler.info('Viewing help screen');
  }

  @override
  void dispose() {
    helpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 100, bottom: 50),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                KLIButton(
                  'Mở thư mục chứa phần mềm',
                  onPressed: () async {
                    logHandler.info('Opened parent folder: ${StorageHandler.appRootDirectory}');
                    await launchUrl(Uri.parse(StorageHandler.appRootDirectory));
                  },
                ),
                const KLIButton('Mở file thông tin chi tiết'),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              sectionList(),
              instructions(),
            ],
          ),
        ],
      ),
    );
  }

  Widget sectionList() {
    return Flexible(
      child: Column(
        children: [
          const Text('Các phần', style: TextStyle(fontSize: fontSizeMedium)),
          Container(
            constraints: const BoxConstraints(maxWidth: 300),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: sectionNames.length,
              separatorBuilder: (_, index) => const SizedBox(height: 10),
              itemBuilder: (_, index) {
                return ListTile(
                  title: Text(sectionNames[index], style: const TextStyle(fontSize: fontSizeMedium)),
                  tileColor: Theme.of(context).colorScheme.background,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(width: 2, color: Theme.of(context).colorScheme.onBackground),
                  ),
                  onTap: () {
                    selectedSectionIndex = index;
                    helpController.text = dedent(helpContentList[index]);
                    setState(() {});
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget instructions() {
    return Flexible(
      child: Column(
        children: [
          Text(
            selectedSectionIndex < 0 ? 'Thông tin' : sectionNames[selectedSectionIndex],
            style: const TextStyle(fontSize: fontSizeMedium),
          ),
          Container(
            margin: const EdgeInsets.only(top: 16),
            padding: const EdgeInsets.only(left: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.background,
              border: Border.all(color: Theme.of(context).colorScheme.onBackground),
            ),
            constraints: const BoxConstraints(minHeight: 600),
            child: selectedSectionIndex >= 0
                ? TextFormField(
                    style: TextStyle(
                      fontSize: fontSizeMSmall,
                      color: Theme.of(context).colorScheme.onBackground,
                    ),
                    maxLines: 20,
                    readOnly: true,
                    controller: helpController,
                  )
                : const Material(
                    child: Center(child: Text('Chưa chọn phần')),
                  ),
          ),
        ],
      ),
    );
  }

  final helpContentList = [
    // * Overview
    '''
    Phần mềm chia thành 2 phần chính: phần quản lý trận đấu, câu hỏi và host & điều khiển trận đấu đang diễn ra.

    Đây là phần hướng dẫn nhanh về cách sử dụng phần mềm.

    Giao diện:
    - Đây là màn hình chính, để chuyển sang các phần của phần mềm, chọn tab tương ứng ở bên trái.
    - Ở các phần của phần mềm cũng có hướng dẫn cụ thể.
    - Sử dụng nút mở thư mục chứa phần mềm để truy cập, chỉnh sửa dữ liệu phần mềm nếu cần. Các dữ liệu của phần mềm được lưu ở thư mục 'UserData'.
    
    Quản lý dữ liệu:
    - Mở phần quản lý dữ liệu ở bên trái.
    - Có thể nhập câu hỏi mỗi phần thi từ file Excel hoặc thêm câu hỏi một cách thủ công. Câu hỏi lưu ở file Excel cần phải đúng định dạng.

    Bắt đầu trận:
    - Mở phần host & điều khiển trận đấu ở bên trái.
    - Trước khi bắt đầu trận, hệ thống cần xác nhận dữ liệu của trận đấu là đầy đủ (tránh lỗi khi chạy).

    Hình nền & âm thanh:
    - Phần mềm cần hình nền và âm thanh để có thể tiếp tục.
    - Chọn mục âm thanh ở bên trái. Mở thư mục Assets để quản lý.''',
    // * Background & Sounds
    '''
    Hình nền và âm thanh của phần mềm được lưu ở 'UserData/Assets'.
    
    Có thể vào trang 'Âm thanh' để kiểm tra âm thanh có trong phần mềm. Ở phía trên có nút mở thư mục 'Assets' để đễ quản lý hình nền và âm thanh.
    
    Vị trí hình nền và âm thanh sẽ dùng chung cho cả bên Server và Client. Tên và vị trí lưu cần chính xác, phần mềm sẽ báo lỗi nếu có sai sót.
    
    Nếu thiếu file (không bị nhầm chỗ) thì có thể tải bản âm thanh, hình nền mặc định.''',
    // * Data Manager
    '''
    Ngoài hình nền và âm thanh, loại dữ liệu khác cần quản lý là dữ liệu trận đấu và câu hỏi.
    
    Dữ liệu trận đấu và câu hỏi được phần mềm lưu ở 'UserData/SavedData'. Không nên chỉnh sửa nếu không hiểu rõ cấu trúc dữ liệu, điều này có thể gây lỗi dữ liệu khi đọc.
    
    Các file hình ảnh, video được sử dụng cho các trận đấu lưu ở 'UserData/Media' để dễ quản lý.''',
    // * Import from Excel
    '''
    Khi nhập dữ liệu câu hỏi, có thể thêm một cách thủ công hoặc nhập từ file Excel.
    
    File Excel cần phải đúng định dạng, nếu không có thể gây ra lỗi khi hiển thị câu hỏi. Ngoài ra có thể xem trước dữ liệu đã đọc trước khi xác nhận nhập.
    
    Các file Excel nên lưu ở 'UserData/NewData' nếu muốn lưu trữ cùng với phần mềm.
    
    Định dạng chung của dữ liệu lưu trong file Excel:
    - Bắt đầu từ ô A1.
    - Không để trống hàng/cột khi vẫn còn dữ liệu. Khi phần mềm sẽ dừng đọc tại hàng trống. Mỗi phần thi có số lượng cột sẽ đọc khác nhau.
    - Không gộp (merge) các hàng/cột với nhau. Chỉ có hàng/cột đầu tiên của nhóm đã gộp có dữ liệu và sẽ đọc thiếu dữ liệu.
    - Dòng 1 là tiêu đề cột (STT, câu hỏi, đáp án...).
    - Một số phần thì cũng có số lượng sheet nhất định. Nếu thừa sẽ không đọc tiếp.''',
    // * Data Checker
    '''
    Trước khi bắt đầu trận đấu, hệ thống cần xác nhận trận đấu đã chọn có đủ dữ liệu hay không.
    
    Có thể kiểm tra dữ liệu trận đấu ở phần 'Bắt đầu trận'.

    Sau khi kiểm tra, mỗi phần dữ liệu sẽ thông báo trạng thái: xanh nếu đủ, đỏ nếu thiếu. Có thể bấm vào từng mục để xem chi tiết kết quả kiểm tra.
    
    Tiêu chí kiểm tra (22-06-2024):
    - Trận đấu: Cần đủ thông tin 4 thí sinh
    - Khởi động: Mỗi thí sinh cần có ít nhất 20 câu hỏi và có ít nhất 1 câu hỏi ở tất cả lĩnh vực
    - Chướng ngại vật: Cần đủ từ khóa, hình ảnh, 5 câu hỏi, ảnh cần được lưu tại vị trí đã nhập
    - Tăng tốc: Có ít nhất 1 ảnh, có ảnh tại vị trí đã nhập, đủ 4 câu hỏi
    - Về đích: Ít nhất 12 câu mỗi mức điểm, các video nếu 
    - Câu hỏi phụ: Có ít nhất 1 câu hỏi''',
    // * Server
    '''
    Chỉ có thể tạo Server nếu có ít nhất 1 trận đấu vả có đủ dữ liệu cần thiết.
    
    Server sử dụng IP local và cho phép tối đa 7 máy khác kết nối với các vai trò khác nhau.
    
    Trên màn hình sẽ hiện địa chỉ IP (local & public) và danh sách máy kết nối.
    
    Có thể mở/đóng Server local. Các máy Client cần nhập địa chỉ IP local để kết nối. Nếu thoát trang thiết lập Server, Server luôn đóng và mọi Client sẽ bị ngắt.
    
    Chỉ sau khi mở Server và cả 4 thí sinh đã kết nối mới có thể bắt đầu trận đấu.''',
  ];
}
