/// Full curriculum: Hangul -> Essential Words -> Grammar (gated) -> Conversation.
library;

import '../models/curriculum.dart';

KCard _j(String id, String ko, String rom, String en, [String? note]) =>
    KCard(id: id, ko: ko, rom: rom, en: en, note: note);

KCard _syl(String id, String ko, String rom, String en, List<String> jamo,
        [String? note]) =>
    KCard(id: id, ko: ko, rom: rom, en: en, jamo: jamo, note: note);

KCard _w(String id, String ko, String rom, String en,
        {Example? ex, String? note}) =>
    KCard(id: id, ko: ko, rom: rom, en: en, example: ex, note: note);

KCard _s(String id, String ko, String rom, String en, List<String> parts,
        [String? note]) =>
    KCard(id: id, ko: ko, rom: rom, en: en, parts: parts, note: note);

// ---------------------------------------------------------------------------
// PATH 1 — HANGUL FOUNDATIONS
// ---------------------------------------------------------------------------

final LearningPath _hangul = LearningPath(
  id: 'p-hangul',
  title: 'Hangul Foundations',
  tagline: 'Read Korean letters in a week — from zero.',
  stage: PathStage.alphabet,
  color: 0xFF22C55E,
  units: [
    Unit(
      id: 'u-h1',
      title: 'First Sounds',
      focus: 'The 10 basic vowels and 9 basic consonants.',
      lessons: [
        Lesson(
          id: 'h-v1',
          title: 'Basic Vowels I',
          goal: 'Recognise and pronounce ㅏ ㅑ ㅓ ㅕ ㅗ',
          icon: '🅰️',
          mode: LessonMode.flashcards,
          cards: [
            _j('h-v1-1', 'ㅏ', 'a', "'a' as in father", 'Vertical stroke + short right arm.'),
            _j('h-v1-2', 'ㅑ', 'ya', "'ya' as in yard", "Two short arms = the extra 'y' sound."),
            _j('h-v1-3', 'ㅓ', 'eo', "'uh' as in duh", 'Arm points LEFT — sound goes back in the mouth.'),
            _j('h-v1-4', 'ㅕ', 'yeo', "'yeo' — y + uh", "Two left arms = 'y' + 'eo'."),
            _j('h-v1-5', 'ㅗ', 'o', "'o' as in go", 'Short arm points UP.'),
          ],
        ),
        Lesson(
          id: 'h-v2',
          title: 'Basic Vowels II',
          goal: 'Recognise and pronounce ㅛ ㅜ ㅠ ㅡ ㅣ',
          icon: '🔤',
          mode: LessonMode.flashcards,
          cards: [
            _j('h-v2-1', 'ㅛ', 'yo', "'yo' as in yoga", "Two up arms = 'y' + 'o'."),
            _j('h-v2-2', 'ㅜ', 'u', "'oo' as in moon", 'Short arm points DOWN.'),
            _j('h-v2-3', 'ㅠ', 'yu', "'yu' as in you", "Two down arms = 'y' + 'u'."),
            _j('h-v2-4', 'ㅡ', 'eu', "'eu' — flat, lips relaxed", "Say 'oo' with flat lips."),
            _j('h-v2-5', 'ㅣ', 'i', "'ee' as in see", 'A single vertical line.'),
          ],
        ),
        Lesson(
          id: 'h-c1',
          title: 'Basic Consonants I',
          goal: 'Read ㄱ ㄴ ㄷ ㄹ ㅁ',
          icon: '🅱️',
          mode: LessonMode.flashcards,
          cards: [
            _j('h-c1-1', 'ㄱ', 'g / k', "'g' as in gun", "Becomes a soft 'k' at the end of a block."),
            _j('h-c1-2', 'ㄴ', 'n', "'n' as in no", 'Shaped like a tongue touching the roof.'),
            _j('h-c1-3', 'ㄷ', 'd / t', "'d' as in door", "Soft 't' when it ends a syllable."),
            _j('h-c1-4', 'ㄹ', 'r / l', "between 'r' and 'l'", 'One symbol, two English sounds.'),
            _j('h-c1-5', 'ㅁ', 'm', "'m' as in mom", "A closed mouth — that is the 'm'."),
          ],
        ),
        Lesson(
          id: 'h-c2',
          title: 'Basic Consonants II',
          goal: 'Read ㅂ ㅅ ㅇ ㅈ ㅎ',
          icon: '🔡',
          mode: LessonMode.flashcards,
          cards: [
            _j('h-c2-1', 'ㅂ', 'b / p', "'b' as in bus", "Soft 'p' at the end of a block."),
            _j('h-c2-2', 'ㅅ', 's', "'s' as in sun", "Before ㅣ it sounds like 'see'."),
            _j('h-c2-3', 'ㅇ', 'silent / ng', "silent, or 'ng' at the end", "A silent placeholder on top, 'ng' as a final."),
            _j('h-c2-4', 'ㅈ', 'j', "'j' as in jam", 'Never aspirated — keep it soft.'),
            _j('h-c2-5', 'ㅎ', 'h', "'h' as in hat", 'The breathy letter.'),
          ],
        ),
        Lesson(
          id: 'h-c3',
          title: 'Aspirated Consonants',
          goal: 'Feel the puff of air: ㅊ ㅋ ㅌ ㅍ',
          icon: '💨',
          mode: LessonMode.quiz,
          cards: [
            _j('h-c3-1', 'ㅊ', 'ch', "'ch' as in chair", 'Aspirated version of ㅈ.'),
            _j('h-c3-2', 'ㅋ', 'k', "'k' with a puff of air", 'Aspirated version of ㄱ.'),
            _j('h-c3-3', 'ㅌ', 't', "'t' with a puff of air", 'Aspirated version of ㄷ.'),
            _j('h-c3-4', 'ㅍ', 'p', "'p' with a puff of air", 'Aspirated version of ㅂ.'),
            _j('h-c3-5', 'ㅎ', 'h', "'h' as in hat", 'Hold a paper in front of your mouth — it should move.'),
          ],
        ),
      ],
    ),
    Unit(
      id: 'u-h2',
      title: 'Syllable Blocks',
      focus: 'Korean letters stack into square blocks.',
      lessons: [
        Lesson(
          id: 'h-b1',
          title: 'Block Builder I',
          goal: 'Combine consonant + vowel into a block',
          icon: '🧱',
          mode: LessonMode.builder,
          cards: [
            _syl('h-b1-1', '가', 'ga', 'ga', ['ㄱ', 'ㅏ']),
            _syl('h-b1-2', '나', 'na', 'na', ['ㄴ', 'ㅏ']),
            _syl('h-b1-3', '다', 'da', 'da', ['ㄷ', 'ㅏ']),
            _syl('h-b1-4', '라', 'ra', 'ra / la', ['ㄹ', 'ㅏ']),
            _syl('h-b1-5', '마', 'ma', 'ma', ['ㅁ', 'ㅏ']),
            _syl('h-b1-6', '사', 'sa', 'sa', ['ㅅ', 'ㅏ']),
          ],
        ),
        Lesson(
          id: 'h-b2',
          title: 'Block Builder II',
          goal: 'Build blocks with other vowels',
          icon: '🏗️',
          mode: LessonMode.builder,
          cards: [
            _syl('h-b2-1', '서', 'seo', 'seo', ['ㅅ', 'ㅓ']),
            _syl('h-b2-2', '고', 'go', 'go', ['ㄱ', 'ㅗ']),
            _syl('h-b2-3', '누', 'nu', 'nu', ['ㄴ', 'ㅜ']),
            _syl('h-b2-4', '보', 'bo', 'bo', ['ㅂ', 'ㅗ']),
            _syl('h-b2-5', '하', 'ha', 'ha', ['ㅎ', 'ㅏ']),
            _syl('h-b2-6', '지', 'ji', 'ji', ['ㅈ', 'ㅣ']),
          ],
        ),
        Lesson(
          id: 'h-b3',
          title: 'Batchim (Final Sound)',
          goal: 'Read the third slot at the bottom of a block',
          icon: '⬇️',
          mode: LessonMode.quiz,
          cards: [
            _syl('h-b3-1', '김', 'gim', 'steam / the name Kim', ['ㄱ', 'ㅣ', 'ㅁ'], 'Consonant + vowel + consonant.'),
            _syl('h-b3-2', '물', 'mul', 'water', ['ㅁ', 'ㅜ', 'ㄹ']),
            _syl('h-b3-3', '밥', 'bap', 'cooked rice', ['ㅂ', 'ㅏ', 'ㅂ'], "The bottom ㅂ is pronounced 'p'."),
            _syl('h-b3-4', '책', 'chaek', 'book', ['ㅊ', 'ㅐ', 'ㄱ'], "The bottom ㄱ is pronounced 'k'."),
            _syl('h-b3-5', '눈', 'nun', 'eye / snow', ['ㄴ', 'ㅜ', 'ㄴ']),
            _syl('h-b3-6', '산', 'san', 'mountain', ['ㅅ', 'ㅏ', 'ㄴ']),
          ],
        ),
      ],
    ),
    Unit(
      id: 'u-h3',
      title: 'Tricky Sounds',
      focus: 'Doubles, compounds and the mastery test.',
      lessons: [
        Lesson(
          id: 'h-d1',
          title: 'Double Consonants',
          goal: 'Tense sounds: ㄲ ㄸ ㅃ ㅆ ㅉ',
          icon: '💪',
          mode: LessonMode.quiz,
          cards: [
            _j('h-d1-1', 'ㄲ', 'kk', "tense 'kk' — no air", 'Doubled ㄱ, tighter throat.'),
            _j('h-d1-2', 'ㄸ', 'tt', "tense 'tt' — no air", 'Doubled ㄷ.'),
            _j('h-d1-3', 'ㅃ', 'pp', "tense 'pp' — no air", 'Doubled ㅂ.'),
            _j('h-d1-4', 'ㅆ', 'ss', "tense 'ss'", 'Doubled ㅅ.'),
            _j('h-d1-5', 'ㅉ', 'jj', "tense 'jj'", 'Doubled ㅈ.'),
          ],
        ),
        Lesson(
          id: 'h-d2',
          title: 'Compound Vowels',
          goal: 'Read ㅐ ㅔ ㅖ ㅘ ㅝ ㅟ ㅢ',
          icon: '🌀',
          mode: LessonMode.quiz,
          cards: [
            _j('h-d2-1', 'ㅐ', 'ae', "'a' as in cat", 'ㅏ + ㅣ merged.'),
            _j('h-d2-2', 'ㅔ', 'e', "'e' as in bed", 'ㅓ + ㅣ merged.'),
            _j('h-d2-3', 'ㅖ', 'ye', "'ye' as in yes", 'ㅕ + ㅣ.'),
            _j('h-d2-4', 'ㅘ', 'wa', "'wa' as in want", 'ㅗ + ㅏ.'),
            _j('h-d2-5', 'ㅝ', 'wo', "'wo' as in won", 'ㅜ + ㅓ.'),
            _j('h-d2-6', 'ㅟ', 'wi', "'wi' as in we", 'ㅜ + ㅣ.'),
            _j('h-d2-7', 'ㅢ', 'ui', "'ui' / 'e'", "ㅡ + ㅣ. Often just 'e' in fast speech."),
          ],
        ),
        Lesson(
          id: 'h-test',
          title: 'Hangul Mastery Test',
          goal: 'Mixed test over every letter you learned',
          icon: '🏆',
          mode: LessonMode.test,
          cards: [
            _j('h-t-1', 'ㅇ', 'silent / ng', "silent, or 'ng' at the end"),
            _j('h-t-2', 'ㅓ', 'eo', "'uh' as in duh"),
            _j('h-t-3', 'ㅡ', 'eu', "'eu' — flat lips"),
            _j('h-t-4', 'ㅊ', 'ch', "'ch' as in chair"),
            _j('h-t-5', 'ㅌ', 't', "'t' with a puff of air"),
            _j('h-t-6', 'ㅆ', 'ss', "tense 'ss'"),
            _j('h-t-7', 'ㅟ', 'wi', "'wi' as in we"),
            _syl('h-t-8', '물', 'mul', 'water', ['ㅁ', 'ㅜ', 'ㄹ']),
            _syl('h-t-9', '하', 'ha', 'ha', ['ㅎ', 'ㅏ']),
            _syl('h-t-10', '책', 'chaek', 'book', ['ㅊ', 'ㅐ', 'ㄱ']),
          ],
        ),
      ],
    ),
  ],
);

