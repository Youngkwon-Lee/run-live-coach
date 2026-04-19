import db from "@/db";
import { sql } from "drizzle-orm";

export async function GET() {
  const hasDatabaseUrl = Boolean(process.env.DATABASE_URL);
  const hasBetterAuthSecret = Boolean(process.env.BETTER_AUTH_SECRET);
  const hasBetterAuthUrl = Boolean(process.env.BETTER_AUTH_URL || process.env.NEXT_PUBLIC_APP_URL);

  let dbReachable = false;
  if (hasDatabaseUrl) {
    try {
      await db.execute(sql`select 1`);
      dbReachable = true;
    } catch {
      dbReachable = false;
    }
  }

  return Response.json({
    mapboxToken: process.env.MAPBOX_TOKEN,
    hasDatabaseUrl,
    hasBetterAuthSecret,
    hasBetterAuthUrl,
    dbReachable,
  });
}
