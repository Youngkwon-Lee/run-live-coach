export async function GET() {
  return Response.json({
    mapboxToken: process.env.MAPBOX_TOKEN,
    hasDatabaseUrl: Boolean(process.env.DATABASE_URL),
    hasBetterAuthSecret: Boolean(process.env.BETTER_AUTH_SECRET),
    hasBetterAuthUrl: Boolean(process.env.BETTER_AUTH_URL || process.env.NEXT_PUBLIC_APP_URL),
  });
}
