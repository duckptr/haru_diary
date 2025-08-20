class Validators {
  // 한글/영문/숫자/_ 2~20자
  static final RegExp _nickRe = RegExp(r'^[A-Za-z0-9_가-힣]{2,20}$');

  static bool isNicknameValid(String s) => _nickRe.hasMatch(s);
}
