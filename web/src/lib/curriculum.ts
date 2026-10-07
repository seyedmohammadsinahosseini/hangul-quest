/**
 * Hangul Quest — full curriculum.
 * Everything is authored in English, teaching Korean from absolute zero.
 *
 * Path 1 (alphabet) -> Path 2 (essential words) -> Path 3 (grammar, gated by
 * a 70% mastery rule) -> Path 4 (real sentences).
 */

export type Card = {
  id: string;
  ko: string;
  rom: string;
  en: string;
  note?: string;
  /** jamo pieces, used by the Syllable Builder game */
  jamo?: string[];
  /** ordered word chunks, used by the Sentence Builder game */
  parts?: string[];
  example?: { ko: string; rom: string; en: string };
};

export type LessonMode =
  | "flashcards"
  | "quiz"
  | "builder"
  | "match"
  | "sentences"
  | "test";

export type Lesson = {
  id: string;
  title: string;
  goal: string;
  icon: string;
  mode: LessonMode;
  passScore: number;
  cards: Card[];
};

export type Unit = {
  id: string;
  title: string;
  focus: string;
  lessons: Lesson[];
};

export type PathStage = "alphabet" | "vocabulary" | "grammar" | "conversation";

export type UnlockRule = {
  pathId: string;
  completedLessons: number;
  minAccuracy: number;
  label: string;
};

export type LearningPath = {
  id: string;
  title: string;
  tagline: string;
  stage: PathStage;
  color: string;
  unlock?: UnlockRule;
  units: Unit[];
};

const j = (
  id: string,
  ko: string,
  rom: string,
  en: string,
  note?: string,
): Card => ({ id, ko, rom, en, note });

const syl = (
  id: string,
  ko: string,
  rom: string,
  en: string,
  jamo: string[],
  note?: string,
): Card => ({ id, ko, rom, en, note, jamo });

const w = (
  id: string,
  ko: string,
  rom: string,
  en: string,
  example?: Card["example"],
  note?: string,
): Card => ({ id, ko, rom, en, example, note });

const s = (
  id: string,
  ko: string,
  rom: string,
  en: string,
  parts: string[],
  note?: string,
): Card => ({ id, ko, rom, en, parts, note });

export const HINT_COST = { small: 6, medium: 12, large: 18 } as const;
export const XP_PER_CORRECT = 1;
export const DEFAULT_PASS_SCORE = 70;

/* ------------------------------------------------------------------ */
/* PATH 1 — HANGUL FOUNDATIONS                                         */
/* ------------------------------------------------------------------ */

