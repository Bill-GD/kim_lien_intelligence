import 'package:dedent/dedent.dart';
import 'package:flutter/material.dart';
import 'package:kli_utils/kli_utils.dart';
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
    'Chung',
    'Trận đấu',
    'Khởi động',
    'Chướng ngại vật',
    'Tăng tốc',
    'Về đich',
    'Câu hỏi phụ',
    'Server'
  ];

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
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              button(
                context,
                'Mở thư mục chứa phần mềm',
                onPressed: () async {
                  await launchUrl(Uri.parse(storageHandler!.parentFolder));
                },
              ),
              button(context, 'Mở file thông tin chi tiết'),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              sectionList(),
              instructions(),
            ],
          )
        ],
      ),
    );
  }

  Widget sectionList() {
    return Flexible(
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Text('Các mục', style: TextStyle(fontSize: fontSizeMedium)),
          ),
          Container(
            constraints: const BoxConstraints(maxWidth: 250),
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
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              selectedSectionIndex < 0 ? 'Thông tin' : sectionNames[selectedSectionIndex],
              style: const TextStyle(fontSize: fontSizeMedium),
            ),
          ),
          Container(
            padding: const EdgeInsets.only(left: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.background,
              border: Border.all(width: 1, color: Theme.of(context).colorScheme.onBackground),
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
                    child: Center(
                    child: Text('No section selected'),
                  )),
          ),
        ],
      ),
    );
  }

  final helpContentList = [
    '''
    Phần mềm chia thành 2 phần chính: phần quản lý trận đấu, câu hỏi và host & điều khiển trận đấu đang diễn ra.

    Đây là hướng dẫn nhanh, để xem thông tin và hướng dẫn chi tiết, bấm nút mở file hướng dẫn phía trên.

    Sau khi mở, phần mềm sẽ tự động tạo thư mục UserData (cùng thư mục cha với phần mềm). Thư mục UserData bao gồm 3 thư mục Media, NewData, SavedData và file "log.txt".
      - UserData/Media: nên dùng để chứa các video, hình ảnh liên quan đến trận đấu (ảnh thí sinh, CNV, video về đích)
      - UserData/NewData: nên dùng để chứa các file excel (.xlsx) để có thể nhập cùng lúc nhiều câu hỏi cho 1 trận đấu
      - UserData/SavedData: nơi phần mềm lưu các trận đấu và câu hỏi
      - log.txt: file lưu các thao tác, tác vụ phần mềm thực hiện, có thể xem file để phát hiện lỗi khi sử dụng phần mềm
    
    Đối với các file Excel, cần có định dạng nhất định, nếu sai thì dữ liệu sẽ không được đọc đúng cách, dẫn đến lỗi. Tổng quan như sau (định dạng chi tiết phụ thuộc vào các phần thi):
      - Dữ liệu bắt đầu ở ô A1
      - Các hàng không được gộp (merge) với nhau (mỗi câu hỏi chỉ được 1 hàng).
      - Không có các hàng, cột trống ở giữa các câu hỏi (nếu có câu hỏi ở hàng 2 và 4 thì bắt buộc phải có ở hàng 3, nếu trống sẽ mất câu hỏi hàng 4)
      - Các cột cần xếp đúng thứ tự như định dạng.

    Ở phần bên trái của trang chính (trang hiện tại) có danh sách các phần của phần mềm: hướng dẫn (trang hiện tại), quản lý dữ liệu, tạo server. Khi mở trang quản lý dữ liệu sẽ có nút để mở phần quản lý dữ liệu trên màn hình.

    Trang quản lý dữ liệu cũng có danh sách nằm ở bên trái hiển thị các trang quản lý các phần thi khác nhau. Chuyển đến từng trang để quản lý phần tương ứng.''',
    '''
    Quản lý trận đấu.
    
    Ở phía trên có 3 nút: thêm trận, sửa thông tin, xóa. Khi chưa có trận đấu nào thì chỉ có thể thêm trận.
    Khi bấm thêm sẽ mở hộp thoại nhập thông tin trận đấu: tên (không được trùng), tên & ảnh thí sinh.
    
    Sau khi có ít nhất 1 trận thì có thể sửa hoặc xóa. Để sửa và xóa cần phải chọn 1 trong các trận ở danh sách và bấm nút tương ứng.
    Sau khi chọn 1 trận, danh sách các thí sinh sẽ hiện ở phía bên phải (không sửa được ở đây).
    Giao diện sửa thông tin trận giống như khi thêm trận.
    
    Câu hỏi các phần thi lưu theo trận, nên sẽ cần phải tạo 1 trận đấu.''',
    '''
    Quản lý câu hỏi khởi động.
    
    Sau khi chọn trận thì có thể nhập câu hỏi: 1 câu (Add), dữ liệu Excel (Import). Khi thêm câu hỏi mới cần điền đủ thông tin: vị trí, lĩnh vực, câu hỏi, đáp án. Nhập xong chọn 'Done' để lưu.

    Nút 'Remove' sẽ xóa toàn bộ câu hỏi của trận đấu đang chọn.

    Để sửa câu hỏi thì cần bấm vào câu hỏi tương ứng ở trong danh sách. Để xóa câu hỏi thì bấm hình thùng rác ở phía bên phải của câu hỏi.

    Để nhập câu hỏi từ Excel (xlsx) cần lưu ý:
      - Chỉ lấy 4 sheet, mỗi sheet là danh sách câu hỏi của 1 thí sinh, theo thứ tự 1 - 4
      - Hàng đầu tiên là tiêu đề cột (STT, Lĩnh vực, Câu hỏi, Đáp án), các hàng sau là câu hỏi
      - Cột 1 là STT câu hỏi
      - Cột 2 (B) là lĩnh vực: Toán, Vật lý, Hóa học, Sinh học, Văn học, Lịch sử, Địa lý, Tiếng Anh, Thể thao, Nghệ thuật, HBC
      - Tên các lĩnh vực cần đúng như trên.
      - Cột 3 (C) & 4 (D) là Câu hỏi & Đáp án.
      - Các cột sau không đọc.
    
    Ngoài ra, sau khi có danh sách câu hỏi, có thể lọc danh sách câu hỏi theo vị trí thí sinh, lĩnh vực câu hỏi.''',
    '''
    Quản lý câu hỏi vượt chướng ngại vật.
    
    Cần chọn trận đấu để có thể xem, sửa, xóa câu hỏi. Nút 'Remove' sẽ xóa toàn bộ câu hỏi của trận đấu đang chọn.

    Phía bên trái là các hàng ngang 1 - 4 và ô trung tâm (5). Bấm vào câu hỏi để sửa.
    
    Bên phải là chướng ngại vật. Nhập CNV vào ô, bấm 'Save' để lưu. Có thể chọn ảnh cho CNV.

    Để nhập câu hỏi từ Excel cần lưu ý:
      - Chỉ lấy sheet đầu tiên.
      - Hàng 1 là tiêu đề cột
      - Hàng 2 - 6 là các câu hỏi, hàng 7 là CNV.
      - Cột 1 là STT câu hỏi
      - Cột 2 (B) là số kí tự
      - Cột 3 (C) & 4 (D) là Câu hỏi & Đáp án.
      - Cột 5 (E) là giải thích.
      - Các cột sau không đọc.''',
    '''
    Quản lý câu hỏi tăng tốc.
    
    Cần chọn trận đấu để có thể xem, sửa, xóa câu hỏi. Nút 'Remove' sẽ xóa toàn bộ câu hỏi của trận đấu đang chọn.

    Phía bên trái là các câu hỏi 1 - 4. Bấm vào câu hỏi để xem hình ảnh, bấm tiếp nút Edit để sửa câu hỏi.
    
    Bên phải là các hình ảnh gợi ý. Bấm 'Add' để thêm hình ảnh vào cuối, 'Remove' để xóa hình ảnh hiện tại. Sử dụng mũi tên phía dưới để chuyển ảnh.
    Loại câu hỏi sẽ được xác định tự động dựa vào số hình ảnh. Câu hỏi chưa có hình ảnh là 'Không xác định', 1 ảnh là 'IQ', 2 ảnh là 'Sắp xếp', 3+ ảnh là 'Chuỗi hình ảnh'.

    Để nhập câu hỏi từ Excel cần lưu ý:
      - Chỉ lấy sheet đầu tiên.
      - Hàng đầu tiên là tiêu đề cột, các hàng sau là câu hỏi
      - Cột 1 là STT câu hỏi
      - Cột 2 (B) & 3 (C) là Câu hỏi & Đáp án.
      - Cột 4 (D) là giải thích.
      - Các cột sau không đọc.''',
    '''
    Quản lý câu hỏi về đích.
    
    Cần chọn trận đấu để có thể xem, sửa, xóa câu hỏi. Nút 'Remove' sẽ xóa toàn bộ câu hỏi của trận đấu đang chọn.
    
    Sau khi chọn trận thì có thể nhập câu hỏi: 1 câu (Add), dữ liệu Excel (Import). Khi thêm câu hỏi mới cần điền đủ thông tin: điểm, câu hỏi, đáp án. Ngoài ra có thể thêm giải thích hoặc video. Nhập xong chọn 'Done' để lưu.
    Để sửa hãy bấm vào câu hỏi.
    
    Để nhập câu hỏi từ Excel cần lưu ý:
      - Chỉ lấy 3 sheet, thứ tự sheet: 10, 20, 30 điểm
      - Hàng đầu tiên là tiêu đề cột, các hàng sau là câu hỏi
      - Cột 1 là STT câu hỏi
      - Cột 2 (B) & 3 (C) là Câu hỏi & Đáp án.
      - Cột 4 (D) là giải thích.
      - Các cột sau không đọc.''',
    '''
    Quản lý câu hỏi phụ.
    
    Cần chọn trận đấu để có thể xem, sửa, xóa câu hỏi. Nút 'Remove' sẽ xóa toàn bộ câu hỏi của trận đấu đang chọn.

    Sau khi chọn trận thì có thể nhập câu hỏi: 1 câu (Add), dữ liệu Excel (Import). Khi thêm câu hỏi mới cần điền đủ thông tin: câu hỏi, đáp án. Nhập xong chọn 'Done' để lưu.
    
    Để sửa hãy bấm vào câu hỏi.

    Để nhập câu hỏi từ Excel cần lưu ý:
      - Chỉ lấy sheet đầu tiên.
      - Hàng đầu tiên là tiêu đề cột, các hàng sau là câu hỏi
      - Cột 1 là STT câu hỏi
      - Cột 2 (B) & 3 (C) là Câu hỏi & Đáp án.
      - Các cột sau không đọc.''',
    '''Phần Server chưa được hoàn thành'''
  ];
}
