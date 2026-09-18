// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appTitle => 'एरो';

  @override
  String get appTagline => 'हर तीर को बाहर निकालो';

  @override
  String get homeSettings => 'सेटिंग्स';

  @override
  String get homeNextUp => 'अगला पड़ाव';

  @override
  String get homePlay => 'खेलें';

  @override
  String get homeReplay => 'फिर खेलें';

  @override
  String get homeAllCleared => 'हर लेवल पार — कमाल कर दिया!';

  @override
  String get homeContinue => 'जारी रखें';

  @override
  String get homeResumeEyebrow => 'जहाँ छोड़ा था, वहीं से';

  @override
  String homeResumeProgress(int out, int total, String time) {
    return '$total में से $out तीर बाहर · घड़ी पर $time';
  }

  @override
  String get homeJourney => 'आपका सफ़र';

  @override
  String get onboardSkip => 'छोड़ें';

  @override
  String get onboardNext => 'आगे';

  @override
  String get onboardStart => 'चलो खेलें!';

  @override
  String get onboardTitle1 => 'किसी तीर पर टैप करो';

  @override
  String get onboardBody1 =>
      'वह जिस ओर इशारा करता है, उसी ओर निकल जाता है। टैप करके देखो।';

  @override
  String get onboardDone1 => 'बस इतना ही — एक निकल गया!';

  @override
  String get onboardTitle2 => 'रास्ता रोकने वालों से बचो';

  @override
  String get onboardBody2 =>
      'एक तीर दूसरे के आर-पार नहीं जा सकता। ऊपर की ओर वाले तीर पर टैप करो और टक्कर देखो।';

  @override
  String get onboardBumped2 =>
      'टक्कर! असली लेवल में इससे एक जान जाती है। पहले ऊपर वाला निकालो, फिर दूसरा।';

  @override
  String get onboardDone2 => 'क्रम मायने रखता है — आप समझ गए।';

  @override
  String get onboardTitle3 => 'बस यही पूरा खेल है';

  @override
  String get onboardRuleLives => 'हर लेवल में 3 जानें — हर टक्कर पर एक जाती है';

  @override
  String get onboardRuleClock => 'घड़ी को हराओ — समय काफ़ी है, पर चलता रहता है';

  @override
  String get onboardRuleHints =>
      'अटक गए? हर लेवल में 3 संकेत एक खुला तीर जगा देते हैं';

  @override
  String get onboardRuleZoom => 'आगे बड़े बोर्ड — पिंच करो या बटन से ज़ूम करो';

  @override
  String get onboardRuleRiddle => 'जानें ख़त्म? एक पहेली बूझो और खेल जारी रखो';

  @override
  String homeStars(int count, int total) {
    return '$total में से $count तारे';
  }

  @override
  String get homeLevels => 'लेवल';

  @override
  String get homeLevelsHint =>
      'अगला लेवल खोलने के लिए यह पार करो। बिना ग़लती के तीन तारे।';

  @override
  String levelNumber(int number) {
    return 'लेवल $number';
  }

  @override
  String levelShort(int number) {
    return 'ले.$number';
  }

  @override
  String get levelLocked => 'बंद';

  @override
  String get levelName1 => 'पहला क़दम';

  @override
  String get levelName2 => 'दो रास्ते';

  @override
  String get levelName3 => 'तंग मोड़';

  @override
  String get levelName4 => 'आड़ा-तिरछा';

  @override
  String get levelName5 => 'अड़चन';

  @override
  String get levelName6 => 'उलझन';

  @override
  String get levelName7 => 'गाँठ';

  @override
  String get levelName8 => 'जकड़न';

  @override
  String get levelName9 => 'भूलभुलैया';

  @override
  String get levelName10 => 'जाम';

  @override
  String get levelName11 => 'मकड़जाल';

  @override
  String get levelName12 => 'झाड़ी';

  @override
  String get levelName13 => 'भागता राही';

  @override
  String get levelName14 => 'धागों का खेल';

  @override
  String get levelName15 => 'ट्रैफ़िक जाम';

  @override
  String get levelName16 => 'सेवइयाँ';

  @override
  String get levelName17 => 'भीड़ का समय';

  @override
  String get levelName18 => 'अबूझ गाँठ';

  @override
  String get levelName19 => 'भागने का उस्ताद';

  @override
  String get levelName20 => 'गहरा पानी';

  @override
  String get levelName21 => 'खींचती लहर';

  @override
  String get levelName22 => 'बाग़ की भूलभुलैया';

  @override
  String get levelName23 => 'ऊन का गोला';

  @override
  String get levelName24 => 'आमने-सामने';

  @override
  String get levelName25 => 'रेल यार्ड';

  @override
  String get levelName26 => 'साँपों का कुआँ';

  @override
  String get levelName27 => 'बालों का गुच्छा';

  @override
  String get levelName28 => 'घड़ी की चाल';

  @override
  String get levelName29 => 'भँवर';

  @override
  String get levelName30 => 'अग्निपरीक्षा';

  @override
  String get levelName31 => 'परिपथ';

  @override
  String get levelName32 => 'काँटों की झाड़ी';

  @override
  String get levelName33 => 'जड़ों का जाल';

  @override
  String get levelName34 => 'बुनी चादर';

  @override
  String get levelName35 => 'ततैयों का छत्ता';

  @override
  String get levelName36 => 'गहरी बुनाई';

  @override
  String get levelName37 => 'सुई का नाका';

  @override
  String get levelName38 => 'हड़कंप';

  @override
  String get levelName39 => 'वापसी नहीं';

  @override
  String get levelName40 => 'आधा सफ़र';

  @override
  String get levelName41 => 'घनी बेलें';

  @override
  String get levelName42 => 'शृंखला';

  @override
  String get levelName43 => 'लट्ठों का जाम';

  @override
  String get levelName44 => 'झाड़-झंखाड़';

  @override
  String get levelName45 => 'जालीदार';

  @override
  String get levelName46 => 'एक में एक';

  @override
  String get levelName47 => 'गतिरोध';

  @override
  String get levelName48 => 'लोहे की भूलभुलैया';

  @override
  String get levelName49 => 'ढीले धागे';

  @override
  String get levelName50 => 'अंदाज़ी राह';

  @override
  String get levelName51 => 'बुख़ार का सपना';

  @override
  String get levelName52 => 'उल्टे इरादे';

  @override
  String get levelName53 => 'चींटियों का घर';

  @override
  String get levelName54 => 'उधड़न';

  @override
  String get levelName55 => 'आख़िरी सहारा';

  @override
  String get levelName56 => 'ओझल बिंदु';

  @override
  String get levelName57 => 'कसी रस्सी';

  @override
  String get levelName58 => 'लंबा सफ़र';

  @override
  String get levelName59 => 'खड़ी चढ़ाई';

  @override
  String get levelName60 => 'निर्णायक मोड़';

  @override
  String get levelName61 => 'दूसरी साँस';

  @override
  String get levelName62 => 'अनजान राह';

  @override
  String get levelName63 => 'तारों का घोंसला';

  @override
  String get levelName64 => 'उलटी लहर';

  @override
  String get levelName65 => 'घना जंगल';

  @override
  String get levelName66 => 'लोहे का कवच';

  @override
  String get levelName67 => 'तहख़ाने की गलियाँ';

  @override
  String get levelName68 => 'उलझा जाल';

  @override
  String get levelName69 => 'गहरी डूब';

  @override
  String get levelName70 => 'कोई रास्ता नहीं';

  @override
  String get levelName71 => 'तूफ़ानी बादल';

  @override
  String get levelName72 => 'गाँठों की गाँठ';

  @override
  String get levelName73 => 'कसौटी';

  @override
  String get levelName74 => 'घुप्प अँधेरा';

  @override
  String get levelName75 => 'चक्कर';

  @override
  String get levelName76 => 'छुरी की धार';

  @override
  String get levelName77 => 'बिना वापसी की रेखा';

  @override
  String get levelName78 => 'अथाह खाई';

  @override
  String get levelName79 => 'आख़िरी रोशनी';

  @override
  String get levelName80 => 'किनारे के पार';

  @override
  String get tutorialTap =>
      'किसी तीर पर टैप करो — वह अपनी दिशा में निकल जाएगा।';

  @override
  String get tutorialBlocked =>
      'रास्ते में खड़ा तीर एक जान ले लेता है — पहले खुले तीर ढूँढो।';

  @override
  String get gameLoading => 'तीर बिछाए जा रहे हैं…';

  @override
  String get gamePause => 'रोकें';

  @override
  String get gameResume => 'जारी रखें';

  @override
  String get gamePaused => 'रुका हुआ';

  @override
  String get gamePausedBody => 'साँस ले लीजिए। घड़ी रुकी हुई है।';

  @override
  String get gameQuit => 'लेवल छोड़ें';

  @override
  String get resumeTitle => 'वापस स्वागत है';

  @override
  String resumeBody(int out, int total, String time) {
    return 'आपने यह लेवल $total में से $out तीर बाहर और घड़ी पर $time के साथ छोड़ा था।';
  }

  @override
  String get resumeContinue => 'जारी रखें';

  @override
  String get resumeStartOver => 'फिर से शुरू';

  @override
  String get gameRestart => 'लेवल फिर से शुरू करें';

  @override
  String get gameBack => 'वापस';

  @override
  String hudArrows(int out, int total) {
    return '$out/$total';
  }

  @override
  String hudLives(int lives) {
    return '$lives जानें बाक़ी';
  }

  @override
  String get toolHint => 'संकेत';

  @override
  String toolHintLeft(int count) {
    return '$count संकेत बाक़ी';
  }

  @override
  String get toolHintRiddle => 'एक के लिए पहेली बूझो';

  @override
  String get toolGrid => 'ग्रिड लाइनें';

  @override
  String toolGridLocked(int level) {
    return 'ग्रिड लाइनें लेवल $level के बाद खुलेंगी';
  }

  @override
  String get toolZoomIn => 'ज़ूम इन';

  @override
  String get toolZoomOut => 'ज़ूम आउट';

  @override
  String get gridUnlockedToast =>
      'ग्रिड लाइनें खुल गईं! बोर्ड के नीचे बटन देखिए।';

  @override
  String get clearedTitle => 'लेवल पार!';

  @override
  String get clearedFlawless => 'बिना एक भी ग़लती — तीन तारे!';

  @override
  String get clearedGood => 'बढ़िया! एक ग़लती, दो तारे।';

  @override
  String get clearedOkay => 'हो गया! अगली बार कम ग़लतियाँ, ज़्यादा तारे।';

  @override
  String clearedTime(String time) {
    return 'समय $time';
  }

  @override
  String get clearedNewBest => 'नया सबसे अच्छा समय!';

  @override
  String get clearedNext => 'अगला लेवल';

  @override
  String get clearedReplay => 'फिर खेलें';

  @override
  String get clearedHome => 'होम';

  @override
  String get clearedAllDone => 'आपने हर लेवल जीत लिया। छा गए!';

  @override
  String get outOfLivesTitle => 'जानें ख़त्म';

  @override
  String get outOfLivesBody =>
      'यह आख़िरी जान थी। एक पहेली बूझिए और यहीं से आगे खेलिए — एक तारे के लिए — या लेवल फिर से शुरू करें?';

  @override
  String get outOfLivesSolveRiddle => 'पहेली बूझें';

  @override
  String get outOfLivesRetry => 'फिर से शुरू';

  @override
  String get riddleTitle => 'बूझो तो जानें';

  @override
  String get riddleIntro => 'सही जवाब दीजिए और एक और जान के साथ बोर्ड पर वापस।';

  @override
  String get riddleIntroHint => 'सही जवाब दीजिए और एक खुला तीर जगमगा उठेगा।';

  @override
  String get riddleField => 'आपका जवाब (हिन्दी या रोमन में)';

  @override
  String get riddleSubmit => 'यही मेरा जवाब है';

  @override
  String get riddleHintAction => 'थोड़ा संकेत दीजिए';

  @override
  String get riddleHintMore => 'एक और इशारा';

  @override
  String riddleFirstLetter(String letter) {
    return 'शुरुआत “$letter” से होती है';
  }

  @override
  String riddleLetters(int count) {
    return '$count अक्षर';
  }

  @override
  String riddleWords(int count) {
    return '$count शब्द';
  }

  @override
  String get riddleWrong1 => 'नहीं जी। इतना भी क़रीब नहीं था।';

  @override
  String get riddleWrong2 => 'फिर भी नहीं। पहेली टस से मस नहीं हुई।';

  @override
  String get riddleWrong3 => 'आत्मविश्वास पूरा था, जवाब बस थोड़ा ग़लत था।';

  @override
  String get riddleWrong4 => 'आप कोशिश करते रहिए, पहेली को कोई जल्दी नहीं है।';

  @override
  String get riddleWrong5 => 'तीर अब देखना बंद कर चुके हैं। अच्छा ही है।';

  @override
  String get riddleWrong6 => 'शब्द तो है, बस वही शब्द नहीं है।';

  @override
  String get riddleWrong7 => 'दिलचस्प अंदाज़ा। ग़लत, पर दिलचस्प।';

  @override
  String get riddleWrong8 => 'पहेली ने सुना, और फिर अनसुना कर दिया।';

  @override
  String get riddleWrong9 => 'नहीं। पर हिम्मत की दाद देनी पड़ेगी।';

  @override
  String get riddleWrong10 =>
      'इतने यक़ीन से ग़लत जवाब कम ही सुनने को मिलता है।';

  @override
  String get riddleWrong11 => 'बहुत क़रीब! (बिल्कुल भी क़रीब नहीं था।)';

  @override
  String get riddleWrong12 =>
      'आपके जवाब और सही जवाब की आज तक मुलाक़ात नहीं हुई।';

  @override
  String get riddleWrong13 => 'नहीं। पहेली नोट कर रही है।';

  @override
  String get riddleWrong14 => 'जजों की तरफ़ से पूरे भरोसे के साथ — ना।';

  @override
  String get riddleWrong15 => 'ग़लत, पर कहा बड़े रौब से गया।';

  @override
  String get riddleWrong16 => 'यह जवाब किसी और सवाल का रहा होगा।';

  @override
  String get riddleWrong17 => 'नहीं। पर जोश बनाए रखिए।';

  @override
  String get riddleWrong18 => 'पहेली ने थोड़ी देर अकेले रहने की माँग की है।';

  @override
  String get riddleWrong19 => 'न क़रीब, न दूर — बस पूरी तरह ग़लत।';

  @override
  String get riddleWrong20 => 'विनम्रता के साथ, मना।';

  @override
  String get riddleWrong21 => 'वर्तनी शानदार। जवाब ग़लत।';

  @override
  String get riddleWrong22 => 'लगता है आप किसी और ही पहेली का जवाब दे रहे हैं।';

  @override
  String get riddleWrong23 =>
      'पहेली को शक होने लगा है कि आप तुक्का लगा रहे हैं।';

  @override
  String get riddleWrong24 => 'नहीं। और पहेली को इसमें मज़ा आ रहा है।';

  @override
  String get riddleWrong25 => 'जो पहला ख़याल आया था, वही आज़मा लीजिए।';

  @override
  String get riddleWrong26 => 'निशाना चूक गया, पर अंदाज़ बढ़िया था।';

  @override
  String get riddleWrong27 => 'पहेली कह रही है ना, और यहाँ चलती पहेली की है।';

  @override
  String get riddleWrong28 => 'पहेली मुस्कुरा रही है, और यह अच्छी बात नहीं है।';

  @override
  String get riddleWrong29 => 'ग़लत। पर आपने पूरे दिल से ग़लत कहा।';

  @override
  String get riddleWrong30 => 'इस बार नहीं। शायद अगली बार, या उसके अगली बार।';

  @override
  String get riddleCloseTitle => 'क़रीब-क़रीब सही!';

  @override
  String riddleClose(String answer) {
    return 'शब्द बिल्कुल यही नहीं था — जवाब था $answer — पर काफ़ी क़रीब। एक और जान आपकी।';
  }

  @override
  String riddleCloseHint(String answer) {
    return 'शब्द बिल्कुल यही नहीं था — जवाब था $answer — पर काफ़ी क़रीब। संकेत बोर्ड पर है।';
  }

  @override
  String get riddleCorrect => 'एकदम सही!';

  @override
  String riddleCorrectBody(String answer) {
    return 'जवाब था $answer। एक और जान हाज़िर, बोर्ड वहीं का वहीं है।';
  }

  @override
  String riddleCorrectBodyHint(String answer) {
    return 'जवाब था $answer। बोर्ड पर एक खुला तीर जगमगा रहा है।';
  }

  @override
  String get riddleBackToBoard => 'तीरों पर वापस';

  @override
  String get riddleSwap => 'दूसरी पहेली दिखाएँ';

  @override
  String get riddleGiveUp => 'रहने दीजिए';

  @override
  String riddleSolvedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'अब तक $count पहेलियाँ बूझीं',
      one: 'अब तक 1 पहेली बूझी',
      zero: 'आपकी पहली पहेली',
    );
    return '$_temp0';
  }

  @override
  String get timeUpTitle => 'समय ख़त्म!';

  @override
  String timeUpBody(int out, int total) {
    return 'बस थोड़ा और — $total में से $out तीर बाहर। एक बार और?';
  }

  @override
  String get timeUpRetry => 'फिर कोशिश करें';

  @override
  String get settingsTitle => 'सेटिंग्स';

  @override
  String get settingsMusic => 'संगीत';

  @override
  String get settingsMusicSubtitle => 'खेलते समय एक शांत धुन';

  @override
  String get settingsSfx => 'ध्वनि प्रभाव';

  @override
  String get settingsSfxSubtitle => 'खेल के छोटे-छोटे स्वर';

  @override
  String get settingsHaptics => 'कंपन';

  @override
  String get settingsHapticsSubtitle => 'हर चाल पर हल्का स्पर्श, टक्कर पर झटका';

  @override
  String get settingsLanguage => 'भाषा';

  @override
  String get languageSystem => 'डिवाइस';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageHindi => 'हिन्दी';

  @override
  String get settingsTheme => 'थीम';

  @override
  String get themeSystem => 'डिवाइस';

  @override
  String get themeLight => 'उजली';

  @override
  String get themeDark => 'गहरी';

  @override
  String get settingsHowToPlay => 'कैसे खेलें';

  @override
  String get howToPlayBody => 'दो मिनट का परिचय फिर से देखें';

  @override
  String get settingsCredits => 'संगीत आभार';

  @override
  String get creditsTitle => 'आभार';

  @override
  String creditsBy(String artist) {
    return '$artist द्वारा';
  }

  @override
  String get settingsResetProgress => 'प्रगति मिटाएँ';

  @override
  String get settingsResetProgressSubtitle =>
      'हर लेवल फिर से बंद और सारे तारे साफ़';

  @override
  String get settingsResetConfirmTitle => 'सारी प्रगति मिटा दें?';

  @override
  String get settingsResetConfirmBody =>
      'तारे और सबसे अच्छे समय मिट जाएँगे। यह वापस नहीं हो सकता।';

  @override
  String get commonCancel => 'रद्द करें';

  @override
  String get commonReset => 'मिटाएँ';
}
