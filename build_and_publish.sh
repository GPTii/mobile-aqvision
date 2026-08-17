#!/bin/bash

echo "🚀 Bắt đầu quá trình Build và Cập nhật tự động..."

# 1. Chuyển vào thư mục mobile
cd /home/ubuntu/mobile || exit

# 2. Đọc version từ file pubspec.yaml
VERSION=$(grep "^version:" pubspec.yaml | sed 's/version: //g' | cut -d '+' -f 1)
echo "📦 Đang build phiên bản: v$VERSION"

# 3. Chạy lệnh build của Flutter
echo "⏳ Đang nén file APK (có thể mất 2-3 phút)..."
/home/ubuntu/flutter/bin/flutter build apk --release

# 4. Kiểm tra xem build có thành công không
if [ -f "build/app/outputs/flutter-apk/app-release.apk" ]; then
    # 5. Đổi tên và Copy vào thư mục public của Web Server
    DEST="/home/ubuntu/html5stream/web/public/app/app-release-v$VERSION.apk"
    echo "✅ Build thành công! Đang tự động kéo file vào Server..."
    cp build/app/outputs/flutter-apk/app-release.apk "$DEST"
    
    echo "🎉 HOÀN TẤT! File cập nhật đã nằm ở: $DEST"
    echo "🔔 Hệ thống Server đã nhận diện bản v$VERSION và tự động bắn thông báo cho tất cả người dùng!"
else
    echo "❌ Lỗi: Không tìm thấy file APK sau khi build. Vui lòng kiểm tra lại!"
fi
