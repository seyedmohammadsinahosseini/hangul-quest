import {
  boolean,
  date,
  integer,
  pgTable,
  text,
  timestamp,
  uniqueIndex,
} from "drizzle-orm/pg-core";

/**
 * A learner. The app is auth-less: the browser creates a "handle" (stored in
 * localStorage) and the server upserts one profile per handle.
 */
export const profiles = pgTable(
  "profiles",
  {
    id: text("id").primaryKey(),
    handle: text("handle").notNull(),
    displayName: text("display_name").notNull().default("Learner"),
    theme: text("theme").notNull().default("light"),
    dailyGoal: integer("daily_goal").notNull().default(10),
    xpEarned: integer("xp_earned").notNull().default(0),
    xpSpent: integer("xp_spent").notNull().default(0),
    hintsUsed: integer("hints_used").notNull().default(0),
    correctAnswers: integer("correct_answers").notNull().default(0),
    wrongAnswers: integer("wrong_answers").notNull().default(0),
    xpToday: integer("xp_today").notNull().default(0),
    streak: integer("streak").notNull().default(0),
    longestStreak: integer("longest_streak").notNull().default(0),
    lastActiveDate: date("last_active_date"),
    createdAt: timestamp("created_at", { withTimezone: true }).notNull().defaultNow(),
    updatedAt: timestamp("updated_at", { withTimezone: true }).notNull().defaultNow(),
  },
  (t) => [uniqueIndex("profiles_handle_idx").on(t.handle)],
);

/** Per-lesson progress. A lesson is "completed" only when score >= passScore. */
export const lessonProgress = pgTable(
  "lesson_progress",
  {
    id: text("id").primaryKey(),
    profileId: text("profile_id")
      .notNull()
      .references(() => profiles.id, { onDelete: "cascade" }),
    lessonId: text("lesson_id").notNull(),
    pathId: text("path_id").notNull(),
    status: text("status").notNull().default("unlocked"), // unlocked | completed
    bestScore: integer("best_score").notNull().default(0),
    attempts: integer("attempts").notNull().default(0),
    correct: integer("correct").notNull().default(0),
    total: integer("total").notNull().default(0),
    xpEarned: integer("xp_earned").notNull().default(0),
    completedAt: timestamp("completed_at", { withTimezone: true }),
    updatedAt: timestamp("updated_at", { withTimezone: true }).notNull().defaultNow(),
  },
  (t) => [uniqueIndex("lesson_progress_unique").on(t.profileId, t.lessonId)],
);

/** Every XP movement, so the economy is auditable. */
export const xpEvents = pgTable("xp_events", {
  id: text("id").primaryKey(),
  profileId: text("profile_id")
    .notNull()
    .references(() => profiles.id, { onDelete: "cascade" }),
  amount: integer("amount").notNull(),
  kind: text("kind").notNull(), // answer | hint | bonus | reset
  note: text("note"),
  createdAt: timestamp("created_at", { withTimezone: true }).notNull().defaultNow(),
});

/** Words the learner got wrong -> feeds the spaced "Review Deck". */
export const mistakes = pgTable(
  "mistakes",
  {
    id: text("id").primaryKey(),
    profileId: text("profile_id")
      .notNull()
      .references(() => profiles.id, { onDelete: "cascade" }),
    cardId: text("card_id").notNull(),
    lessonId: text("lesson_id").notNull(),
    wrongCount: integer("wrong_count").notNull().default(1),
    rightSince: integer("right_since").notNull().default(0),
    mastered: boolean("mastered").notNull().default(false),
    lastSeenAt: timestamp("last_seen_at", { withTimezone: true }).notNull().defaultNow(),
  },
  (t) => [uniqueIndex("mistakes_unique").on(t.profileId, t.cardId)],
);

export type ProfileRow = typeof profiles.$inferSelect;
export type LessonProgressRow = typeof lessonProgress.$inferSelect;
export type MistakeRow = typeof mistakes.$inferSelect;
