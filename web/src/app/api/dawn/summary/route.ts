import { NextRequest, NextResponse } from "next/server";
import { and, desc, eq, gte, sql } from "drizzle-orm";
import db from "@/db";
import { runs, trackingPoints } from "@/db/schema";
import { getSessionFromRequest } from "@/lib/auth-server";

export async function GET(request: NextRequest) {
  const session = await getSessionFromRequest(request);
  if (!session) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  const userId = session.user.id;

  const latestRun = await db
    .select({ id: runs.id, startedAt: runs.startedAt, endedAt: runs.endedAt })
    .from(runs)
    .where(eq(runs.userId, userId))
    .orderBy(desc(runs.startedAt))
    .limit(1);

  const now = new Date();
  const weekAgo = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);

  const weeklyRuns = await db
    .select({ id: runs.id, startedAt: runs.startedAt, endedAt: runs.endedAt })
    .from(runs)
    .where(and(eq(runs.userId, userId), gte(runs.startedAt, weekAgo)));

  let latest = null as null | {
    runId: string;
    startedAt: string;
    durationSec: number;
    distanceMeters: number;
    avgHr: number | null;
    latestPace: number | null;
    paceSeries: { label: string; pace: number }[];
    hrSeries: { label: string; hr: number }[];
  };

  if (latestRun.length > 0) {
    const run = latestRun[0];

    const points = await db
      .select({
        recordedAt: trackingPoints.recordedAt,
        pace: trackingPoints.pace,
        heartRate: trackingPoints.heartRate,
        distanceMeters: trackingPoints.distanceMeters,
      })
      .from(trackingPoints)
      .where(eq(trackingPoints.runId, run.id))
      .orderBy(trackingPoints.recordedAt);

    const firstT = run.startedAt ?? points[0]?.recordedAt ?? new Date();
    const lastT = run.endedAt ?? points[points.length - 1]?.recordedAt ?? firstT;
    const durationSec = Math.max(0, Math.round((new Date(lastT).getTime() - new Date(firstT).getTime()) / 1000));
    const distanceMeters = points.reduce((m, p) => Math.max(m, p.distanceMeters ?? 0), 0);
    const hrVals = points.map((p) => p.heartRate).filter((v): v is number => v !== null);
    const avgHr = hrVals.length ? Math.round(hrVals.reduce((a, b) => a + b, 0) / hrVals.length) : null;

    const sampled = points.length > 40 ? points.filter((_, i) => i % Math.ceil(points.length / 40) === 0) : points;
    const paceSeries = sampled
      .filter((p) => p.pace !== null)
      .map((p, i) => ({ label: `${i + 1}`, pace: Math.round((p.pace ?? 0) * 60) }));
    const hrSeries = sampled
      .filter((p) => p.heartRate !== null)
      .map((p, i) => ({ label: `${i + 1}`, hr: p.heartRate ?? 0 }));

    latest = {
      runId: run.id,
      startedAt: new Date(run.startedAt ?? firstT).toISOString(),
      durationSec,
      distanceMeters,
      avgHr,
      latestPace: points[points.length - 1]?.pace ? Math.round((points[points.length - 1]!.pace ?? 0) * 60) : null,
      paceSeries,
      hrSeries,
    };
  }

  const runIds = weeklyRuns.map((r) => r.id);
  let weeklyVolume: { day: string; km: number }[] = ["일", "월", "화", "수", "목", "금", "토"].map((d) => ({ day: d, km: 0 }));

  if (runIds.length > 0) {
    const weeklyDistanceRows = await db.execute(sql`
      select r.id as run_id,
             date_trunc('day', r.started_at at time zone 'Asia/Seoul') as day_key,
             max(tp.distance_meters) as max_distance
      from runs r
      left join tracking_points tp on tp.run_id = r.id
      where r.id = any(${sql.raw(`ARRAY[${runIds.map((id) => `'${id.replace(/'/g, "''")}'`).join(",")}]::text[]`)})
      group by r.id, day_key
    `);

    const dayMap = new Map<string, number>();
    for (const row of weeklyDistanceRows.rows as any[]) {
      const kstDate = new Date(row.day_key);
      const day = ["일", "월", "화", "수", "목", "금", "토"][kstDate.getDay()];
      const prev = dayMap.get(day) ?? 0;
      dayMap.set(day, prev + Number(row.max_distance ?? 0) / 1000);
    }

    weeklyVolume = weeklyVolume.map((d) => ({ ...d, km: Number((dayMap.get(d.day) ?? 0).toFixed(2)) }));
  }

  return NextResponse.json({ latest, weeklyVolume });
}