// ---------------------------------------------------------------------------
// PATH 2 — ESSENTIAL WORDS
// ---------------------------------------------------------------------------

final LearningPath _words = LearningPath(
  id: 'p-words',
  title: 'Essential Words',
  tagline: 'The 200 words you actually need to survive.',
  stage: PathStage.vocabulary,
  color: 0xFF3B82F6,
  units: [
    Unit(
      id: 'u-w1',
      title: 'Survival Kit',
      focus: 'Say hello, thank you, and get help.',
      lessons: [
        Lesson(
          id: 'w-s1',
          title: 'First Five Words',
          goal: 'Greet and be polite instantly',
          icon: '👋',
          mode: LessonMode.flashcards,
          cards: [
            _w('w-s1-1', '안녕하세요', 'annyeonghaseyo', 'Hello (polite)',
                ex: Example('안녕하세요, 만나서 반갑습니다.', 'annyeonghaseyo, mannaseo bangapseumnida.', 'Hello, nice to meet you.')),
            _w('w-s1-2', '감사합니다', 'gamsahamnida', 'Thank you (formal)',
                ex: Example('도와주셔서 감사합니다.', 'dowajusyeoseo gamsahamnida.', 'Thank you for helping me.')),
            _w('w-s1-3', '죄송합니다', 'joesonghamnida', 'I am sorry (formal)'),
            _w('w-s1-4', '네', 'ne', 'Yes'),
            _w('w-s1-5', '아니요', 'aniyo', 'No'),
          ],
        ),
        Lesson(
          id: 'w-s2',
          title: 'Polite Reactions',
          goal: 'Respond naturally in conversation',
          icon: '🙏',
          mode: LessonMode.quiz,
          cards: [
            _w('w-s2-1', '괜찮아요', 'gwaenchanayo', "It's okay / I'm fine"),
            _w('w-s2-2', '미안해요', 'mianhaeyo', 'Sorry (everyday polite)'),
            _w('w-s2-3', '반갑습니다', 'bangapseumnida', 'Nice to meet you'),
            _w('w-s2-4', '주세요', 'juseyo', 'Please give me …', ex: Example('물 주세요.', 'mul juseyo.', 'Water, please.')),
            _w('w-s2-5', '실례합니다', 'sillyehamnida', 'Excuse me'),
            _w('w-s2-6', '도와주세요', 'dowajuseyo', 'Please help me'),
          ],
        ),
        Lesson(
          id: 'w-s3',
          title: 'When You Are Lost',
          goal: 'Keep a conversation alive as a beginner',
          icon: '🆘',
          mode: LessonMode.quiz,
          cards: [
            _w('w-s3-1', '모르겠어요', 'moreugesseoyo', "I don't understand / know"),
            _w('w-s3-2', '다시 말해주세요', 'dasi malhaejuseyo', 'Please say it again'),
            _w('w-s3-3', '천천히', 'cheoncheonhi', 'Slowly', ex: Example('천천히 말해주세요.', 'cheoncheonhi malhaejuseyo.', 'Please speak slowly.')),
            _w('w-s3-4', '한국어', 'hangugeo', 'The Korean language'),
            _w('w-s3-5', '영어', 'yeongeo', 'The English language'),
            _w('w-s3-6', '영어 할 수 있어요?', 'yeongeo hal su isseoyo', 'Can you speak English?'),
          ],
        ),
      ],
    ),
    Unit(
      id: 'u-w2',
      title: 'People',
      focus: 'Family and the people around you.',
      lessons: [
        Lesson(
          id: 'w-p1',
          title: 'Family',
          goal: 'Name your family members',
          icon: '👨‍👩‍👧',
          mode: LessonMode.flashcards,
          cards: [
            _w('w-p1-1', '가족', 'gajok', 'Family'),
            _w('w-p1-2', '어머니', 'eomeoni', 'Mother (polite)', note: '엄마 (eomma) = mum, casual.'),
            _w('w-p1-3', '아버지', 'abeoji', 'Father (polite)', note: '아빠 (appa) = dad, casual.'),
            _w('w-p1-4', '동생', 'dongsaeng', 'Younger sibling'),
            _w('w-p1-5', '언니', 'eonni', 'Older sister (said by a woman)'),
            _w('w-p1-6', '형', 'hyeong', 'Older brother (said by a man)'),
            _w('w-p1-7', '할머니', 'halmeoni', 'Grandmother'),
            _w('w-p1-8', '할아버지', 'harabeoji', 'Grandfather'),
          ],
        ),
        Lesson(
          id: 'w-p2',
          title: 'People & Jobs',
          goal: 'Talk about who someone is',
          icon: '🧑‍🏫',
          mode: LessonMode.quiz,
          cards: [
            _w('w-p2-1', '사람', 'saram', 'Person / people'),
            _w('w-p2-2', '친구', 'chingu', 'Friend'),
            _w('w-p2-3', '선생님', 'seonsaengnim', 'Teacher'),
            _w('w-p2-4', '학생', 'haksaeng', 'Student'),
            _w('w-p2-5', '의사', 'uisa', 'Doctor'),
            _w('w-p2-6', '회사원', 'hoesawon', 'Office worker'),
            _w('w-p2-7', '이름', 'ireum', 'Name'),
          ],
        ),
      ],
    ),
    Unit(
      id: 'u-w3',
      title: 'Food & Drink',
      focus: 'Order, eat and survive a restaurant.',
      lessons: [
        Lesson(
          id: 'w-f1',
          title: 'On The Table',
          goal: 'Core food words',
          icon: '🍚',
          mode: LessonMode.flashcards,
          cards: [
            _w('w-f1-1', '밥', 'bap', 'Cooked rice / a meal'),
            _w('w-f1-2', '물', 'mul', 'Water', ex: Example('물 주세요.', 'mul juseyo.', 'Water, please.')),
            _w('w-f1-3', '김치', 'gimchi', 'Kimchi'),
            _w('w-f1-4', '빵', 'ppang', 'Bread'),
            _w('w-f1-5', '우유', 'uyu', 'Milk'),
            _w('w-f1-6', '커피', 'keopi', 'Coffee'),
            _w('w-f1-7', '차', 'cha', 'Tea / a vehicle', note: 'Same sound, two meanings — context decides.'),
          ],
        ),
        Lesson(
          id: 'w-f2',
          title: 'Menu Words',
          goal: 'Read a menu without panicking',
          icon: '🍜',
          mode: LessonMode.match,
          cards: [
            _w('w-f2-1', '고기', 'gogi', 'Meat'),
            _w('w-f2-2', '생선', 'saengseon', 'Fish'),
            _w('w-f2-3', '계란', 'gyeran', 'Egg'),
            _w('w-f2-4', '라면', 'ramyeon', 'Instant noodles'),
            _w('w-f2-5', '아이스크림', 'aiseukeurim', 'Ice cream'),
            _w('w-f2-6', '맛있다', 'masitda', 'Delicious', ex: Example('이 음식은 맛있어요.', 'i eumsigeun masisseoyo.', 'This food is delicious.')),
          ],
        ),
      ],
    ),
    Unit(
      id: 'u-w4',
      title: 'Places & Things',
      focus: 'Move around the city.',
      lessons: [
        Lesson(
          id: 'w-l1',
          title: 'Places',
          goal: 'Ask where things are',
          icon: '📍',
          mode: LessonMode.quiz,
          cards: [
            _w('w-l1-1', '집', 'jip', 'House / home'),
            _w('w-l1-2', '학교', 'hakgyo', 'School'),
            _w('w-l1-3', '병원', 'byeongwon', 'Hospital'),
            _w('w-l1-4', '식당', 'sikdang', 'Restaurant'),
            _w('w-l1-5', '카페', 'kape', 'Café'),
            _w('w-l1-6', '공항', 'gonghang', 'Airport'),
            _w('w-l1-7', '화장실', 'hwajangsil', 'Toilet / restroom', ex: Example('화장실이 어디예요?', 'hwajangsiri eodiyeyo?', 'Where is the restroom?')),
          ],
        ),
        Lesson(
          id: 'w-l2',
          title: 'Everyday Things',
          goal: 'Objects you touch daily',
          icon: '🎒',
          mode: LessonMode.match,
          cards: [
            _w('w-l2-1', '책', 'chaek', 'Book'),
            _w('w-l2-2', '가방', 'gabang', 'Bag'),
            _w('w-l2-3', '휴대폰', 'hyudaepon', 'Mobile phone'),
            _w('w-l2-4', '컴퓨터', 'keompyuteo', 'Computer'),
            _w('w-l2-5', '의자', 'uija', 'Chair'),
            _w('w-l2-6', '문', 'mun', 'Door'),
          ],
        ),
      ],
    ),
    Unit(
      id: 'u-w5',
      title: 'Numbers & Time',
      focus: 'Two number systems + telling time.',
      lessons: [
        Lesson(
          id: 'w-n1',
          title: 'Native Numbers 1-10',
          goal: '하나 둘 셋 … used for counting things',
          icon: '1️⃣',
          mode: LessonMode.flashcards,
          cards: [
            _w('w-n1-1', '하나', 'hana', 'One'),
            _w('w-n1-2', '둘', 'dul', 'Two'),
            _w('w-n1-3', '셋', 'set', 'Three'),
            _w('w-n1-4', '넷', 'net', 'Four'),
            _w('w-n1-5', '다섯', 'daseot', 'Five'),
            _w('w-n1-6', '여섯', 'yeoseot', 'Six'),
            _w('w-n1-7', '일곱', 'ilgop', 'Seven'),
            _w('w-n1-8', '여덟', 'yeodeol', 'Eight'),
            _w('w-n1-9', '아홉', 'ahop', 'Nine'),
            _w('w-n1-10', '열', 'yeol', 'Ten'),
          ],
        ),
        Lesson(
          id: 'w-n2',
          title: 'Sino Numbers',
          goal: '일 이 삼 사 … used for dates, money, minutes',
          icon: '🔢',
          mode: LessonMode.quiz,
          cards: [
            _w('w-n2-1', '일', 'il', '1 (Sino)'),
            _w('w-n2-2', '이', 'i', '2 (Sino)'),
            _w('w-n2-3', '삼', 'sam', '3 (Sino)'),
            _w('w-n2-4', '사', 'sa', '4 (Sino)'),
            _w('w-n2-5', '오', 'o', '5 (Sino)'),
            _w('w-n2-6', '육', 'yuk', '6 (Sino)'),
            _w('w-n2-7', '칠', 'chil', '7 (Sino)'),
            _w('w-n2-8', '팔', 'pal', '8 (Sino)'),
            _w('w-n2-9', '구', 'gu', '9 (Sino)'),
            _w('w-n2-10', '십', 'sip', '10 (Sino)'),
          ],
        ),
        Lesson(
          id: 'w-t1',
          title: 'Time Words',
          goal: 'Talk about when',
          icon: '⏰',
          mode: LessonMode.quiz,
          cards: [
            _w('w-t1-1', '오늘', 'oneul', 'Today'),
            _w('w-t1-2', '어제', 'eoje', 'Yesterday'),
            _w('w-t1-3', '내일', 'naeil', 'Tomorrow'),
            _w('w-t1-4', '아침', 'achim', 'Morning / breakfast'),
            _w('w-t1-5', '점심', 'jeomsim', 'Noon / lunch'),
            _w('w-t1-6', '저녁', 'jeonyeok', 'Evening / dinner'),
            _w('w-t1-7', '지금', 'jigeum', 'Now', ex: Example('지금 몇 시예요?', 'jigeum myeot siyeyo?', 'What time is it now?')),
            _w('w-t1-8', '시간', 'sigan', 'Time / hour'),
          ],
        ),
      ],
    ),
    Unit(
      id: 'u-w6',
      title: 'Describing The World',
      focus: 'Colors, adjectives and verbs.',
      lessons: [
        Lesson(
          id: 'w-a1',
          title: 'Colors',
          goal: 'Describe what you see',
          icon: '🎨',
          mode: LessonMode.match,
          cards: [
            _w('w-a1-1', '빨간색', 'ppalgansaek', 'Red'),
            _w('w-a1-2', '파란색', 'paransaek', 'Blue'),
            _w('w-a1-3', '노란색', 'noransaek', 'Yellow'),
            _w('w-a1-4', '초록색', 'choroksaek', 'Green'),
            _w('w-a1-5', '검은색', 'geomeunsaek', 'Black'),
            _w('w-a1-6', '하얀색', 'hayansaek', 'White'),
          ],
        ),
        Lesson(
          id: 'w-a2',
          title: 'Core Adjectives',
          goal: 'Big, small, good, expensive …',
          icon: '📏',
          mode: LessonMode.quiz,
          cards: [
            _w('w-a2-1', '크다', 'keuda', 'To be big'),
            _w('w-a2-2', '작다', 'jakda', 'To be small'),
            _w('w-a2-3', '좋다', 'jota', 'To be good / nice'),
            _w('w-a2-4', '나쁘다', 'nappeuda', 'To be bad'),
            _w('w-a2-5', '예쁘다', 'yeppeuda', 'To be pretty'),
            _w('w-a2-6', '비싸다', 'bissada', 'To be expensive'),
            _w('w-a2-7', '싸다', 'ssada', 'To be cheap'),
            _w('w-a2-8', '바쁘다', 'bappeuda', 'To be busy'),
          ],
        ),
        Lesson(
          id: 'w-v1',
          title: 'Core Verbs',
          goal: 'The verbs you will use every day',
          icon: '🏃',
          mode: LessonMode.quiz,
          cards: [
            _w('w-v1-1', '가다', 'gada', 'To go'),
            _w('w-v1-2', '오다', 'oda', 'To come'),
            _w('w-v1-3', '먹다', 'meokda', 'To eat'),
            _w('w-v1-4', '마시다', 'masida', 'To drink'),
            _w('w-v1-5', '자다', 'jada', 'To sleep'),
            _w('w-v1-6', '보다', 'boda', 'To see / watch'),
            _w('w-v1-7', '만나다', 'mannada', 'To meet'),
            _w('w-v1-8', '공부하다', 'gongbuhada', 'To study'),
            _w('w-v1-9', '하다', 'hada', 'To do'),
            _w('w-v1-10', '있다', 'itda', 'To have / to exist'),
          ],
        ),
      ],
    ),
  ],
);