const hangul: LearningPath = {
  id: "p-hangul",
  title: "Hangul Foundations",
  tagline: "Read Korean letters in a week — from zero.",
  stage: "alphabet",
  color: "#22c55e",
  units: [
    {
      id: "u-h1",
      title: "First Sounds",
      focus: "The 10 basic vowels and 9 basic consonants.",
      lessons: [
        {
          id: "h-v1",
          title: "Basic Vowels I",
          goal: "Recognise and pronounce ㅏ ㅑ ㅓ ㅕ ㅗ",
          icon: "🅰️",
          mode: "flashcards",
          passScore: 70,
          cards: [
            j("h-v1-1", "ㅏ", "a", "'a' as in father", "Vertical stroke + short right arm."),
            j("h-v1-2", "ㅑ", "ya", "'ya' as in yard", "Two short arms = the extra 'y' sound."),
            j("h-v1-3", "ㅓ", "eo", "'uh' as in duh", "Arm points LEFT — sound goes back in the mouth."),
            j("h-v1-4", "ㅕ", "yeo", "'yeo' — y + uh", "Two left arms = 'y' + 'eo'."),
            j("h-v1-5", "ㅗ", "o", "'o' as in go", "Short arm points UP."),
          ],
        },
        {
          id: "h-v2",
          title: "Basic Vowels II",
          goal: "Recognise and pronounce ㅛ ㅜ ㅠ ㅡ ㅣ",
          icon: "🔤",
          mode: "flashcards",
          passScore: 70,
          cards: [
            j("h-v2-1", "ㅛ", "yo", "'yo' as in yoga", "Two up arms = 'y' + 'o'."),
            j("h-v2-2", "ㅜ", "u", "'oo' as in moon", "Short arm points DOWN."),
            j("h-v2-3", "ㅠ", "yu", "'yu' as in_YUV", "Two down arms = 'y' + 'u'."),
            j("h-v2-4", "ㅡ", "eu", "'eu' — flat, lips relaxed", "Say 'oo' with flat lips."),
            j("h-v2-5", "ㅣ", "i", "'ee' as in see", "A single vertical line."),
          ],
        },
        {
          id: "h-c1",
          title: "Basic Consonants I",
          goal: "Read ㄱ ㄴ ㄷ ㄹ ㅁ",
          icon: "🅱️",
          mode: "flashcards",
          passScore: 70,
          cards: [
            j("h-c1-1", "ㄱ", "g / k", "'g' as in gun", "Becomes a soft 'k' at the end of a block."),
            j("h-c1-2", "ㄴ", "n", "'n' as in no", "Shaped like a tongue touching the roof."),
            j("h-c1-3", "ㄷ", "d / t", "'d' as in door", "Soft 't' when it ends a syllable."),
            j("h-c1-4", "ㄹ", "r / l", "between 'r' and 'l'", "One symbol, two English sounds."),
            j("h-c1-5", "ㅁ", "m", "'m' as in mom", "A closed mouth — that is the 'm'."),
          ],
        },
        {
          id: "h-c2",
          title: "Basic Consonants II",
          goal: "Read ㅂ ㅅ ㅇ ㅈ ㅎ",
          icon: "🔡",
          mode: "flashcards",
          passScore: 70,
          cards: [
            j("h-c2-1", "ㅂ", "b / p", "'b' as in bus", "Soft 'p' at the end of a block."),
            j("h-c2-2", "ㅅ", "s", "'s' as in sun", "Before ㅣ it sounds like 'see'."),
            j("h-c2-3", "ㅇ", "silent / ng", "silent, or 'ng' at the end", "A silent placeholder on top, 'ng' as a final."),
            j("h-c2-4", "ㅈ", "j", "'j' as in jam", "Never aspirated — keep it soft."),
            j("h-c2-5", "ㅎ", "h", "'h' as in hat", "The breathy letter."),
          ],
        },
        {
          id: "h-c3",
          title: "Aspirated Consonants",
          goal: "Feel the puff of air: ㅊ ㅋ ㅌ ㅍ",
          icon: "💨",
          mode: "quiz",
          passScore: 70,
          cards: [
            j("h-c3-1", "ㅊ", "ch", "'ch' as in chair", "Aspirated version of ㅈ."),
            j("h-c3-2", "ㅋ", "k", "'k' with a puff of air", "Aspirated version of ㄱ."),
            j("h-c3-3", "ㅌ", "t", "'t' with a puff of air", "Aspirated version of ㄷ."),
            j("h-c3-4", "ㅍ", "p", "'p' with a puff of air", "Aspirated version of ㅂ."),
            j("h-c3-5", "ㅎ", "h", "'h' as in hat", "Hold a paper in front of your mouth — it should move."),
          ],
        },
      ],
    },
    {
      id: "u-h2",
      title: "Syllable Blocks",
      focus: "Korean letters stack into square blocks.",
      lessons: [
        {
          id: "h-b1",
          title: "Block Builder I",
          goal: "Combine consonant + vowel into a block",
          icon: "🧱",
          mode: "builder",
          passScore: 70,
          cards: [
            syl("h-b1-1", "가", "ga", "ga", ["ㄱ", "ㅏ"]),
            syl("h-b1-2", "나", "na", "na", ["ㄴ", "ㅏ"]),
            syl("h-b1-3", "다", "da", "da", ["ㄷ", "ㅏ"]),
            syl("h-b1-4", "라", "ra", "ra / la", ["ㄹ", "ㅏ"]),
            syl("h-b1-5", "마", "ma", "ma", ["ㅁ", "ㅏ"]),
            syl("h-b1-6", "사", "sa", "sa", ["ㅅ", "ㅏ"]),
          ],
        },
        {
          id: "h-b2",
          title: "Block Builder II",
          goal: "Build blocks with other vowels",
          icon: "🏗️",
          mode: "builder",
          passScore: 70,
          cards: [
            syl("h-b2-1", "서", "seo", "seo", ["ㅅ", "ㅓ"]),
            syl("h-b2-2", "고", "go", "go", ["ㄱ", "ㅗ"]),
            syl("h-b2-3", "누", "nu", "nu", ["ㄴ", "ㅜ"]),
            syl("h-b2-4", "보", "bo", "bo", ["ㅂ", "ㅗ"]),
            syl("h-b2-5", "하", "ha", "ha", ["ㅎ", "ㅏ"]),
            syl("h-b2-6", "지", "ji", "ji", ["ㅈ", "ㅣ"]),
          ],
        },
        {
          id: "h-b3",
          title: "Batchim (Final Sound)",
          goal: "Read the third slot at the bottom of a block",
          icon: "⬇️",
          mode: "quiz",
          passScore: 70,
          cards: [
            syl("h-b3-1", "김", "gim", "steam / the name Kim", ["ㄱ", "ㅣ", "ㅁ"], "Consonant + vowel + consonant."),
            syl("h-b3-2", "물", "mul", "water", ["ㅁ", "ㅜ", "ㄹ"]),
            syl("h-b3-3", "밥", "bap", "cooked rice", ["ㅂ", "ㅏ", "ㅂ"], "The bottom ㅂ is pronounced 'p'."),
            syl("h-b3-4", "책", "chaek", "book", ["ㅊ", "ㅐ", "ㄱ"], "The bottom ㄱ is pronounced 'k'."),
            syl("h-b3-5", "눈", "nun", "eye / snow", ["ㄴ", "ㅜ", "ㄴ"]),
            syl("h-b3-6", "산", "san", "mountain", ["ㅅ", "ㅏ", "ㄴ"]),
          ],
        },
      ],
    },
    {
      id: "u-h3",
      title: "Tricky Sounds",
      focus: "Doubles, compounds and the mastery test.",
      lessons: [
        {
          id: "h-d1",
          title: "Double Consonants",
          goal: "Tense sounds: ㄲ ㄸ ㅃ ㅆ ㅉ",
          icon: "💪",
          mode: "quiz",
          passScore: 70,
          cards: [
            j("h-d1-1", "ㄲ", "kk", "tense 'kk' — no air", "Doubled ㄱ, tighter throat."),
            j("h-d1-2", "ㄸ", "tt", "tense 'tt' — no air", "Doubled ㄷ."),
            j("h-d1-3", "ㅃ", "pp", "tense 'pp' — no air", "Doubled ㅂ."),
            j("h-d1-4", "ㅆ", "ss", "tense 'ss'", "Doubled ㅅ."),
            j("h-d1-5", "ㅉ", "jj", "tense 'jj'", "Doubled ㅈ."),
          ],
        },
        {
          id: "h-d2",
          title: "Compound Vowels",
          goal: "Read ㅐ ㅔ ㅖ ㅘ ㅝ ㅚ ㅟ ㅢ",
          icon: "🌀",
          mode: "quiz",
          passScore: 70,
          cards: [
            j("h-d2-1", "ㅐ", "ae", "'a' as in cat", "ㅏ + ㅣ merged."),
            j("h-d2-2", "ㅔ", "e", "'e' as in bed", "ㅓ + ㅣ merged."),
            j("h-d2-3", "ㅖ", "ye", "'ye' as in yes", "ㅕ + ㅣ."),
            j("h-d2-4", "ㅘ", "wa", "'wa' as in want", "ㅗ + ㅏ."),
            j("h-d2-5", "ㅝ", "wo", "'wo' as in won", "ㅜ + ㅓ."),
            j("h-d2-6", "ㅟ", "wi", "'wi' as in we", "ㅜ + ㅣ."),
            j("h-d2-7", "ㅢ", "ui", "'ui' / 'e'", "ㅡ + ㅣ. Often just 'e' in fast speech."),
          ],
        },
        {
          id: "h-test",
          title: "Hangul Mastery Test",
          goal: "Mixed test over every letter you learned",
          icon: "🏆",
          mode: "test",
          passScore: 70,
          cards: [
            j("h-t-1", "ㅇ", "silent / ng", "silent, or 'ng' at the end"),
            j("h-t-2", "ㅓ", "eo", "'uh' as in duh"),
            j("h-t-3", "ㅡ", "eu", "'eu' — flat lips"),
            j("h-t-4", "ㅊ", "ch", "'ch' as in chair"),
            j("h-t-5", "ㅌ", "t", "'t' with a puff of air"),
            j("h-t-6", "ㅆ", "ss", "tense 'ss'"),
            j("h-t-7", "ㅟ", "wi", "'wi' as in we"),
            syl("h-t-8", "물", "mul", "water", ["ㅁ", "ㅜ", "ㄹ"]),
            syl("h-t-9", "하", "ha", "ha", ["ㅎ", "ㅏ"]),
            syl("h-t-10", "책", "chaek", "book", ["ㅊ", "ㅐ", "ㄱ"]),
          ],
        },
      ],
    },
  ],
};

