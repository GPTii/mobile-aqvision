import '../data/app_theme_store.dart';

class AppStrings {
  static const Map<String, Map<String, String>> _translations = {
    // --- Account info / Business info section ---
    'Thông tin doanh nghiệp': {'en': 'Business information', 'ko': '사업자 정보', 'zh_Hant': '企業資訊'},
    'Tên doanh nghiệp': {'en': 'Company name', 'ko': '회사명', 'zh_Hant': '公司名稱'},
    'Giấy chứng nhận ĐKKD': {'en': 'Business registration certificate', 'ko': '사업자등록증', 'zh_Hant': '營業登記證'},
    'Trụ sở chính': {'en': 'Headquarters', 'ko': '본사', 'zh_Hant': '總公司'},
    'Mã số thuế': {'en': 'Tax code', 'ko': '사업자등록번호(세금)', 'zh_Hant': '統一編號'},
    'Email liên hệ': {'en': 'Contact email', 'ko': '연락처 이메일', 'zh_Hant': '聯絡電子郵件'},
    'Hotline hỗ trợ': {'en': 'Support hotline', 'ko': '고객 지원 핫라인', 'zh_Hant': '客服專線'},
    'Số giấy chứng nhận đăng ký kinh doanh': {
      'en': 'Business registration number',
      'ko': '사업자등록증 번호',
      'zh_Hant': '營業登記證號碼'
    },
    'Địa chỉ trụ sở chính': {'en': 'Headquarters address', 'ko': '본사 주소', 'zh_Hant': '總公司地址'},
    'VD: Công ty TNHH ABC': {'en': 'E.g.: ABC Co., Ltd', 'ko': '예: ABC 주식회사', 'zh_Hant': '例如：ABC 有限公司'},
    '— chưa cập nhật —': {'en': '— not updated yet —', 'ko': '— 아직 업데이트되지 않음 —', 'zh_Hant': '— 尚未更新 —'},
    'Thông tin cá nhân': {'en': 'Personal information', 'ko': '개인 정보', 'zh_Hant': '個人資料'},
    'Đã cập nhật thông tin': {'en': 'Information updated', 'ko': '정보가 업데이트되었습니다', 'zh_Hant': '資料已更新'},
    'Lỗi cập nhật thông tin doanh nghiệp': {
      'en': 'Error updating business information',
      'ko': '사업자 정보 업데이트 오류',
      'zh_Hant': '更新企業資訊時發生錯誤'
    },
    'Đang bật tự động ghi hình — tắt tự động ghi hình trước khi ghi thủ công.': {
      'en': 'Auto-record is on — turn it off before recording manually.',
      'ko': '자동 녹화가 켜져 있습니다 — 수동 녹화 전에 자동 녹화를 끄세요.',
      'zh_Hant': '自動錄影已開啟 — 請先關閉自動錄影再手動錄影。'
    },
    'Email liên hệ không đúng định dạng': {
      'en': 'Contact email is not in a valid format',
      'ko': '연락처 이메일 형식이 올바르지 않습니다',
      'zh_Hant': '聯絡電子郵件格式不正確'
    },
    'Bảo mật': {'en': 'Security', 'ko': '보안', 'zh_Hant': '安全性'},
    // --- Notification relative-time / source labels ---
    'Hệ thống': {'en': 'System', 'ko': '시스템', 'zh_Hant': '系統'},
    'Vừa xong': {'en': 'Just now', 'ko': '방금 전', 'zh_Hant': '剛剛'},
    'phút trước': {'en': 'minutes ago', 'ko': '분 전', 'zh_Hant': '分鐘前'},
    'giờ trước': {'en': 'hours ago', 'ko': '시간 전', 'zh_Hant': '小時前'},
    'ngày trước': {'en': 'days ago', 'ko': '일 전', 'zh_Hant': '天前'},
    // --- Camera store defaults / errors ---
    'Chưa xác định': {'en': 'Unknown', 'ko': '알 수 없음', 'zh_Hant': '未確定'},
    'Vừa mới': {'en': 'Just now', 'ko': '방금', 'zh_Hant': '剛剛'},
    'Vừa thêm': {'en': 'Just added', 'ko': '방금 추가됨', 'zh_Hant': '剛新增'},
    // --- Recording store errors ---
    'Máy chủ ghi hình trả về lỗi': {
      'en': 'Recording server returned an error',
      'ko': '녹화 서버에서 오류를 반환했습니다',
      'zh_Hant': '錄影伺服器回傳錯誤'
    },
    'Lỗi ghi hình': {'en': 'Recording error', 'ko': '녹화 오류', 'zh_Hant': '錄影錯誤'},
    'Camera chưa online trên máy chủ ghi hình': {
      'en': 'Camera is not online on the recording server',
      'ko': '카메라가 녹화 서버에 온라인 상태가 아닙니다',
      'zh_Hant': '攝影機未在錄影伺服器上線'
    },
    'Không có quyền ghi hình': {'en': 'No permission to record', 'ko': '녹화 권한이 없습니다', 'zh_Hant': '沒有錄影權限'},
    'Thiếu thông tin camera để ghi hình': {
      'en': 'Missing camera information for recording',
      'ko': '녹화에 필요한 카메라 정보가 없습니다',
      'zh_Hant': '缺少錄影所需的攝影機資訊'
    },
    'Lỗi bắt đầu ghi hình': {'en': 'Error starting recording', 'ko': '녹화 시작 오류', 'zh_Hant': '開始錄影時發生錯誤'},
    'Lỗi dừng ghi hình': {'en': 'Error stopping recording', 'ko': '녹화 중지 오류', 'zh_Hant': '停止錄影時發生錯誤'},
    'Lỗi cập nhật cài đặt ghi hình': {
      'en': 'Error updating recording settings',
      'ko': '녹화 설정 업데이트 오류',
      'zh_Hant': '更新錄影設定時發生錯誤'
    },
    'Lỗi xóa bản ghi': {'en': 'Error deleting recording', 'ko': '녹화 파일 삭제 오류', 'zh_Hant': '刪除錄影時發生錯誤'},
    'Lỗi tạo bản cắt': {'en': 'Error creating video clip', 'ko': '영상 클립 생성 오류', 'zh_Hant': '建立影片片段時發生錯誤'},
    // --- News (Tin tức) tab ---
    'Tin tức': {'en': 'News', 'ko': '뉴스', 'zh_Hant': '新聞'},
    'bài viết mới trong tuần này': {'en': 'new articles this week', 'ko': '이번 주 새 게시물', 'zh_Hant': '本週新文章'},
    'TIN MỚI NHẤT': {'en': 'LATEST', 'ko': '최신 뉴스', 'zh_Hant': '最新消息'},
    'Không tải được tin tức': {'en': 'Could not load news', 'ko': '뉴스를 불러올 수 없습니다', 'zh_Hant': '無法載入新聞'},
    'Không tải được nhật ký phiên bản': {
      'en': 'Could not load version history',
      'ko': '버전 기록을 불러올 수 없습니다',
      'zh_Hant': '無法載入版本紀錄'
    },
    'Chưa có bản cập nhật nào': {'en': 'No updates yet', 'ko': '아직 업데이트가 없습니다', 'zh_Hant': '尚無更新'},
    'Chưa có tin tức nào': {'en': 'No news yet', 'ko': '아직 뉴스가 없습니다', 'zh_Hant': '尚無新聞'},
    // --- Version history (Nhật ký) screen ---
    'Lịch sử phiên bản': {'en': 'Version history', 'ko': '버전 기록', 'zh_Hant': '版本紀錄'},
    'bản cập nhật gần đây': {'en': 'recent updates', 'ko': '최근 업데이트', 'zh_Hant': '近期更新'},
    'Phiên bản': {'en': 'Version', 'ko': '버전', 'zh_Hant': '版本'},
    'MỚI NHẤT': {'en': 'LATEST', 'ko': '최신', 'zh_Hant': '最新'},
    'ĐANG DÙNG': {'en': 'INSTALLED', 'ko': '사용 중', 'zh_Hant': '使用中'},
    'Tính năng mới': {'en': 'New feature', 'ko': '새 기능', 'zh_Hant': '新功能'},
    'Cải tiến': {'en': 'Improvement', 'ko': '개선', 'zh_Hant': '改進'},
    'Sửa lỗi': {'en': 'Bug fix', 'ko': '버그 수정', 'zh_Hant': '錯誤修正'},
    'Lưu ý đặc biệt': {'en': 'Special note', 'ko': '특별 참고', 'zh_Hant': '特別注意'},
    'Đổi tab Hồ sơ thành Cài đặt, thêm chế độ tối, đa ngôn ngữ và thư viện ảnh.': {
      'en': 'Switched the Profile tab to Settings, added dark mode, multi-language support and a photo gallery.',
      'ko': '프로필 탭을 설정으로 변경하고 다크 모드, 다국어 지원, 사진 갤러리를 추가했습니다.',
      'zh_Hant': '將「個人檔案」分頁改為「設定」，新增深色模式、多語言與相簿。'
    },
    'Thêm màn hình Lịch sử phiên bản ngay trong Hồ sơ.': {
      'en': 'Added a Version History screen right inside Profile.',
      'ko': '프로필 안에 버전 기록 화면을 추가했습니다.',
      'zh_Hant': '在個人檔案中新增版本紀錄畫面。'
    },
    'Sửa lỗi ghi hình, chụp ảnh camera và hiển thị dung lượng Cloud.': {
      'en': 'Fixed recording, camera photo capture, and Cloud storage display bugs.',
      'ko': '녹화, 카메라 사진 촬영 및 클라우드 용량 표시 오류를 수정했습니다.',
      'zh_Hant': '修正錄影、攝影機拍照與雲端容量顯示的錯誤。'
    },
    'Thêm yêu cầu nâng cấp gói ngay trong app, ổn định kết nối camera.': {
      'en': 'Added in-app service package upgrade requests and improved camera connection stability.',
      'ko': '앱에서 바로 요금제 업그레이드를 요청할 수 있도록 했고 카메라 연결을 안정화했습니다.',
      'zh_Hant': '新增 App 內方案升級申請，並提升攝影機連線穩定性。'
    },
    'Đổi tab "Hồ sơ" thành "Cài đặt" — thiết kế lại toàn bộ bố cục, phân nhóm rõ ràng, gọn gàng và dễ dùng hơn hẳn.': {
      'en':
          'Renamed the "Profile" tab to "Settings" — completely redesigned the layout with clear grouping, cleaner and much easier to use.',
      'ko': '"프로필" 탭을 "설정"으로 변경 — 전체 레이아웃을 새로 디자인하여 그룹이 명확하고 훨씬 깔끔하며 사용하기 쉬워졌습니다.',
      'zh_Hant': '將「個人檔案」分頁改為「設定」— 全面重新設計版面，分組清楚、更簡潔也更好用。'
    },
    'Thêm chế độ giao diện Sáng / Tối, đổi được ngay trong app.': {
      'en': 'Added Light / Dark theme mode, switchable right inside the app.',
      'ko': '라이트 / 다크 테마 모드를 추가했습니다. 앱에서 바로 전환할 수 있습니다.',
      'zh_Hant': '新增淺色 / 深色主題，可直接在 App 內切換。'
    },
    'Thêm chuyển đổi ngôn ngữ Tiếng Việt / English.': {
      'en': 'Added Vietnamese / English language switching.',
      'ko': '베트남어 / 영어 언어 전환을 추가했습니다.',
      'zh_Hant': '新增越南文 / 英文語言切換。'
    },
    'Thêm Thư viện ảnh để xem lại các ảnh đã chụp từ camera.': {
      'en': 'Added a Photo Gallery to review photos captured from cameras.',
      'ko': '카메라에서 촬영한 사진을 다시 볼 수 있는 사진 갤러리를 추가했습니다.',
      'zh_Hant': '新增相簿，可回顧從攝影機拍攝的照片。'
    },
    'Thêm mục Thông tin doanh nghiệp trong Tài khoản & bảo mật — nhập và lưu lại được ngay trong app.': {
      'en': 'Added a Business Information section under Account & Security — enter and save it directly in the app.',
      'ko': '계정 및 보안에 사업자 정보 항목을 추가했습니다 — 앱에서 바로 입력하고 저장할 수 있습니다.',
      'zh_Hant': '在「帳號與安全性」中新增企業資訊 — 可直接在 App 內輸入並儲存。'
    },
    'Tab Báo cáo hỗ trợ đổi sang tiếng Anh (trước đây chỉ có tiếng Việt).': {
      'en': 'The Reports tab now supports switching to English (previously Vietnamese only).',
      'ko': '보고서 탭에서 영어로 전환할 수 있습니다(이전에는 베트남어만 지원).',
      'zh_Hant': '報表分頁現在可切換為英文（先前僅支援越南文）。'
    },
    'Màn "Gói dịch vụ" thiết kế lại gọn gàng, dễ nhìn hơn, nút Nâng cấp gói rõ ràng hơn.': {
      'en':
          'The "Service Package" screen was redesigned to be cleaner and easier to read, with a clearer upgrade button.',
      'ko': '"요금제" 화면을 더 깔끔하고 보기 쉽게 다시 디자인했으며 업그레이드 버튼을 더 명확하게 했습니다.',
      'zh_Hant': '「服務方案」畫面重新設計，更簡潔易讀，升級按鈕也更明顯。'
    },
    'Chỉnh sửa thông tin cá nhân chuyển từ cửa sổ nhỏ sang trang riêng để chứa được nhiều thông tin hơn.': {
      'en': 'Editing personal information moved from a small popup to a dedicated page to fit more information.',
      'ko': '개인 정보 편집을 작은 팝업에서 전용 페이지로 옮겨 더 많은 정보를 담을 수 있게 했습니다.',
      'zh_Hant': '編輯個人資料從小視窗改為獨立頁面，可容納更多資訊。'
    },
    'Mục "Nhật ký" hiện sẵn số phiên bản đang dùng, không cần bấm vào mới biết.': {
      'en': 'The "Version log" entry now shows the current version number without needing to tap in.',
      'ko': '"로그" 항목에 현재 사용 중인 버전 번호가 바로 표시되어 눌러 보지 않아도 됩니다.',
      'zh_Hant': '「日誌」項目直接顯示目前版本號碼，不必點進去查看。'
    },
    'Thêm màn hình "Lịch sử phiên bản" trong Hồ sơ — xem nhanh các bản cập nhật, tính năng mới và lỗi đã sửa ngay trong app, không cần hỏi lại đội kỹ thuật.':
        {
      'en':
          'Added a "Version History" screen in Profile — quickly view updates, new features and fixed bugs right in the app, no need to ask the tech team.',
      'ko': '프로필에 "버전 기록" 화면 추가 — 업데이트, 새 기능, 수정된 버그를 앱에서 바로 확인할 수 있어 기술팀에 물어볼 필요가 없습니다.',
      'zh_Hant': '在個人檔案新增「版本紀錄」畫面 — 在 App 內快速查看更新、新功能與已修正的錯誤，無需再詢問技術團隊。'
    },
    'Tab Báo cáo hiển thị ngay dữ liệu dung lượng đã tải lần trước ngay khi vừa mở tab, không phải chờ trắng màn hình mỗi lần vào.':
        {
      'en':
          'The Reports tab now instantly shows the previously loaded storage data as soon as the tab opens, no blank-screen wait each time.',
      'ko': '보고서 탭을 열면 이전에 불러온 용량 데이터가 바로 표시되어 매번 빈 화면을 기다릴 필요가 없습니다.',
      'zh_Hant': '開啟報表分頁時會立即顯示上次載入的容量資料，不必每次等待空白畫面。'
    },
    'Nút "Chụp" trên camera trực tiếp trước đây không lưu được ảnh nào — nay chụp và lưu ảnh thật, có xem trước và xác nhận Lưu / Xoá.':
        {
      'en':
          'The "Capture" button on the live camera previously saved no photos — now it actually captures and saves photos, with a preview and Save / Delete confirmation.',
      'ko': '라이브 카메라의 "캡처" 버튼이 이전에는 사진을 저장하지 못했습니다 — 이제 실제로 촬영·저장되며 미리보기와 저장 / 삭제 확인이 있습니다.',
      'zh_Hant': '即時攝影機上的「拍照」按鈕先前無法儲存照片 — 現在可實際拍攝並儲存，並提供預覽及儲存 / 刪除確認。'
    },
    'Sửa thông báo sai "Phiên ghi hình hết hạn, hãy đăng nhập lại" xuất hiện dù tài khoản vẫn đang đăng nhập bình thường.':
        {
      'en':
          'Fixed the incorrect "Recording session expired, please log in again" message appearing even while still logged in normally.',
      'ko': '정상적으로 로그인되어 있는데도 "녹화 세션이 만료되었습니다. 다시 로그인하세요" 메시지가 잘못 표시되던 문제를 수정했습니다.',
      'zh_Hant': '修正帳號仍正常登入時卻錯誤顯示「錄影工作階段已過期，請重新登入」的問題。'
    },
    'Sửa lỗi mục "Camera chiếm nhiều dung lượng nhất" luôn hiển thị 0 MB dù camera đã có dữ liệu ghi hình thật.': {
      'en':
          'Fixed the "Cameras taking up the most storage" section always showing 0 MB even when cameras had real recording data.',
      'ko': '카메라에 실제 녹화 데이터가 있는데도 "가장 많은 용량을 차지하는 카메라"가 항상 0 MB로 표시되던 오류를 수정했습니다.',
      'zh_Hant': '修正「佔用最多容量的攝影機」即使有實際錄影資料仍一律顯示 0 MB 的錯誤。'
    },
    'Khuyến nghị cập nhật cho các thiết bị đang gặp lỗi khi nhấn ghi hình hoặc chụp ảnh camera.': {
      'en': 'Update recommended for devices experiencing issues when tapping record or capture on cameras.',
      'ko': '카메라 녹화 또는 캡처 시 오류가 발생하는 기기는 업데이트를 권장합니다.',
      'zh_Hant': '建議按下錄影或拍照時發生錯誤的裝置進行更新。'
    },
    'Thêm luồng gửi yêu cầu nâng cấp gói dịch vụ ngay trong app, có thể kèm lời nhắn.': {
      'en': 'Added an in-app flow to send a service package upgrade request, optionally with a message.',
      'ko': '앱에서 바로 요금제 업그레이드 요청을 보낼 수 있는 기능을 추가했습니다(메시지 첨부 가능).',
      'zh_Hant': '新增 App 內送出服務方案升級申請的流程，可附上留言。'
    },
    'Trang Hồ sơ hiển thị thông tin gói dịch vụ và dung lượng lưu trữ đang dùng.': {
      'en': 'The Profile page now shows service package info and current storage usage.',
      'ko': '프로필 페이지에 요금제 정보와 현재 사용 중인 저장 용량이 표시됩니다.',
      'zh_Hant': '個人檔案頁面顯示服務方案資訊與目前使用的儲存容量。'
    },
    'Khoá xoay màn hình dọc để thao tác ổn định hơn khi xem camera.': {
      'en': 'Locked screen rotation to portrait for more stable interaction while viewing cameras.',
      'ko': '카메라를 볼 때 더 안정적으로 조작할 수 있도록 화면을 세로로 고정했습니다.',
      'zh_Hant': '鎖定直向螢幕，觀看攝影機時操作更穩定。'
    },
    'Tinh gọn tab Báo cáo: gộp về tổng quan hệ thống và dung lượng Cloud, bớt rối mắt.': {
      'en': 'Streamlined the Reports tab: consolidated into system overview and Cloud storage, less visual clutter.',
      'ko': '보고서 탭 간소화: 시스템 개요와 클라우드 용량으로 통합해 덜 복잡해졌습니다.',
      'zh_Hant': '精簡報表分頁：整合為系統總覽與雲端容量，畫面更清爽。'
    },
    'Cải thiện độ ổn định khi xem camera trực tiếp qua WebRTC.': {
      'en': 'Improved stability when viewing live cameras over WebRTC.',
      'ko': 'WebRTC로 라이브 카메라를 볼 때의 안정성을 개선했습니다.',
      'zh_Hant': '提升透過 WebRTC 觀看即時攝影機的穩定性。'
    },
    'Sửa lỗi phát lại video HLS bị gián đoạn ở một số camera.': {
      'en': 'Fixed HLS video playback interruptions on some cameras.',
      'ko': '일부 카메라에서 HLS 영상 재생이 끊기던 문제를 수정했습니다.',
      'zh_Hant': '修正部分攝影機 HLS 影片播放中斷的問題。'
    },
    'Sửa lỗi truy cập file ghi hình khi kết nối qua máy chủ proxy.': {
      'en': 'Fixed recording file access errors when connecting through a proxy server.',
      'ko': '프록시 서버를 통해 연결할 때 녹화 파일에 접근하지 못하던 오류를 수정했습니다.',
      'zh_Hant': '修正透過代理伺服器連線時無法存取錄影檔的錯誤。'
    },
    'Sửa một số lỗi hiển thị ở màn hình chi tiết camera.': {
      'en': 'Fixed several display bugs on the camera detail screen.',
      'ko': '카메라 상세 화면의 일부 표시 오류를 수정했습니다.',
      'zh_Hant': '修正攝影機詳細畫面的部分顯示錯誤。'
    },
    'Dung lượng gần đầy. Xoá bớt recording cũ hoặc liên hệ quản trị viên để tăng dung lượng.': {
      'en': 'Storage is nearly full. Delete old recordings or contact admin to increase storage.',
      'ko': '저장 용량이 거의 찼습니다. 오래된 녹화를 삭제하거나 관리자에게 용량 증설을 문의하세요.',
      'zh_Hant': '儲存空間即將滿載。請刪除舊錄影或聯絡管理員增加容量。'
    },
    'Tổng quan hệ thống': {'en': 'System overview', 'ko': '시스템 개요', 'zh_Hant': '系統總覽'},
    'Gói dịch vụ': {'en': 'Service Package', 'ko': '요금제', 'zh_Hant': '服務方案'},
    'Chủ Nhật': {'en': 'Sunday', 'ko': '일요일', 'zh_Hant': '星期日'},
    'App (Thường là \'live\')': {
      'en': 'App (Usually \'live\')',
      'ko': '앱 (보통 \'live\')',
      'zh_Hant': 'App（通常為 \'live\'）'
    },
    'Đã cập nhật thông tin cá nhân': {
      'en': 'Personal information updated',
      'ko': '개인 정보가 업데이트되었습니다',
      'zh_Hant': '個人資料已更新'
    },
    'Thêm': {'en': 'Add', 'ko': '추가', 'zh_Hant': '新增'},
    'Xoá camera': {'en': 'Delete camera', 'ko': '카메라 삭제', 'zh_Hant': '刪除攝影機'},
    'Phương pháp giải mã': {'en': 'Decoding method', 'ko': '디코딩 방식', 'zh_Hant': '解碼方式'},
    'Mưa nhẹ': {'en': 'Light rain', 'ko': '약한 비', 'zh_Hant': '小雨'},
    'Loại camera': {'en': 'Camera type', 'ko': '카메라 유형', 'zh_Hant': '攝影機類型'},
    'Thứ Hai': {'en': 'Monday', 'ko': '월요일', 'zh_Hant': '星期一'},
    'Chưa có camera nào trong nhóm này': {
      'en': 'No cameras in this group',
      'ko': '이 그룹에 카메라가 없습니다',
      'zh_Hant': '此群組中沒有攝影機'
    },
    'Không có bản ghi': {'en': 'No recordings', 'ko': '녹화 없음', 'zh_Hant': '沒有錄影'},
    '/tháng': {'en': '/month', 'ko': '/월', 'zh_Hant': '/月'},
    'Tất cả': {'en': 'All', 'ko': '전체', 'zh_Hant': '全部'},
    'Mưa phùn': {'en': 'Drizzle', 'ko': '이슬비', 'zh_Hant': '毛毛雨'},
    'Đã lưu ảnh vào Photos': {'en': 'Saved photo to Gallery', 'ko': '사진에 이미지를 저장했습니다', 'zh_Hant': '已將照片儲存至相簿'},
    'Chưa kích hoạt': {'en': 'Not activated', 'ko': '활성화되지 않음', 'zh_Hant': '尚未啟用'},
    'Mưa rào to': {'en': 'Heavy shower', 'ko': '강한 소나기', 'zh_Hant': '大陣雨'},
    'Không thể lưu ảnh cục bộ: ': {
      'en': 'Cannot save local image: ',
      'ko': '로컬 이미지를 저장할 수 없습니다: ',
      'zh_Hant': '無法儲存本機圖片：'
    },
    'Báo cáo': {'en': 'Reports', 'ko': '보고서', 'zh_Hant': '報表'},
    'Vui lòng nhập URL nguồn': {'en': 'Please enter source URL', 'ko': '소스 URL을 입력하세요', 'zh_Hant': '請輸入來源 URL'},
    'Xóa nhóm "\${group.name}"?': {
      'en': 'Delete group "\${group.name}"?',
      'ko': '"\${group.name}" 그룹을 삭제할까요?',
      'zh_Hant': '要刪除群組「\${group.name}」嗎？'
    },
    'Trang chủ': {'en': 'Home', 'ko': '홈', 'zh_Hant': '首頁'},
    'Vui lòng nhập họ tên': {'en': 'Please enter your name', 'ko': '이름을 입력하세요', 'zh_Hant': '請輸入姓名'},
    'Tắt ghi hình': {'en': 'Stop recording', 'ko': '녹화 끄기', 'zh_Hant': '關閉錄影'},
    'Đã đổi tên thành "\$newName"': {
      'en': 'Renamed to "\$newName"',
      'ko': '"\$newName"(으)로 이름을 변경했습니다',
      'zh_Hant': '已重新命名為「\$newName」'
    },
    'Xóa bản ghi?': {'en': 'Delete recording?', 'ko': '녹화를 삭제할까요?', 'zh_Hant': '要刪除錄影嗎？'},
    'Bạn sẽ cần đăng nhập lại để tiếp tục sử dụng ứng dụng.': {
      'en': 'You will need to log in again to continue using the app.',
      'ko': '앱을 계속 사용하려면 다시 로그인해야 합니다.',
      'zh_Hant': '您需要重新登入才能繼續使用 App。'
    },
    'Camera mất kết nối': {'en': 'Camera disconnected', 'ko': '카메라 연결 끊김', 'zh_Hant': '攝影機連線中斷'},
    // --- Server notification titles / message templates (see utils/server_text.dart) ---
    'Gateway không nhận lệnh qua Bluetooth. Rút điện gateway khoảng 10 giây rồi cắm lại và thử lại, hoặc bấm "Dùng WiFi dự phòng".': {'en': 'The gateway is not accepting Bluetooth commands. Unplug the gateway for about 10 seconds, plug it back in and try again, or tap "Use backup WiFi".', 'ko': '게이트웨이가 블루투스 명령을 받지 않습니다. 게이트웨이 전원을 약 10초간 뽑았다가 다시 꽂고 다시 시도하거나 "백업 WiFi 사용"을 누르세요.', 'zh_Hant': 'Gateway 未接受藍牙指令。請拔除 Gateway 電源約 10 秒後再插回並重試，或點選「使用備用 WiFi」。'},
    'Camera hoạt động trở lại': {'en': 'Camera back online', 'ko': '카메라가 다시 온라인입니다', 'zh_Hant': '攝影機已恢復運作'},
    'Camera Offline': {'en': 'Camera offline', 'ko': '카메라 오프라인', 'zh_Hant': '攝影機離線'},
    'Camera Đã Ngắt Kết Nối': {'en': 'Camera disconnected', 'ko': '카메라 연결 해제됨', 'zh_Hant': '攝影機已中斷連線'},
    'Camera Mới': {'en': 'New camera', 'ko': '새 카메라', 'zh_Hant': '新攝影機'},
    'Camera Đã Kết Nối Lại': {'en': 'Camera reconnected', 'ko': '카메라 재연결됨', 'zh_Hant': '攝影機已重新連線'},
    'Camera mới được thêm': {'en': 'New camera added', 'ko': '새 카메라가 추가되었습니다', 'zh_Hant': '已新增攝影機'},
    'Camera đã bị xóa': {'en': 'Camera deleted', 'ko': '카메라가 삭제되었습니다', 'zh_Hant': '攝影機已刪除'},
    'Camera đã ngắt kết nối': {'en': 'Camera disconnected', 'ko': '카메라 연결 해제됨', 'zh_Hant': '攝影機已中斷連線'},
    'Camera đã kết nối lại': {'en': 'Camera reconnected', 'ko': '카메라 재연결됨', 'zh_Hant': '攝影機已重新連線'},
    'Không có cảnh báo nào': {'en': 'No alerts', 'ko': '알림이 없습니다', 'zh_Hant': '沒有任何警示'},
    'Camera "{cam}" thuộc ứng dụng "{app}" đang offline.': {
      'en': 'Camera "{cam}" in app "{app}" is offline.',
      'ko': '앱 "{app}"의 카메라 "{cam}"이(가) 오프라인입니다.',
      'zh_Hant': '應用程式「{app}」的攝影機「{cam}」目前離線。'
    },
    'Camera "{cam}" thuộc ứng dụng "{app}" đã online trở lại.': {
      'en': 'Camera "{cam}" in app "{app}" is back online.',
      'ko': '앱 "{app}"의 카메라 "{cam}"이(가) 다시 온라인입니다.',
      'zh_Hant': '應用程式「{app}」的攝影機「{cam}」已恢復上線。'
    },
    'Camera "{cam}" (ứng dụng: {app}) đang mất kết nối.': {
      'en': 'Camera "{cam}" (app: {app}) has lost connection.',
      'ko': '카메라 "{cam}"(앱: {app})의 연결이 끊겼습니다.',
      'zh_Hant': '攝影機「{cam}」（應用程式：{app}）連線中斷。'
    },
    'Camera "{cam}" (ứng dụng: {app}) đã được ngắt kết nối thủ công.': {
      'en': 'Camera "{cam}" (app: {app}) was disconnected manually.',
      'ko': '카메라 "{cam}"(앱: {app})의 연결이 수동으로 해제되었습니다.',
      'zh_Hant': '攝影機「{cam}」（應用程式：{app}）已被手動中斷連線。'
    },
    'Camera "{cam}" (ứng dụng: {app}) đã được thêm vào hệ thống.': {
      'en': 'Camera "{cam}" (app: {app}) was added to the system.',
      'ko': '카메라 "{cam}"(앱: {app})이(가) 시스템에 추가되었습니다.',
      'zh_Hant': '攝影機「{cam}」（應用程式：{app}）已加入系統。'
    },
    'Camera "{cam}" (ứng dụng: {app}) đang hoạt động (vừa được kết nối lại hoặc cập nhật).': {
      'en': 'Camera "{cam}" (app: {app}) is running (just reconnected or updated).',
      'ko': '카메라 "{cam}"(앱: {app})이(가) 작동 중입니다(방금 재연결 또는 업데이트됨).',
      'zh_Hant': '攝影機「{cam}」（應用程式：{app}）運作中（剛重新連線或更新）。'
    },
    'Camera "{cam}" đã được thêm vào hệ thống với trạng thái {status}.': {
      'en': 'Camera "{cam}" was added to the system with status {status}.',
      'ko': '카메라 "{cam}"이(가) {status} 상태로 시스템에 추가되었습니다.',
      'zh_Hant': '攝影機「{cam}」已加入系統，狀態為 {status}。'
    },
    'Camera "{cam}" đã bị xóa khỏi hệ thống.': {
      'en': 'Camera "{cam}" was removed from the system.',
      'ko': '카메라 "{cam}"이(가) 시스템에서 삭제되었습니다.',
      'zh_Hant': '攝影機「{cam}」已從系統中移除。'
    },
    'Camera "{cam}" đã bị ngắt kết nối thủ công.': {
      'en': 'Camera "{cam}" was disconnected manually.',
      'ko': '카메라 "{cam}"의 연결이 수동으로 해제되었습니다.',
      'zh_Hant': '攝影機「{cam}」已被手動中斷連線。'
    },
    'Camera "{cam}" đã được kết nối lại thủ công.': {
      'en': 'Camera "{cam}" was reconnected manually.',
      'ko': '카메라 "{cam}"이(가) 수동으로 재연결되었습니다.',
      'zh_Hant': '攝影機「{cam}」已被手動重新連線。'
    },
    'Hôm nay · \$date': {'en': 'Today · \$date', 'ko': '오늘 · \$date', 'zh_Hant': '今天 · \$date'},
    'Ghi nhớ': {'en': 'Remember me', 'ko': '로그인 정보 기억', 'zh_Hant': '記住我'},
    'Mưa': {'en': 'Rain', 'ko': '비', 'zh_Hant': '雨'},
    '1.0x (Bình thường)': {'en': '1.0x (Normal)', 'ko': '1.0x (보통)', 'zh_Hant': '1.0x（正常）'},
    'Tiếng Việt': {'en': 'Vietnamese', 'ko': '베트남어', 'zh_Hant': '越南文'},
    'nhóm': {'en': 'groups', 'ko': '그룹', 'zh_Hant': '群組'},
    'Lỗi chụp ảnh: \$e': {'en': 'Screenshot error: \$e', 'ko': '캡처 오류: \$e', 'zh_Hant': '截圖錯誤：\$e'},
    'Ngày bắt đầu gói': {'en': 'Package start date', 'ko': '요금제 시작일', 'zh_Hant': '方案開始日期'},
    'Bình thường': {'en': 'Normal', 'ko': '정상', 'zh_Hant': '正常'},
    'Yêu cầu của bạn đang chờ quản trị viên duyệt. Gói sẽ tự cập nhật ': {
      'en': 'Your request is pending admin approval. The package will automatically update ',
      'ko': '요청이 관리자 승인을 기다리고 있습니다. 승인되면 요금제가 자동으로 업데이트됩니다 ',
      'zh_Hant': '您的申請正在等待管理員核准。方案將自動更新於'
    },
    'Vui lòng nhập mật khẩu': {'en': 'Please enter password', 'ko': '비밀번호를 입력하세요', 'zh_Hant': '請輸入密碼'},
    'Nhóm': {'en': 'Group', 'ko': '그룹', 'zh_Hant': '群組'},
    'Họ và tên': {'en': 'Full name', 'ko': '이름', 'zh_Hant': '姓名'},
    'Không rõ': {'en': 'Unknown', 'ko': '알 수 없음', 'zh_Hant': '不明'},
    'Sắp đầy': {'en': 'Almost full', 'ko': '거의 참', 'zh_Hant': '即將滿載'},
    'Chưa đăng nhập': {'en': 'Not logged in', 'ko': '로그인하지 않음', 'zh_Hant': '尚未登入'},
    'Cài đặt': {'en': 'Settings', 'ko': '설정', 'zh_Hant': '設定'},
    'Chỉnh sửa thông tin cá nhân': {'en': 'Edit personal information', 'ko': '개인 정보 편집', 'zh_Hant': '編輯個人資料'},
    'Cập nhật hệ thống': {'en': 'System update', 'ko': '시스템 업데이트', 'zh_Hant': '系統更新'},
    'Thông tin ứng dụng': {'en': 'App info', 'ko': '앱 정보', 'zh_Hant': 'App 資訊'},
    'Đang đổi...': {'en': 'Changing...', 'ko': '변경 중...', 'zh_Hant': '變更中...'},
    'Xóa nhóm?': {'en': 'Delete group?', 'ko': '그룹을 삭제할까요?', 'zh_Hant': '要刪除群組嗎？'},
    '+ Tạo nhóm mới': {'en': '+ Create new group', 'ko': '+ 새 그룹 만들기', 'zh_Hant': '+ 建立新群組'},
    'Mưa to': {'en': 'Heavy rain', 'ko': '폭우', 'zh_Hant': '大雨'},
    'Không thể phát video: \$e': {'en': 'Cannot play video: \$e', 'ko': '영상을 재생할 수 없습니다: \$e', 'zh_Hant': '無法播放影片：\$e'},
    'thiết bị': {'en': 'devices', 'ko': '기기', 'zh_Hant': '裝置'},
    'Chưa có nhóm nào': {'en': 'No groups yet', 'ko': '아직 그룹이 없습니다', 'zh_Hant': '尚無群組'},
    'Hôm qua · \$date': {'en': 'Yesterday · \$date', 'ko': '어제 · \$date', 'zh_Hant': '昨天 · \$date'},
    'Vui lòng nhập Stream ID': {'en': 'Please enter Stream ID', 'ko': 'Stream ID를 입력하세요', 'zh_Hant': '請輸入 Stream ID'},
    'Chuyển về Free': {'en': 'Switch to Free', 'ko': 'Free로 전환', 'zh_Hant': '切換為 Free'},
    'Tên nhóm mới...': {'en': 'New group name...', 'ko': '새 그룹 이름...', 'zh_Hant': '新群組名稱...'},
    'Ứng dụng đang được cập nhật. Không thể kết nối tới máy chủ lúc này. Vui lòng thử lại sau!': {
      'en': 'App is being updated. Cannot connect to server at this time. Please try again later!',
      'ko': '앱을 업데이트하는 중입니다. 지금은 서버에 연결할 수 없습니다. 잠시 후 다시 시도하세요!',
      'zh_Hant': 'App 正在更新中，目前無法連線到伺服器。請稍後再試！'
    },
    '\$cameraCount (không giới hạn)': {
      'en': '\$cameraCount (unlimited)',
      'ko': '\$cameraCount (무제한)',
      'zh_Hant': '\$cameraCount（無限制）'
    },
    'Đăng xuất?': {'en': 'Log out?', 'ko': '로그아웃할까요?', 'zh_Hant': '要登出嗎？'},
    'Sáng': {'en': 'Light', 'ko': '라이트', 'zh_Hant': '淺色'},
    'Gói hiện tại': {'en': 'Current package', 'ko': '현재 요금제', 'zh_Hant': '目前方案'},
    'Gần đây': {'en': 'Recent', 'ko': '최근', 'zh_Hant': '最近'},
    'Đang hoạt động': {'en': 'Online', 'ko': '온라인', 'zh_Hant': '在線'},
    'Tự động ghi hình': {'en': 'Auto record', 'ko': '자동 녹화', 'zh_Hant': '自動錄影'},
    'Email hoặc tên đăng nhập': {'en': 'Email or username', 'ko': '이메일 또는 사용자 이름', 'zh_Hant': '電子郵件或使用者名稱'},
    'Cài Đặt': {'en': 'Settings', 'ko': '설정', 'zh_Hant': '設定'},
    'Thư viện ảnh': {'en': 'Gallery', 'ko': '사진 갤러리', 'zh_Hant': '相簿'},
    'Thông tin tài khoản': {'en': 'Account information', 'ko': '계정 정보', 'zh_Hant': '帳號資訊'},
    'Bạn có chắc chắn muốn xóa camera này không?': {
      'en': 'Are you sure you want to delete this camera?',
      'ko': '이 카메라를 삭제하시겠습니까?',
      'zh_Hant': '確定要刪除此攝影機嗎？'
    },
    'Email không hợp lệ': {'en': 'Invalid email', 'ko': '이메일이 올바르지 않습니다', 'zh_Hant': '電子郵件無效'},
    'Mật khẩu phải có ít nhất 4 ký tự': {
      'en': 'Password must be at least 4 characters',
      'ko': '비밀번호는 최소 4자 이상이어야 합니다',
      'zh_Hant': '密碼至少需要 4 個字元'
    },
    'Đã hiểu': {'en': 'Got it', 'ko': '확인', 'zh_Hant': '我知道了'},
    'Không thể tạo ảnh chụp': {'en': 'Cannot create screenshot', 'ko': '스크린샷을 만들 수 없습니다', 'zh_Hant': '無法建立截圖'},
    'Liên hệ quản lý về gói': {'en': 'Contact manager about package', 'ko': '요금제 관련 관리자 문의', 'zh_Hant': '聯絡管理員詢問方案'},
    'Xác nhận mật khẩu mới': {'en': 'Confirm new password', 'ko': '새 비밀번호 확인', 'zh_Hant': '確認新密碼'},
    'Tự động phát chế độ xem trực tiếp trên trang chủ.': {
      'en': 'Auto-play live view on home screen.',
      'ko': '홈 화면에서 라이브 보기를 자동 재생합니다.',
      'zh_Hant': '在首頁自動播放即時畫面。'
    },
    'VD: Phòng ngủ': {'en': 'E.g.: Bedroom', 'ko': '예: 침실', 'zh_Hant': '例如：臥室'},
    'Tìm kiếm, xem và xóa video đã ghi': {
      'en': 'Search, view and delete recorded videos',
      'ko': '녹화된 영상 검색, 보기 및 삭제',
      'zh_Hant': '搜尋、觀看及刪除已錄製的影片'
    },
    'Camera thân trụ': {'en': 'Bullet camera', 'ko': '불릿 카메라', 'zh_Hant': '槍型攝影機'},
    'Xem & quản lý': {'en': 'View & manage', 'ko': '보기 및 관리', 'zh_Hant': '檢視與管理'},
    ' /tháng': {'en': ' /month', 'ko': ' /월', 'zh_Hant': ' /月'},
    'Miễn phí': {'en': 'Free', 'ko': '무료', 'zh_Hant': '免費'},
    'Thứ Năm': {'en': 'Thursday', 'ko': '목요일', 'zh_Hant': '星期四'},
    'Đã lưu video vào thư mục Download': {
      'en': 'Saved video to Download folder',
      'ko': '다운로드 폴더에 영상을 저장했습니다',
      'zh_Hant': '已將影片儲存至 Download 資料夾'
    },
    'Xóa': {'en': 'Delete', 'ko': '삭제', 'zh_Hant': '刪除'},
    'Đang bật ghi hình': {'en': 'Starting recording', 'ko': '녹화 시작 중', 'zh_Hant': '正在開始錄影'},
    'Hệ thống sẽ tạo 1 đoạn video dài 30 giây bắt đầu từ giây thứ \$pos của bản ghi hiện tại. Tiếp tục?': {
      'en':
          'The system will create a 30-second video clip starting at \$pos seconds of the current recording. Continue?',
      'ko': '현재 녹화의 \$pos초부터 30초 길이의 영상 클립을 생성합니다. 계속할까요?',
      'zh_Hant': '系統將從目前錄影的第 \$pos 秒開始建立 30 秒的影片片段。要繼續嗎？'
    },
    'kết nối lại': {'en': 'reconnect', 'ko': '재연결', 'zh_Hant': '重新連線'},
    'Đặt lại mật khẩu thiết bị': {'en': 'Reset device password', 'ko': '기기 비밀번호 재설정', 'zh_Hant': '重設裝置密碼'},
    'Lưu': {'en': 'Save', 'ko': '저장', 'zh_Hant': '儲存'},
    'Toàn bộ camera trong nhóm này': {'en': 'All cameras in this group', 'ko': '이 그룹의 모든 카메라', 'zh_Hant': '此群組的所有攝影機'},
    'Tên luồng (Stream ID)': {
      'en': 'Stream Name (Stream ID)',
      'ko': '스트림 이름 (Stream ID)',
      'zh_Hant': '串流名稱（Stream ID）'
    },
    'Không tải được dung lượng lưu trữ': {
      'en': 'Cannot load storage capacity',
      'ko': '저장 용량을 불러올 수 없습니다',
      'zh_Hant': '無法載入儲存容量'
    },
    'giá gốc': {'en': 'original price', 'ko': '정가', 'zh_Hant': '原價'},
    'Đổi mật khẩu thành công': {'en': 'Password changed successfully', 'ko': '비밀번호가 변경되었습니다', 'zh_Hant': '密碼變更成功'},
    'Lỗi: \$e': {'en': 'Error: \$e', 'ko': '오류: \$e', 'zh_Hant': '錯誤：\$e'},
    'Thêm camera có sẵn': {'en': 'Add existing camera', 'ko': '기존 카메라 추가', 'zh_Hant': '新增現有攝影機'},
    'Lịch sử ghi hình': {'en': 'Recording history', 'ko': '녹화 기록', 'zh_Hant': '錄影紀錄'},
    'Nâng cấp': {'en': 'Upgrade', 'ko': '업그레이드', 'zh_Hant': '升級'},
    'Vui lòng nhập email hoặc tên đăng nhập': {
      'en': 'Please enter email or username',
      'ko': '이메일 또는 사용자 이름을 입력하세요',
      'zh_Hant': '請輸入電子郵件或使用者名稱'
    },
    'Thêm camera mới': {'en': 'Add new camera', 'ko': '새 카메라 추가', 'zh_Hant': '新增攝影機'},
    'Tắt tự động ghi hình': {'en': 'Turn off auto recording', 'ko': '자동 녹화 끄기', 'zh_Hant': '關閉自動錄影'},
    'Mưa phùn dày': {'en': 'Heavy drizzle', 'ko': '짙은 이슬비', 'zh_Hant': '濃密毛毛雨'},
    'Quản lý →': {'en': 'Manage →', 'ko': '관리 →', 'zh_Hant': '管理 →'},
    'Vui lòng nhập mật khẩu mới': {'en': 'Please enter new password', 'ko': '새 비밀번호를 입력하세요', 'zh_Hant': '請輸入新密碼'},
    'Bật tự động ghi hình': {'en': 'Turn on auto recording', 'ko': '자동 녹화 켜기', 'zh_Hant': '開啟自動錄影'},
    'Đã xóa bản ghi': {'en': 'Recording deleted', 'ko': '녹화를 삭제했습니다', 'zh_Hant': '錄影已刪除'},
    'Thông báo hệ thống': {'en': 'System notification', 'ko': '시스템 알림', 'zh_Hant': '系統通知'},
    'Theo tháng': {'en': 'Monthly', 'ko': '월간', 'zh_Hant': '按月'},
    'Xoá camera?': {'en': 'Delete camera?', 'ko': '카메라를 삭제할까요?', 'zh_Hant': '要刪除攝影機嗎？'},
    'Server lỗi \${res.statusCode}': {
      'en': 'Server error \${res.statusCode}',
      'ko': '서버 오류 \${res.statusCode}',
      'zh_Hant': '伺服器錯誤 \${res.statusCode}'
    },
    'Tuyết nhẹ': {'en': 'Light snow', 'ko': '약한 눈', 'zh_Hant': '小雪'},
    'Không có thông báo nào': {'en': 'No notifications', 'ko': '알림이 없습니다', 'zh_Hant': '沒有通知'},
    'Đổi mật khẩu': {'en': 'Change password', 'ko': '비밀번호 변경', 'zh_Hant': '變更密碼'},
    'Tự Động Cập Nhật': {'en': 'Auto Update', 'ko': '자동 업데이트', 'zh_Hant': '自動更新'},
    'Camera chiếm nhiều dung lượng nhất': {
      'en': 'Cameras taking up most storage',
      'ko': '가장 많은 용량을 차지하는 카메라',
      'zh_Hant': '佔用最多容量的攝影機'
    },
    'Nhấn nút + phía trên để thêm camera đầu tiên.': {
      'en': 'Tap the + button above to add the first camera.',
      'ko': '위의 + 버튼을 눌러 첫 번째 카메라를 추가하세요.',
      'zh_Hant': '點選上方的 + 按鈕新增第一台攝影機。'
    },
    'Chưa có ảnh nào được lưu': {'en': 'No photos saved yet', 'ko': '저장된 사진이 없습니다', 'zh_Hant': '尚未儲存任何照片'},
    'Bắt đầu: \${parts[3]}:\${parts[4]}:\${parts[5]}': {
      'en': 'Start: \${parts[3]}:\${parts[4]}:\${parts[5]}',
      'ko': '시작: \${parts[3]}:\${parts[4]}:\${parts[5]}',
      'zh_Hant': '開始：\${parts[3]}:\${parts[4]}:\${parts[5]}'
    },
    'Tên nhóm mới': {'en': 'New group name', 'ko': '새 그룹 이름', 'zh_Hant': '新群組名稱'},
    'Theo năm': {'en': 'Yearly', 'ko': '연간', 'zh_Hant': '按年'},
    'Đã thêm nhóm "\$name"': {'en': 'Added group "\$name"', 'ko': '"\$name" 그룹을 추가했습니다', 'zh_Hant': '已新增群組「\$name」'},
    'Tối': {'en': 'Dark', 'ko': '다크', 'zh_Hant': '深色'},
    'Cắt đoạn video': {'en': 'Cut video clip', 'ko': '영상 클립 자르기', 'zh_Hant': '剪輯影片片段'},
    'Đang tải video...': {'en': 'Loading video...', 'ko': '영상 불러오는 중...', 'zh_Hant': '影片載入中...'},
    'Stream ID (Mã camera)': {'en': 'Stream ID (Camera ID)', 'ko': 'Stream ID (카메라 코드)', 'zh_Hant': 'Stream ID（攝影機代碼）'},
    'Xóa Camera': {'en': 'Delete Camera', 'ko': '카메라 삭제', 'zh_Hant': '刪除攝影機'},
    'Ghi hình': {'en': 'Record', 'ko': '녹화', 'zh_Hant': '錄影'},
    'Vị trí lắp đặt': {'en': 'Installation location', 'ko': '설치 위치', 'zh_Hant': '安裝位置'},
    'Nhật ký': {'en': 'Logs', 'ko': '로그', 'zh_Hant': '日誌'},
    'Dung lượng lưu trữ (GB)': {'en': 'Storage capacity (GB)', 'ko': '저장 용량 (GB)', 'zh_Hant': '儲存容量（GB）'},
    'Lưu thay đổi': {'en': 'Save changes', 'ko': '변경 사항 저장', 'zh_Hant': '儲存變更'},
    ' /năm': {'en': ' /year', 'ko': ' /년', 'zh_Hant': ' /年'},
    'Kết nối': {'en': 'Connect', 'ko': '연결', 'zh_Hant': '連線'},
    'Vui lòng nhập email': {'en': 'Please enter email', 'ko': '이메일을 입력하세요', 'zh_Hant': '請輸入電子郵件'},
    'Camera đang offline, không thể bắt đầu ghi hình': {
      'en': 'Camera is offline, cannot start recording',
      'ko': '카메라가 오프라인이라 녹화를 시작할 수 없습니다',
      'zh_Hant': '攝影機離線，無法開始錄影'
    },
    'Thiết bị này chưa hỗ trợ lưu trữ cục bộ': {
      'en': 'This device does not support local storage yet',
      'ko': '이 기기는 아직 로컬 저장을 지원하지 않습니다',
      'zh_Hant': '此裝置尚不支援本機儲存'
    },
    'trong mục "Gói dịch vụ" ngay sau khi được duyệt.': {
      'en': 'in the "Service Package" section upon approval.',
      'ko': '승인 즉시 "요금제" 항목에서 확인할 수 있습니다.',
      'zh_Hant': '核准後即會在「服務方案」中更新。'
    },
    'Mật khẩu mới': {'en': 'New password', 'ko': '새 비밀번호', 'zh_Hant': '新密碼'},
    'Nguy cấp': {'en': 'Critical', 'ko': '위험', 'zh_Hant': '危急'},
    'Sửa thông tin': {'en': 'Edit information', 'ko': '정보 수정', 'zh_Hant': '編輯資訊'},
    'Cắt thành công! Đã lưu tại: \$clipUrl': {
      'en': 'Cut successful! Saved at: \$clipUrl',
      'ko': '자르기 성공! 저장 위치: \$clipUrl',
      'zh_Hant': '剪輯成功！已儲存於：\$clipUrl'
    },
    'ICE Connection Failed (Có thể do mạng Simulator chặn UDP)': {
      'en': 'ICE Connection Failed (Network Simulator might be blocking UDP)',
      'ko': 'ICE 연결 실패 (시뮬레이터 네트워크가 UDP를 차단했을 수 있음)',
      'zh_Hant': 'ICE 連線失敗（可能是模擬器網路封鎖了 UDP）'
    },
    'Xoá khỏi nhóm': {'en': 'Remove from group', 'ko': '그룹에서 제거', 'zh_Hant': '從群組移除'},
    'Ẩn khỏi trang chủ': {'en': 'Hide from Home', 'ko': '홈에서 숨기기', 'zh_Hant': '從首頁隱藏'},
    'Đã ẩn "{name}" khỏi trang chủ': {
      'en': 'Hid "{name}" from Home',
      'ko': '"{name}"을(를) 홈에서 숨겼습니다',
      'zh_Hant': '已從首頁隱藏「{name}」'
    },
    'Hoàn tác': {'en': 'Undo', 'ko': '실행 취소', 'zh_Hant': '復原'},
    'Camera đã ẩn': {'en': 'Hidden cameras', 'ko': '숨긴 카메라', 'zh_Hant': '已隱藏的攝影機'},
    'Camera đã ẩn ({count})': {'en': 'Hidden cameras ({count})', 'ko': '숨긴 카메라 ({count})', 'zh_Hant': '已隱藏的攝影機（{count}）'},
    'Đã ẩn {count} camera · Nhấn để hiện lại': {
      'en': '{count} camera(s) hidden · Tap to show',
      'ko': '카메라 {count}대 숨김 · 탭하여 표시',
      'zh_Hant': '已隱藏 {count} 支攝影機 · 點擊以顯示'
    },
    'Hiện tất cả': {'en': 'Show all', 'ko': '모두 표시', 'zh_Hant': '全部顯示'},
    'Hiện lại': {'en': 'Show', 'ko': '표시', 'zh_Hant': '顯示'},
    'Ảnh gateway': {'en': 'Gateway photo', 'ko': '게이트웨이 사진', 'zh_Hant': '閘道器照片'},
    'Chọn từ thư viện': {'en': 'Choose from gallery', 'ko': '갤러리에서 선택', 'zh_Hant': '從相簿選擇'},
    'Dùng ảnh mặc định': {'en': 'Use default photo', 'ko': '기본 사진 사용', 'zh_Hant': '使用預設照片'},
    'Chưa cấp quyền Camera': {'en': 'Camera permission not granted', 'ko': '카메라 권한이 없습니다', 'zh_Hant': '未授予相機權限'},
    'Không đổi được ảnh: {e}': {'en': "Couldn't change photo: {e}", 'ko': '사진을 변경할 수 없습니다: {e}', 'zh_Hant': '無法更換照片：{e}'},
    'Giá gói': {'en': 'Package price', 'ko': '요금제 가격', 'zh_Hant': '方案價格'},
    'Truy cập hệ thống camera của bạn': {
      'en': 'Access your camera system',
      'ko': '카메라 시스템에 접속',
      'zh_Hant': '存取您的攝影機系統'
    },
    'Chỉnh sửa thông tin': {'en': 'Edit information', 'ko': '정보 수정', 'zh_Hant': '編輯資訊'},
    'Bạn có chắc muốn xoá "\${camera.name}"? Hành động này không thể hoàn tác.': {
      'en': 'Are you sure you want to delete "\${camera.name}"? This action cannot be undone.',
      'ko': '"\${camera.name}"을(를) 삭제하시겠습니까? 이 작업은 되돌릴 수 없습니다.',
      'zh_Hant': '確定要刪除「\${camera.name}」嗎？此動作無法復原。'
    },
    'Lịch sử hoạt động': {'en': 'Activity history', 'ko': '활동 기록', 'zh_Hant': '活動紀錄'},
    'Chi tiết gói': {'en': 'Package details', 'ko': '요금제 상세', 'zh_Hant': '方案詳情'},
    'Đang kết nối…': {'en': 'Connecting…', 'ko': '연결 중…', 'zh_Hant': '連線中…'},
    'đang hoạt động': {'en': 'online', 'ko': '온라인', 'zh_Hant': '在線'},
    'Tên nhóm camera': {'en': 'Camera group name', 'ko': '카메라 그룹 이름', 'zh_Hant': '攝影機群組名稱'},
    'Lỗi cập nhật thông tin': {'en': 'Error updating information', 'ko': '정보 업데이트 오류', 'zh_Hant': '更新資訊時發生錯誤'},
    'Kết nối quá hạn': {'en': 'Connection timeout', 'ko': '연결 시간 초과', 'zh_Hant': '連線逾時'},
    'Tài khoản và bảo mật': {'en': 'Account & Security', 'ko': '계정 및 보안', 'zh_Hant': '帳號與安全性'},
    'Mưa rào nhẹ': {'en': 'Light shower', 'ko': '약한 소나기', 'zh_Hant': '小陣雨'},
    'Camera sẽ không bị xóa nhưng sẽ không còn thuộc nhóm này.': {
      'en': 'The camera will not be deleted but will no longer belong to this group.',
      'ko': '카메라는 삭제되지 않지만 더 이상 이 그룹에 속하지 않습니다.',
      'zh_Hant': '攝影機不會被刪除，但將不再屬於此群組。'
    },
    'Dung lượng đang ở mức': {'en': 'Storage is at', 'ko': '저장 용량이 현재', 'zh_Hant': '儲存容量目前為'},
    'cân nhắc nâng cấp gói để tránh gián đoạn ghi hình.': {
      'en': 'consider upgrading your package to avoid recording interruptions.',
      'ko': '녹화 중단을 피하려면 요금제 업그레이드를 고려하세요.',
      'zh_Hant': '建議升級方案以避免錄影中斷。'
    },
    'Chọn camera vào nhóm': {'en': 'Select cameras for group', 'ko': '그룹에 추가할 카메라 선택', 'zh_Hant': '選擇要加入群組的攝影機'},
    'Camera theo nhóm': {'en': 'Cameras by group', 'ko': '그룹별 카메라', 'zh_Hant': '依群組顯示攝影機'},
    'Phát hiện chuyển động': {'en': 'Motion detected', 'ko': '움직임 감지', 'zh_Hant': '偵測到移動'},
    'Chưa có dữ liệu': {'en': 'No data available', 'ko': '데이터가 없습니다', 'zh_Hant': '尚無資料'},
    'Nguồn RTSP / URL': {'en': 'RTSP Source / URL', 'ko': 'RTSP 소스 / URL', 'zh_Hant': 'RTSP 來源 / URL'},
    'Thời lượng: \$dur giây': {'en': 'Duration: \$dur seconds', 'ko': '재생 시간: \$dur초', 'zh_Hant': '時長：\$dur 秒'},
    'Đổi tên': {'en': 'Rename', 'ko': '이름 변경', 'zh_Hant': '重新命名'},
    'Số điện thoại': {'en': 'Phone number', 'ko': '전화번호', 'zh_Hant': '電話號碼'},
    'Quên mật khẩu?': {'en': 'Forgot password?', 'ko': '비밀번호를 잊으셨나요?', 'zh_Hant': '忘記密碼？'},
    'Đang lưu...': {'en': 'Saving...', 'ko': '저장 중...', 'zh_Hant': '儲存中...'},
    'Người dùng': {'en': 'User', 'ko': '사용자', 'zh_Hant': '使用者'},
    'Lỗi': {'en': 'Error', 'ko': '오류', 'zh_Hant': '錯誤'},
    'Quản trị viên': {'en': 'Admin', 'ko': '관리자', 'zh_Hant': '管理員'},
    'Mưa rào': {'en': 'Showers', 'ko': '소나기', 'zh_Hant': '陣雨'},
    'Thứ Bảy': {'en': 'Saturday', 'ko': '토요일', 'zh_Hant': '星期六'},
    'Sương mù': {'en': 'Fog', 'ko': '안개', 'zh_Hant': '霧'},
    'Vui lòng nhập App': {'en': 'Please enter App', 'ko': 'App을 입력하세요', 'zh_Hant': '請輸入 App'},
    'Không có dữ liệu gói dịch vụ': {'en': 'No service package data', 'ko': '요금제 데이터가 없습니다', 'zh_Hant': '沒有服務方案資料'},
    'Xem bản ghi': {'en': 'View recording', 'ko': '녹화 보기', 'zh_Hant': '檢視錄影'},
    'Nhấn "+" để thêm nhóm mới': {
      'en': 'Tap "+" to add new group',
      'ko': '"+"를 눌러 새 그룹을 추가하세요',
      'zh_Hant': '點選「+」新增群組'
    },
    'Bật tự động ghi hình hoặc nhấn "Ghi hình"': {
      'en': 'Turn on auto recording or tap "Record"',
      'ko': '자동 녹화를 켜거나 "녹화"를 누르세요',
      'zh_Hant': '開啟自動錄影或點選「錄影」'
    },
    'Không tải được thông tin gói dịch vụ': {
      'en': 'Failed to load service package info',
      'ko': '요금제 정보를 불러오지 못했습니다',
      'zh_Hant': '無法載入服務方案資訊'
    },
    'Đang sử dụng': {'en': 'In use', 'ko': '사용 중', 'zh_Hant': '使用中'},
    'Bắt đầu: \${parts[0]}:\${parts[1]}:\${parts[2]}': {
      'en': 'Start: \${parts[0]}:\${parts[1]}:\${parts[2]}',
      'ko': '시작: \${parts[0]}:\${parts[1]}:\${parts[2]}',
      'zh_Hant': '開始：\${parts[0]}:\${parts[1]}:\${parts[2]}'
    },
    'Ghi hình (MP4)': {'en': 'Record (MP4)', 'ko': '녹화 (MP4)', 'zh_Hant': '錄影（MP4）'},
    'Ngắt': {'en': 'Disconnect', 'ko': '연결 끊기', 'zh_Hant': '中斷連線'},
    'Dông kèm mưa đá': {'en': 'Thunderstorm with hail', 'ko': '우박을 동반한 뇌우', 'zh_Hant': '雷雨夾冰雹'},
    'Nhập họ và tên': {'en': 'Enter full name', 'ko': '이름을 입력하세요', 'zh_Hant': '請輸入姓名'},
    'Nhóm / phòng': {'en': 'Group / Room', 'ko': '그룹 / 방', 'zh_Hant': '群組 / 房間'},
    'Thử lại': {'en': 'Retry', 'ko': '다시 시도', 'zh_Hant': '重試'},
    'Dung lượng Cloud': {'en': 'Cloud storage', 'ko': '클라우드 용량', 'zh_Hant': '雲端容量'},
    'ngắt kết nối': {'en': 'disconnect', 'ko': '연결 끊김', 'zh_Hant': '中斷連線'},
    'Bản ghi': {'en': 'Recordings', 'ko': '녹화', 'zh_Hant': '錄影'},
    'Vui lòng nhập tên nhóm': {'en': 'Please enter group name', 'ko': '그룹 이름을 입력하세요', 'zh_Hant': '請輸入群組名稱'},
    'Đã dùng': {'en': 'Used', 'ko': '사용량', 'zh_Hant': '已使用'},
    'Xóa file \${file.fileName} ngày \${file.date}? Không thể hoàn tác.': {
      'en': 'Delete file \${file.fileName} on \${file.date}? Cannot be undone.',
      'ko': '\${file.date}의 \${file.fileName} 파일을 삭제할까요? 되돌릴 수 없습니다.',
      'zh_Hant': '要刪除 \${file.date} 的檔案 \${file.fileName} 嗎？此動作無法復原。'
    },
    'Lịch sử': {'en': 'History', 'ko': '기록', 'zh_Hant': '紀錄'},
    'Tuyết': {'en': 'Snow', 'ko': '눈', 'zh_Hant': '雪'},
    'Vui lòng nhập mật khẩu hiện tại': {
      'en': 'Please enter current password',
      'ko': '현재 비밀번호를 입력하세요',
      'zh_Hant': '請輸入目前密碼'
    },
    'Đã xóa nhóm "\${group.name}"': {
      'en': 'Deleted group "\${group.name}"',
      'ko': '"\${group.name}" 그룹을 삭제했습니다',
      'zh_Hant': '已刪除群組「\${group.name}」'
    },
    'LƯU': {'en': 'SAVE', 'ko': '저장', 'zh_Hant': '儲存'},
    'Tải lại': {'en': 'Reload', 'ko': '새로고침', 'zh_Hant': '重新載入'},
    'Chưa có camera nào': {'en': 'No cameras yet', 'ko': '아직 카메라가 없습니다', 'zh_Hant': '尚無攝影機'},
    'Chưa có camera · Nhấn để thêm': {
      'en': 'No cameras · Tap to add',
      'ko': '카메라 없음 · 눌러서 추가',
      'zh_Hant': '尚無攝影機 · 點選以新增'
    },
    'Không tìm thấy khung hình camera': {
      'en': 'Camera frame not found',
      'ko': '카메라 프레임을 찾을 수 없습니다',
      'zh_Hant': '找不到攝影機畫面'
    },
    'Nhiều mây': {'en': 'Cloudy', 'ko': '흐림', 'zh_Hant': '多雲'},
    'Không có camera nào khả dụng.': {'en': 'No cameras available.', 'ko': '사용 가능한 카메라가 없습니다.', 'zh_Hant': '沒有可用的攝影機。'},
    'Phát lại tự động': {'en': 'Auto playback', 'ko': '자동 재생', 'zh_Hant': '自動播放'},
    'Hủy': {'en': 'Cancel', 'ko': '취소', 'zh_Hant': '取消'},
    'Phát bằng mạng di động': {'en': 'Play via cellular', 'ko': '모바일 데이터로 재생', 'zh_Hant': '使用行動網路播放'},
    'Mật khẩu xác nhận không khớp': {
      'en': 'Confirm password does not match',
      'ko': '확인 비밀번호가 일치하지 않습니다',
      'zh_Hant': '確認密碼不一致'
    },
    'Thêm nhóm camera': {'en': 'Add camera group', 'ko': '카메라 그룹 추가', 'zh_Hant': '新增攝影機群組'},
    'Không giới hạn camera': {'en': 'Unlimited cameras', 'ko': '카메라 무제한', 'zh_Hant': '攝影機數量不限'},
    'Cài đặt cảnh báo': {'en': 'Alert settings', 'ko': '알림 설정', 'zh_Hant': '警示設定'},
    'Tuyết dày': {'en': 'Heavy snow', 'ko': '폭설', 'zh_Hant': '大雪'},
    'Đăng nhập thất bại': {'en': 'Login failed', 'ko': '로그인 실패', 'zh_Hant': '登入失敗'},
    'Đăng nhập': {'en': 'Log in', 'ko': '로그인', 'zh_Hant': '登入'},
    'Mật khẩu': {'en': 'Password', 'ko': '비밀번호', 'zh_Hant': '密碼'},
    'Không thể kết nối máy chủ': {'en': 'Cannot connect to server', 'ko': '서버에 연결할 수 없습니다', 'zh_Hant': '無法連線到伺服器'},
    'Lỗi gửi yêu cầu nâng cấp (\${res.statusCode}): \${res.body}': {
      'en': 'Error sending upgrade request (\${res.statusCode}): \${res.body}',
      'ko': '업그레이드 요청 전송 오류 (\${res.statusCode}): \${res.body}',
      'zh_Hant': '傳送升級申請時發生錯誤（\${res.statusCode}）：\${res.body}'
    },
    'Chưa có hoạt động nào': {'en': 'No activity yet', 'ko': '아직 활동이 없습니다', 'zh_Hant': '尚無活動'},
    'Server không trả SDP answer': {
      'en': 'Server did not return SDP answer',
      'ko': '서버가 SDP answer를 반환하지 않았습니다',
      'zh_Hant': '伺服器未回傳 SDP answer'
    },
    'Đăng xuất': {'en': 'Log out', 'ko': '로그아웃', 'zh_Hant': '登出'},
    'Có mây': {'en': 'Partly cloudy', 'ko': '구름 조금', 'zh_Hant': '局部多雲'},
    'Khi bật lên, luôn cho phép phát lại trên mạng di động': {
      'en': 'When enabled, always allow playback over cellular networks',
      'ko': '켜면 모바일 네트워크에서도 항상 재생을 허용합니다',
      'zh_Hant': '開啟後，一律允許透過行動網路播放'
    },
    'Tỷ lệ Camera': {'en': 'Camera Ratio', 'ko': '카메라 비율', 'zh_Hant': '攝影機比例'},
    'Lỗi đổi mật khẩu': {'en': 'Error changing password', 'ko': '비밀번호 변경 오류', 'zh_Hant': '變更密碼時發生錯誤'},
    'Dung lượng sắp hết. Liên hệ quản trị viên ngay để tránh gián đoạn ghi hình.': {
      'en': 'Storage is running out. Contact admin immediately to avoid recording interruption.',
      'ko': '저장 용량이 곧 부족합니다. 녹화 중단을 피하려면 즉시 관리자에게 문의하세요.',
      'zh_Hant': '儲存空間即將用完。請立即聯絡管理員以免錄影中斷。'
    },
    'Xoá ảnh?': {'en': 'Delete photo?', 'ko': '사진을 삭제할까요?', 'zh_Hant': '要刪除照片嗎？'},
    'Thứ Ba': {'en': 'Tuesday', 'ko': '화요일', 'zh_Hant': '星期二'},
    'Đã đầy dung lượng — recording mới sẽ KHÔNG được lưu cho tới khi bạn xoá bớt hoặc được tăng dung lượng. Dữ liệu cũ vẫn an toàn, không bị xoá.':
        {
      'en':
          'Storage is full — new recordings will NOT be saved until you delete some or upgrade storage. Old data is safe and will not be deleted.',
      'ko': '저장 용량이 가득 찼습니다 — 일부를 삭제하거나 용량을 늘릴 때까지 새 녹화는 저장되지 않습니다. 기존 데이터는 안전하며 삭제되지 않습니다.',
      'zh_Hant': '儲存空間已滿 — 在您刪除部分資料或擴充容量之前，新錄影將「不會」被儲存。舊資料仍然安全，不會被刪除。'
    },
    'Nhóm "\${group.name}" có \${cameras.length} camera. ': {
      'en': 'Group "\${group.name}" has \${cameras.length} cameras. ',
      'ko': '"\${group.name}" 그룹에 카메라가 \${cameras.length}대 있습니다. ',
      'zh_Hant': '群組「\${group.name}」有 \${cameras.length} 台攝影機。'
    },
    'Nhóm: \${group.name}': {'en': 'Group: \${group.name}', 'ko': '그룹: \${group.name}', 'zh_Hant': '群組：\${group.name}'},
    'Trạng thái': {'en': 'Status', 'ko': '상태', 'zh_Hant': '狀態'},
    'Thông tin người dùng': {'en': 'User information', 'ko': '사용자 정보', 'zh_Hant': '使用者資訊'},
    'Đang xử lý cắt video...': {'en': 'Processing video clip...', 'ko': '영상 클립 처리 중...', 'zh_Hant': '正在處理影片剪輯...'},
    'Xác nhận xóa': {'en': 'Confirm delete', 'ko': '삭제 확인', 'zh_Hant': '確認刪除'},
    'GB lưu trữ': {'en': 'GB storage', 'ko': 'GB 저장 공간', 'zh_Hant': 'GB 儲存空間'},
    'Gần đầy': {'en': 'Almost full', 'ko': '거의 참', 'zh_Hant': '接近滿載'},
    'Ảnh vừa chụp': {'en': 'Recently captured photo', 'ko': '방금 촬영한 사진', 'zh_Hant': '剛拍攝的照片'},
    'Ngôn ngữ': {'en': 'Language', 'ko': '언어', 'zh_Hant': '語言'},
    'Dung lượng lưu trữ': {'en': 'Storage capacity', 'ko': '저장 용량', 'zh_Hant': '儲存容量'},
    'Trạng thái dung lượng': {'en': 'Storage status', 'ko': '저장 용량 상태', 'zh_Hant': '容量狀態'},
    'Sửa Camera': {'en': 'Edit Camera', 'ko': '카메라 수정', 'zh_Hant': '編輯攝影機'},
    'Giữ để nói': {'en': 'Hold to talk', 'ko': '길게 눌러 말하기', 'zh_Hant': '按住說話'},
    '\${buf}đ\$suffix': {'en': '\${buf}d\$suffix', 'ko': '\${buf}đ\$suffix', 'zh_Hant': '\${buf}đ\$suffix'},
    '\${buf}đ': {'en': '\${buf}d', 'ko': '\${buf}đ', 'zh_Hant': '\${buf}đ'},
    'Lỗi tải video': {'en': 'Error loading video', 'ko': '영상 불러오기 오류', 'zh_Hant': '載入影片時發生錯誤'},
    'Quản lý nhóm': {'en': 'Manage groups', 'ko': '그룹 관리', 'zh_Hant': '管理群組'},
    'Nâng cấp gói dịch vụ': {'en': 'Upgrade service package', 'ko': '요금제 업그레이드', 'zh_Hant': '升級服務方案'},
    'Trống': {'en': 'Empty', 'ko': '비어 있음', 'zh_Hant': '空'},
    'Thông báo': {'en': 'Notifications', 'ko': '알림', 'zh_Hant': '通知'},
    'Bắt đầu ghi hình...': {'en': 'Starting recording...', 'ko': '녹화 시작 중...', 'zh_Hant': '正在開始錄影...'},
    'Thêm Camera': {'en': 'Add Camera', 'ko': '카메라 추가', 'zh_Hant': '新增攝影機'},
    '/năm': {'en': '/year', 'ko': '/년', 'zh_Hant': '/年'},
    'Xoá nhóm': {'en': 'Delete group', 'ko': '그룹 삭제', 'zh_Hant': '刪除群組'},
    'Giải mã phần cứng': {'en': 'Hardware decoding', 'ko': '하드웨어 디코딩', 'zh_Hant': '硬體解碼'},
    'Chưa phân nhóm': {'en': 'Ungrouped', 'ko': '그룹 없음', 'zh_Hant': '未分組'},
    'Tổng nhóm': {'en': 'Total groups', 'ko': '전체 그룹', 'zh_Hant': '群組總數'},
    'Huỷ': {'en': 'Cancel', 'ko': '취소', 'zh_Hant': '取消'},
    'Trời quang': {'en': 'Clear sky', 'ko': '맑음', 'zh_Hant': '晴朗'},
    'Thêm camera': {'en': 'Add camera', 'ko': '카메라 추가', 'zh_Hant': '新增攝影機'},
    'Tốc độ phát': {'en': 'Playback speed', 'ko': '재생 속도', 'zh_Hant': '播放速度'},
    'Thứ Sáu': {'en': 'Friday', 'ko': '금요일', 'zh_Hant': '星期五'},
    'Lỗi kết nối': {'en': 'Connection error', 'ko': '연결 오류', 'zh_Hant': '連線錯誤'},
    'sẽ bị xoá theo.': {'en': 'will also be deleted.', 'ko': '도 함께 삭제됩니다.', 'zh_Hant': '也會一併刪除。'},
    'Ngoại hình': {'en': 'Appearance', 'ko': '화면 스타일', 'zh_Hant': '外觀'},
    'Ít mây': {'en': 'Few clouds', 'ko': '구름 약간', 'zh_Hant': '少雲'},
    'Truy cập nhanh': {'en': 'Quick access', 'ko': '빠른 접근', 'zh_Hant': '快速存取'},
    'Ảnh chụp từ hệ thống AQ-VISION': {
      'en': 'Photo captured from AQ-VISION system',
      'ko': 'AQ-VISION 시스템에서 촬영한 사진',
      'zh_Hant': '從 AQ-VISION 系統拍攝的照片'
    },
    'Ảnh này sẽ bị xoá vĩnh viễn khỏi thiết bị.': {
      'en': 'This photo will be permanently deleted from the device.',
      'ko': '이 사진은 기기에서 영구적으로 삭제됩니다.',
      'zh_Hant': '此照片將從裝置中永久刪除。'
    },
    'Mưa phùn nhẹ': {'en': 'Light drizzle', 'ko': '약한 이슬비', 'zh_Hant': '輕微毛毛雨'},
    'Đánh dấu đã đọc': {'en': 'Mark as read', 'ko': '읽음으로 표시', 'zh_Hant': '標示為已讀'},
    'Bắt đầu ghi hình': {'en': 'Start recording', 'ko': '녹화 시작', 'zh_Hant': '開始錄影'},
    'Nhóm (Có thể chọn nhiều)': {'en': 'Groups (Select multiple)', 'ko': '그룹 (여러 개 선택 가능)', 'zh_Hant': '群組（可複選）'},
    'Xóa nhóm': {'en': 'Delete group', 'ko': '그룹 삭제', 'zh_Hant': '刪除群組'},
    'Đổi tên nhóm': {'en': 'Rename group', 'ko': '그룹 이름 변경', 'zh_Hant': '重新命名群組'},
    'Đã dừng ghi hình': {'en': 'Stopped recording', 'ko': '녹화를 중지했습니다', 'zh_Hant': '已停止錄影'},
    'Thông tin thiết bị': {'en': 'Device info', 'ko': '기기 정보', 'zh_Hant': '裝置資訊'},
    'Dông': {'en': 'Thunderstorm', 'ko': '뇌우', 'zh_Hant': '雷雨'},
    'Sửa thông tin camera': {'en': 'Edit camera info', 'ko': '카메라 정보 수정', 'zh_Hant': '編輯攝影機資訊'},
    'Xoá': {'en': 'Delete', 'ko': '삭제', 'zh_Hant': '刪除'},
    'Dung lượng sắp đầy. Xoá bớt recording cũ hoặc liên hệ quản trị viên để tăng dung lượng.': {
      'en': 'Storage is almost full. Delete old recordings or contact admin to increase storage.',
      'ko': '저장 용량이 거의 찼습니다. 오래된 녹화를 삭제하거나 관리자에게 용량 증설을 문의하세요.',
      'zh_Hant': '儲存空間即將滿載。請刪除舊錄影或聯絡管理員增加容量。'
    },
    'Thứ Tư': {'en': 'Wednesday', 'ko': '수요일', 'zh_Hant': '星期三'},
    'Mật khẩu hiện tại': {'en': 'Current password', 'ko': '현재 비밀번호', 'zh_Hant': '目前密碼'},
    'Bật định vị để xem thời tiết': {
      'en': 'Enable location to see weather',
      'ko': '날씨를 보려면 위치를 켜세요',
      'zh_Hant': '開啟定位以查看天氣'
    },
    'Chu kỳ thanh toán': {'en': 'Billing cycle', 'ko': '결제 주기', 'zh_Hant': '計費週期'},
    'camera · chưa xếp vào nhóm nào': {
      'en': 'camera(s) · not assigned to any group',
      'ko': '대 · 그룹에 속하지 않음',
      'zh_Hant': '台 · 尚未分組'
    },
    'Đã đầy': {'en': 'Full', 'ko': '가득 참', 'zh_Hant': '已滿'},
    'Chọn Gateway': {'en': 'Choose gateway', 'ko': '게이트웨이 선택', 'zh_Hant': '選擇 Gateway'},
    'Công ty': {'en': 'Company', 'ko': '회사', 'zh_Hant': '公司'},
    'Link Google Maps': {'en': 'Google Maps link', 'ko': 'Google 지도 링크', 'zh_Hant': 'Google 地圖連結'},
    'VD: Cổng trước, tầng 1': {'en': 'e.g. Front gate, 1st floor', 'ko': '예: 정문, 1층', 'zh_Hant': '例如：前門、1 樓'},
    'Link không hợp lệ (phải bắt đầu bằng https://)': {
      'en': 'Invalid link (must start with https://)',
      'ko': '잘못된 링크입니다 (https://로 시작해야 함)',
      'zh_Hant': '連結無效（必須以 https:// 開頭）'
    },
    'Không mở được link bản đồ': {'en': 'Could not open the map link', 'ko': '지도 링크를 열 수 없습니다', 'zh_Hant': '無法開啟地圖連結'},
    'Xem trên bản đồ': {'en': 'View on map', 'ko': '지도에서 보기', 'zh_Hant': '在地圖上查看'},
    'Thêm vị trí': {'en': 'Add location', 'ko': '위치 추가', 'zh_Hant': '新增位置'},
    'Thêm Gateway': {'en': 'Add gateway', 'ko': '게이트웨이 추가', 'zh_Hant': '新增 Gateway'},
    'Không kết nối được gateway': {
      'en': 'Could not connect to gateway',
      'ko': '게이트웨이에 연결할 수 없습니다',
      'zh_Hant': '無法連線到 Gateway'
    },
    'Chưa có gateway nào. Hãy thêm gateway trước.': {
      'en': 'No gateways yet. Add a gateway first.',
      'ko': '아직 게이트웨이가 없습니다. 먼저 게이트웨이를 추가하세요.',
      'zh_Hant': '尚無 Gateway。請先新增 Gateway。'
    },
    'Không tải được bài viết': {'en': 'Could not load article', 'ko': '게시물을 불러올 수 없습니다', 'zh_Hant': '無法載入文章'},
    'lượt xem': {'en': 'views', 'ko': '조회수', 'zh_Hant': '次瀏覽'},
    // --- i18n sweep (setup, gateway, recording, groups) ---
    'Chụp ảnh': {'en': 'Capture', 'ko': '캡처', 'zh_Hant': '拍照'},
    'Xong': {'en': 'Done', 'ko': '완료', 'zh_Hant': '完成'},
    'Không tìm thấy thiết bị {name}': {
      'en': 'Device {name} not found',
      'ko': '{name} 기기를 찾을 수 없습니다',
      'zh_Hant': '找不到裝置 {name}'
    },
    'Gateway chưa sẵn sàng / khác mạng': {
      'en': 'Gateway not ready / on a different network',
      'ko': '게이트웨이가 준비되지 않았거나 다른 네트워크에 있습니다',
      'zh_Hant': 'Gateway 尚未就緒 / 位於不同網路'
    },
    'Lỗi thêm nhóm': {'en': 'Failed to add group', 'ko': '그룹 추가 오류', 'zh_Hant': '新增群組時發生錯誤'},
    'Lỗi thêm camera': {'en': 'Failed to add camera', 'ko': '카메라 추가 오류', 'zh_Hant': '新增攝影機時發生錯誤'},
    'Lỗi cập nhật camera': {'en': 'Failed to update camera', 'ko': '카메라 업데이트 오류', 'zh_Hant': '更新攝影機時發生錯誤'},
    'Lỗi xóa camera': {'en': 'Failed to delete camera', 'ko': '카메라 삭제 오류', 'zh_Hant': '刪除攝影機時發生錯誤'},
    'Lỗi khi kết nối lại camera': {'en': 'Failed to reconnect camera', 'ko': '카메라 재연결 오류', 'zh_Hant': '重新連線攝影機時發生錯誤'},
    'Lỗi khi ngắt kết nối camera': {
      'en': 'Failed to disconnect camera',
      'ko': '카메라 연결 해제 오류',
      'zh_Hant': '中斷攝影機連線時發生錯誤'
    },
    'Không tìm thấy gateway trong mạng. Kiểm tra WiFi điện thoại, hoặc nhấn nhanh nút trên gateway rồi cài lại.': {
      'en':
          'Gateway not found on the network. Check your phone\'s WiFi, or briefly press the gateway button and set it up again.',
      'ko': '네트워크에서 게이트웨이를 찾을 수 없습니다. 휴대폰 WiFi를 확인하거나 게이트웨이 버튼을 짧게 누른 후 다시 설정하세요.',
      'zh_Hant': '在網路中找不到 Gateway。請檢查手機 WiFi，或短按 Gateway 上的按鈕後重新設定。'
    },
    'Lỗi kết nối gateway: {e}': {
      'en': 'Gateway connection error: {e}',
      'ko': '게이트웨이 연결 오류: {e}',
      'zh_Hant': 'Gateway 連線錯誤：{e}'
    },
    '{n} phút trước': {'en': '{n} min ago', 'ko': '{n}분 전', 'zh_Hant': '{n} 分鐘前'},
    '{n} giờ trước': {'en': '{n} h ago', 'ko': '{n}시간 전', 'zh_Hant': '{n} 小時前'},
    '{n} ngày trước': {'en': '{n} days ago', 'ko': '{n}일 전', 'zh_Hant': '{n} 天前'},
    'Bắt đầu: {t}': {'en': 'Start: {t}', 'ko': '시작: {t}', 'zh_Hant': '開始：{t}'},
    'Thời lượng: {n} giây': {'en': 'Duration: {n} s', 'ko': '재생 시간: {n}초', 'zh_Hant': '時長：{n} 秒'},
    'Phiên đăng nhập hết hạn. Hãy đăng nhập lại.': {
      'en': 'Session expired. Please log in again.',
      'ko': '로그인 세션이 만료되었습니다. 다시 로그인하세요.',
      'zh_Hant': '登入工作階段已過期，請重新登入。'
    },
    'Máy chủ ghi hình trả về lỗi ({code})': {
      'en': 'Recording server returned an error ({code})',
      'ko': '녹화 서버에서 오류를 반환했습니다 ({code})',
      'zh_Hant': '錄影伺服器回傳錯誤（{code}）'
    },
    'Lỗi ghi hình ({code})': {'en': 'Recording error ({code})', 'ko': '녹화 오류 ({code})', 'zh_Hant': '錄影錯誤（{code}）'},
    'Lỗi gửi yêu cầu liên hệ ({code}): {body}': {
      'en': 'Failed to send contact request ({code}): {body}',
      'ko': '문의 요청 전송 오류 ({code}): {body}',
      'zh_Hant': '傳送聯絡申請時發生錯誤（{code}）：{body}'
    },
    'Yêu cầu liên hệ đã được ghi nhận, quản lý sẽ liên hệ với bạn sớm': {
      'en': 'Your request has been received, a manager will contact you soon',
      'ko': '문의 요청이 접수되었습니다. 관리자가 곧 연락드릴 예정입니다',
      'zh_Hant': '已收到您的聯絡申請，管理員將盡快與您聯繫'
    },
    'Camera đang offline, không thể chụp ảnh': {
      'en': 'Camera is offline, cannot take a snapshot',
      'ko': '카메라가 오프라인이라 사진을 찍을 수 없습니다',
      'zh_Hant': '攝影機離線，無法拍照'
    },
    'Đã lưu ảnh chụp màn hình': {'en': 'Screenshot saved', 'ko': '스크린샷을 저장했습니다', 'zh_Hant': '截圖已儲存'},
    'Lỗi chụp ảnh: {e}': {'en': 'Snapshot error: {e}', 'ko': '캡처 오류: {e}', 'zh_Hant': '拍照錯誤：{e}'},
    'Bạn có chắc muốn xoá "{name}"? Hành động này không thể hoàn tác.': {
      'en': 'Are you sure you want to delete "{name}"? This cannot be undone.',
      'ko': '"{name}"을(를) 삭제하시겠습니까? 이 작업은 되돌릴 수 없습니다.',
      'zh_Hant': '確定要刪除「{name}」嗎？此動作無法復原。'
    },
    'Đã thêm nhóm "{name}"': {'en': 'Added group "{name}"', 'ko': '"{name}" 그룹을 추가했습니다', 'zh_Hant': '已新增群組「{name}」'},
    'Lỗi: {e}': {'en': 'Error: {e}', 'ko': '오류: {e}', 'zh_Hant': '錯誤：{e}'},
    'Đã đổi tên thành "{name}"': {
      'en': 'Renamed to "{name}"',
      'ko': '"{name}"(으)로 이름을 변경했습니다',
      'zh_Hant': '已重新命名為「{name}」'
    },
    'Nhóm "{name}" có {count} camera. ': {
      'en': 'Group "{name}" has {count} camera(s). ',
      'ko': '"{name}" 그룹에 카메라가 {count}대 있습니다. ',
      'zh_Hant': '群組「{name}」有 {count} 台攝影機。'
    },
    'Xóa nhóm "{name}"?': {'en': 'Delete group "{name}"?', 'ko': '"{name}" 그룹을 삭제할까요?', 'zh_Hant': '要刪除群組「{name}」嗎？'},
    'Đã xóa nhóm "{name}"': {'en': 'Deleted group "{name}"', 'ko': '"{name}" 그룹을 삭제했습니다', 'zh_Hant': '已刪除群組「{name}」'},
    'Nhóm: {name}': {'en': 'Group: {name}', 'ko': '그룹: {name}', 'zh_Hant': '群組：{name}'},
    'Nhắn thêm cho quản lý (không bắt buộc)...': {
      'en': 'Message to the manager (optional)...',
      'ko': '관리자에게 남길 메시지 (선택 사항)...',
      'zh_Hant': '給管理員的留言（選填）...'
    },
    'Gửi yêu cầu': {'en': 'Send request', 'ko': '요청 보내기', 'zh_Hant': '送出申請'},
    'Yêu cầu đã gửi': {'en': 'Request sent', 'ko': '요청을 보냈습니다', 'zh_Hant': '申請已送出'},
    'Liên hệ quản lý': {'en': 'Contact manager', 'ko': '관리자 문의', 'zh_Hant': '聯絡管理員'},
    'Xóa file {file} ngày {date}? Không thể hoàn tác.': {
      'en': 'Delete file {file} from {date}? This cannot be undone.',
      'ko': '{date}의 {file} 파일을 삭제할까요? 되돌릴 수 없습니다.',
      'zh_Hant': '要刪除 {date} 的檔案 {file} 嗎？此動作無法復原。'
    },
    'Không thể phát video: {e}': {'en': 'Cannot play video: {e}', 'ko': '영상을 재생할 수 없습니다: {e}', 'zh_Hant': '無法播放影片：{e}'},
    'Hệ thống sẽ tạo 1 đoạn video dài 30 giây bắt đầu từ giây thứ {pos} của bản ghi hiện tại. Tiếp tục?': {
      'en': 'A 30-second clip will be created starting at second {pos} of the current recording. Continue?',
      'ko': '현재 녹화의 {pos}초부터 30초 길이의 클립을 생성합니다. 계속할까요?',
      'zh_Hant': '將從目前錄影的第 {pos} 秒開始建立 30 秒的片段。要繼續嗎？'
    },
    'Cắt thành công! Đã lưu tại: {url}': {
      'en': 'Clip created! Saved at: {url}',
      'ko': '클립 생성 완료! 저장 위치: {url}',
      'zh_Hant': '片段建立成功！已儲存於：{url}'
    },
    'Thẻ nhớ': {'en': 'Memory card', 'ko': '메모리 카드', 'zh_Hant': '記憶卡'},
    'Thêm thiết bị mới': {'en': 'Add new device', 'ko': '새 기기 추가', 'zh_Hant': '新增裝置'},
    'Quét mã QR để cài đặt Gateway Eyerus': {
      'en': 'Scan the QR code to set up an Eyerus Gateway',
      'ko': 'QR 코드를 스캔하여 Eyerus 게이트웨이를 설정하세요',
      'zh_Hant': '掃描 QR 碼以設定 Eyerus Gateway'
    },
    'Quét camera': {'en': 'Scan cameras', 'ko': '카메라 스캔', 'zh_Hant': '掃描攝影機'},
    'Tìm và thêm camera qua Gateway trong mạng': {
      'en': 'Find and add cameras through the Gateway on your network',
      'ko': '네트워크의 게이트웨이를 통해 카메라를 찾아 추가합니다',
      'zh_Hant': '透過網路中的 Gateway 尋找並新增攝影機'
    },
    'Chưa có dữ liệu gói dịch vụ': {'en': 'No service plan data yet', 'ko': '아직 요금제 데이터가 없습니다', 'zh_Hant': '尚無服務方案資料'},
    'Thời hạn lưu bản ghi': {'en': 'Recording retention', 'ko': '녹화 보관 기간', 'zh_Hant': '錄影保存期限'},
    'Không giới hạn*': {'en': 'Unlimited*', 'ko': '무제한*', 'zh_Hant': '無限制*'},
    'Mô tả': {'en': 'Description', 'ko': '설명', 'zh_Hant': '說明'},
    '* Lưu đến khi đầy dung lượng, cần xoá bớt bản ghi cũ hoặc nâng cấp gói để ghi tiếp.': {
      'en': '* Kept until storage is full; delete old recordings or upgrade your plan to keep recording.',
      'ko': '* 저장 공간이 찰 때까지 보관됩니다. 계속 녹화하려면 오래된 녹화를 삭제하거나 요금제를 업그레이드하세요.',
      'zh_Hant': '* 保存至儲存空間滿載為止；需刪除舊錄影或升級方案才能繼續錄影。'
    },
    'Trải nghiệm': {'en': 'Experience', 'ko': '사용 경험', 'zh_Hant': '使用體驗'},
    'Nhập mã thủ công': {'en': 'Enter code manually', 'ko': '코드 직접 입력', 'zh_Hant': '手動輸入代碼'},
    'Thiết bị: {name}': {'en': 'Device: {name}', 'ko': '기기: {name}', 'zh_Hant': '裝置：{name}'},
    'Mã định danh (Device ID)': {'en': 'Device ID', 'ko': '기기 ID (Device ID)', 'zh_Hant': '裝置 ID（Device ID）'},
    'Mã bảo mật (PIN)': {'en': 'Security code (PIN)', 'ko': '보안 코드 (PIN)', 'zh_Hant': '安全碼（PIN）'},
    'Vui lòng nhập đầy đủ mã!': {'en': 'Please enter all codes!', 'ko': '코드를 모두 입력하세요!', 'zh_Hant': '請輸入完整代碼！'},
    'Xác nhận': {'en': 'Confirm', 'ko': '확인', 'zh_Hant': '確認'},
    'Quét Bluetooth': {'en': 'Bluetooth scan', 'ko': '블루투스 스캔', 'zh_Hant': '藍牙掃描'},
    'Đang tìm kiếm Gateway lân cận...': {
      'en': 'Searching for nearby Gateways...',
      'ko': '주변 게이트웨이를 검색하는 중...',
      'zh_Hant': '正在搜尋附近的 Gateway...'
    },
    'Không tìm thấy thiết bị nào.': {'en': 'No devices found.', 'ko': '기기를 찾을 수 없습니다.', 'zh_Hant': '找不到任何裝置。'},
    'Không kết nối được gateway.': {
      'en': 'Could not connect to the gateway.',
      'ko': '게이트웨이에 연결할 수 없습니다.',
      'zh_Hant': '無法連線到 Gateway。'
    },
    'Không đọc được danh sách camera: {e}': {
      'en': 'Could not read camera list: {e}',
      'ko': '카메라 목록을 읽을 수 없습니다: {e}',
      'zh_Hant': '無法讀取攝影機清單：{e}'
    },
    'Quét lỗi: {e}': {'en': 'Scan error: {e}', 'ko': '스캔 오류: {e}', 'zh_Hant': '掃描錯誤：{e}'},
    'Không tìm thấy camera nào trong mạng.': {
      'en': 'No cameras found on the network.',
      'ko': '네트워크에서 카메라를 찾을 수 없습니다.',
      'zh_Hant': '在網路中找不到任何攝影機。'
    },
    'Camera tìm thấy trong mạng': {
      'en': 'Cameras found on the network',
      'ko': '네트워크에서 찾은 카메라',
      'zh_Hant': '在網路中找到的攝影機'
    },
    'Sửa camera': {'en': 'Edit camera', 'ko': '카메라 수정', 'zh_Hant': '編輯攝影機'},
    'Mount (cam1, cam2… chỉ A-Z a-z 0-9 _ -)': {
      'en': 'Mount (cam1, cam2… only A-Z a-z 0-9 _ -)',
      'ko': 'Mount (cam1, cam2… A-Z a-z 0-9 _ - 만 사용)',
      'zh_Hant': 'Mount（cam1、cam2… 僅限 A-Z a-z 0-9 _ -）'
    },
    'Địa chỉ IP camera': {'en': 'Camera IP address', 'ko': '카메라 IP 주소', 'zh_Hant': '攝影機 IP 位址'},
    'Cổng ONVIF (Tapo: 2020)': {
      'en': 'ONVIF port (Tapo: 2020)',
      'ko': 'ONVIF 포트 (Tapo: 2020)',
      'zh_Hant': 'ONVIF 連接埠（Tapo：2020）'
    },
    'Tài khoản camera': {'en': 'Camera username', 'ko': '카메라 계정', 'zh_Hant': '攝影機帳號'},
    'Mật khẩu camera': {'en': 'Camera password', 'ko': '카메라 비밀번호', 'zh_Hant': '攝影機密碼'},
    'Mật khẩu (bỏ trống = giữ cũ)': {
      'en': 'Password (leave empty = keep current)',
      'ko': '비밀번호 (비워 두면 기존 유지)',
      'zh_Hant': '密碼（留空 = 保留原密碼）'
    },
    'Bật camera': {'en': 'Enable camera', 'ko': '카메라 켜기', 'zh_Hant': '啟用攝影機'},
    'Kèm âm thanh': {'en': 'Include audio', 'ko': '오디오 포함', 'zh_Hant': '包含音訊'},
    'Tắt để giảm trễ luồng': {
      'en': 'Turn off to reduce stream latency',
      'ko': '스트림 지연을 줄이려면 끄세요',
      'zh_Hant': '關閉可降低串流延遲'
    },
    'Mount không hợp lệ (chỉ A-Z a-z 0-9 _ -)': {
      'en': 'Invalid mount (only A-Z a-z 0-9 _ -)',
      'ko': '잘못된 Mount (A-Z a-z 0-9 _ - 만 사용)',
      'zh_Hant': 'Mount 無效（僅限 A-Z a-z 0-9 _ -）'
    },
    'Nhập địa chỉ IP camera': {
      'en': 'Enter the camera IP address',
      'ko': '카메라 IP 주소를 입력하세요',
      'zh_Hant': '請輸入攝影機 IP 位址'
    },
    'Chưa có camera nào để lưu.': {'en': 'No cameras to save yet.', 'ko': '저장할 카메라가 없습니다.', 'zh_Hant': '尚無可儲存的攝影機。'},
    'Camera "{mount}" chưa có mật khẩu.': {
      'en': 'Camera "{mount}" has no password.',
      'ko': '"{mount}" 카메라에 비밀번호가 없습니다.',
      'zh_Hant': '攝影機「{mount}」尚未設定密碼。'
    },
    'Đã lưu, đang áp dụng cấu hình…': {
      'en': 'Saved, applying configuration…',
      'ko': '저장했습니다. 설정 적용 중…',
      'zh_Hant': '已儲存，正在套用設定…'
    },
    'Hoàn tất.': {'en': 'Done.', 'ko': '완료.', 'zh_Hant': '完成。'},
    'Lưu lỗi: {e}': {'en': 'Save error: {e}', 'ko': '저장 오류: {e}', 'zh_Hant': '儲存錯誤：{e}'},
    'Đang áp dụng…': {'en': 'Applying…', 'ko': '적용 중…', 'zh_Hant': '套用中…'},
    'Lưu & áp dụng ({n} camera)': {
      'en': 'Save & apply ({n} cameras)',
      'ko': '저장 및 적용 (카메라 {n}대)',
      'zh_Hant': '儲存並套用（{n} 台攝影機）'
    },
    'Đang kết nối gateway…': {'en': 'Connecting to gateway…', 'ko': '게이트웨이에 연결 중…', 'zh_Hant': '正在連線到 Gateway…'},
    'Đang quét…': {'en': 'Scanning…', 'ko': '스캔 중…', 'zh_Hant': '掃描中…'},
    'Quét camera trong mạng': {'en': 'Scan cameras on network', 'ko': '네트워크에서 카메라 스캔', 'zh_Hant': '掃描網路中的攝影機'},
    'Thêm thủ công': {'en': 'Add manually', 'ko': '직접 추가', 'zh_Hant': '手動新增'},
    'Chưa có camera. Bấm "Quét camera trong mạng".': {
      'en': 'No cameras yet. Tap "Scan cameras on network".',
      'ko': '아직 카메라가 없습니다. "네트워크에서 카메라 스캔"을 누르세요.',
      'zh_Hant': '尚無攝影機。請點選「掃描網路中的攝影機」。'
    },
    'Tắt': {'en': 'Off', 'ko': '꺼짐', 'zh_Hant': '關閉'},
    'Lỗi tài khoản/cổng': {'en': 'Wrong account/port', 'ko': '계정/포트 오류', 'zh_Hant': '帳號 / 連接埠錯誤'},
    'Mới thêm': {'en': 'New', 'ko': '새로 추가', 'zh_Hant': '新增'},
    'Đang tìm kiếm thiết bị...': {'en': 'Searching for devices...', 'ko': '기기를 검색하는 중...', 'zh_Hant': '正在搜尋裝置...'},
    'Lỗi BLE: {e}': {'en': 'BLE error: {e}', 'ko': 'BLE 오류: {e}', 'zh_Hant': 'BLE 錯誤：{e}'},
    'Đã kết nối. Đang lấy thông tin...': {
      'en': 'Connected. Fetching info...',
      'ko': '연결되었습니다. 정보를 가져오는 중...',
      'zh_Hant': '已連線，正在取得資訊...'
    },
    'Lỗi kết nối: {e}': {'en': 'Connection error: {e}', 'ko': '연결 오류: {e}', 'zh_Hant': '連線錯誤：{e}'},
    'Vui lòng nhấn nút trên Gateway để xác thực!': {
      'en': 'Please press the button on the Gateway to authenticate!',
      'ko': '인증하려면 게이트웨이의 버튼을 누르세요!',
      'zh_Hant': '請按下 Gateway 上的按鈕以進行驗證！'
    },
    'Xác thực thành công. Đang quét WiFi...': {
      'en': 'Authenticated. Scanning WiFi...',
      'ko': '인증되었습니다. WiFi 스캔 중...',
      'zh_Hant': '驗證成功，正在掃描 WiFi...'
    },
    'Vui lòng chọn WiFi để Gateway kết nối': {
      'en': 'Please choose a WiFi network for the Gateway',
      'ko': '게이트웨이가 연결할 WiFi를 선택하세요',
      'zh_Hant': '請選擇 Gateway 要連線的 WiFi'
    },
    'Lỗi quét WiFi: {e}': {'en': 'WiFi scan error: {e}', 'ko': 'WiFi 스캔 오류: {e}', 'zh_Hant': 'WiFi 掃描錯誤：{e}'},
    'Đang kết nối mạng...': {'en': 'Connecting to network...', 'ko': '네트워크에 연결 중...', 'zh_Hant': '正在連線網路...'},
    'Kết nối mạng thành công!': {'en': 'Network connected!', 'ko': '네트워크 연결 성공!', 'zh_Hant': '網路連線成功！'},
    'Đang gửi thông tin WiFi...': {
      'en': 'Sending WiFi details...',
      'ko': 'WiFi 정보를 보내는 중...',
      'zh_Hant': '正在傳送 WiFi 資訊...'
    },
    'Gateway đã vào mạng (URL: {url}). Đang kết nối gateway...': {
      'en': 'Gateway is online (URL: {url}). Connecting to gateway...',
      'ko': '게이트웨이가 네트워크에 연결되었습니다 (URL: {url}). 게이트웨이에 연결 중...',
      'zh_Hant': 'Gateway 已連上網路（URL：{url}），正在連線到 Gateway...'
    },
    'Đã kết nối gateway. Đang đăng ký lên Cloud...': {
      'en': 'Gateway connected. Registering with the Cloud...',
      'ko': '게이트웨이에 연결되었습니다. 클라우드에 등록하는 중...',
      'zh_Hant': '已連線到 Gateway，正在向雲端註冊...'
    },
    'Thiết lập thành công!': {'en': 'Setup complete!', 'ko': '설정 완료!', 'zh_Hant': '設定完成！'},
    'Thành công': {'en': 'Success', 'ko': '성공', 'zh_Hant': '成功'},
    'Gateway đã được cài đặt và kết nối mạng thành công.': {
      'en': 'The Gateway has been set up and connected to the network.',
      'ko': '게이트웨이 설정 및 네트워크 연결이 완료되었습니다.',
      'zh_Hant': 'Gateway 已完成設定並成功連上網路。'
    },
    'Đóng': {'en': 'Close', 'ko': '닫기', 'zh_Hant': '關閉'},
    'Lỗi gửi WiFi: {e}': {'en': 'Error sending WiFi: {e}', 'ko': 'WiFi 전송 오류: {e}', 'zh_Hant': '傳送 WiFi 時發生錯誤：{e}'},
    'Cài đặt Gateway': {'en': 'Gateway setup', 'ko': '게이트웨이 설정', 'zh_Hant': 'Gateway 設定'},
    'Thiết lập Gateway mới': {'en': 'Set up a new Gateway', 'ko': '새 게이트웨이 설정', 'zh_Hant': '設定新的 Gateway'},
    'Chọn mạng WiFi': {'en': 'Choose WiFi network', 'ko': 'WiFi 네트워크 선택', 'zh_Hant': '選擇 WiFi 網路'},
    'Mật khẩu WiFi': {'en': 'WiFi password', 'ko': 'WiFi 비밀번호', 'zh_Hant': 'WiFi 密碼'},
    'Kết nối Gateway với WiFi': {
      'en': 'Connect Gateway to WiFi',
      'ko': '게이트웨이를 WiFi에 연결',
      'zh_Hant': '將 Gateway 連上 WiFi'
    },
    'Quét mã QR Gateway': {'en': 'Scan Gateway QR code', 'ko': '게이트웨이 QR 코드 스캔', 'zh_Hant': '掃描 Gateway QR 碼'},
    'Đưa mã QR trên thiết bị vào khung': {
      'en': 'Place the QR code on the device inside the frame',
      'ko': '기기의 QR 코드를 프레임 안에 맞추세요',
      'zh_Hant': '將裝置上的 QR 碼對準框內'
    },
    'Camera Dome': {'en': 'Dome camera', 'ko': '돔 카메라', 'zh_Hant': '半球型攝影機'},
    'Camera PTZ xoay': {'en': 'PTZ camera', 'ko': 'PTZ 회전 카메라', 'zh_Hant': 'PTZ 旋轉攝影機'},
    'Camera mini Wifi': {'en': 'Mini WiFi camera', 'ko': '미니 WiFi 카메라', 'zh_Hant': '迷你 WiFi 攝影機'},
    'Lưu trữ không giới hạn thời gian, đến khi đầy dung lượng thì cần xoá bớt mới ghi tiếp': {
      'en': 'Recordings are kept indefinitely; once storage is full, delete some to keep recording',
      'ko': '녹화는 기간 제한 없이 보관되며, 저장 공간이 가득 차면 일부를 삭제해야 계속 녹화할 수 있습니다',
      'zh_Hant': '錄影不限保存時間；儲存空間滿載時需刪除部分資料才能繼續錄影'
    },
    // --- Device management ---
    'Dùng WiFi dự phòng (Eyerus-Setup)': {
      'en': 'Use backup WiFi (Eyerus-Setup)',
      'ko': '백업 WiFi 사용 (Eyerus-Setup)',
      'zh_Hant': '使用備援 WiFi（Eyerus-Setup）'
    },
    'Không dò được WiFi: {e}': {
      'en': 'Could not scan WiFi: {e}',
      'ko': 'WiFi를 스캔할 수 없습니다: {e}',
      'zh_Hant': '無法掃描 WiFi：{e}'
    },
    'Đang vào WiFi {ssid}…': {'en': 'Joining WiFi {ssid}…', 'ko': 'WiFi {ssid}에 연결 중…', 'zh_Hant': '正在加入 WiFi {ssid}…'},
    'Không vào được {ssid}. Thử vào thủ công trong Cài đặt WiFi.': {
      'en': 'Could not join {ssid}. Try joining it manually in WiFi settings.',
      'ko': '{ssid}에 연결할 수 없습니다. WiFi 설정에서 직접 연결해 보세요.',
      'zh_Hant': '無法加入 {ssid}。請嘗試在 WiFi 設定中手動加入。'
    },
    'Đang tìm Gateway tại 10.42.0.1…': {
      'en': 'Looking for the gateway at 10.42.0.1…',
      'ko': '10.42.0.1에서 게이트웨이를 찾는 중…',
      'zh_Hant': '正在 10.42.0.1 尋找 Gateway…'
    },
    'Chưa thấy Gateway. Kiểm tra điện thoại đang ở WiFi {prefix}XXXX.': {
      'en': 'Gateway not found. Make sure the phone is on WiFi {prefix}XXXX.',
      'ko': '게이트웨이를 찾을 수 없습니다. 휴대폰이 WiFi {prefix}XXXX에 연결되어 있는지 확인하세요.',
      'zh_Hant': '找不到 Gateway。請確認手機已連上 WiFi {prefix}XXXX。'
    },
    'Điện thoại đang quay lại WiFi nhà và tìm Gateway…': {
      'en': 'The phone is returning to the home WiFi and looking for the gateway…',
      'ko': '휴대폰이 집 WiFi로 돌아가 게이트웨이를 찾는 중…',
      'zh_Hant': '手機正在切回家中 WiFi 並尋找 Gateway…'
    },
    'Gateway đã vào WiFi "{ssid}" và đã được thêm vào app.': {
      'en': 'The gateway joined "{ssid}" and was added to the app.',
      'ko': '게이트웨이가 "{ssid}" WiFi에 연결되었고 앱에 추가되었습니다.',
      'zh_Hant': 'Gateway 已加入「{ssid}」並已新增到 App。'
    },
    'Đã gửi WiFi "{ssid}" cho Gateway. Nếu đèn Gateway báo đã có mạng là thành công; nếu sau 1 phút Gateway lại phát WiFi {prefix}XXXX thì mật khẩu chưa đúng, làm lại.':
        {
      'en':
          'WiFi "{ssid}" was sent to the gateway. If its LED shows it is online, it worked; if it broadcasts {prefix}XXXX again after 1 minute, the password was wrong — try again.',
      'ko':
          'WiFi "{ssid}" 정보를 게이트웨이에 보냈습니다. 게이트웨이 표시등이 온라인을 나타내면 성공입니다. 1분 후 게이트웨이가 다시 WiFi {prefix}XXXX를 송출하면 비밀번호가 틀린 것이니 다시 시도하세요.',
      'zh_Hant':
          '已將 WiFi「{ssid}」傳送給 Gateway。若 Gateway 指示燈顯示已連網即為成功；若 1 分鐘後 Gateway 再次發出 WiFi {prefix}XXXX，表示密碼錯誤，請重新操作。'
    },
    'Gateway đã vào WiFi "{ssid}". Kết nối điện thoại vào cùng WiFi đó để quản lý gateway.': {
      'en': 'The gateway joined "{ssid}". Join the same WiFi on this phone to manage it.',
      'ko': '게이트웨이가 "{ssid}" WiFi에 연결되었습니다. 게이트웨이를 관리하려면 휴대폰을 같은 WiFi에 연결하세요.',
      'zh_Hant': 'Gateway 已加入「{ssid}」。請將手機連上同一個 WiFi 以管理 Gateway。'
    },
    'Cài đặt qua WiFi dự phòng': {'en': 'Setup via backup WiFi', 'ko': '백업 WiFi로 설정', 'zh_Hant': '透過備援 WiFi 設定'},
    'Bước 1: Vào WiFi cài đặt của Gateway': {
      'en': 'Step 1: Join the gateway setup WiFi',
      'ko': '1단계: 게이트웨이 설정 WiFi에 연결',
      'zh_Hant': '步驟 1：加入 Gateway 的設定 WiFi'
    },
    'Gateway không có mạng khoảng 1 phút sẽ tự phát WiFi {prefix}XXXX, mật khẩu {pass}.': {
      'en': 'After about 1 minute without network the gateway broadcasts WiFi {prefix}XXXX, password {pass}.',
      'ko': '게이트웨이는 네트워크가 없는 상태로 약 1분이 지나면 WiFi {prefix}XXXX(비밀번호 {pass})를 자동으로 송출합니다.',
      'zh_Hant': 'Gateway 在無網路約 1 分鐘後，會自動發出 WiFi {prefix}XXXX，密碼 {pass}。'
    },
    'WiFi Gateway tìm thấy': {'en': 'Gateway WiFi found', 'ko': '찾은 게이트웨이 WiFi', 'zh_Hant': '找到的 Gateway WiFi'},
    'Dò lại': {'en': 'Scan again', 'ko': '다시 찾기', 'zh_Hant': '重新偵測'},
    'Chưa thấy WiFi {prefix}XXXX. Chờ thêm khoảng 1 phút sau khi Gateway mất mạng rồi bấm "Dò lại".': {
      'en': 'No {prefix}XXXX WiFi yet. Wait about 1 minute after the gateway loses network, then tap "Scan again".',
      'ko': '아직 WiFi {prefix}XXXX가 보이지 않습니다. 게이트웨이의 네트워크가 끊긴 후 약 1분 더 기다린 다음 "다시 찾기"를 누르세요.',
      'zh_Hant': '尚未看到 WiFi {prefix}XXXX。請在 Gateway 斷網後再等約 1 分鐘，然後點選「重新偵測」。'
    },
    'Bấm để tự kết nối': {'en': 'Tap to connect automatically', 'ko': '눌러서 자동 연결', 'zh_Hant': '點選以自動連線'},
    'Mở Cài đặt → WiFi trên iPhone, chọn {prefix}XXXX và nhập mật khẩu {pass}, rồi quay lại app.': {
      'en': 'Open Settings → WiFi on the iPhone, choose {prefix}XXXX with password {pass}, then come back to the app.',
      'ko': 'iPhone에서 설정 → WiFi를 열고 {prefix}XXXX를 선택해 비밀번호 {pass}를 입력한 후 앱으로 돌아오세요.',
      'zh_Hant': '在 iPhone 開啟「設定」→「WiFi」，選擇 {prefix}XXXX 並輸入密碼 {pass}，然後返回 App。'
    },
    'Tôi đã vào WiFi này, tiếp tục': {
      'en': 'I joined this WiFi, continue',
      'ko': '이 WiFi에 연결했습니다, 계속',
      'zh_Hant': '我已加入此 WiFi，繼續'
    },
    'Đã kết nối Gateway qua WiFi dự phòng': {
      'en': 'Connected to the gateway via backup WiFi',
      'ko': '백업 WiFi로 게이트웨이에 연결되었습니다',
      'zh_Hant': '已透過備援 WiFi 連線到 Gateway'
    },
    'Bước 2: Chọn WiFi nhà cho Gateway': {
      'en': 'Step 2: Choose the home WiFi for the gateway',
      'ko': '2단계: 게이트웨이가 사용할 집 WiFi 선택',
      'zh_Hant': '步驟 2：為 Gateway 選擇家中 WiFi'
    },
    'Hoàn tất': {'en': 'Done', 'ko': '완료', 'zh_Hant': '完成'},
    'Không quét được WiFi ({e}). Có thể nhập tên WiFi thủ công.': {
      'en': 'Could not scan WiFi ({e}). You can type the WiFi name manually.',
      'ko': 'WiFi를 스캔할 수 없습니다 ({e}). WiFi 이름을 직접 입력할 수 있습니다.',
      'zh_Hant': '無法掃描 WiFi（{e}）。您可以手動輸入 WiFi 名稱。'
    },
    'Chọn hoặc nhập tên WiFi': {
      'en': 'Choose or enter a WiFi name',
      'ko': 'WiFi 이름 선택 또는 입력',
      'zh_Hant': '選擇或輸入 WiFi 名稱'
    },
    'Mật khẩu WiFi cần ít nhất 8 ký tự': {
      'en': 'WiFi password needs at least 8 characters',
      'ko': 'WiFi 비밀번호는 최소 8자 이상이어야 합니다',
      'zh_Hant': 'WiFi 密碼至少需要 8 個字元'
    },
    'Gateway không vào được "{ssid}". Kiểm tra lại mật khẩu.': {
      'en': 'The gateway could not join "{ssid}". Check the password.',
      'ko': '게이트웨이가 "{ssid}"에 연결하지 못했습니다. 비밀번호를 확인하세요.',
      'zh_Hant': 'Gateway 無法加入「{ssid}」。請檢查密碼。'
    },
    'Hết thời gian chờ nhấn nút trên Gateway': {
      'en': 'Timed out waiting for the gateway button press',
      'ko': '게이트웨이 버튼 입력 대기 시간이 초과되었습니다',
      'zh_Hant': '等待按下 Gateway 按鈕逾時'
    },
    'Gateway đã kết nối WiFi thành công.': {
      'en': 'The gateway is connected to WiFi.',
      'ko': '게이트웨이가 WiFi에 연결되었습니다.',
      'zh_Hant': 'Gateway 已成功連上 WiFi。'
    },
    'Gateway đã vào mạng và đã được thêm vào app ({url}).': {
      'en': 'The gateway is online and was added to the app ({url}).',
      'ko': '게이트웨이가 네트워크에 연결되었고 앱에 추가되었습니다 ({url}).',
      'zh_Hant': 'Gateway 已連上網路並新增到 App（{url}）。'
    },
    'Gateway đã vào mạng ({url}). Kết nối điện thoại vào cùng WiFi đó để quản lý gateway.': {
      'en': 'The gateway is online ({url}). Join the same WiFi on this phone to manage it.',
      'ko': '게이트웨이가 네트워크에 연결되었습니다 ({url}). 게이트웨이를 관리하려면 휴대폰을 같은 WiFi에 연결하세요.',
      'zh_Hant': 'Gateway 已連上網路（{url}）。請將手機連上同一個 WiFi 以管理 Gateway。'
    },
    'Đang kết nối Bluetooth…': {'en': 'Connecting over Bluetooth…', 'ko': '블루투스 연결 중…', 'zh_Hant': '正在透過藍牙連線…'},
    'Đã kết nối Bluetooth': {'en': 'Connected over Bluetooth', 'ko': '블루투스로 연결됨', 'zh_Hant': '已透過藍牙連線'},
    'Đang tìm và kết nối Gateway qua Bluetooth. Để điện thoại gần Gateway.': {
      'en': 'Finding and connecting to the gateway over Bluetooth. Keep the phone close to it.',
      'ko': '블루투스로 게이트웨이를 찾아 연결하는 중입니다. 휴대폰을 게이트웨이 가까이에 두세요.',
      'zh_Hant': '正在透過藍牙尋找並連線 Gateway。請將手機靠近 Gateway。'
    },
    'Gateway đang quét WiFi xung quanh (5–30 giây)…': {
      'en': 'The gateway is scanning nearby WiFi (5–30 s)…',
      'ko': '게이트웨이가 주변 WiFi를 스캔하는 중 (5–30초)…',
      'zh_Hant': 'Gateway 正在掃描附近的 WiFi（5–30 秒）…'
    },
    'Chọn WiFi cho Gateway': {
      'en': 'Choose WiFi for the gateway',
      'ko': '게이트웨이 WiFi 선택',
      'zh_Hant': '為 Gateway 選擇 WiFi'
    },
    'Quét lại': {'en': 'Rescan', 'ko': '다시 스캔', 'zh_Hant': '重新掃描'},
    'Không tìm thấy WiFi nào. Bấm "Quét lại" hoặc nhập tên WiFi thủ công.': {
      'en': 'No WiFi found. Tap "Rescan" or enter the WiFi name manually.',
      'ko': 'WiFi를 찾을 수 없습니다. "다시 스캔"을 누르거나 WiFi 이름을 직접 입력하세요.',
      'zh_Hant': '找不到任何 WiFi。請點選「重新掃描」或手動輸入 WiFi 名稱。'
    },
    'Chọn từ danh sách': {'en': 'Choose from the list', 'ko': '목록에서 선택', 'zh_Hant': '從清單選擇'},
    'Nhập tên WiFi thủ công (mạng ẩn)': {
      'en': 'Enter WiFi name manually (hidden network)',
      'ko': 'WiFi 이름 직접 입력 (숨겨진 네트워크)',
      'zh_Hant': '手動輸入 WiFi 名稱（隱藏網路）'
    },
    'Tên WiFi (SSID)': {'en': 'WiFi name (SSID)', 'ko': 'WiFi 이름 (SSID)', 'zh_Hant': 'WiFi 名稱（SSID）'},
    'Gateway đang có mạng nên cần xác nhận: nhấn nhanh nút trên Gateway, app sẽ tự gửi lại.': {
      'en':
          'The gateway is already online and needs confirmation: briefly press its button, the app will resend automatically.',
      'ko': '게이트웨이가 이미 네트워크에 연결되어 있어 확인이 필요합니다: 게이트웨이 버튼을 짧게 누르면 앱이 자동으로 다시 보냅니다.',
      'zh_Hant': 'Gateway 已連網，需要確認：請短按 Gateway 上的按鈕，App 會自動重新傳送。'
    },
    'Đang chờ nhấn nút…': {'en': 'Waiting for button press…', 'ko': '버튼 입력 대기 중…', 'zh_Hant': '等待按下按鈕…'},
    'Đang kết nối WiFi…': {'en': 'Connecting WiFi…', 'ko': 'WiFi 연결 중…', 'zh_Hant': '正在連線 WiFi…'},
    'Chuyển sang HLS': {'en': 'Switch to HLS', 'ko': 'HLS로 전환', 'zh_Hant': '切換為 HLS'},
    'Kết nối WebRTC thất bại': {'en': 'WebRTC connection failed', 'ko': 'WebRTC 연결 실패', 'zh_Hant': 'WebRTC 連線失敗'},
    'Server lỗi {code}': {'en': 'Server error {code}', 'ko': '서버 오류 {code}', 'zh_Hant': '伺服器錯誤 {code}'},
    'Đã thêm {n} camera vào app': {
      'en': 'Added {n} cameras to the app',
      'ko': '카메라 {n}대를 앱에 추가했습니다',
      'zh_Hant': '已將 {n} 台攝影機新增到 App'
    },
    '{n} camera đã có sẵn': {'en': '{n} already in the app', 'ko': '카메라 {n}대는 이미 있습니다', 'zh_Hant': '{n} 台攝影機已存在'},
    '{n} camera đẩy sang server khác': {
      'en': '{n} pushed to another server',
      'ko': '카메라 {n}대는 다른 서버로 송출 중',
      'zh_Hant': '{n} 台攝影機推送到其他伺服器'
    },
    'Lỗi: {list}': {'en': 'Errors: {list}', 'ko': '오류: {list}', 'zh_Hant': '錯誤：{list}'},
    'Không có camera nào để thêm.': {'en': 'No cameras to add.', 'ko': '추가할 카메라가 없습니다.', 'zh_Hant': '沒有可新增的攝影機。'},
    'Tên luồng "{stream}" đã được tài khoản khác dùng': {
      'en': 'Stream name "{stream}" is used by another account',
      'ko': '스트림 이름 "{stream}"은(는) 다른 계정에서 사용 중입니다',
      'zh_Hant': '串流名稱「{stream}」已被其他帳號使用'
    },
    'Thêm camera vào app': {'en': 'Add cameras to the app', 'ko': '앱에 카메라 추가', 'zh_Hant': '將攝影機新增到 App'},
    '{summary}. Hoàn tất.': {'en': '{summary}. Done.', 'ko': '{summary}. 완료.', 'zh_Hant': '{summary}。完成。'},
    'Tìm Gateway qua Bluetooth': {
      'en': 'Find Gateway via Bluetooth',
      'ko': '블루투스로 게이트웨이 찾기',
      'zh_Hant': '透過藍牙尋找 Gateway'
    },
    'Quản lý đẩy luồng': {'en': 'Stream push', 'ko': '스트림 송출 관리', 'zh_Hant': '推流管理'},
    'Tự động đẩy lên media server, bật/tắt từng camera, thêm URL khác': {
      'en': 'Auto-push to the media server, per-camera switch, extra URLs',
      'ko': '미디어 서버로 자동 송출, 카메라별 켜기/끄기, 추가 URL',
      'zh_Hant': '自動推送到媒體伺服器、個別開關攝影機、新增其他 URL'
    },
    'Xoá đích đẩy luồng?': {'en': 'Delete push destination?', 'ko': '송출 대상을 삭제할까요?', 'zh_Hant': '要刪除推流目的地嗎？'},
    'Luồng {camera} sẽ ngừng đẩy tới {url}.': {
      'en': 'Stream {camera} will stop pushing to {url}.',
      'ko': '{camera} 스트림이 {url}(으)로의 송출을 중지합니다.',
      'zh_Hant': '串流 {camera} 將停止推送到 {url}。'
    },
    'Đẩy luồng': {'en': 'Stream push', 'ko': '스트림 송출', 'zh_Hant': '推流'},
    'Đích khác (tuỳ chọn)': {'en': 'Other destinations (optional)', 'ko': '기타 대상 (선택 사항)', 'zh_Hant': '其他目的地（選填）'},
    'Thêm URL': {'en': 'Add URL', 'ko': 'URL 추가', 'zh_Hant': '新增 URL'},
    'Tự động đẩy lên media server': {'en': 'Auto-push to media server', 'ko': '미디어 서버로 자동 송출', 'zh_Hant': '自動推送到媒體伺服器'},
    '{running}/{total} camera đang đẩy': {
      'en': '{running}/{total} cameras pushing',
      'ko': '카메라 {running}/{total}대 송출 중',
      'zh_Hant': '{running}/{total} 台攝影機推流中'
    },
    'Đang tắt': {'en': 'Off', 'ko': '꺼짐', 'zh_Hant': '已關閉'},
    'Dịch vụ đẩy luồng (eyerus-push) trên gateway chưa chạy.': {
      'en': 'The push service (eyerus-push) is not running on the gateway.',
      'ko': '게이트웨이의 송출 서비스(eyerus-push)가 실행되고 있지 않습니다.',
      'zh_Hant': 'Gateway 上的推流服務（eyerus-push）尚未執行。'
    },
    'Cần tài khoản admin của gateway để thay đổi.': {
      'en': 'A gateway admin account is required to make changes.',
      'ko': '변경하려면 게이트웨이 관리자 계정이 필요합니다.',
      'zh_Hant': '需要 Gateway 管理員帳號才能變更。'
    },
    'Chưa có camera nào được lưu trên gateway.': {
      'en': 'No cameras saved on the gateway yet.',
      'ko': '게이트웨이에 저장된 카메라가 없습니다.',
      'zh_Hant': 'Gateway 上尚未儲存任何攝影機。'
    },
    'Chưa có. Thêm URL để đẩy một camera sang server khác (rtsp, rtmp, srt…).': {
      'en': 'None yet. Add a URL to push a camera to another server (rtsp, rtmp, srt…).',
      'ko': '아직 없습니다. 카메라를 다른 서버(rtsp, rtmp, srt…)로 송출하려면 URL을 추가하세요.',
      'zh_Hant': '尚無。新增 URL 以將攝影機推送到其他伺服器（rtsp、rtmp、srt…）。'
    },
    'Đang khởi động': {'en': 'Starting', 'ko': '시작 중', 'zh_Hant': '啟動中'},
    'Đang thử lại': {'en': 'Retrying', 'ko': '재시도 중', 'zh_Hant': '重試中'},
    'Server từ chối (sai URL/khoá)': {
      'en': 'Rejected by server (wrong URL/key)',
      'ko': '서버가 거부함 (URL/키 오류)',
      'zh_Hant': '伺服器拒絕（URL / 金鑰錯誤）'
    },
    'Dịch vụ đẩy chưa chạy': {'en': 'Push service not running', 'ko': '송출 서비스가 실행되지 않음', 'zh_Hant': '推流服務未執行'},
    'Đã tắt': {'en': 'Off', 'ko': '꺼짐', 'zh_Hant': '已關閉'},
    'Tạm dừng': {'en': 'Paused', 'ko': '일시 중지', 'zh_Hant': '已暫停'},
    'Camera đang tắt': {'en': 'Camera is off', 'ko': '카메라가 꺼져 있음', 'zh_Hant': '攝影機已關閉'},
    'Đang đẩy qua đích khác cùng URL': {
      'en': 'Pushed by another destination with the same URL',
      'ko': '같은 URL의 다른 대상으로 송출 중',
      'zh_Hant': '由相同 URL 的其他目的地推送中'
    },
    'Thêm đích đẩy luồng': {'en': 'Add push destination', 'ko': '송출 대상 추가', 'zh_Hant': '新增推流目的地'},
    'URL đích': {'en': 'Destination URL', 'ko': '대상 URL', 'zh_Hant': '目的地 URL'},
    'URL phải bắt đầu bằng rtsp://, rtsps://, rtmp://, rtmps:// hoặc srt://': {
      'en': 'URL must start with rtsp://, rtsps://, rtmp://, rtmps:// or srt://',
      'ko': 'URL은 rtsp://, rtsps://, rtmp://, rtmps:// 또는 srt://로 시작해야 합니다',
      'zh_Hant': 'URL 必須以 rtsp://、rtsps://、rtmp://、rtmps:// 或 srt:// 開頭'
    },
    'Tên (tuỳ chọn)': {'en': 'Name (optional)', 'ko': '이름 (선택 사항)', 'zh_Hant': '名稱（選填）'},
    'Đổi địa chỉ Gateway': {'en': 'Change gateway address', 'ko': '게이트웨이 주소 변경', 'zh_Hant': '變更 Gateway 位址'},
    'Mở web quản trị Gateway': {
      'en': 'Open the gateway admin web',
      'ko': '게이트웨이 관리 웹 열기',
      'zh_Hant': '開啟 Gateway 管理網頁'
    },
    'Nhập IP của Gateway trong cùng mạng WiFi với điện thoại.': {
      'en': 'Enter the IP of a Gateway on the same WiFi as this phone.',
      'ko': '휴대폰과 같은 WiFi에 있는 게이트웨이의 IP를 입력하세요.',
      'zh_Hant': '請輸入與手機位於同一 WiFi 的 Gateway IP。'
    },
    'Địa chỉ Gateway': {'en': 'Gateway address', 'ko': '게이트웨이 주소', 'zh_Hant': 'Gateway 位址'},
    'Mở trang bảo trì': {'en': 'Open maintenance page', 'ko': '유지보수 페이지 열기', 'zh_Hant': '開啟維護頁面'},
    'Bảo trì nâng cao': {'en': 'Advanced maintenance', 'ko': '고급 유지보수', 'zh_Hant': '進階維護'},
    'Web quản trị: RTSP, đẩy luồng, MQTT, Webhook, nhật ký': {
      'en': 'Admin web: RTSP, stream push, MQTT, Webhook, logs',
      'ko': '관리 웹: RTSP, 스트림 송출, MQTT, Webhook, 로그',
      'zh_Hant': '管理網頁：RTSP、推流、MQTT、Webhook、日誌'
    },
    'Không mở được trang bảo trì: {e}': {
      'en': 'Could not open the maintenance page: {e}',
      'ko': '유지보수 페이지를 열 수 없습니다: {e}',
      'zh_Hant': '無法開啟維護頁面：{e}'
    },
    'Bảo trì Gateway': {'en': 'Gateway maintenance', 'ko': '게이트웨이 유지보수', 'zh_Hant': 'Gateway 維護'},
    'Xem camera của mọi nơi': {'en': 'Cameras from every place', 'ko': '모든 장소의 카메라', 'zh_Hant': '所有地點的攝影機'},
    'Giao thông': {'en': 'Traffic', 'ko': '교통', 'zh_Hant': '交通'},
    'Gateway Công ty': {'en': 'Company gateway', 'ko': '회사 게이트웨이', 'zh_Hant': '公司 Gateway'},
    'Gateway Giao thông': {'en': 'Traffic gateway', 'ko': '교통 게이트웨이', 'zh_Hant': '交通 Gateway'},
    'Mẫu': {'en': 'Demo', 'ko': '샘플', 'zh_Hant': '範例'},
    'Dữ liệu mẫu: chưa kết nối gateway thật. Thêm Gateway để xem số liệu thực tế.': {
      'en': 'Demo data: no real gateway connected. Add a Gateway to see live readings.',
      'ko': '샘플 데이터: 실제 게이트웨이가 연결되지 않았습니다. 실제 수치를 보려면 게이트웨이를 추가하세요.',
      'zh_Hant': '範例資料：尚未連接實際 Gateway。新增 Gateway 以查看即時數據。'
    },
    'Thiết bị': {'en': 'Devices', 'ko': '기기', 'zh_Hant': '裝置'},
    'Quản lý thiết bị': {'en': 'Device management', 'ko': '기기 관리', 'zh_Hant': '裝置管理'},
    'Gateway, thông số, nhiệt độ, độ ẩm': {
      'en': 'Gateways, parameters, temperature, humidity',
      'ko': '게이트웨이, 파라미터, 온도, 습도',
      'zh_Hant': 'Gateway、參數、溫度、濕度'
    },
    'Đang online': {'en': 'Online', 'ko': '온라인', 'zh_Hant': '在線'},
    'Đang kiểm tra…': {'en': 'Checking…', 'ko': '확인 중…', 'zh_Hant': '檢查中…'},
    'Đang dùng': {'en': 'In use', 'ko': '사용 중', 'zh_Hant': '使用中'},
    'Chưa có gateway nào': {'en': 'No gateways yet', 'ko': '아직 게이트웨이가 없습니다', 'zh_Hant': '尚無 Gateway'},
    'Quét mã QR trên Gateway Eyerus để thêm thiết bị và xem thông số, nhiệt độ, độ ẩm.': {
      'en': 'Scan the QR code on an Eyerus Gateway to add it and see its parameters, temperature and humidity.',
      'ko': 'Eyerus 게이트웨이의 QR 코드를 스캔하여 기기를 추가하고 파라미터, 온도, 습도를 확인하세요.',
      'zh_Hant': '掃描 Eyerus Gateway 上的 QR 碼以新增裝置，並查看參數、溫度與濕度。'
    },
    'Đổi tên Gateway': {'en': 'Rename gateway', 'ko': '게이트웨이 이름 변경', 'zh_Hant': '重新命名 Gateway'},
    'VD: Gateway tầng 1': {'en': 'e.g. 1st floor gateway', 'ko': '예: 1층 게이트웨이', 'zh_Hant': '例如：1 樓 Gateway'},
    'Đang chờ dữ liệu…': {'en': 'Waiting for data…', 'ko': '데이터 대기 중…', 'zh_Hant': '等待資料中…'},
    'Cập nhật lúc {time}': {'en': 'Updated at {time}', 'ko': '{time}에 업데이트됨', 'zh_Hant': '更新於 {time}'},
    'Môi trường': {'en': 'Environment', 'ko': '환경', 'zh_Hant': '環境'},
    'Gateway chưa gửi dữ liệu cảm biến.': {
      'en': 'The gateway has not sent sensor data yet.',
      'ko': '게이트웨이가 아직 센서 데이터를 보내지 않았습니다.',
      'zh_Hant': 'Gateway 尚未傳送感測器資料。'
    },
    'Nhiệt độ': {'en': 'Temperature', 'ko': '온도', 'zh_Hant': '溫度'},
    'Độ ẩm': {'en': 'Humidity', 'ko': '습도', 'zh_Hant': '濕度'},
    'Chất lượng không khí (TVOC)': {'en': 'Air quality (TVOC)', 'ko': '공기질 (TVOC)', 'zh_Hant': '空氣品質（TVOC）'},
    'Lỗi cảm biến: {names}': {'en': 'Sensor error: {names}', 'ko': '센서 오류: {names}', 'zh_Hant': '感測器錯誤：{names}'},
    'Tốt': {'en': 'Good', 'ko': '좋음', 'zh_Hant': '良好'},
    'Trung bình': {'en': 'Moderate', 'ko': '보통', 'zh_Hant': '普通'},
    'Kém': {'en': 'Poor', 'ko': '나쁨', 'zh_Hant': '不佳'},
    'Rất kém': {'en': 'Very poor', 'ko': '매우 나쁨', 'zh_Hant': '非常差'},
    'Nguy hại': {'en': 'Hazardous', 'ko': '위험', 'zh_Hant': '有害'},
    'Tài nguyên hệ thống': {'en': 'System resources', 'ko': '시스템 리소스', 'zh_Hant': '系統資源'},
    'Nhiệt độ chip': {'en': 'Chip temperature', 'ko': '칩 온도', 'zh_Hant': '晶片溫度'},
    'Bộ nhớ': {'en': 'Storage', 'ko': '저장소', 'zh_Hant': '儲存空間'},
    'Tải từng lõi CPU': {'en': 'Per-core CPU load', 'ko': 'CPU 코어별 부하', 'zh_Hant': '各 CPU 核心負載'},
    'Luồng camera': {'en': 'Camera streams', 'ko': '카메라 스트림', 'zh_Hant': '攝影機串流'},
    'Đã cấu hình': {'en': 'Configured', 'ko': '설정됨', 'zh_Hant': '已設定'},
    'Đang bật': {'en': 'Enabled', 'ko': '켜짐', 'zh_Hant': '已啟用'},
    'Đang phát': {'en': 'Streaming', 'ko': '스트리밍 중', 'zh_Hant': '串流中'},
    'Đích đẩy luồng': {'en': 'Push targets', 'ko': '송출 대상', 'zh_Hant': '推流目的地'},
    'Đang đẩy': {'en': 'Pushing', 'ko': '송출 중', 'zh_Hant': '推流中'},
    'Cổng RTSP': {'en': 'RTSP port', 'ko': 'RTSP 포트', 'zh_Hant': 'RTSP 連接埠'},
    'Chưa kết nối': {'en': 'Not connected', 'ko': '연결되지 않음', 'zh_Hant': '未連線'},
    'Tín hiệu WiFi': {'en': 'WiFi signal', 'ko': 'WiFi 신호', 'zh_Hant': 'WiFi 訊號'},
    'Cổng HTTP': {'en': 'HTTP port', 'ko': 'HTTP 포트', 'zh_Hant': 'HTTP 連接埠'},
    'Mạng': {'en': 'Network', 'ko': '네트워크', 'zh_Hant': '網路'},
    'Bo mạch': {'en': 'Board', 'ko': '보드', 'zh_Hant': '主機板'},
    'Vi xử lý': {'en': 'Processor', 'ko': '프로세서', 'zh_Hant': '處理器'},
    'Lõi / luồng CPU': {'en': 'CPU cores / threads', 'ko': 'CPU 코어 / 스레드', 'zh_Hant': 'CPU 核心 / 執行緒'},
    'Hệ điều hành': {'en': 'Operating system', 'ko': '운영 체제', 'zh_Hant': '作業系統'},
    'Thời gian hoạt động': {'en': 'Uptime', 'ko': '가동 시간', 'zh_Hant': '運作時間'},
    'Phiên bản API': {'en': 'API version', 'ko': 'API 버전', 'zh_Hant': 'API 版本'},
    'Phần cứng': {'en': 'Hardware', 'ko': '하드웨어', 'zh_Hant': '硬體'},
    '{d} ngày {h} giờ': {'en': '{d} d {h} h', 'ko': '{d}일 {h}시간', 'zh_Hant': '{d} 天 {h} 小時'},
    '{h} giờ {m} phút': {'en': '{h} h {m} min', 'ko': '{h}시간 {m}분', 'zh_Hant': '{h} 小時 {m} 分鐘'},
    '{m} phút': {'en': '{m} min', 'ko': '{m}분', 'zh_Hant': '{m} 分鐘'},
    'Xoá gateway': {'en': 'Remove gateway', 'ko': '게이트웨이 삭제', 'zh_Hant': '移除 Gateway'},
    'Xoá gateway?': {'en': 'Remove gateway?', 'ko': '게이트웨이를 삭제할까요?', 'zh_Hant': '要移除 Gateway 嗎？'},
    'Gateway "{name}" sẽ bị xoá khỏi điện thoại này. Muốn dùng lại phải thêm gateway lại.': {
      'en': 'Gateway "{name}" will be removed from this phone. You\'ll need to add it again to use it.',
      'ko': '게이트웨이 "{name}"이(가) 이 휴대폰에서 삭제됩니다. 다시 사용하려면 게이트웨이를 다시 추가해야 합니다.',
      'zh_Hant': 'Gateway「{name}」將從此手機中移除。若要再次使用，需要重新新增。'
    },
    'Đã xoá gateway "{name}"': {
      'en': 'Removed gateway "{name}"',
      'ko': '게이트웨이 "{name}"을(를) 삭제했습니다',
      'zh_Hant': '已移除 Gateway「{name}」'
    },
    'Không kết nối được http://{host}:{port} ({e})': {
      'en': 'Cannot reach http://{host}:{port} ({e})',
      'ko': 'http://{host}:{port}에 연결할 수 없습니다 ({e})',
      'zh_Hant': '無法連線到 http://{host}:{port}（{e}）'
    },
    'Kết nối gateway qua IP': {'en': 'Connect gateway by IP', 'ko': 'IP로 게이트웨이 연결', 'zh_Hant': '以 IP 連線 Gateway'},
    'Địa chỉ': {'en': 'Address', 'ko': '주소', 'zh_Hant': '位址'},
    'Port': {'en': 'Port', 'ko': '포트', 'zh_Hant': '連接埠'},
    'Port phải từ 1 đến 65535': {
      'en': 'Port must be between 1 and 65535',
      'ko': '포트는 1~65535 사이여야 합니다',
      'zh_Hant': '連接埠必須介於 1 到 65535'
    },
    'Port mặc định {port}. Port khác thì nhập kèm, VD 192.168.1.189:8080': {
      'en': 'Default port {port}. For another port, type it too, e.g. 192.168.1.189:8080',
      'ko': '기본 포트 {port}. 다른 포트는 함께 입력하세요. 예: 192.168.1.189:8080',
      'zh_Hant': '預設連接埠 {port}。其他連接埠請一併輸入，例如 192.168.1.189:8080'
    },
    'VD: localhost hoặc 192.168.1.189': {
      'en': 'e.g. localhost or 192.168.1.189',
      'ko': '예: localhost 또는 192.168.1.189',
      'zh_Hant': '例如：localhost 或 192.168.1.189'
    },
    'Đang kết nối {host}…': {'en': 'Connecting to {host}…', 'ko': '{host}에 연결 중…', 'zh_Hant': '正在連線到 {host}…'},
    'Đã thêm gateway': {'en': 'Gateway added', 'ko': '게이트웨이를 추가했습니다', 'zh_Hant': '已新增 Gateway'},
    'Quét mã QR': {'en': 'Scan QR code', 'ko': 'QR 코드 스캔', 'zh_Hant': '掃描 QR 碼'},
    'Nhập địa chỉ IP': {'en': 'Enter IP address', 'ko': 'IP 주소 입력', 'zh_Hant': '輸入 IP 位址'},
    'Điều khiển gateway': {'en': 'Gateway control', 'ko': '게이트웨이 제어', 'zh_Hant': 'Gateway 控制'},
    'Khởi động lại, ping camera, WiFi, Bluetooth, cụm': {
      'en': 'Restart, ping cameras, WiFi, Bluetooth, cluster',
      'ko': '재시작, 카메라 핑, WiFi, 블루투스, 클러스터',
      'zh_Hant': '重新啟動、Ping 攝影機、WiFi、藍牙、叢集'
    },
    'Khởi động lại gateway RTSP?': {
      'en': 'Restart RTSP gateway?',
      'ko': 'RTSP 게이트웨이를 재시작할까요?',
      'zh_Hant': '要重新啟動 RTSP Gateway 嗎？'
    },
    'Các luồng camera sẽ gián đoạn khoảng 5–15 giây.': {
      'en': 'Camera streams will pause for about 5–15 seconds.',
      'ko': '카메라 스트림이 약 5–15초 동안 중단됩니다.',
      'zh_Hant': '攝影機串流將中斷約 5–15 秒。'
    },
    'Đã khởi động lại': {'en': 'Restarted', 'ko': '재시작했습니다', 'zh_Hant': '已重新啟動'},
    'Tắt dịch vụ RTSP?': {'en': 'Stop RTSP service?', 'ko': 'RTSP 서비스를 중지할까요?', 'zh_Hant': '要停止 RTSP 服務嗎？'},
    'Mọi luồng camera và đẩy luồng sẽ dừng cho tới khi bật lại.': {
      'en': 'All camera streams and pushes stop until it is started again.',
      'ko': '다시 시작할 때까지 모든 카메라 스트림과 송출이 중지됩니다.',
      'zh_Hant': '所有攝影機串流與推流將停止，直到重新啟動為止。'
    },
    'Đã bật dịch vụ': {'en': 'Service started', 'ko': '서비스를 시작했습니다', 'zh_Hant': '服務已啟動'},
    'Đã tắt dịch vụ': {'en': 'Service stopped', 'ko': '서비스를 중지했습니다', 'zh_Hant': '服務已停止'},
    'Ngắt WiFi?': {'en': 'Disconnect WiFi?', 'ko': 'WiFi 연결을 끊을까요?', 'zh_Hant': '要中斷 WiFi 嗎？'},
    'Nếu điện thoại đang nói chuyện với gateway qua WiFi này, kết nối sẽ mất.': {
      'en': 'If the phone reaches the gateway over this WiFi, the connection will drop.',
      'ko': '휴대폰이 이 WiFi를 통해 게이트웨이와 통신 중이라면 연결이 끊어집니다.',
      'zh_Hant': '若手機正透過此 WiFi 與 Gateway 通訊，連線將會中斷。'
    },
    'Đã ngắt WiFi': {'en': 'WiFi disconnected', 'ko': 'WiFi 연결을 끊었습니다', 'zh_Hant': '已中斷 WiFi'},
    'Quên mạng "{ssid}"?': {
      'en': 'Forget network "{ssid}"?',
      'ko': '"{ssid}" 네트워크를 삭제할까요?',
      'zh_Hant': '要忘記網路「{ssid}」嗎？'
    },
    'Gateway sẽ không tự kết nối lại mạng này.': {
      'en': 'The gateway will no longer auto-join this network.',
      'ko': '게이트웨이가 더 이상 이 네트워크에 자동 연결하지 않습니다.',
      'zh_Hant': 'Gateway 將不再自動連線到此網路。'
    },
    'Đã quên mạng': {'en': 'Network forgotten', 'ko': '네트워크를 삭제했습니다', 'zh_Hant': '已忘記網路'},
    'Đã lưu': {'en': 'Saved', 'ko': '저장했습니다', 'zh_Hant': '已儲存'},
    'Nhật ký gateway': {'en': 'Gateway logs', 'ko': '게이트웨이 로그', 'zh_Hant': 'Gateway 日誌'},
    'Gateway chưa bật tài khoản': {
      'en': 'Gateway accounts not enabled',
      'ko': '게이트웨이 계정이 활성화되지 않음',
      'zh_Hant': 'Gateway 尚未啟用帳號'
    },
    'Vai trò trên gateway: {role}': {
      'en': 'Role on gateway: {role}',
      'ko': '게이트웨이 역할: {role}',
      'zh_Hant': 'Gateway 角色：{role}'
    },
    'Đang chạy': {'en': 'Running', 'ko': '실행 중', 'zh_Hant': '執行中'},
    'Đã dừng': {'en': 'Stopped', 'ko': '중지됨', 'zh_Hant': '已停止'},
    'Dịch vụ RTSP': {'en': 'RTSP service', 'ko': 'RTSP 서비스', 'zh_Hant': 'RTSP 服務'},
    'Chạy từ {t}': {'en': 'Running since {t}', 'ko': '{t}부터 실행 중', 'zh_Hant': '自 {t} 起執行'},
    'Khởi động lại': {'en': 'Restart', 'ko': '재시작', 'zh_Hant': '重新啟動'},
    'Tắt dịch vụ': {'en': 'Stop service', 'ko': '서비스 중지', 'zh_Hant': '停止服務'},
    'Bật dịch vụ': {'en': 'Start service', 'ko': '서비스 시작', 'zh_Hant': '啟動服務'},
    'Kiểm tra camera': {'en': 'Camera check', 'ko': '카메라 점검', 'zh_Hant': '攝影機檢查'},
    'Gateway chưa lưu camera nào.': {
      'en': 'No cameras saved on the gateway.',
      'ko': '게이트웨이에 저장된 카메라가 없습니다.',
      'zh_Hant': 'Gateway 上尚未儲存任何攝影機。'
    },
    'Không ping được': {'en': 'Ping failed', 'ko': '핑 실패', 'zh_Hant': 'Ping 失敗'},
    'Chưa kết nối WiFi': {'en': 'WiFi not connected', 'ko': 'WiFi 연결 안 됨', 'zh_Hant': '未連線 WiFi'},
    '{ip} · sóng {sig}%': {'en': '{ip} · signal {sig}%', 'ko': '{ip} · 신호 {sig}%', 'zh_Hant': '{ip} · 訊號 {sig}%'},
    'Ngắt WiFi': {'en': 'Disconnect WiFi', 'ko': 'WiFi 연결 끊기', 'zh_Hant': '中斷 WiFi'},
    'Quên mạng': {'en': 'Forget network', 'ko': '네트워크 삭제', 'zh_Hant': '忘記網路'},
    'Đang cho phép cài WiFi qua BLE': {
      'en': 'WiFi setup over BLE allowed',
      'ko': 'BLE로 WiFi 설정 허용 중',
      'zh_Hant': '允許透過 BLE 設定 WiFi'
    },
    'Cần nhấn nút trên gateway': {
      'en': 'Press the button on the gateway',
      'ko': '게이트웨이 버튼을 눌러야 합니다',
      'zh_Hant': '需要按下 Gateway 上的按鈕'
    },
    'Đang cài WiFi': {'en': 'Provisioning WiFi', 'ko': 'WiFi 설정 중', 'zh_Hant': '正在設定 WiFi'},
    'Đã cài WiFi': {'en': 'WiFi provisioned', 'ko': 'WiFi 설정 완료', 'zh_Hant': 'WiFi 已設定'},
    'Định danh (cụm)': {'en': 'Identity (cluster)', 'ko': '식별 정보 (클러스터)', 'zh_Hant': '識別資訊（叢集）'},
    'Mã gateway': {'en': 'Gateway ID', 'ko': '게이트웨이 ID', 'zh_Hant': 'Gateway ID'},
    'Tên cụm': {'en': 'Cluster name', 'ko': '클러스터 이름', 'zh_Hant': '叢集名稱'},
    'Khu vực': {'en': 'Zone', 'ko': '구역', 'zh_Hant': '區域'},
    'Quản trị': {'en': 'Administration', 'ko': '관리', 'zh_Hant': '管理'},
    'Không đọc được cấu hình': {'en': 'Could not read config', 'ko': '설정을 읽을 수 없습니다', 'zh_Hant': '無法讀取設定'},
    'Thử kết nối': {'en': 'Test connection', 'ko': '연결 테스트', 'zh_Hant': '測試連線'},
    'Kết nối broker thành công': {'en': 'Broker connection OK', 'ko': '브로커 연결 성공', 'zh_Hant': 'Broker 連線成功'},
    'Gửi ngay': {'en': 'Send now', 'ko': '지금 보내기', 'zh_Hant': '立即傳送'},
    'Đã gửi': {'en': 'Sent', 'ko': '보냈습니다', 'zh_Hant': '已傳送'},
    'Chưa cấu hình': {'en': 'Not configured', 'ko': '설정되지 않음', 'zh_Hant': '尚未設定'},
    '100 dòng gần nhất': {'en': 'Last 100 lines', 'ko': '최근 100줄', 'zh_Hant': '最近 100 行'},
    'Email': {'en': 'Email', 'ko': '이메일', 'zh_Hant': '電子郵件'},
    'Gateway': {'en': 'Gateway', 'ko': '게이트웨이', 'zh_Hant': 'Gateway'},
    'REST: {url}': {'en': 'REST: {url}', 'ko': 'REST: {url}', 'zh_Hant': 'REST：{url}'},
    'Ping': {'en': 'Ping', 'ko': '핑', 'zh_Hant': 'Ping'},
    'WiFi & Bluetooth': {'en': 'WiFi & Bluetooth', 'ko': 'WiFi 및 블루투스', 'zh_Hant': 'WiFi 與藍牙'},
    'URL media server': {'en': 'Media server URL', 'ko': '미디어 서버 URL', 'zh_Hant': '媒體伺服器 URL'},
    'Camera': {'en': 'Camera', 'ko': '카메라', 'zh_Hant': '攝影機'},
    'Media server': {'en': 'Media server', 'ko': '미디어 서버', 'zh_Hant': '媒體伺服器'},
    'VD: YouTube': {'en': 'e.g. YouTube', 'ko': '예: YouTube', 'zh_Hant': '例如：YouTube'},
    'camera': {'en': 'camera', 'ko': '카메라', 'zh_Hant': '攝影機'},
    // --- Common camera group / room names (CameraGroup.displayName) ---
    'Phòng khách': {'en': 'Living room', 'ko': '거실', 'zh_Hant': '客廳'},
    'Phòng ngủ': {'en': 'Bedroom', 'ko': '침실', 'zh_Hant': '臥室'},
    'Phòng ngủ chính': {'en': 'Master bedroom', 'ko': '안방', 'zh_Hant': '主臥室'},
    'Phòng trẻ em': {'en': 'Kids\' room', 'ko': '아이 방', 'zh_Hant': '兒童房'},
    'Phòng bé': {'en': 'Baby\'s room', 'ko': '아기 방', 'zh_Hant': '嬰兒房'},
    'Nhà bếp': {'en': 'Kitchen', 'ko': '주방', 'zh_Hant': '廚房'},
    'Phòng bếp': {'en': 'Kitchen', 'ko': '주방', 'zh_Hant': '廚房'},
    'Phòng ăn': {'en': 'Dining room', 'ko': '식당', 'zh_Hant': '餐廳'},
    'Phòng làm việc': {'en': 'Study', 'ko': '서재', 'zh_Hant': '書房'},
    'Văn phòng': {'en': 'Office', 'ko': '사무실', 'zh_Hant': '辦公室'},
    'Phòng họp': {'en': 'Meeting room', 'ko': '회의실', 'zh_Hant': '會議室'},
    'Cổng': {'en': 'Gate', 'ko': '대문', 'zh_Hant': '大門'},
    'Cổng trước': {'en': 'Front gate', 'ko': '앞문', 'zh_Hant': '前門'},
    'Cổng sau': {'en': 'Back gate', 'ko': '뒷문', 'zh_Hant': '後門'},
    'Cổng chính': {'en': 'Main gate', 'ko': '정문', 'zh_Hant': '正門'},
    'Lối vào': {'en': 'Entrance', 'ko': '입구', 'zh_Hant': '入口'},
    'Sảnh': {'en': 'Lobby', 'ko': '로비', 'zh_Hant': '大廳'},
    'Lễ tân': {'en': 'Reception', 'ko': '안내 데스크', 'zh_Hant': '櫃台'},
    'Quầy thu ngân': {'en': 'Cashier', 'ko': '계산대', 'zh_Hant': '收銀台'},
    'Sân': {'en': 'Yard', 'ko': '마당', 'zh_Hant': '庭院'},
    'Sân trước': {'en': 'Front yard', 'ko': '앞마당', 'zh_Hant': '前院'},
    'Sân sau': {'en': 'Backyard', 'ko': '뒷마당', 'zh_Hant': '後院'},
    'Sân vườn': {'en': 'Garden', 'ko': '정원', 'zh_Hant': '花園'},
    'Ban công': {'en': 'Balcony', 'ko': '발코니', 'zh_Hant': '陽台'},
    'Nhà xe': {'en': 'Garage', 'ko': '차고', 'zh_Hant': '車庫'},
    'Gara': {'en': 'Garage', 'ko': '차고', 'zh_Hant': '車庫'},
    'Bãi xe': {'en': 'Parking lot', 'ko': '주차장', 'zh_Hant': '停車場'},
    'Bãi đỗ xe': {'en': 'Parking lot', 'ko': '주차장', 'zh_Hant': '停車場'},
    'Hành lang': {'en': 'Hallway', 'ko': '복도', 'zh_Hant': '走廊'},
    'Cầu thang': {'en': 'Stairs', 'ko': '계단', 'zh_Hant': '樓梯'},
    'Kho': {'en': 'Warehouse', 'ko': '창고', 'zh_Hant': '倉庫'},
    'Nhà kho': {'en': 'Warehouse', 'ko': '창고', 'zh_Hant': '倉庫'},
    'Cửa hàng': {'en': 'Store', 'ko': '매장', 'zh_Hant': '店面'},
    'Nhà xưởng': {'en': 'Factory', 'ko': '공장', 'zh_Hant': '廠房'},
    'Xưởng': {'en': 'Workshop', 'ko': '작업장', 'zh_Hant': '工坊'},
    'Tầng 1': {'en': '1st floor', 'ko': '1층', 'zh_Hant': '1 樓'},
    'Tầng 2': {'en': '2nd floor', 'ko': '2층', 'zh_Hant': '2 樓'},
    'Tầng 3': {'en': '3rd floor', 'ko': '3층', 'zh_Hant': '3 樓'},
    'Tầng hầm': {'en': 'Basement', 'ko': '지하', 'zh_Hant': '地下室'},
    'Sân thượng': {'en': 'Rooftop', 'ko': '옥상', 'zh_Hant': '頂樓'},
    'Ngoài trời': {'en': 'Outdoor', 'ko': '실외', 'zh_Hant': '戶外'},
    'Trong nhà': {'en': 'Indoor', 'ko': '실내', 'zh_Hant': '室內'},
    'Nhà': {'en': 'Home', 'ko': '집', 'zh_Hant': '住家'},
    'Gia đình': {'en': 'Family', 'ko': '가족', 'zh_Hant': '家庭'},
    'Nhà riêng': {'en': 'House', 'ko': '주택', 'zh_Hant': '住宅'},
    'Chung cư': {'en': 'Apartment', 'ko': '아파트', 'zh_Hant': '公寓'},
    'Trường học': {'en': 'School', 'ko': '학교', 'zh_Hant': '學校'},
    'Bệnh viện': {'en': 'Hospital', 'ko': '병원', 'zh_Hant': '醫院'},
    'Ngã tư': {'en': 'Intersection', 'ko': '교차로', 'zh_Hant': '十字路口'},
    'Đường phố': {'en': 'Street', 'ko': '거리', 'zh_Hant': '街道'},
  };

  /// Languages offered in Settings: code -> native name. Vietnamese is the
  /// source language (keys); others fall back to English, then Vietnamese.
  static const languages = {
    'vi': 'Tiếng Việt',
    'en': 'English',
    'ko': '한국어',
    'zh_Hant': '繁體中文',
  };

  static String tr(String key, String lang) {
    if (lang == 'vi') return key;
    final t = _translations[key];
    if (t == null) return key;
    return t[lang] ?? t['en'] ?? key;
  }
}

extension StringI18n on String {
  String get tr {
    final lang = AppThemeStore.instance.lang;
    return AppStrings.tr(this, lang);
  }

  /// Translate a template, then fill `{name}` placeholders. Use this instead
  /// of `'... $x ...'.tr` — interpolating first makes the key never match.
  String trArgs(Map<String, Object?> args) {
    var s = tr;
    args.forEach((k, v) => s = s.replaceAll('{$k}', '${v ?? ''}'));
    return s;
  }
}
