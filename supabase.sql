-- ============================================================
-- 衣橱 H5 · Supabase 初始化脚本
-- 用法：Supabase Dashboard -> SQL Editor -> 整段粘贴 -> Run
-- ============================================================

-- 1. 建表：衣服
create table if not exists public.clothes (
  id           uuid primary key default gen_random_uuid(),
  owner        text not null default '',          -- 设备标识，用于数据隔离
  name         text not null,                     -- 名称
  category     text not null default '其他',       -- 分类：上衣/下装/连衣裙/外套/鞋/配饰/其他
  color        text,                              -- 颜色（hex 色值）
  seasons      text[] not null default '{}',      -- 季节数组：春/夏/秋/冬
  gender       text not null default '中性',       -- 性别：男/女/中性
  price        numeric(12,2) not null default 0,  -- 金额（元）
  purchased_at date,                              -- 购入时间
  image_url    text,                              -- 图片公开 URL
  note         text,                              -- 备注
  created_at   timestamptz not null default now()
);

-- 索引（按 owner 隔离，排序/筛选更快）
create index if not exists clothes_owner_idx    on public.clothes (owner);
create index if not exists clothes_category_idx on public.clothes (owner, category);
create index if not exists clothes_price_idx    on public.clothes (owner, price);

-- 给匿名角色授予读写权限（个人试用；前端用 owner 字段做逻辑隔离）
grant select, insert, update, delete on public.clothes to anon;

-- ============================================================
-- 2. 图片存储桶（public：图片公开可访问）
-- ============================================================
insert into storage.buckets (id, name, public)
values ('clothes', 'clothes', true)
on conflict (id) do nothing;

-- 3. 存储权限：允许匿名上传/更新/删除 clothes 桶内的对象
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