/* ------------------------------------------------------------------ */
/* PATH 2 — ESSENTIAL WORDS                                            */
/* ------------------------------------------------------------------ */

const words: LearningPath = {
  id: "p-words",
  title: "Essential Words",
  tagline: "The 200 words you actually need to survive.",
  stage: "vocabulary",
  color: "#3b82f6",
  units: [
    {
      id: "u-w1",
      title: "Survival Kit",
      focus: "Say hello, thank you, and get help.",
      lessons: [
        {
          id: "w-s1",
          title: "First Five Words",
          goal: "Greet and be polite instantly",
          icon: "👋",
          mode: "flashcards",
          passScore: 70,
          cards: [
            w("w-s1-1", "안녕하세요", "annyeonghaseyo", "Hello (polite)", {
              ko: "안녕하세요, 만나서 반갑습니다.",
              rom: "annyeonghaseyo, mannaseo bangapseumnida.",
              en: "Hello, nice to meet you.",
            }),
            w("w-s1-2", "감사합니다", "gamsahamnida", "Thank you (formal)", {
              ko: "도와주셔서 감사합니다.",
              rom: "dowajusyeoseo gamsahamnida.",
              en: "Thank you for helping me.",
            }),
            w("w-s1-3", "죄송합니다", "joesonghamnida", "I am sorry (formal)"),
            w("w-s1-4", "네", "ne", "Yes"),
            w("w-s1-5", "아니요", "aniyo", "No"),
          ],
        },
        {
          id: "w-s2",
          title: "Polite Reactions",
          goal: "Respond naturally in conversation",
          icon: "🙏",
          mode: "quiz",
          passScore: 70,
          cards: [
            w("w-s2-1", "괜찮아요", "gwaenchanayo", "It's okay / I'm fine"),
            w("w-s2-2", "미안해요", "mianhaeyo", "Sorry (everyday polite)"),
            w("w-s2-3", "반갑습니다", "bangapseumnida", "Nice to meet you"),
            w("w-s2-4", "주세요", "juseyo", "Please give me …", {
              ko: "물 주세요.", rom: "mul juseyo.", en: "Water, please.",
            }),
            w("w-s2-5", "실례합니다", "sillyehamnida", "Excuse me"),
            w("w-s2-6", "도와주세요", "dowajuseyo", "Please help me"),
          ],
        },
        {
          id: "w-s3",
          title: "When You Are Lost",
          goal: "Keep a conversation alive as a beginner",
          icon: "🆘",
          mode: "quiz",
          passScore: 70,
          cards: [
            w("w-s3-1", "모르겠어요", "moreugesseoyo", "I don't understand / know"),
            w("w-s3-2", "다시 말해주세요", "dasi malhaejuseyo", "Please say it again"),
            w("w-s3-3", "천천히", "cheoncheonhi", "Slowly", {
              ko: "천천히 말해주세요.", rom: "cheoncheonhi malhaejuseyo.", en: "Please speak slowly.",
            }),
            w("w-s3-4", "한국어", "hangugeo", "The Korean language"),
            w("w-s3-5", "영어", "yeongeo", "The English language"),
            w("w-s3-6", "영어 할 수 있어요?", "yeongeo hal su isseoyo", "Can you speak English?"),
          ],
        },
      ],
    },
    {
      id: "u-w2",
      title: "People",
      focus: "Family and the people around you.",
      lessons: [
        {
          id: "w-p1",
          title: "Family",
          goal: "Name your family members",
          icon: "👨‍👩‍👧",
          mode: "flashcards",
          passScore: 70,
          cards: [
            w("w-p1-1", "가족", "gajok", "Family"),
            w("w-p1-2", "어머니", "eomeoni", "Mother (polite)", undefined, "엄마 (emma) = mum, casual."),
            w("w-p1-3", "아버지", "abeoji", "Father (polite)", undefined, "아빠 (appa) = dad, casual."),
            w("w-p1-4", "동생", "dongsaeng", "Younger sibling"),
            w("w-p1-5", "언니", "eonni", "Older sister (said by a woman)"),
            w("w-p1-6", "형", "hyeong", "Older brother (said by a man)"),
            w("w-p1-7", "할머니", "halmeoni", "Grandmother"),
            w("w-p1-8", "할아버지", "harabeoji", "Grandfather"),
          ],
        },
        {
          id: "w-p2",
          title: "People & Jobs",
          goal: "Talk about who someone is",
          icon: "🧑‍🏫",
          mode: "quiz",
          passScore: 70,
          cards: [
            w("w-p2-1", "사람", "saram", "Person / people"),
            w("w-p2-2", "친구", "chingu", "Friend"),
            w("w-p2-3", "선생님", "seonsaengnim", "Teacher"),
            w("w-p2-4", "학생", "haksaeng", "Student"),
            w("w-p2-5", "의사", "uisa", "Doctor"),
            w("w-p2-6", "회사원", "hoesawon", "Office worker"),
            w("w-p2-7", "이름", "ireum", "Name"),
          ],
        },
      ],
    },
    {
      id: "u-w3",
      title: "Food & Drink",
      focus: "Order, eat and survive a restaurant.",
      lessons: [
        {
          id: "w-f1",
          title: "On The Table",
          goal: "Core food words",
          icon: "🍚",
          mode: "flashcards",
          passScore: 70,
          cards: [
            w("w-f1-1", "밥", "bap", "Cooked rice / a meal"),
            w("w-f1-2", "물", "mul", "Water", { ko: "물 주세요.", rom: "mul juseyo.", en: "Water, please." }),
            w("w-f1-3", "김치", "gimchi", "Kimchi"),
            w("w-f1-4", "빵", "ppang", "Bread"),
            w("w-f1-5", "우유", "uyu", "Milk"),
            w("w-f1-6", "커피", "keopi", "Coffee"),
            w("w-f1-7", "차", "cha", "Tea / a vehicle", undefined, "Same sound, two meanings — context decides."),
          ],
        },
        {
          id: "w-f2",
          title: "Menu Words",
          goal: "Read a menu without panicking",
          icon: "🍜",
          mode: "match",
          passScore: 70,
          cards: [
            w("w-f2-1", "고기", "gogi", "Meat"),
            w("w-f2-2", "생선", "saengseon", "Fish"),
            w("w-f2-3", "계란", "gyeran", "Egg"),
            w("w-f2-4", "라면", "ramyeon", "Instant noodles"),
            w("w-f2-5", "아이스크림", "aiseukeurim", "Ice cream"),
            w("w-f2-6", "맛있다", "masitda", "Delicious", {
              ko: "이 음식은 맛있어요.", rom: "i eumsigeun masisseoyo.", en: "This food is delicious.",
            }),
          ],
        },
      ],
    },
    {
      id: "u-w4",
      title: "Places & Things",
      focus: "Move around the city.",
      lessons: [
        {
          id: "w-l1",
          title: "Places",
          goal: "Ask where things are",
          icon: "📍",
          mode: "quiz",
          passScore: 70,
          cards: [
            w("w-l1-1", "집", "jip", "House / home"),
            w("w-l1-2", "학교", "hakgyo", "School"),
            w("w-l1-3", "병원", "byeongwon", "Hospital"),
            w("w-l1-4", "식당", "sikdang", "Restaurant"),
            w("w-l1-5", "카페", "kape", "Café"),
            w("w-l1-6", "공항", "gonghang", "Airport"),
            w("w-l1-7", "화장실", "hwajangsil", "Toilet / restroom", {
              ko: "화장실이 어디예요?", rom: "hwajangsiri eodiyeyo?", en: "Where is the restroom?",
            }),
          ],
        },
        {
          id: "w-l2",
          title: "Everyday Things",
          goal: "Objects you touch daily",
          icon: "🎒",
          mode: "match",
          passScore: 70,
          cards: [
            w("w-l2-1", "책", "chaek", "Book"),
            w("w-l2-2", "가방", "gabang", "Bag"),
            w("w-l2-3", "휴대폰", "hyudaepon", "Mobile phone"),
            w("w-l2-4", "컴퓨터", "keompyuteo", "Computer"),
            w("w-l2-5", "의자", "uija", "Chair"),
            w("w-l2-6", "문", "mun", "Door"),
          ],
        },
      ],
    },
    {
      id: "u-w5",
      title: "Numbers & Time",
      focus: "Two number systems + telling time.",
      lessons: [
        {
          id: "w-n1",
          title: "Native Numbers 1-10",
          goal: "하나 둘 셋 … used for counting things",
          icon: "1️⃣",
          mode: "flashcards",
          passScore: 70,
          cards: [
            w("w-n1-1", "하나", "hana", "One"),
            w("w-n1-2", "둘", "dul", "Two"),
            w("w-n1-3", "셋", "set", "Three"),
            w("w-n1-4", "넷", "net", "Four"),
            w("w-n1-5", "다섯", "daseot", "Five"),
            w("w-n1-6", "여섯", "yeoseot", "Six"),
            w("w-n1-7", "일곱", "ilgop", "Seven"),
            w("w-n1-8", "여덟", "yeodeol", "Eight"),
            w("w-n1-9", "아홉", "ahop", "Nine"),
            w("w-n1-10", "열", "yeol", "Ten"),
          ],
        },
        {
          id: "w-n2",
          title: "Sino Numbers",
          goal: "일 이 삼 사 … used for dates, money, minutes",
          icon: "🔢",
          mode: "quiz",
          passScore: 70,
          cards: [
            w("w-n2-1", "일", "il", "1 (Sino)"),
            w("w-n2-2", "이", "i", "2 (Sino)"),
            w("w-n2-3", "삼", "sam", "3 (Sino)"),
            w("w-n2-4", "사", "sa", "4 (Sino)"),
            w("w-n2-5", "오", "o", "5 (Sino)"),
            w("w-n2-6", "육", "yuk", "6 (Sino)"),
            w("w-n2-7", "칠", "chil", "7 (Sino)"),
            w("w-n2-8", "팔", "pal", "8 (Sino)"),
            w("w-n2-9", "구", "gu", "9 (Sino)"),
            w("w-n2-10", "십", "sip", "10 (Sino)"),
          ],
        },
        {
          id: "w-t1",
          title: "Time Words",
          goal: "Talk about when",
          icon: "⏰",
          mode: "quiz",
          passScore: 70,
          cards: [
            w("w-t1-1", "오늘", "oneul", "Today"),
            w("w-t1-2", "어제", "eoje", "Yesterday"),
            w("w-t1-3", "내일", "naeil", "Tomorrow"),
            w("w-t1-4", "아침", "achim", "Morning / breakfast"),
            w("w-t1-5", "점심", "jeomsim", "Noon / lunch"),
            w("w-t1-6", "저녁", "jeonyeok", "Evening / dinner"),
            w("w-t1-7", "지금", "jigeum", "Now", { ko: "지금 몇 시예요?", rom: "jigeum myeot siyeyo?", en: "What time is it now?" }),
            w("w-t1-8", "시간", "sigan", "Time / hour"),
          ],
        },
      ],
    },
    {
      id: "u-w6",
      title: "Describing The World",
      focus: "Colors, adjectives and verbs.",
      lessons: [
        {
          id: "w-a1",
          title: "Colors",
          goal: "Describe what you see",
          icon: "🎨",
          mode: "match",
          passScore: 70,
          cards: [
            w("w-a1-1", "빨간색", "ppalgansaek", "Red"),
            w("w-a1-2", "파란색", "paransaek", "Blue"),
            w("w-a1-3", "노란색", "noransaek", "Yellow"),
            w("w-a1-4", "초록색", "choroksaek", "Green"),
            w("w-a1-5", "검은색", "geomeunsaek", "Black"),
            w("w-a1-6", "하얀색", "hayansaek", "White"),
          ],
        },
        {
          id: "w-a2",
          title: "Core Adjectives",
          goal: "Big, small, good, expensive …",
          icon: "📏",
          mode: "quiz",
          passScore: 70,
          cards: [
            w("w-a2-1", "크다", "keuda", "To be big"),
            w("w-a2-2", "작다", "jakda", "To be small"),
            w("w-a2-3", "좋다", "jota", "To be good / nice"),
            w("w-a2-4", "나쁘다", "nappeuda", "To be bad"),
            w("w-a2-5", "예쁘다", "yeppeuda", "To be pretty"),
            w("w-a2-6", "비싸다", "bissada", "To be expensive"),
            w("w-a2-7", "싸다", "ssada", "To be cheap"),
            w("w-a2-8", "바쁘다", "bappeuda", "To be busy"),
          ],
        },
        {
          id: "w-v1",
          title: "Core Verbs",
          goal: "The verbs you will use every day",
          icon: "🏃",
          mode: "quiz",
          passScore: 70,
          cards: [
            w("w-v1-1", "가다", "gada", "To go"),
            w("w-v1-2", "오다", "oda", "To come"),
            w("w-v1-3", "먹다", "meokda", "To eat"),
            w("w-v1-4", "마시다", "masida", "To drink"),
            w("w-v1-5", "자다", "jada", "To sleep"),
            w("w-v1-6", "보다", "boda", "To see / watch"),
            w("w-v1-7", "만나다", "mannada", "To meet"),
            w("w-v1-8", "공부하다", "gongbuhada", "To study"),
            w("w-v1-9", "하다", "hada", "To do"),
            w("w-v1-10", "있다", "itda", "To have / to exist"),
          ],
        },
      ],
    },
  ],
};

