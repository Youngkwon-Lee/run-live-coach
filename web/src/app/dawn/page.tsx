"use client";

import { useEffect, useMemo, useState } from "react";
import { Bar, BarChart, Line, LineChart, ResponsiveContainer, Tooltip, XAxis, YAxis } from "recharts";

type SummaryResponse = {
  latest: null | {
    runId: string;
    durationSec: number;
    distanceMeters: number;
    avgHr: number | null;
    latestPace: number | null;
    paceSeries: { label: string; pace: number }[];
    hrSeries: { label: string; hr: number }[];
  };
  weeklyVolume: { day: string; km: number }[];
};

const fallback: SummaryResponse = {
  latest: null,
  weeklyVolume: ["월", "화", "수", "목", "금", "토", "일"].map((day) => ({ day, km: 0 })),
};

function formatPace(sec: number | null) {
  if (!sec || sec <= 0) return "기기 데이터 없음";
  const m = Math.floor(sec / 60);
  const s = sec % 60;
  return `${m}'${String(s).padStart(2, "0")}"/km`;
}

function formatDuration(sec: number) {
  const h = Math.floor(sec / 3600);
  const m = Math.floor((sec % 3600) / 60);
  const s = sec % 60;
  if (h > 0) return `${h}:${String(m).padStart(2, "0")}:${String(s).padStart(2, "0")}`;
  return `${m}:${String(s).padStart(2, "0")}`;
}

export default function DawnPage() {
  const [data, setData] = useState<SummaryResponse>(fallback);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let mounted = true;
    (async () => {
      try {
        const res = await fetch("/api/dawn/summary", { cache: "no-store" });
        if (!res.ok) throw new Error(res.status === 401 ? "로그인이 필요합니다" : "요약 데이터 조회 실패");
        const json = (await res.json()) as SummaryResponse;
        if (mounted) setData(json);
      } catch (e) {
        if (mounted) setError(e instanceof Error ? e.message : "오류");
      } finally {
        if (mounted) setLoading(false);
      }
    })();
    return () => {
      mounted = false;
    };
  }, []);

  const distanceKm = useMemo(() => Number(((data.latest?.distanceMeters ?? 0) / 1000).toFixed(2)), [data.latest]);

  return (
    <main className="min-h-screen bg-zinc-950 text-zinc-100 p-4">
      <div className="mx-auto max-w-5xl space-y-4">
        <h1 className="text-2xl font-semibold">새벽런 대시보드</h1>

        {loading && <p className="text-zinc-400">불러오는 중...</p>}
        {error && <p className="text-amber-300">{error}</p>}

        <section className="grid grid-cols-2 md:grid-cols-4 gap-3">
          <div className="rounded-xl bg-zinc-900 p-3">거리<br />{distanceKm}km</div>
          <div className="rounded-xl bg-zinc-900 p-3">시간<br />{formatDuration(data.latest?.durationSec ?? 0)}</div>
          <div className="rounded-xl bg-zinc-900 p-3">페이스<br />{formatPace(data.latest?.latestPace ?? null)}</div>
          <div className="rounded-xl bg-zinc-900 p-3">평균심박<br />{data.latest?.avgHr ? `${data.latest.avgHr} bpm` : "기기 데이터 없음"}</div>
        </section>

        <section className="grid md:grid-cols-2 gap-4">
          <div className="rounded-xl bg-zinc-900 p-4">
            <h2 className="mb-2">페이스 추세</h2>
            <div className="h-56">
              <ResponsiveContainer width="100%" height="100%">
                <LineChart data={data.latest?.paceSeries ?? []}>
                  <XAxis dataKey="label" />
                  <YAxis />
                  <Tooltip formatter={(v: number) => formatPace(v)} />
                  <Line dataKey="pace" stroke="#60a5fa" dot={false} />
                </LineChart>
              </ResponsiveContainer>
            </div>
          </div>

          <div className="rounded-xl bg-zinc-900 p-4">
            <h2 className="mb-2">심박 추세</h2>
            <div className="h-56">
              <ResponsiveContainer width="100%" height="100%">
                <LineChart data={data.latest?.hrSeries ?? []}>
                  <XAxis dataKey="label" />
                  <YAxis />
                  <Tooltip formatter={(v: number) => `${v} bpm`} />
                  <Line dataKey="hr" stroke="#fb7185" dot={false} />
                </LineChart>
              </ResponsiveContainer>
            </div>
          </div>
        </section>

        <section className="rounded-xl bg-zinc-900 p-4">
          <h2 className="mb-2">주간 볼륨</h2>
          <div className="h-56">
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={data.weeklyVolume}>
                <XAxis dataKey="day" />
                <YAxis />
                <Tooltip formatter={(v: number) => `${v} km`} />
                <Bar dataKey="km" fill="#34d399" />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </section>
      </div>
    </main>
  );
}
