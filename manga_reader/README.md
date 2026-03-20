# 📚 MangaVerse — Ứng dụng Đọc Truyện Tranh Flutter + Firebase

> **Đồ án môn học Flutter** | Full CRUD + Provider + SQLite + Firebase Auth + Firestore + Storage + fl_chart + Hero Animation

---

## 📋 Mục lục

1. [Yêu cầu hệ thống](#-yêu-cầu-hệ-thống)
2. [Cài đặt môi trường Flutter](#-cài-đặt-môi-trường-flutter)
3. [Cấu hình Firebase](#-cấu-hình-firebase-bắt-buộc)
4. [Tải project & cài dependencies](#-tải-project--cài-dependencies)
5. [Chạy ứng dụng](#-chạy-ứng-dụng)
6. [Thiết lập Firestore Rules & Storage Rules](#-thiết-lập-rules)
7. [Tạo tài khoản Admin](#-tạo-tài-khoản-admin)
8. [Upload chapter truyện](#-upload-chapter-truyện)
9. [Build APK Release](#-build-apk-release)
10. [Cấu trúc project](#-cấu-trúc-project)
11. [Tính năng](#-tính-năng)
12. [Xử lý lỗi thường gặp](#-xử-lý-lỗi-thường-gặp)

---

## 💻 Yêu cầu hệ thống

| Thành phần | Phiên bản tối thiểu |
|---|---|
| Flutter SDK | 3.3.0 trở lên (khuyến nghị 3.24.x) |
| Dart SDK | 3.3.0 trở lên |
| Android Studio | 2022.3 trở lên (hoặc VS Code) |
| Android SDK | API 21 (Android 5.0+) |
| Java JDK | 11 trở lên |
| Node.js | 18+ (cho FlutterFire CLI) |
| Firebase CLI | Phiên bản mới nhất |

---

## 🔧 Cài đặt môi trường Flutter

### Bước 1 — Cài Flutter SDK

**Windows:**
```powershell
# Tải từ: https://docs.flutter.dev/get-started/install/windows
# Giải nén vào C:\flutter (KHÔNG đặt trong Program Files)
# Thêm C:\flutter\bin vào biến môi trường PATH
```

**macOS:**
```bash
brew install --cask flutter
```

**Ubuntu/Linux:**
```bash
sudo snap install flutter --classic
```

### Bước 2 — Kiểm tra môi trường

```bash
flutter doctor
```

Kết quả cần đạt (tất cả dấu ✓):
```
[✓] Flutter (Channel stable, 3.24.x)
[✓] Android toolchain
[✓] Android Studio
[✓] Connected device
```

Nếu thiếu Android licenses:
```bash
flutter doctor --android-licenses
# Nhấn 'y' cho tất cả
```

### Bước 3 — Cài Firebase CLI & FlutterFire CLI

```bash
# Cài Firebase CLI (cần Node.js)
npm install -g firebase-tools

# Đăng nhập Firebase
firebase login

# Cài FlutterFire CLI
dart pub global activate flutterfire_cli
```

---

## 🔥 Cấu hình Firebase (BẮT BUỘC)

> ⚠️ **Đây là bước quan trọng nhất.** App sẽ chạy offline nếu bỏ qua,
> nhưng sẽ KHÔNG có tính năng đọc chapter & đồng bộ.

### Bước 1 — Kích hoạt các dịch vụ Firebase

Vào [Firebase Console](https://console.firebase.google.com) → Project **quangminh**:

**Authentication:**
- `Authentication` → `Sign-in method` → Bật **Email/Password** → Save

**Firestore Database:**
- `Firestore Database` → `Create database`
- Chọn `Start in production mode` → chọn region **asia-southeast1 (Singapore)**
- Nhấn **Enable**

**Firebase Storage:**
- `Storage` → `Get started`
- Chọn `Start in production mode` → chọn region **asia-southeast1**
- Nhấn **Done**

### Bước 2 — Thêm Android app vào Firebase (nếu chưa có)

1. Firebase Console → Project Settings (⚙️) → `Your apps` → `Add app` → Android
2. **Android package name:** `com.example.manga_reader`
3. Nhấn **Register app**
4. Tải file `google-services.json`
5. Đặt file này vào: `android/app/google-services.json`

### Bước 3 — Chạy FlutterFire Configure (tự động)

```bash
# Trong thư mục gốc của project manga_reader/
flutterfire configure --project=quangminh
```

Lệnh này sẽ:
- Tự động tạo file `lib/firebase_options.dart` với đúng API keys
- Thêm cấu hình cho Android/iOS

> ✅ Sau bước này file `lib/firebase_options.dart` sẽ có giá trị thật thay vì `YOUR_API_KEY`

### Bước 4 — Cập nhật android/app/build.gradle

Đảm bảo file `android/app/build.gradle` có:
```gradle
plugins {
    id "com.android.application"
    id "kotlin-android"
    id "dev.flutter.flutter-gradle-plugin"
    id "com.google.gms.google-services"  // ← Thêm dòng này
}
```

Và file `android/build.gradle` có:
```gradle
dependencies {
    classpath 'com.android.tools.build:gradle:8.1.0'
    classpath 'com.google.gms:google-services:4.4.0'  // ← Thêm dòng này
}
```

---

## 📂 Tải project & cài dependencies

```bash
# 1. Giải nén file ZIP
unzip MangaVerse_Flutter.zip

# 2. Vào thư mục project
cd manga_reader

# 3. Cài tất cả packages
flutter pub get

# 4. Kiểm tra không có lỗi
flutter analyze
```

Nếu gặp lỗi network khi pub get:
```bash
export PUB_HOSTED_URL=https://pub.flutter-io.cn
export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn
flutter pub get
```

---

## 🚀 Chạy ứng dụng

### Chuẩn bị thiết bị

**Android thật:**
```
Cài đặt → Giới thiệu điện thoại → Nhấn "Số bản dựng" 7 lần
→ Tùy chọn nhà phát triển → Bật USB debugging
→ Cắm cáp USB → Chấp nhận dialog trên điện thoại
```

**Android Emulator:**
```
Android Studio → Tools → Device Manager → ▶ Start
```

### Kiểm tra thiết bị

```bash
flutter devices
# Kết quả mong đợi: hiển thị emulator hoặc thiết bị thật
```

### Chạy app

```bash
# Chế độ debug (khuyến nghị khi phát triển)
flutter run

# Chỉ định thiết bị cụ thể
flutter run -d emulator-5554

# Chế độ release (hiệu năng cao)
flutter run --release
```

### Hot Reload / Hot Restart

| Phím | Chức năng |
|---|---|
| `r` | Hot Reload — cập nhật UI giữ nguyên state |
| `R` | Hot Restart — khởi động lại app |
| `q` | Thoát |

---

## 🛡️ Thiết lập Rules

### Firestore Rules

1. Mở file `firestore.rules` trong project
2. Vào Firebase Console → **Firestore Database** → **Rules**
3. Xóa nội dung cũ, dán toàn bộ nội dung file `firestore.rules`
4. Nhấn **Publish**

### Storage Rules

1. Mở file `storage.rules` trong project
2. Vào Firebase Console → **Storage** → **Rules**
3. Xóa nội dung cũ, dán toàn bộ nội dung file `storage.rules`
4. Nhấn **Publish**

---

## 👑 Tạo tài khoản Admin

Chỉ tài khoản Admin mới có thể upload chapter truyện.

### Cách 1 — Qua Firebase Console (khuyến nghị)

```
1. Đăng ký tài khoản bình thường trong app (Settings → Đăng nhập)
2. Firebase Console → Firestore Database → Collection "users"
3. Tìm document có email của bạn
4. Nhấn Edit (✏️) → Thêm field: is_admin = true (boolean)
5. Save
6. Đăng xuất và đăng nhập lại trong app
```

### Cách 2 — Firebase Console trực tiếp

```
Firebase Console → Authentication → Users
→ Ghi lại UID của user muốn set admin
→ Firestore → users → {UID} → Edit → is_admin: true
```

Sau khi set admin, user sẽ thấy nút **⭐ Admin** trong profile và nút **Upload Chương** trên màn hình danh sách chapter.

---

## 📤 Upload chapter truyện

### Quy trình upload chapter

```
1. Đăng nhập tài khoản Admin
2. Vào trang chi tiết một bộ truyện
3. Nhấn nút "Đọc Truyện" → Màn hình danh sách chapter
4. Nhấn nút FAB "Upload Chương" (hoặc nút + ở góc trên phải)
5. Nhập số chương và tiêu đề chương
6. Nhấn "Chọn ảnh" → Chọn nhiều ảnh từ thư viện (JPG/PNG)
7. Sắp xếp lại thứ tự trang bằng cách giữ và kéo
8. Nhấn "Upload X ảnh" → Chờ upload hoàn tất
```

### Cấu trúc lưu trữ trên Firebase Storage

```
Firebase Storage/
└── chapters/
    └── {manga_id}/
        └── chapter_{n}/
            ├── page_000.jpg   ← Trang 1
            ├── page_001.jpg   ← Trang 2
            └── page_002.jpg   ← Trang 3
```

### Cấu trúc Firestore

```
Firestore/
├── users/
│   └── {uid}/             { email, display_name, is_admin, ... }
├── chapters/
│   └── {chapter_id}/      { manga_id, chapter_number, image_urls[], ... }
├── read_states/
│   └── {uid}_{chapterId}/ { last_page, is_completed, read_at }
└── manga_cloud/
    └── {uid}_{mangaId}/   { manga data được sync từ SQLite }
```

---

## 📦 Build APK Release

```bash
# Build APK release
flutter build apk --release

# Build APK split theo kiến trúc (file nhỏ hơn)
flutter build apk --split-per-abi --release

# File APK xuất ra tại:
# build/app/outputs/flutter-apk/app-release.apk

# Cài lên thiết bị
adb install build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

---

## 🗂️ Cấu trúc project

```
manga_reader/
│
├── lib/
│   ├── main.dart                      # Entry point + Firebase.initializeApp()
│   ├── firebase_options.dart          # ⚠️ Cần chạy flutterfire configure
│   │
│   ├── models/
│   │   ├── manga.dart                 # Model truyện (SQLite)
│   │   ├── reading_history.dart       # Model lịch sử + MangaStats
│   │   ├── chapter.dart               # Model chapter (Firestore)
│   │   └── app_user.dart              # Model user (Firebase Auth)
│   │
│   ├── services/
│   │   ├── database_service.dart      # SQLite CRUD (sqflite)
│   │   ├── preferences_service.dart   # SharedPreferences
│   │   └── firebase_service.dart      # Firebase Auth + Firestore + Storage
│   │
│   ├── providers/
│   │   ├── manga_provider.dart        # State quản lý truyện (SQLite)
│   │   ├── theme_provider.dart        # State Dark/Light mode
│   │   ├── auth_provider.dart         # State Firebase Authentication
│   │   └── chapter_provider.dart      # State chapters (Firestore)
│   │
│   ├── screens/
│   │   ├── splash_screen.dart         # Khởi động + animation
│   │   ├── home_screen.dart           # Dashboard chính
│   │   ├── add_edit_screen.dart       # Form thêm/sửa truyện
│   │   ├── detail_screen.dart         # Chi tiết + nút "Đọc Truyện"
│   │   ├── statistics_screen.dart     # Biểu đồ fl_chart
│   │   ├── settings_screen.dart       # Cài đặt + Login/Logout
│   │   ├── auth/
│   │   │   ├── login_screen.dart      # Đăng nhập Firebase
│   │   │   └── register_screen.dart   # Đăng ký tài khoản
│   │   └── chapter/
│   │       ├── chapter_list_screen.dart   # Danh sách chapter (Firestore)
│   │       ├── chapter_reader_screen.dart # Đọc truyện (ảnh + swipe/scroll)
│   │       └── add_chapter_screen.dart    # Upload chapter (Admin only)
│   │
│   ├── widgets/
│   │   ├── app_widgets.dart           # Loading, EmptyState, Dialog
│   │   └── manga_card.dart            # Grid/List card
│   │
│   └── utils/
│       ├── constants.dart
│       ├── app_theme.dart             # Material Design 3
│       └── validators.dart
│
├── android/
│   └── app/
│       ├── google-services.json       # ⚠️ Tải từ Firebase Console
│       └── build.gradle
│
├── firestore.rules                    # Dán vào Firebase Console
├── storage.rules                      # Dán vào Firebase Console
└── pubspec.yaml
```

---

## ✨ Tính năng đầy đủ

### 📱 Màn hình & Chức năng

| Màn hình | Tính năng |
|---|---|
| **Splash** | Logo animation elastic, khởi tạo Firebase + SQLite |
| **Home** | Grid/List view, search, filter theo thể loại & trạng thái |
| **Add/Edit** | Form 10 trường, validate, preview ảnh bìa |
| **Detail** | Hero animation, tiến trình đọc, nút **Đọc Truyện** |
| **Chapter List** | Danh sách chapter từ Firestore, badge "đã đọc" |
| **Chapter Reader** | Đọc ảnh từng trang, swipe ngang (manga) hoặc cuộn dọc (webtoon), zoom |
| **Add Chapter** | Upload ảnh lên Firebase Storage, kéo thả sắp xếp |
| **Statistics** | Pie chart + Bar chart + Progress bars |
| **Settings** | Dark/Light mode, xem profile, đăng xuất |
| **Login** | Đăng nhập Firebase Email/Password |
| **Register** | Tạo tài khoản Firebase |

### 🔥 Firebase Features

| Tính năng | Mô tả |
|---|---|
| **Authentication** | Đăng ký/đăng nhập Email+Password, reset mật khẩu |
| **Firestore** | Lưu trữ chapters, read states, user profiles |
| **Storage** | Upload/lưu ảnh chapter theo path có cấu trúc |
| **Security Rules** | Phân quyền user/admin, bảo vệ dữ liệu |
| **Offline Support** | SQLite hoạt động khi không có Firebase |

### 📖 Trải nghiệm đọc truyện

- **Chế độ ngang (Manga):** Lật trang bằng swipe, PhotoViewGallery với zoom
- **Chế độ dọc (Webtoon):** Cuộn dọc liên tục như web comic
- **Thanh điều hướng:** Slider tiến trình trang, nút prev/next
- **Auto-save:** Lưu trang đang đọc khi thoát, khôi phục lần sau
- **Full screen:** Ẩn/hiện UI bằng tap
- **Cache ảnh:** CachedNetworkImage tránh load lại

---

## ✅ Đáp ứng yêu cầu đồ án

### A. Kỹ thuật (40%)
- ✅ **Dart & Flutter** (SDK ≥ 3.3.0)
- ✅ **sqflite** — `database_service.dart`: 2 bảng, index, cascade delete, dữ liệu mẫu
- ✅ **shared_preferences** — `preferences_service.dart`: theme, viewMode, fontSize
- ✅ **Provider** — 4 providers: MangaProvider, ThemeProvider, AuthProvider, ChapterProvider

### B. CRUD (40%)
- ✅ **Create** — Form 10 trường + validate (7 hàm)
- ✅ **Read** — GridView + ListView + search + filter
- ✅ **Update** — Pre-fill form + cập nhật tiến trình đọc
- ✅ **Delete** — AlertDialog xác nhận

### C. Giao diện (20%)
- ✅ **10 màn hình** (yêu cầu tối thiểu 4)
- ✅ **Material Design 3** — `useMaterial3: true`
- ✅ **Light/Dark mode** — SharedPreferences
- ✅ **Loading Indicator** — mọi màn hình tải data
- ✅ **Responsive** — không overflow

### ⭐ Điểm Cộng (Advanced)
- ✅ **Firebase Authentication** — Email/Password + reset password
- ✅ **Firebase Firestore** — Chapters, ReadStates, UserProfiles
- ✅ **Firebase Storage** — Upload ảnh chapter
- ✅ **fl_chart** — Pie chart + Bar chart + Progress bars
- ✅ **Hero Animation** — ảnh bìa list → detail
- ✅ **Elastic Animation** — Splash screen
- ✅ **Phân quyền Admin/User** — Bảo vệ tính năng upload

---

## 🐛 Xử lý lỗi thường gặp

### ❌ `FirebaseException: [core/no-app]`
Firebase chưa được khởi tạo. Chạy:
```bash
flutterfire configure --project=quangminh
```

### ❌ `google-services.json not found`
Tải file từ Firebase Console → Project Settings → android app → Download `google-services.json`, đặt vào `android/app/`.

### ❌ `permission-denied` khi đọc Firestore
Chưa set Security Rules. Dán nội dung file `firestore.rules` vào Firebase Console → Firestore → Rules.

### ❌ `User is not admin` — không thấy nút Upload
Set `is_admin: true` trong Firestore → `users` → `{uid}` của tài khoản bạn dùng.

### ❌ `MissingPluginException` (sqflite/image_picker)
```bash
flutter clean && flutter pub get && flutter run
```

### ❌ Build lỗi Gradle
```bash
cd android && ./gradlew clean && cd ..
flutter clean && flutter pub get && flutter run
```

### ❌ `minSdkVersion` thấp hơn yêu cầu
Đảm bảo `android/app/build.gradle` có `minSdkVersion 21`.

### ❌ Image Picker không hoạt động trên Android 13+
Thêm vào `AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>
```

---

*Được xây dựng với ❤️ bằng Flutter + Firebase*