// ---------------------------------------------------------------------------
// PATH 3 — GRAMMAR ENGINE (gated)
// ---------------------------------------------------------------------------

final LearningPath _grammar = LearningPath(
  id: 'p-grammar',
  title: 'Grammar Engine',
  tagline: 'Unlocks when your word accuracy hits 70%.',
  stage: PathStage.grammar,
  color: 0xFFA855F7,
  unlock: const UnlockRule(
    pathId: 'p-words',
    completedLessons: 4,
    minAccuracy: 70,
    label: 'Finish 4 Essential Word lessons with ≥70% accuracy',
  ),
  units: [
    Unit(
      id: 'u-g1',
      title: 'To Be & Politeness',
      focus: 'The backbone of every Korean sentence.',
      lessons: [
        Lesson(
          id: 'g-b1',
          title: '이에요 / 예요 — To Be',
          goal: 'Say what things are',
          icon: '🟰',
          mode: LessonMode.sentences,
          cards: [
            _s('g-b1-1', '저는 학생이에요.', 'jeoneun haksaengieyo.', 'I am a student.', ['저는', '학생이에요.'], '이에요 after a consonant, 예요 after a vowel.'),
            _s('g-b1-2', '이것은 책이에요.', 'igeoseun chaeg-ieyo.', 'This is a book.', ['이것은', '책이에요.']),
            _s('g-b1-3', '그것은 물이에요.', 'geugeoseun mur-ieyo.', 'That is water.', ['그것은', '물이에요.']),
            _s('g-b1-4', '선생님이에요.', 'seonsaengnim-ieyo.', '(He/She) is a teacher.', ['선생님이에요.']),
            _s('g-b1-5', '친구예요.', 'chinguyeyo.', '(He/She) is a friend.', ['친구예요.'], '친구 ends in a vowel → 예요.'),
          ],
        ),
        Lesson(
          id: 'g-b2',
          title: 'Three Speech Levels',
          goal: 'Pick the right level of politeness',
          icon: '🎚️',
          mode: LessonMode.quiz,
          cards: [
            _w('g-b2-1', '감사합니다', 'gamsahamnida', 'Thank you — 합니다체 (formal)', note: 'News, speeches, bosses, strangers.'),
            _w('g-b2-2', '감사해요', 'gamsahaeyo', 'Thank you — 아요체 (polite)', note: 'The default safe level. Use this.'),
            _w('g-b2-3', '고마워', 'gomawo', 'Thanks — 반말 (casual)', note: 'Friends and kids only.'),
            _w('g-b2-4', '먹습니다', 'meokseumnida', 'I eat (formal)'),
            _w('g-b2-5', '먹어요', 'meogeoyo', 'I eat (polite)'),
            _w('g-b2-6', '먹어', 'meogeo', 'I eat (casual)'),
          ],
        ),
      ],
    ),
    Unit(
      id: 'u-g2',
      title: 'Particles',
      focus: 'Small words that glue a sentence together.',
      lessons: [
        Lesson(
          id: 'g-p1',
          title: '은 / 는 — Topic',
          goal: 'Mark what you are talking about',
          icon: '🏷️',
          mode: LessonMode.sentences,
          cards: [
            _s('g-p1-1', '저는 학생이에요.', 'jeoneun haksaengieyo.', 'As for me, I am a student.', ['저는', '학생이에요.'], '는 after a vowel, 은 after a consonant.'),
            _s('g-p1-2', '김치는 맛있어요.', 'gimchineun masisseoyo.', 'Kimchi is delicious.', ['김치는', '맛있어요.']),
            _s('g-p1-3', '이것은 커피예요.', 'igeoseun keopiyeyo.', 'This is coffee.', ['이것은', '커피예요.']),
            _s('g-p1-4', '오늘은 바빠요.', 'oneureun bappayo.', 'Today (I) am busy.', ['오늘은', '바빠요.']),
          ],
        ),
        Lesson(
          id: 'g-p2',
          title: '이 / 가 & 을 / 를',
          goal: 'Subject and object markers',
          icon: '🎯',
          mode: LessonMode.sentences,
          cards: [
            _s('g-p2-1', '친구가 좋아요.', 'chinguga joayo.', 'My friend is nice.', ['친구가', '좋아요.'], '가 marks the subject — vowel ending.'),
            _s('g-p2-2', '물이 있어요.', 'muri isseoyo.', 'There is water.', ['물이', '있어요.']),
            _s('g-p2-3', '밥을 먹어요.', 'babeul meogeoyo.', 'I eat rice.', ['밥을', '먹어요.'], '을 marks the object — consonant ending.'),
            _s('g-p2-4', '커피를 마셔요.', 'keopireul masyeoyo.', 'I drink coffee.', ['커피를', '마셔요.']),
            _s('g-p2-5', '한국어를 공부해요.', 'hangugeoreul gongbuhaeyo.', 'I study Korean.', ['한국어를', '공부해요.']),
          ],
        ),
        Lesson(
          id: 'g-p3',
          title: '에, 에서 & Other Particles',
          goal: 'Place, time, and, only, too',
          icon: '🧩',
          mode: LessonMode.sentences,
          cards: [
            _s('g-p3-1', '학교에 가요.', 'hakgyoe gayo.', 'I go to school.', ['학교에', '가요.'], '에 = direction / time point.'),
            _s('g-p3-2', '집에서 공부해요.', 'jibeseo gongbuhaeyo.', 'I study at home.', ['집에서', '공부해요.'], '에서 = where an action happens.'),
            _s('g-p3-3', '저도 학생이에요.', 'jeodo haksaengieyo.', 'I am a student too.', ['저도', '학생이에요.'], '도 = also.'),
            _s('g-p3-4', '물만 마셔요.', 'mulman masyeoyo.', 'I only drink water.', ['물만', '마셔요.'], '만 = only.'),
            _s('g-p3-5', '빵과 우유', 'ppang-gwa uyu', 'Bread and milk', ['빵과', '우유'], '과 (consonant) / 와 (vowel) = and.'),
            _s('g-p3-6', '친구의 책', 'chingu-ui chaek', "My friend's book", ['친구의', '책'], "의 = possessive 'of'."),
          ],
        ),
      ],
    ),
    Unit(
      id: 'u-g3',
      title: 'Verbs In Motion',
      focus: 'Tense, wants and connectors.',
      lessons: [
        Lesson(
          id: 'g-v1',
          title: 'Present: 아요 / 어요',
          goal: 'Conjugate any verb in the polite present',
          icon: '⏳',
          mode: LessonMode.sentences,
          cards: [
            _s('g-v1-1', '가요', 'gayo', '(I) go — 가다 → 가요', ['저는', '학교에', '가요.'], 'Vowel ㅏ → 아요, but 가다 is irregularly just 가요.'),
            _s('g-v1-2', '먹어요', 'meogeoyo', '(I) eat — 먹다 → 먹어요', ['저는', '밥을', '먹어요.'], 'Vowel ㅓ/ㅡ/ㅣ → 어요.'),
            _s('g-v1-3', '마셔요', 'masyeoyo', '(I) drink — 마시다 → 마셔요', ['물을', '마셔요.'], 'ㅣ + 어요 contract to 여요.'),
            _s('g-v1-4', '공부해요', 'gongbuhaeyo', '(I) study — 공부하다 → 공부해요', ['한국어를', '공부해요.'], '하다 → 해요. The most useful rule in Korean.'),
            _s('g-v1-5', '봐요', 'bwayo', '(I) see — 보다 → 봐요', ['영화를', '봐요.'], 'ㅗ + 아요 contract to 와요.'),
          ],
        ),
        Lesson(
          id: 'g-v2',
          title: 'Past & Future',
          goal: '았/었어요 and (으)ㄹ 거예요',
          icon: '🔮',
          mode: LessonMode.sentences,
          cards: [
            _s('g-v2-1', '먹었어요', 'meogeosseoyo', '(I) ate — 먹다 → 먹었어요', ['어제', '밥을', '먹었어요.'], 'Add 았/었 + 어요.'),
            _s('g-v2-2', '갔어요', 'gasseoyo', '(I) went — 가다 → 갔어요', ['학교에', '갔어요.']),
            _s('g-v2-3', '공부했어요', 'gongbuhaesseoyo', '(I) studied', ['오늘', '공부했어요.']),
            _s('g-v2-4', '갈 거예요', 'gal geoyeyo', '(I) will go', ['내일', '학교에', '갈 거예요.'], 'Verb stem + (으)ㄹ 거예요.'),
            _s('g-v2-5', '먹을 거예요', 'meogeul geoyeyo', '(I) will eat', ['점심을', '먹을 거예요.']),
          ],
        ),
        Lesson(
          id: 'g-v3',
          title: 'Want, Can & Connectors',
          goal: '고 싶다, (으)ㄹ 수 있다, 고 / 지만 / 그래서',
          icon: '🔗',
          mode: LessonMode.sentences,
          cards: [
            _s('g-v3-1', '가고 싶어요', 'gago sipeoyo', 'I want to go', ['저는', '한국에', '가고', '싶어요.'], 'Verb stem + 고 싶다.'),
            _s('g-v3-2', '먹을 수 있어요', 'meogeul su isseoyo', 'I can eat it', ['저는', '김치를', '먹을 수', '있어요.'], '(으)ㄹ 수 있다 = can.'),
            _s('g-v3-3', '밥을 먹고 학교에 가요', 'babeul meokgo hakgyoe gayo', 'I eat and go to school', ['밥을', '먹고', '학교에', '가요.'], '고 = and (actions in sequence).'),
            _s('g-v3-4', '비싸지만 좋아요', 'bissajiman joayo', 'It is expensive but good', ['비싸지만', '좋아요.'], '지만 = but.'),
            _s('g-v3-5', '바빠서 못 갔어요', 'bappaseo mot gasseoyo', "I was busy so I couldn't go", ['바빠서', '못', '갔어요.'], '아서/어서 = because / so.'),
          ],
        ),
        Lesson(
          id: 'g-test',
          title: 'Grammar Checkpoint',
          goal: 'Mixed test across particles and tenses',
          icon: '📝',
          mode: LessonMode.test,
          cards: [
            _s('g-t-1', '저는 학생이에요.', 'jeoneun haksaengieyo.', 'I am a student.', ['저는', '학생이에요.']),
            _s('g-t-2', '밥을 먹어요.', 'babeul meogeoyo.', 'I eat rice.', ['밥을', '먹어요.']),
            _s('g-t-3', '학교에 가요.', 'hakgyoe gayo.', 'I go to school.', ['학교에', '가요.']),
            _s('g-t-4', '집에서 공부해요.', 'jibeseo gongbuhaeyo.', 'I study at home.', ['집에서', '공부해요.']),
            _s('g-t-5', '어제 물을 마셨어요.', 'eoje mureul masyeosseoyo.', 'Yesterday I drank water.', ['어제', '물을', '마셨어요.']),
            _s('g-t-6', '한국어를 배우고 싶어요.', 'hangugeoreul baeugo sipeoyo.', 'I want to learn Korean.', ['한국어를', '배우고', '싶어요.']),
          ],
        ),
      ],
    ),
  ],
);

