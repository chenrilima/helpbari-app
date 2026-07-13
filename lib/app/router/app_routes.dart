abstract final class AppRoutes {
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const signUp = '/sign-up';
  static const resetPassword = '/reset-password';
  static const home = '/home';
  static const showcase = '/showcase';
  static const profile = '/profile';
  static const completeProfile = '/complete-profile';
  static const weight = '/weight';
  static const registerWeight = '/register-weight';
  static const water = '/water';
  static const registerWater = '/register-water';
  static const baria = '/baria';
  static const vitamins = '/vitamins';
  static const registerVitamin = '/register-vitamin';
  static const appointments = '/appointments';
  static const registerAppointment = '/register-appointment';
  static const exams = '/exams';
  static const registerExam = '/register-exam';
  static const examDetails = '/exam-details';
  static const progress = '/progress';
  static const medications = '/medications';
  static const registerMedication = '/register-medication';
  static const meals = '/meals';
  static const registerMeal = '/mealsRegister';
  static const medicalReports = '/medical-reports';
  static const settings = '/settings';
  static const privacy = '/privacy';
  static const academy = '/academy';
  static const academyArticle = '/academy/article/:articleId';
  static const academyFaq = '/academy/faq';
  static const academyGlossary = '/academy/glossary';
  static const academyHistory = '/academy/history';

  static String academyArticlePath(String articleId) {
    return '/academy/article/${Uri.encodeComponent(articleId)}';
  }
}
