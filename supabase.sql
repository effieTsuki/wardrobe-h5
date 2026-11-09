-- ============================================================
-- 衣橱 H5 · Supabase 初始化脚本
-- 用法：Supabase Dashboard -> SQL Editor -> 整段粘贴 -> Run
-- ============================================================

-- 1. 建表：衣服
create table if not exists public.clothes (
  id           uuid primary key default gen_random_uuid(),
  owner        text not null default '',          -- 设备标识，用于数据隔离
  name         text not null,                     -- 名称
  category     text not null default '其他',       -- 分类：上衣/毛衣/下装/半身裙/连衣裙/汉服/旗袍/外套/大衣/羽绒服/鞋/帽子/围巾/包包/其他（text 字段，无枚举约束，可自由扩展）
  color        text,                              -- 颜色（hex 色值）
  size         text,                              -- 尺码：字母码 XS/S/M/L/XL/XXL/均码 或鞋码/腰码（text，可空）
  seasons      text[] not null default '{}',      -- 季节数组：春/夏/秋/冬
  gender       text not null default '中性',       -- 性别：男/女/中性
  price        numeric(12,2) not null default 0,  -- 金额（元）
  purchased_at date,                              -- 购入时间
  platform     text,                              -- 购入平台：淘宝/京东/拼多多/唯品会/抖音商城/线下门店/其他
  image_url    text,                              -- 图片公开 URL
  note         text,                              -- 备注
  created_at   timestamptz not null default now()
);

-- 索引（按 owner 隔离，排序/筛选更快）
create index if not exists clothes_owner_idx    on public.clothes (owner);
create index if not exists clothes_category_idx on public.clothes (owner, category);
create index if not exists clothes_price_idx    on public.clothes (owner, price);

-- 已建过表的用户升级用：追加购入平台、尺码列（可重复执行）
alter table public.clothes add column if not exists platform text;
alter table public.clothes add column if not exists size text;

-- 给匿名角色授予读写权限（个人试用；前端用 owner 字段做逻辑隔离）
grant select, insert, update, delete on public.clothes to anon;

-- 行级安全（RLS）：若表已启用 RLS（Table Editor 常引导开启），需建放行策略
drop policy if exists "clothes_public_all" on public.clothes;
create policy "clothes_public_all"
  on public.clothes
  for all
  to anon
  using (true)
  with check (true);

-- ============================================================
-- 2. 图片存储桶（public：图片公开可访问）
-- ============================================================
insert into storage.buckets (id, name, public)
values ('clothes', 'clothes', true)
on conflict (id) do nothing;

-- 3. 存储权限：允许匿名上传/更新/删除 clothes 桶内的对象
-- 注意：SELECT 策略必不可少——本环境（Supabase PG）的 DELETE/UPDATE 要求
-- 目标行同时对 SELECT 策略可见，缺它会导致删除静默匹配 0 行（403/空数组）
drop policy if exists clothes_storage_public_select on storage.objects;
create policy clothes_storage_public_select
  on storage.objects for select to anon
  using (bucket_id = 'clothes');

drop policy if exists clothes_storage_public_insert on storage.objects;
create policy clothes_storage_public_insert
  on storage.objects for insert to anon
  with check (bucket_id = 'clothes');

drop policy if exists clothes_storage_public_update on storage.objects;
create policy clothes_storage_public_update
  on storage.objects for update to anon
  using (bucket_id = 'clothes');

drop policy if exists clothes_storage_public_delete on storage.objects;
create policy clothes_storage_public_delete
  on storage.objects for delete to anon
  using (bucket_id = 'clothes');