// ---------------------------------------------------------------------------
// PATH 4 — REAL CONVERSATIONS
// ---------------------------------------------------------------------------

final LearningPath _talk = LearningPath(
  id: 'p-talk',
  title: 'Real Conversations',
  tagline: 'Whole sentences you can use today.',
  stage: PathStage.conversation,
  color: 0xFFF59E0B,
  unlock: const UnlockRule(
    pathId: 'p-grammar',
    completedLessons: 3,
    minAccuracy: 70,
    label: 'Finish 3 Grammar Engine lessons with ≥70% accuracy',
  ),
  units: [
    Unit(
      id: 'u-t1',
      title: 'Meeting People',
      focus: 'Introduce yourself properly.',
      lessons: [
        Lesson(
          id: 't-m1',
          title: 'Introductions',
          goal: 'Name, country, first impressions',
          icon: '🤝',
          mode: LessonMode.sentences,
          cards: [
            _s('t-m1-1', '이름이 뭐예요?', 'ireumi mwoyeyo?', 'What is your name?', ['이름이', '뭐예요?']),
            _s('t-m1-2', '저는 민수예요.', 'jeoneun minsuyeyo.', 'I am Minsu.', ['저는', '민수예요.']),
            _s('t-m1-3', '어디에서 왔어요?', 'eodieseo wasseoyo?', 'Where are you from?', ['어디에서', '왔어요?']),
            _s('t-m1-4', '저는 영국에서 왔어요.', 'jeoneun yeonggugeseo wasseoyo.', 'I am from the UK.', ['저는', '영국에서', '왔어요.']),
            _s('t-m1-5', '만나서 반갑습니다.', 'mannaseo bangapseumnida.', 'Nice to meet you.', ['만나서', '반갑습니다.']),
          ],
        ),
      ],
    ),
    Unit(
      id: 'u-t2',
      title: 'Daily Life',
      focus: 'Routines, time and small talk.',
      lessons: [
        Lesson(
          id: 't-d1',
          title: 'My Day',
          goal: 'Describe a routine',
          icon: '🌅',
          mode: LessonMode.sentences,
          cards: [
            _s('t-d1-1', '아침에 뭐 해요?', 'achime mwo haeyo?', 'What do you do in the morning?', ['아침에', '뭐', '해요?']),
            _s('t-d1-2', '저는 아침을 먹어요.', 'jeoneun achimeul meogeoyo.', 'I eat breakfast.', ['저는', '아침을', '먹어요.']),
            _s('t-d1-3', '지금 몇 시예요?', 'jigeum myeot siyeyo?', 'What time is it now?', ['지금', '몇', '시예요?']),
            _s('t-d1-4', '오늘 날씨가 좋아요.', 'oneul nalssiga joayo.', 'The weather is nice today.', ['오늘', '날씨가', '좋아요.']),
            _s('t-d1-5', '저는 한국어를 매일 공부해요.', 'jeoneun hangugeoreul maeil gongbuhaeyo.', 'I study Korean every day.', ['저는', '한국어를', '매일', '공부해요.']),
          ],
        ),
      ],
    ),
    Unit(
      id: 'u-t3',
      title: 'Out & About',
      focus: 'Cafés, shops and directions.',
      lessons: [
        Lesson(
          id: 't-o1',
          title: 'Ordering & Shopping',
          goal: 'Buy things without switching to English',
          icon: '☕',
          mode: LessonMode.sentences,
          cards: [
            _s('t-o1-1', '이거 주세요.', 'igeo juseyo.', 'This one, please.', ['이거', '주세요.']),
            _s('t-o1-2', '얼마예요?', 'eolmayeyo?', 'How much is it?', ['얼마예요?']),
            _s('t-o1-3', '메뉴판 주세요.', 'menyupan juseyo.', 'The menu, please.', ['메뉴판', '주세요.']),
            _s('t-o1-4', '계산서 주세요.', 'gyesanseo juseyo.', 'The bill, please.', ['계산서', '주세요.']),
            _s('t-o1-5', '화장실이 어디예요?', 'hwajangsiri eodiyeyo?', 'Where is the restroom?', ['화장실이', '어디예요?']),
          ],
        ),
        Lesson(
          id: 't-final',
          title: 'Final Boss Test',
          goal: 'Letters + words + grammar, all mixed',
          icon: '🐉',
          mode: LessonMode.test,
          cards: [
            _j('t-f-1', 'ㅓ', 'eo', "'uh' as in duh"),
            _w('t-f-2', '물', 'mul', 'Water'),
            _w('t-f-3', '학교', 'hakgyo', 'School'),
            _w('t-f-4', '감사합니다', 'gamsahamnida', 'Thank you (formal)'),
            _w('t-f-5', '먹다', 'meokda', 'To eat'),
            _s('t-f-6', '저는 학생이에요.', 'jeoneun haksaengieyo.', 'I am a student.', ['저는', '학생이에요.']),
            _s('t-f-7', '밥을 먹어요.', 'babeul meogeoyo.', 'I eat rice.', ['밥을', '먹어요.']),
            _s('t-f-8', '이거 주세요.', 'igeo juseyo.', 'This one, please.', ['이거', '주세요.']),
            _s('t-f-9', '어디에서 왔어요?', 'eodieseo wasseoyo?', 'Where are you from?', ['어디에서', '왔어요?']),
            _s('t-f-10', '학교에 가요.', 'hakgyoe gayo.', 'I go to school.', ['학교에', '가요.']),
          ],
        ),
      ],
    ),
  ],
);

