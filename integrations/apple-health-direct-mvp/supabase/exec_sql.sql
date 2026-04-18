-- Run once in Supabase SQL Editor (service role only)
create or replace function public.exec_sql(q text)
returns jsonb
language plpgsql
security definer
as $$
declare
  result jsonb;
begin
  execute format('select coalesce(jsonb_agg(t), ''[]''::jsonb) from (%s) t', q) into result;
  return coalesce(result, '[]'::jsonb);
end;
$$;

revoke all on function public.exec_sql(text) from public;
grant execute on function public.exec_sql(text) to service_role;
