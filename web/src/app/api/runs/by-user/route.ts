import { NextRequest, NextResponse } from "next/server";
import { and, desc, eq, isNotNull } from "drizzle-orm";
import db from "@/db";
import { runs } from "@/db/schema";

export async function GET(request: NextRequest) {
  const userId = request.nextUrl.searchParams.get("userId");
  if (!userId) {
    return NextResponse.json({ error: "Missing userId" }, { status: 400 });
  }

  const data = await db
    .select({
      id: runs.id,
      user_id: runs.userId,
      started_at: runs.startedAt,
      ended_at: runs.endedAt,
    })
    .from(runs)
    .where(and(eq(runs.userId, userId), isNotNull(runs.startedAt)))
    .orderBy(desc(runs.startedAt))
    .limit(100);

  return NextResponse.json({ runs: data });
}