/* ------------------------------------------------------------------ */
/* PATH 3 — GRAMMAR ENGINE (gated)                                     */
/* ------------------------------------------------------------------ */

const grammar: LearningPath = {
  id: "p-grammar",
  title: "Grammar Engine",
  tagline: "Unlocks when your word accuracy hits 70%.",
  stage: "grammar",
  color: "#a855f7",
  unlock: {
    pathId: "p-words",
    completedLessons: 4,
    minAccuracy: 70,
    label: "Finish 4 Essential Word lessons with ≥70% accuracy",
  },
  units: [
    {
      id: "u-g1",
      title: "To Be & Politeness",
      focus: "The backbone of every Korean sentence.",
      lessons: [
        {
          id: "g-b1",
          title: "이에요 / 예요 — To Be",
          goal: "Say what things are",
          icon: "🟰",
          mode: "sentences",
          passScore: 70,
          cards: [
            s("g-b1-1", "저는 학생이에요.", "jeoneun haksaengieyo.", "I am a student.", [
              "저는", "학생이에요.",
            ], "이에요 after a consonant, 예요 after a vowel."),
            s("g-b1-2", "이것은 책이에요.", "igeoseun chaeg-ieyo.", "This is a book.", [
              "이것은", "책이에요.",
            ]),
            s("g-b1-3", "그것은 물이에요.", "geugeoseun mur-ieyo.", "That is water.", [
              "그것은", "물이에요.",
            ]),
            s("g-b1-4", "선생님이에요.", "seonsaengnim-ieyo.", "(He/She) is a teacher.", [
              "선생님이에요.",
            ]),
            s("g-b1-5", "친구예요.", "chinguyeyo.", "(He/She) is a friend.", [
              "친구예요.",
            ], "친구 ends in a vowel → 예요."),
          ],
        },
        {
          id: "g-b2",
          title: "Three Speech Levels",
          goal: "Pick the right level of politeness",
          icon: "🎚️",
          mode: "quiz",
          passScore: 70,
          cards: [
            w("g-b2-1", "감사합니다", "gamsahamnida", "Thank you — 합니다체 (formal)", undefined, "News, speeches, bosses, strangers."),
            w("g-b2-2", "감사해요", "gamsahaeyo", "Thank you — 아요체 (polite)", undefined, "The default safe level. Use this."),
            w("g-b2-3", "고마워", "gomawo", "Thanks — 반말 (casual)", undefined, "Friends and kids only."),
            w("g-b2-4", "먹습니다", "meokseumnida", "I eat (formal)"),
            w("g-b2-5", "먹어요", "meogeoyo", "I eat (polite)"),
            w("g-b2-6", "먹어", "meogeo", "I eat (casual)"),
          ],
        },
      ],
    },
    {
      id: "u-g2",
      title: "Particles",
      focus: "Small words that glue a sentence together.",
      lessons: [
        {
          id: "g-p1",
          title: "은 / 는 — Topic",
          goal: "Mark what you are talking about",
          icon: "🏷️",
          mode: "sentences",
          passScore: 70,
          cards: [
            s("g-p1-1", "저는 학생이에요.", "jeoneun haksaengieyo.", "As for me, I am a student.", [
              "저는", "학생이에요.",
            ], "는 after a vowel, 은 after a consonant."),
            s("g-p1-2", "김치는 맛있어요.", "gimchineun masisseoyo.", "Kimchi is delicious.", [
              "김치는", "맛있어요.",
            ]),
            s("g-p1-3", "이것은 커피예요.", "igeoseun keopiyeyo.", "This is coffee.", [
              "이것은", "커피예요.",
            ]),
            s("g-p1-4", "오늘은 바빠요.", "oneureun bappayo.", "Today (I) am busy.", [
              "오늘은", "바빠요.",
            ]),
          ],
        },
        {
          id: "g-p2",
          title: "이 / 가 & 을 / 를",
          goal: "Subject and object markers",
          icon: "🎯",
          mode: "sentences",
          passScore: 70,
          cards: [
            s("g-p2-1", "친구가 좋아요.", "chinguga joayo.", "My friend is nice.", [
              "친구가", "좋아요.",
            ], "가 marks the subject — vowel ending."),
            s("g-p2-2", "물이 있어요.", "muri isseoyo.", "There is water.", [
              "물이", "있어요.",
            ]),
            s("g-p2-3", "밥을 먹어요.", "babeul meogeoyo.", "I eat rice.", [
              "밥을", "먹어요.",
            ], "을 marks the object — consonant ending."),
            s("g-p2-4", "커피를 마셔요.", "keopireul masyeoyo.", "I drink coffee.", [
              "커피를", "마셔요.",
            ]),
            s("g-p2-5", "한국어를 공부해요.", "hangugeoreul gongbuhaeyo.", "I study Korean.", [
              "한국어를", "공부해요.",
            ]),
          ],
        },
        {
          id: "g-p3",
          title: "에, 에서 & Other Particles",
          goal: "Place, time, and, only, too",
          icon: "🧩",
          mode: "sentences",
          passScore: 70,
          cards: [
            s("g-p3-1", "학교에 가요.", "hakgyoe gayo.", "I go to school.", [
              "학교에", "가요.",
            ], "에 = direction / time point."),
            s("g-p3-2", "집에서 공부해요.", "jibeseo gongbuhaeyo.", "I study at home.", [
              "집에서", "공부해요.",
            ], "에서 = where an action happens."),
            s("g-p3-3", "저도 학생이에요.", "jeodo haksaengieyo.", "I am a student too.", [
              "저도", "학생이에요.",
            ], "도 = also."),
            s("g-p3-4", "물만 마셔요.", "mulman masyeoyo.", "I only drink water.", [
              "물만", "마셔요.",
            ], "만 = only."),
            s("g-p3-5", "빵과 우유", "ppang-gwa uyu", "Bread and milk", [
              "빵과", "우유",
            ], "과 (consonant) / 와 (vowel) = and."),
            s("g-p3-6", "친구의 책", "chingu-ui chaek", "My friend's book", [
              "친구의", "책",
            ], "의 = possessive 'of."),
          ],
        },
      ],
    },
    {
      id: "u-g3",
      title: "Verbs In Motion",
      focus: "Tense, wants and connectors.",
      lessons: [
        {
          id: "g-v1",
          title: "Present: 아요 / 어요",
          goal: "Conjugate any verb in the polite present",
          icon: "⏳",
          mode: "sentences",
          passScore: 70,
          cards: [
            s("g-v1-1", "가요", "gayo", "(I) go — 가다 → 가요", ["저는", "학교에", "가요."], "Vowel ㅏ → 아요, but 가다 is irregularly just 가요."),
            s("g-v1-2", "먹어요", "meogeoyo", "(I) eat — 먹다 → 먹어요", ["저는", "밥을", "먹어요."], "Vowel ㅓ/ㅡ/ㅣ → 어요."),
            s("g-v1-3", "마셔요", "masyeoyo", "(I) drink — 마시다 → 마셔요", ["물을", "마셔요."], "하다 family: drop 다, add 셔요."),
            s("g-v1-4", "공부해요", "gongbuhaeyo", "(I) study — 공부하다 → 공부해요", ["한국어를", "공부해요."], "하다 → 해요. The most useful rule in Korean."),
            s("g-v1-5", "봐요", "bwayo", "(I) see — 보다 → 봐요", ["영화를", "봐요."], "오 + 아요 contract to 와요."),
          ],
        },
        {
          id: "g-v2",
          title: "Past & Future",
          goal: "았/었어요 and (으)ㄹ 거예요",
          icon: "🔮",
          mode: "sentences",
          passScore: 70,
          cards: [
            s("g-v2-1", "먹었어요", "meogeosseoyo", "(I) ate — 먹다 → 먹었어요", ["어제", "밥을", "먹었어요."], "Add 았/었 + 어요."),
            s("g-v2-2", "갔어요", "gasseoyo", "(I) went — 가다 → 갔어요", ["학교에", "갔어요."]),
            s("g-v2-3", "공부했어요", "gongbuhaesseoyo", "(I) studied", ["오늘", "공부했어요."]),
            s("g-v2-4", "갈 거예요", "gal geoyeyo", "(I) will go", ["내일", "학교에", "갈 거예요."], "Verb stem + (으)ㄹ 거예요."),
            s("g-v2-5", "먹을 거예요", "meogeul geoyeyo", "(I) will eat", ["점심을", "먹을 거예요."]),
          ],
        },
        {
          id: "g-v3",
          title: "Want, Can & Connectors",
          goal: "고 싶다, (으)ㄹ 수 있다, 고 / 지만 / 그래서",
          icon: "🔗",
          mode: "sentences",
          passScore: 70,
          cards: [
            s("g-v3-1", "가고 싶어요", "gago sipeoyo", "I want to go", ["저는", "한국에", "가고", "싶어요."], "Verb stem + 고 싶다."),
            s("g-v3-2", "먹을 수 있어요", "meogeul su isseoyo", "I can eat it", ["저는", "김치를", "먹을 수", "있어요."], "(으)ㄹ 수 있다 = can."),
            s("g-v3-3", "밥을 먹고 학교에 가요", "babeul meokgo hakgyoe gayo", "I eat and go to school", ["밥을", "먹고", "학교에", "가요."], "고 = and (actions in sequence)."),
            s("g-v3-4", "비싸지만 좋아요", "bissajiman joayo", "It is expensive but good", ["비싸지만", "좋아요."], "지만 = but."),
            s("g-v3-5", "바빠서 못 갔어요", "bappaseo mot gasseoyo", "I was busy so I couldn't go", ["바빠서", "못", "갔어요."], "아서/어서 = because / so."),
          ],
        },
        {
          id: "g-test",
          title: "Grammar Checkpoint",
          goal: "Mixed test across particles and tenses",
          icon: "📝",
          mode: "test",
          passScore: 70,
          cards: [
            s("g-t-1", "저는 학생이에요.", "jeoneun haksaengieyo.", "I am a student.", ["저는", "학생이에요."]),
            s("g-t-2", "밥을 먹어요.", "babeul meogeoyo.", "I eat rice.", ["밥을", "먹어요."]),
            s("g-t-3", "학교에 가요.", "hakgyoe gayo.", "I go to school.", ["학교에", "가요."]),
            s("g-t-4", "집에서 공부해요.", "jibeseo gongbuhaeyo.", "I study at home.", ["집에서", "공부해요."]),
            s("g-t-5", "어제 물을 마셨어요.", "eoje mureul masyeosseoyo.", "Yesterday I drank water.", ["어제", "물을", "마셨어요."]),
            s("g-t-6", "한국어를 배우고 싶어요.", "hangugeoreul baeugo sipeoyo.", "I want to learn Korean.", ["한국어를", "배우고", "싶어요."]),
          ],
        },
      ],
    },
  ],
};