// ---------------------------------------------------------------------------
// Lookups
// ---------------------------------------------------------------------------

final List<LearningPath> paths = [_hangul, _words, _grammar, _talk];

final List<Lesson> allLessons =
    paths.expand((p) => p.units).expand((u) => u.lessons).toList();

final Map<String, String> lessonPathId = {
  for (final p in paths)
    for (final u in p.units)
      for (final l in u.lessons) l.id: p.id,
};

final List<KCard> allCards = allLessons.expand((l) => l.cards).toList();

final Map<String, KCard> cardById = {for (final c in allCards) c.id: c};

Lesson? getLesson(String id) => allLessons.where((l) => l.id == id).firstOrNull;

LearningPath? getPath(String id) => paths.where((p) => p.id == id).firstOrNull;

/// Cards from the same unit — used to build plausible wrong options.
List<KCard> siblingCards(String lessonId) {
  for (final path in paths) {
    for (final unit in path.units) {
      if (unit.lessons.any((l) => l.id == lessonId)) {
        final all = unit.lessons.expand((l) => l.cards).toList();
        if (all.length > 4) return all;
        return path.units.expand((u) => u.lessons).expand((l) => l.cards).toList();
      }
    }
  }
  return allCards;
}

class HangulGroup {
  final String group;
  final List<String> items;
  const HangulGroup(this.group, this.items);
}

const List<HangulGroup> hangulTable = [
  HangulGroup('Basic vowels', ['ㅏ a', 'ㅑ ya', 'ㅓ eo', 'ㅕ yeo', 'ㅗ o', 'ㅛ yo', 'ㅜ u', 'ㅠ yu', 'ㅡ eu', 'ㅣ i']),
  HangulGroup('Compound vowels', ['ㅐ ae', 'ㅔ e', 'ㅒ yae', 'ㅖ ye', 'ㅘ wa', 'ㅙ wae', 'ㅚ oe', 'ㅝ wo', 'ㅞ we', 'ㅟ wi', 'ㅢ ui']),
  HangulGroup('Basic consonants', ['ㄱ g', 'ㄴ n', 'ㄷ d', 'ㄹ r/l', 'ㅁ m', 'ㅂ b', 'ㅅ s', 'ㅇ -/ng', 'ㅈ j', 'ㅊ ch', 'ㅋ k', 'ㅌ t', 'ㅍ p', 'ㅎ h']),
  HangulGroup('Double consonants', ['ㄲ kk', 'ㄸ tt', 'ㅃ pp', 'ㅆ ss', 'ㅉ jj']),
];
