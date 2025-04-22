import { integer, pgTable, varchar, timestamp } from "drizzle-orm/pg-core";

export const userTable = pgTable("users", {
    id: integer().primaryKey().generatedAlwaysAsIdentity(),
    name: varchar().notNull().unique(),
    email: varchar().notNull().unique(),
    avatar: varchar(),
    signature: varchar(),
    backgrond: varchar(),
    createTime: timestamp().defaultNow().notNull(),
    updateTime: timestamp().notNull()
})

export const table = {
    userTable
} as const

export type Tables = typeof table