/* ------------------------------------------------------------------ */
/* PATH 4 — REAL CONVERSATIONS                                         */
/* ------------------------------------------------------------------ */

const conversation: LearningPath = {
  id: "p-talk",
  title: "Real Conversations",
  tagline: "Whole sentences you can use today.",
  stage: "conversation",
  color: "#f59e0b",
  unlock: {
    pathId: "p-grammar",
    completedLessons: 3,
    minAccuracy: 70,
    label: "Finish 3 Grammar Engine lessons with ≥70% accuracy",
  },
  units: [
    {
      id: "u-t1",
      title: "Meeting People",
      focus: "Introduce yourself properly.",
      lessons: [
        {
          id: "t-m1",
          title: "Introductions",
          goal: "Name, country, first impressions",
          icon: "🤝",
          mode: "sentences",
          passScore: 70,
          cards: [
            s("t-m1-1", "이름이 뭐예요?", "ireumi mwoyeyo?", "What is your name?", ["이름이", "뭐예요?"]),
            s("t-m1-2", "저는 민수예요.", "jeoneun minsuyeyo.", "I am Minsu.", ["저는", "민수예요."]),
            s("t-m1-3", "어디에서 왔어요?", "eodieseo wasseoyo?", "Where are you from?", ["어디에서", "왔어요?"]),
            s("t-m1-4", "저는 영국에서 왔어요.", "jeoneun yeonggugeseo wasseoyo.", "I am from the UK.", ["저는", "영국에서", "왔어요."]),
            s("t-m1-5", "만나서 반갑습니다.", "mannaseo bangapseumnida.", "Nice to meet you.", ["만나서", "반갑습니다."]),
          ],
        },
      ],
    },
    {
      id: "u-t2",
      title: "Daily Life",
      focus: "Routines, time and small talk.",
      lessons: [
        {
          id: "t-d1",
          title: "My Day",
          goal: "Describe a routine",
          icon: "🌅",
          mode: "sentences",
          passScore: 70,
          cards: [
            s("t-d1-1", "아침에 뭐 해요?", "achime mwo haeyo?", "What do you do in the morning?", ["아침에", "뭐", "해요?"]),
            s("t-d1-2", "저는 아침을 먹어요.", "jeoneun achimeul meogeoyo.", "I eat breakfast.", ["저는", "아침을", "먹어요."]),
            s("t-d1-3", "지금 몇 시예요?", "jigeum myeot siyeyo?", "What time is it now?", ["지금", "몇", "시예요?"]),
            s("t-d1-4", "오늘 날씨가 좋아요.", "oneul nalssiga joayo.", "The weather is nice today.", ["오늘", "날씨가", "좋아요."]),
            s("t-d1-5", "저는 한국어를 매일 공부해요.", "jeoneun hangugeoreul maeil gongbuhaeyo.", "I study Korean every day.", ["저는", "한국어를", "매일", "공부해요."]),
          ],
        },
      ],
    },
    {
      id: "u-t3",
      title: "Out & About",
      focus: "Cafés, shops and directions.",
      lessons: [
        {
          id: "t-o1",
          title: "Ordering & Shopping",
          goal: "Buy things without switching to English",
          icon: "☕",
          mode: "sentences",
          passScore: 70,
          cards: [
            s("t-o1-1", "이거 주세요.", "igeo juseyo.", "This one, please.", ["이거", "주세요."]),
            s("t-o1-2", "얼마예요?", "eolmayeyo?", "How much is it?", ["얼마예요?"]),
            s("t-o1-3", "메뉴판 주세요.", "menyupan juseyo.", "The menu, please.", ["메뉴판", "주세요."]),
            s("t-o1-4", "계산서 주세요.", "gyesanseo juseyo.", "The bill, please.", ["계산서", "주세요."]),
            s("t-o1-5", "화장실이 어디예요?", "hwajangsiri eodiyeyo?", "Where is the restroom?", ["화장실이", "어디예요?"]),
          ],
        },
        {
          id: "t-final",
          title: "Final Boss Test",
          goal: "Letters + words + grammar, all mixed",
          icon: "🐉",
          mode: "test",
          passScore: 70,
          cards: [
            j("t-f-1", "ㅓ", "eo", "'uh' as in duh"),
            w("t-f-2", "물", "mul", "Water"),
            w("t-f-3", "학교", "hakgyo", "School"),
            w("t-f-4", "감사합니다", "gamsahamnida", "Thank you (formal)"),
            w("t-f-5", "먹다", "meokda", "To eat"),
            s("t-f-6", "저는 학생이에요.", "jeoneun haksaengieyo.", "I am a student.", ["저는", "학생이에요."]),
            s("t-f-7", "밥을 먹어요.", "babeul meogeoyo.", "I eat rice.", ["밥을", "먹어요."]),
            s("t-f-8", "이거 주세요.", "igeo juseyo.", "This one, please.", ["이거", "주세요."]),
            s("t-f-9", "어디에서 왔어요?", "eodieseo wasseoyo?", "Where are you from?", ["어디에서", "왔어요?"]),
            s("t-f-10", "학교에 가요.", "hakgyoe gayo.", "I go to school.", ["학교에", "가요."]),
          ],
        },
      ],
    },
  ],
};

