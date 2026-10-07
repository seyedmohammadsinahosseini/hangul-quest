export type LessonState = {
  id: string;
  pathId: string;
  unitId: string;
  unitTitle: string;
  status: "locked" | "available" | "completed";
  bestScore: number;
  attempts: number;
};

export type PathProgress = {
  id: string;
  title: string;
  tagline: string;
  stage: string;
  color: string;
  locked: boolean;
  unlockLabel?: string;
  unlockDone: number;
  unlockNeed: number;
  completedLessons: number;
  totalLessons: number;
  percent: number;
  accuracy: number;
  firstAvailableLessonId?: string;
};

export type Achievement = {
  id: string;
  title: string;
  desc: string;
  icon: string;
  earned: boolean;
  progress: number;
  target: number;
};

export type ProfileView = {
  id: string;
  displayName: string;
  theme: "light" | "dark";
  dailyGoal: number;
  xpEarned: number;
  xpSpent: number;
  xpBalance: number;
  xpToday: number;
  hintsUsed: number;
  correctAnswers: number;
  wrongAnswers: number;
  accuracy: number;
  streak: number;
  longestStreak: number;
  goalDone: boolean;
  joinedAt: string;
};

export type ReviewCard = {
  cardId: string;
  lessonId: string;
  ko: string;
  rom: string;
  en: string;
  wrongCount: number;
  mastered: boolean;
};

export type AppState = {
  ready: boolean;
  profile: ProfileView;
  paths: PathProgress[];
  lessons: Record<string, LessonState>;
  review: ReviewCard[];
  achievements: Achievement[];
  overallPercent: number;
  hintCosts: { small: number; medium: number; large: number };
  xpPerCorrect: number;
};
