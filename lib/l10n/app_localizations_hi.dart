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
  String get chapterName1 => 'रेखाएँ';

  @override
  String get chapterName2 => 'आईने';

  @override
  String get chapterName3 => 'ताले';

  @override
  String get chapterName4 => 'धुंध';

  @override
  String get chapterName5 => 'जोड़ियाँ';

  @override
  String chapterHeading(int number, String name) {
    return 'अध्याय $number · $name';
  }

  @override
  String chapterLevels(int first, int last) {
    return 'लेवल $first–$last';
  }

  @override
  String get chapterBlurb1 =>
      'एक ही नियम: जिस तीर का रास्ता साफ़ हो उसे छुओ और वह निकल जाता है।';

  @override
  String get chapterBlurb2 =>
      'बोर्ड पर आईने। तीर टकराकर मुड़ता है और आगे बढ़ता है।';

  @override
  String get chapterBlurb3 => 'ताले वाले तीर अपनी चाबी का इंतज़ार करते हैं।';

  @override
  String get chapterBlurb4 => 'कुछ सिरे छिपे हैं, जब तक पास का तीर न निकले।';

  @override
  String get chapterBlurb5 => 'बँधे तीर साथ निकलते हैं।';

  @override
  String get introTitleMirrors => 'आईने';

  @override
  String get introBodyMirrors => 'तीर आईने से टकराकर मुड़ जाते हैं।';

  @override
  String get introTitleLocks => 'ताले';

  @override
  String get introBodyLocks => 'पहले चाबी निकलती है। फिर ताला खुलता है।';

  @override
  String get introTitleFog => 'छिपे सिरे';

  @override
  String get introBodyFog => 'पास का तीर निकालो, सिरा दिख जाएगा।';

  @override
  String get introTitlePairs => 'जोड़ियाँ';

  @override
  String get introBodyPairs =>
      'एक छुअन, दोनों निकलते हैं। दोनों रास्ते साफ़ चाहिए।';

  @override
  String get introGotIt => 'समझ गया';

  @override
  String get tutorialMirrors => 'तीर आईने से टकराकर मुड़ जाते हैं।';

  @override
  String get tutorialLocks => 'ताले वाला तीर अपनी चाबी का इंतज़ार करता है।';

  @override
  String get tutorialFog =>
      'बिंदीदार तीर के पास का तीर निकालो, सिरा दिखेगा। बिंदीदार तीर छूने पर जान नहीं जाती।';

  @override
  String get tutorialPairs => 'बँधे तीर साथ निकलते हैं।';

  @override
  String get dailyEyebrow => 'आज का बोर्ड';

  @override
  String get dailyTitle => 'आज का बोर्ड';

  @override
  String dailyBody(int minutes, int arrows, String chapter) {
    return '$minutes मिनट, $arrows तीर, $chapter के नियम। हर दिन एक नया बोर्ड — सिर्फ़ आपका।';
  }

  @override
  String dailyStreak(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days दिन का सिलसिला',
      one: '1 दिन का सिलसिला',
      zero: 'अभी कोई सिलसिला नहीं',
    );
    return '$_temp0';
  }

  @override
  String dailyBestToday(String time) {
    return 'आज का सबसे अच्छा $time';
  }

  @override
  String get dailyClearedToday => 'आज पूरा हुआ';

  @override
  String dailyNextInHours(int hours, int minutes) {
    return 'अगला बोर्ड $hoursघं $minutesमि में';
  }

  @override
  String dailyNextInMinutes(int minutes) {
    return 'अगला बोर्ड $minutesमि में';
  }

  @override
  String get dailyPlay => 'आज खेलें';

  @override
  String get dailyReplay => 'फिर से खेलें';

  @override
  String get dailyLevelTitle => 'आज का बोर्ड';

  @override
  String get dailyClearedBody => 'आज का बोर्ड हो गया। कल नए बोर्ड के लिए आइए।';

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
  String homeLevelsCleared(int cleared, int total) {
    return '$total में से $cleared पार';
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
  String get levelName81 => 'उस पार';

  @override
  String get levelName82 => 'महाभँवर';

  @override
  String get levelName83 => 'काँटों की दीवार';

  @override
  String get levelName84 => 'शीशमहल';

  @override
  String get levelName85 => 'घुमावदार सीढ़ी';

  @override
  String get levelName86 => 'दलदल';

  @override
  String get levelName87 => 'हज़ार फन';

  @override
  String get levelName88 => 'पाला';

  @override
  String get levelName89 => 'आँधी';

  @override
  String get levelName90 => 'लोहे का परदा';

  @override
  String get levelName91 => 'लंबी रात';

  @override
  String get levelName92 => 'टूटन बिंदु';

  @override
  String get levelName93 => 'तूफ़ान की आँख';

  @override
  String get levelName94 => 'जमी बर्फ़';

  @override
  String get levelName95 => 'अजगर की कुंडली';

  @override
  String get levelName96 => 'चोटी का जुनून';

  @override
  String get levelName97 => 'टूटते तारे';

  @override
  String get levelName98 => 'अंतहीन भूलभुलैया';

  @override
  String get levelName99 => 'बस एक क़दम';

  @override
  String get levelName100 => 'आख़िरी तीर';

  @override
  String get levelName101 => 'पहला कोना';

  @override
  String get levelName102 => 'छह पहलू';

  @override
  String get levelName103 => 'मोड़';

  @override
  String get levelName104 => 'शुरुआत';

  @override
  String get levelName105 => 'ईंट दर ईंट';

  @override
  String get levelName106 => 'सतह की बात';

  @override
  String get levelName107 => 'डिब्बे का किनारा';

  @override
  String get levelName108 => 'नुक्कड़';

  @override
  String get levelName109 => 'घनमूल';

  @override
  String get levelName110 => 'चपटा डिब्बा';

  @override
  String get levelName111 => 'शीश महल';

  @override
  String get levelName112 => 'प्रिज़्म';

  @override
  String get levelName113 => 'तिरछा कोण';

  @override
  String get levelName114 => 'आईना';

  @override
  String get levelName115 => 'निशाना';

  @override
  String get levelName116 => 'बहुरूपदर्शी';

  @override
  String get levelName117 => 'काँच का डिब्बा';

  @override
  String get levelName118 => 'मुड़ती रोशनी';

  @override
  String get levelName119 => 'परछाईं';

  @override
  String get levelName120 => 'आईने के पार';

  @override
  String get levelName121 => 'बंद डिब्बा';

  @override
  String get levelName122 => 'गुप्त अंक';

  @override
  String get levelName123 => 'तिजोरी';

  @override
  String get levelName124 => 'चाबियों का गुच्छा';

  @override
  String get levelName125 => 'ख़ज़ाने का संदूक';

  @override
  String get levelName126 => 'पहेली का डिब्बा';

  @override
  String get levelName127 => 'तहख़ाना';

  @override
  String get levelName128 => 'ताला-तोड़';

  @override
  String get levelName129 => 'मास्टर चाबी';

  @override
  String get levelName130 => 'ताला-कुंजी';

  @override
  String get levelName131 => 'काला डिब्बा';

  @override
  String get levelName132 => 'धुआँ और आईने';

  @override
  String get levelName133 => 'कोहरे की चादर';

  @override
  String get levelName134 => 'अँधेरा पहलू';

  @override
  String get levelName135 => 'अंधा मोड़';

  @override
  String get levelName136 => 'परछाईं का डिब्बा';

  @override
  String get levelName137 => 'रात की पाली';

  @override
  String get levelName138 => 'गहरे राज़';

  @override
  String get levelName139 => 'धुंध का घन';

  @override
  String get levelName140 => 'ग्रहण';

  @override
  String get levelName141 => 'एक जैसे दो';

  @override
  String get levelName142 => 'बँधे हुए';

  @override
  String get levelName143 => 'जोड़ी';

  @override
  String get levelName144 => 'जुड़वाँ चोटियाँ';

  @override
  String get levelName145 => 'गुत्थी';

  @override
  String get levelName146 => 'साथी';

  @override
  String get levelName147 => 'क़दम से क़दम';

  @override
  String get levelName148 => 'कंधे से कंधा';

  @override
  String get levelName149 => 'भरा घर';

  @override
  String get levelName150 => 'आख़िरी घन';

  @override
  String get levelName151 => 'तंग जगह';

  @override
  String get levelName152 => 'दबाव';

  @override
  String get levelName153 => 'कसाव';

  @override
  String get levelName154 => 'नज़दीकियाँ';

  @override
  String get levelName155 => 'ठसाठस';

  @override
  String get levelName156 => 'डिब्बाबंद';

  @override
  String get levelName157 => 'बोतल की गर्दन';

  @override
  String get levelName158 => 'धागा पिरोना';

  @override
  String get levelName159 => 'बाल-बाल बचे';

  @override
  String get levelName160 => 'कसमसाहट';

  @override
  String get levelName161 => 'भीड़ का वक़्त';

  @override
  String get levelName162 => 'ज़रा सी जगह';

  @override
  String get levelName163 => 'धक्का-मुक्की';

  @override
  String get levelName164 => 'चुटकी';

  @override
  String get levelName165 => 'लकड़ियों का जाम';

  @override
  String get levelName166 => 'रुका पहिया';

  @override
  String get levelName167 => 'खचाखच';

  @override
  String get levelName168 => 'खड़े-खड़े';

  @override
  String get levelName169 => 'लबालब';

  @override
  String get levelName170 => 'दबा-दबाया';

  @override
  String get levelName171 => 'दबाव में';

  @override
  String get levelName172 => 'पकड़';

  @override
  String get levelName173 => 'गुँथा हुआ';

  @override
  String get levelName174 => 'नपा-तुला';

  @override
  String get levelName175 => 'आख़िरी इंच';

  @override
  String get levelName176 => 'भीड़ भरा कमरा';

  @override
  String get levelName177 => 'छेद';

  @override
  String get levelName178 => 'हारमोनियम';

  @override
  String get levelName179 => 'प्रेशर कुकर';

  @override
  String get levelName180 => 'कसता फंदा';

  @override
  String get levelName181 => 'बाल भर';

  @override
  String get levelName182 => 'सुई की नोक';

  @override
  String get levelName183 => 'ताले का छेद';

  @override
  String get levelName184 => 'मुश्किल से';

  @override
  String get levelName185 => 'तंग गली';

  @override
  String get levelName186 => 'पिछली गली';

  @override
  String get levelName187 => 'बारीक फ़र्क़';

  @override
  String get levelName188 => 'छोटी लाइन';

  @override
  String get levelName189 => 'एक ही रास्ता';

  @override
  String get levelName190 => 'घिरते हुए';

  @override
  String get levelName191 => 'ज़ोर का दबाव';

  @override
  String get levelName192 => 'हीरा';

  @override
  String get levelName193 => 'गहरा दबाव';

  @override
  String get levelName194 => 'छलकता प्याला';

  @override
  String get levelName195 => 'पलड़ा';

  @override
  String get levelName196 => 'टूटने की कगार';

  @override
  String get levelName197 => 'आख़िरी कसाव';

  @override
  String get levelName198 => 'आख़िरी साँस';

  @override
  String get levelName199 => 'अंतिम दाँव';

  @override
  String get levelName200 => 'आख़िरी पड़ाव';

  @override
  String get levelName201 => 'डिब्बा खुला';

  @override
  String get levelName202 => 'पार्सल';

  @override
  String get levelName203 => 'पेटी';

  @override
  String get levelName204 => 'ईंट';

  @override
  String get levelName205 => 'जूतों का डिब्बा';

  @override
  String get levelName206 => 'माचिस';

  @override
  String get levelName207 => 'टिफ़िन';

  @override
  String get levelName208 => 'औज़ार पेटी';

  @override
  String get levelName209 => 'जादुई डिब्बा';

  @override
  String get levelName210 => 'किताबों की अलमारी';

  @override
  String get levelName211 => 'डोमिनो';

  @override
  String get levelName212 => 'ऊँची इमारत';

  @override
  String get levelName213 => 'गगनचुंबी';

  @override
  String get levelName214 => 'दराज़';

  @override
  String get levelName215 => 'अलमारी';

  @override
  String get levelName216 => 'कपड़ों की अलमारी';

  @override
  String get levelName217 => 'सूटकेस';

  @override
  String get levelName218 => 'संदूक';

  @override
  String get levelName219 => 'कंटेनर';

  @override
  String get levelName220 => 'माल';

  @override
  String get levelName221 => 'मालगाड़ी';

  @override
  String get levelName222 => 'समुद्री रास्ता';

  @override
  String get levelName223 => 'गोदाम';

  @override
  String get levelName224 => 'लदाई';

  @override
  String get levelName225 => 'फ़ोर्कलिफ़्ट';

  @override
  String get levelName226 => 'तख़्ता';

  @override
  String get levelName227 => 'ढेर';

  @override
  String get levelName228 => 'घर बदली';

  @override
  String get levelName229 => 'पैकिंग टेप';

  @override
  String get levelName230 => 'बुलबुले वाली पन्नी';

  @override
  String get levelName231 => 'डाक टिकट';

  @override
  String get levelName232 => 'तेज़ डाक';

  @override
  String get levelName233 => 'रातोंरात';

  @override
  String get levelName234 => 'डाकघर';

  @override
  String get levelName235 => 'वापस भेजो';

  @override
  String get levelName236 => 'नाज़ुक';

  @override
  String get levelName237 => 'यह तरफ़ ऊपर';

  @override
  String get levelName238 => 'सँभाल के';

  @override
  String get levelName239 => 'भारी बोझ';

  @override
  String get levelName240 => 'दूर की ढुलाई';

  @override
  String get levelName241 => 'शिलाखंड';

  @override
  String get levelName242 => 'मीनार';

  @override
  String get levelName243 => 'खंभा';

  @override
  String get levelName244 => 'स्तंभ';

  @override
  String get levelName245 => 'पगोडा';

  @override
  String get levelName246 => 'प्रकाशस्तंभ';

  @override
  String get levelName247 => 'घंटाघर';

  @override
  String get levelName248 => 'बड़ी फ़रमाइश';

  @override
  String get levelName249 => 'लंबा रास्ता';

  @override
  String get levelName250 => 'आख़िरी डिलीवरी';

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
    String _temp0 = intl.Intl.pluralLogic(
      lives,
      locale: localeName,
      other: '$lives जानें बचीं',
      one: '1 जान बची',
    );
    return '$_temp0';
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

  @override
  String hudArrowsLeft(int out, int total) {
    return '$total में से $out तीर बाहर';
  }

  @override
  String hudTimeLeft(String time) {
    return 'घड़ी पर $time बाक़ी';
  }

  @override
  String starsOfThree(int stars) {
    return '3 में से $stars तारे';
  }

  @override
  String boardLabel(int width, int height, int left, int total) {
    return 'पहेली बोर्ड, $width गुणा $height, $total में से $left तीर बाक़ी';
  }

  @override
  String arrowLabel(
    String direction,
    int length,
    int row,
    int column,
    String path,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      length,
      locale: localeName,
      other: '$length खाने',
      one: '1 खाना',
    );
    return '$direction की ओर तीर, $_temp0 लंबा, सिरा पंक्ति $row, स्तंभ $column पर। $path';
  }

  @override
  String get arrowPathClear => 'किनारे तक रास्ता साफ़ है।';

  @override
  String get arrowPathMirror => 'इसका रास्ता आईने से टकराकर मुड़ता है।';

  @override
  String arrowPathBlocked(int distance) {
    String _temp0 = intl.Intl.pluralLogic(
      distance,
      locale: localeName,
      other: '$distance खाने आगे एक और तीर है।',
      one: 'ठीक सामने एक और तीर है।',
    );
    return '$_temp0';
  }

  @override
  String get arrowHinted => 'संकेत: यह निकल सकता है।';

  @override
  String get arrowBumpedBefore =>
      'पहले टकरा चुका है; यहाँ फिर टकराने पर जान नहीं जाएगी।';

  @override
  String arrowHiddenLabel(int length, int row, int column) {
    String _temp0 = intl.Intl.pluralLogic(
      length,
      locale: localeName,
      other: '$length खाने',
      one: '1 खाना',
    );
    return 'छिपे सिरे वाला तीर, $_temp0 लंबा, पंक्ति $row, स्तंभ $column से। पास का कोई तीर निकलते ही दिखेगा कि यह किस ओर है। इसे छूने पर जान नहीं जाती: बोर्ड उस तीर की ओर इशारा करता है जो इसे खोलेगा।';
  }

  @override
  String arrowLocked(int number) {
    return 'ताला $number: यह चाबी $number के निकलने का भी इंतज़ार करता है।';
  }

  @override
  String arrowUnlocked(int number) {
    return 'ताला $number खुल गया है।';
  }

  @override
  String arrowKey(int number) {
    return 'चाबी $number: यह ताला $number खोलती है।';
  }

  @override
  String get arrowTethered =>
      'दूसरे तीर से बँधा है: दोनों साथ निकलते हैं, इसलिए दोनों के रास्ते साफ़ होने चाहिए।';

  @override
  String get arrowTapHint => 'इसे बाहर निकालें';

  @override
  String get directionUp => 'ऊपर';

  @override
  String get directionRight => 'दाएँ';

  @override
  String get directionDown => 'नीचे';

  @override
  String get directionLeft => 'बाएँ';

  @override
  String get levelCleared => 'पार';

  @override
  String get levelUpNext => 'अगला';

  @override
  String levelBestTime(String time) {
    return 'सबसे अच्छा समय $time';
  }

  @override
  String onboardStep(int step, int total) {
    return '$total में से चरण $step';
  }

  @override
  String get settingsMusicVolume => 'संगीत की आवाज़';

  @override
  String get settingsAccessibility => 'सुगम्यता';

  @override
  String get settingsReduceMotion => 'हरकत कम करें';

  @override
  String get settingsReduceMotionSubtitle =>
      'कोई झटका, छलाँग या कंफ़ेटी नहीं — तीर फिर भी चलते हैं';

  @override
  String get settingsExtraTime => 'अतिरिक्त समय';

  @override
  String get settingsExtraTimeSubtitle => 'हर लेवल पर दुगनी घड़ी';

  @override
  String get chapterName6 => 'क्यूब';

  @override
  String get chapterBlurb6 =>
      'एक क्यूब की छह सतहों पर तीर। हर सतह तक पहुँचने के लिए उसे घुमाओ।';

  @override
  String get introTitleCube => 'क्यूब';

  @override
  String get introBodyCube => 'एक क्यूब पर छह सतहें। घुमाकर हर सतह खेलो।';

  @override
  String get tutorialCube =>
      'क्यूब को उँगली से घुमाओ। सामने वाली सतह खेलो; बगल की सतह छुओ तो वो सामने आ जाएगी।';

  @override
  String get chapterName7 => 'शिकंजा';

  @override
  String get chapterBlurb7 => 'कसकर भरा क्यूब: हर सतह से एक साथ कम ही रास्ते।';

  @override
  String get tutorialSqueeze =>
      'हर सतह से एक साथ कम ही तीर निकल पाते हैं। जो निकल सके उसे ढूँढो, फिर अगला खुलेगा।';

  @override
  String get chapterName8 => 'बक्सा';

  @override
  String get chapterBlurb8 =>
      'अब क्यूब नहीं, बक्सा: तीन नाप की सतहें, पहले से बड़ी।';

  @override
  String get tutorialBox =>
      'यह ब्लॉक बक्सा है: इसकी सतहें तीन नाप की हैं। हर सतह देखने के लिए इसे घुमाओ।';

  @override
  String get cubeTurnLeft => 'बाईं सतह पर घुमाओ';

  @override
  String get cubeTurnRight => 'दाईं सतह पर घुमाओ';

  @override
  String get cubeTurnUp => 'ऊपर की सतह पर घुमाओ';

  @override
  String get cubeTurnDown => 'नीचे की सतह पर घुमाओ';

  @override
  String cubeFaceArrows(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'इस सतह पर $count तीर',
      one: 'इस सतह पर 1 तीर',
      zero: 'सतह साफ़',
    );
    return '$_temp0';
  }

  @override
  String cubeFacesClear(int cleared, int total) {
    return '$total में से $cleared सतहें साफ़';
  }

  @override
  String cubeMapLabel(int face, int cleared, int total) {
    return 'क्यूब, सामने सतह $face, $total में से $cleared सतहें साफ़';
  }

  @override
  String boardFaceLabel(int face, int width, int height, int left, int total) {
    return 'क्यूब की सतह $face, $width गुणा $height, $total में से $left तीर बाक़ी';
  }

  @override
  String get onboardRuleNoClock =>
      'कोई घड़ी नहीं — जितना चाहो समय लो (सेटिंग्स में घड़ी चालू कर सकते हो)';

  @override
  String get settingsGameplay => 'खेल';

  @override
  String get settingsRemoveTimeLimits => 'समय-सीमा हटाएँ';

  @override
  String get settingsRemoveTimeLimitsSubtitle =>
      'किसी लेवल पर घड़ी नहीं — अपनी रफ़्तार से खेलो';

  @override
  String homeResumeProgressUntimed(int out, int total) {
    return '$total में से $out तीर बाहर';
  }

  @override
  String resumeBodyUntimed(int out, int total) {
    return 'आपने यह लेवल $total में से $out तीर बाहर के साथ छोड़ा था।';
  }

  @override
  String get gamePausedBodyUntimed => 'साँस ले लीजिए। बोर्ड इंतज़ार करेगा।';
}