export const PATHS: LearningPath[] = [hangul, words, grammar, conversation];

/* ------------------------------------------------------------------ */
/* Lookups                                                             */
/* ------------------------------------------------------------------ */

export const ALL_LESSONS: Lesson[] = PATHS.flatMap((p) =>
  p.units.flatMap((u) => u.lessons),
);

export const LESSON_PATH: Record<string, string> = Object.fromEntries(
  PATHS.flatMap((p) => p.units.flatMap((u) => u.lessons.map((l) => [l.id, p.id]))),
);

export const ALL_CARDS: Card[] = ALL_LESSONS.flatMap((l) => l.cards);
export const CARD_BY_ID: Record<string, Card> = Object.fromEntries(
  ALL_CARDS.map((c) => [c.id, c]),
);

export function getLesson(id: string): Lesson | undefined {
  return ALL_LESSONS.find((l) => l.id === id);
}

export function getPath(id: string): LearningPath | undefined {
  return PATHS.find((p) => p.id === id);
}

/** Cards from the same unit — used to build plausible wrong options. */
export function siblingCards(lessonId: string): Card[] {
  for (const path of PATHS) {
    for (const unit of path.units) {
      const lesson = unit.lessons.find((l) => l.id === lessonId);
      if (lesson) {
        const all = unit.lessons.flatMap((l) => l.cards);
        return all.length > 4 ? all : path.units.flatMap((u) => u.lessons.flatMap((l) => l.cards));
      }
    }
  }
  return ALL_CARDS;
}

export const HANGUL_TABLE = [
  { group: "Basic vowels", items: ["ㅏ a", "ㅑ ya", "ㅓ eo", "ㅕ yeo", "ㅗ o", "ㅛ yo", "ㅜ u", "ㅠ yu", "ㅡ eu", "ㅣ i"] },
  { group: "Compound vowels", items: ["ㅐ ae", "ㅔ e", "ㅒ yae", "ㅖ ye", "ㅘ wa", "ㅙ wae", "ㅚ oe", "ㅝ wo", "ㅞ we", "ㅟ wi", "ㅢ ui"] },
  { group: "Basic consonants", items: ["ㄱ g", "ㄴ n", "ㄷ d", "ㄹ r/l", "ㅁ m", "ㅂ b", "ㅅ s", "ㅇ -/ng", "ㅈ j", "ㅊ ch", "ㅋ k", "ㅌ t", "ㅍ p", "ㅎ h"] },
  { group: "Double consonants", items: ["ㄲ kk", "ㄸ tt", "ㅃ pp", "ㅆ ss", "ㅉ jj"] },
];
