import { drizzle } from 'drizzle-orm/postgres-js';

const connectionString = process.env.DATABASE_URL!;
export const db = drizzle(connectionString);