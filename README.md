<p align="center">
  <img src="assets/banner/banner.png" alt="하루일기 배너" width="100%" />
</p>

---

# 하루일기 (Haru Diary) 📔
Flutter로 만든 일기장 앱입니다.  
하루의 기분을 텍스트, 날씨, 해시태그로 기록하고,  
캘린더와 통계를 통해 나를 시각적으로 돌아볼 수 있습니다.

---

## ✨ 주요 기능

### 📅 캘린더 시각화
- 일기를 작성한 날짜에 **날씨 태그** 표시  
- 날씨별로 **색상이 달라 시각적으로 구분** 가능  
- 선택한 날짜를 눌러 **일기 작성 또는 조회** 가능  

### ✍️ 일기 작성
- **텍스트**, **날씨(필수 선택)**, **해시태그** 입력 가능  
- 해시태그는 `#` 자동완성 + **Chip 형태로 변환**  
- **날짜 선택 UI는 제거**되어 항상 캘린더에서 선택한 날짜로 작성  
- **날씨를 선택하지 않고 작성 완료 버튼을 누르면** 선택 안내 모달 표시  
- 작성된 일기는 Firebase Firestore의 **개인 컬렉션 + 루트 컬렉션**에 저장됨  
- 수정 시 기존 정보(제목, 내용, 해시태그, 날씨 등) **자동 불러오기**  

### 📋 일기 목록
- 작성된 일기를 **리스트 형태**로 확인  
- 각 일기는 **고정된 높이로 정렬되어 깔끔한 UI 유지**  
- 일기 클릭 시 **모달로 상세 내용 표시** (닫기 버튼 없이 스와이프로 닫힘)  

### 📊 통계 화면
- **총 일기 수**  
- **월별 일기 수 막대그래프**  
- **날씨(기분)별 분포 시각화**  
- **가장 활동적인 요일 분석**  
- **가장 많이 사용된 해시태그 TOP 3**  
- **기간 필터 기능 포함** (선택한 기간 기준 통계 제공)  

### 🔐 Firebase 로그인/회원가입
- 이메일 및 비밀번호 기반 로그인  
- 회원가입 시 **이메일 인증 후 로그인 안내 화면 제공**  

### ☁️ Firestore 데이터 저장 구조
- 사용자별 컬렉션: `users/{uid}/diaries`  
- 루트 컬렉션: `diaries`  
- 일기 **작성/수정/삭제 시 두 컬렉션 모두 동기화**  
- `rootId` 필드 기반으로 루트 문서 참조 및 관리  


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

- ⏳ **푸시 알림**: 일기 작성 리마인더 기능 (개발 예정)  
- ⏳ **AI 챗봇**: 자연어 처리(NLP)를 기반으로 감정 분석 및 대화형 기록 도우미 제공 (진행 중)  
- ⏳ **위치 기록**: 일기 작성 시 위치 정보 연동 (기획 중)  
- ⏳ **테마 설정**: 다크 모드 / 라이트 모드 지원 (진행 중)  


---

## 👨‍💻 개발자

- 김명준 ([duckptr](https://github.com/duckptr))


