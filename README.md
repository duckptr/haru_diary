<p align="center">
  <img src="assets/banner/banner.png" alt="하루일기 배너" width="100%" />
</p>

# 하루일기 (Haru Diary) 📔
Flutter로 만든 일기장 앱입니다.  
하루의 기분을 텍스트, 날씨, 해시태그로 기록하고,  
캘린더와 통계를 통해 나를 시각적으로 돌아볼 수 있습니다.

---

## ✨ 주요 기능

- 📅 **캘린더 시각화**: 작성한 일기를 날씨 아이콘과 함께 캘린더에 표시

- ✍️ **일기 작성**: 텍스트, 날씨, 해시태그 입력 가능

- 📋 **일기 목록**: 모든 일기를 리스트 형태로 확인 가능

- 📊 **통계 화면**:
  
  - 총 일기 수  
  - 월별 일기 수 그래프  
  - 날씨(기분) 분포  
  - 요일별 활동 분석  
  - 가장 많이 쓴 해시태그 TOP3

- 🔐 Firebase 로그인/회원가입

- ☁️ Firestore 데이터 저장 (사용자별 + 루트 컬렉션)


---

## 🛠 기술 스택

- Flutter 3.x
- Dart
- Firebase (Authentication, Firestore)
- Provider (상태 관리)
- TableCalendar
- Lottie
- Custom BottomNavigationBar

---

## 🧪 실행 방법

bash
# 1. 프로젝트 클론
git clone https://github.com/duckptr/haru_diary.git
cd haru_diary

# 2. 패키지 설치
flutter pub get

# 3. .env 파일 생성
echo "OPENWEATHER_API_KEY=your_openweather_api_key_here" > .env

# 4. 앱 실행
flutter run

---

## 📁 디렉토리 구조

🗂️ assets  
🗂️ lib  
 ┣ 📁 screens  
 ┃ ┣ 📄 auth_screen.dart  
 ┃ ┣ 📄 diary_list_screen.dart  
 ┃ ┣ 📄 email_verified_screen.dart  
 ┃ ┣ 📄 home_screen.dart  
 ┃ ┣ 📄 my_page_screen.dart  
 ┃ ┣ 📄 sign_screen.dart  
 ┃ ┣ 📄 splash_screen.dart  
 ┃ ┣ 📄 statistics_screen.dart  
 ┃ ┗ 📄 write_diary_screen.dart  
 ┣ 📁 widgets  
 ┃ ┣ 📄 bouncy_button.dart  
 ┃ ┣ 📄 calendar_weather_icon.dart  
 ┃ ┣ 📄 custom_bottom_navbar.dart  
 ┃ ┣ 📄 diary_modal.dart  
 ┃ ┣ 📄 hashtag_input_field.dart  
 ┃ ┣ 📄 loading_indicator.dart  
 ┃ ┣ 📄 statistics_card.dart  
 ┃ ┗ 📄 weather_selector.dart  
 ┣ 📁 models  
 ┣ 📁 services  
 ┣ 📁 utils  
 ┗ 🚀 main.dart  


---

## 📌 업데이트 중/예정 기능

- ✅ **일기 검색 기능**: 해시태그 및 내용으로 필터링 가능 (기능 구현 완료)
- ⏳ **푸시 알림**: 일기 작성 리마인더 기능 (개발 예정)
- ⏳ **AI 챗봇**: 감정 분석 또는 대화 기반 기록 도우미 (기획 중)
- ⏳ **위치 기록**: 일기 작성 시 위치 정보 연동 (기획 중)

---

## 👨‍💻 개발자

- 김명준 ([duckptr](https://github.com/duckptr))


