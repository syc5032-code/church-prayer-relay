-- ========================================================
-- 뉴사운드교회 6차 성전 릴레이기도 Supabase 클라우드 스키마
-- Supabase 대시보드 -> SQL Editor에 붙여넣고 [Run]을 누르세요.
-- ========================================================

-- 1. 기도 신청 테이블 (prayer_bookings)
CREATE TABLE IF NOT EXISTS public.prayer_bookings (
    id TEXT PRIMARY KEY,
    day_num INTEGER NOT NULL,
    hour INTEGER NOT NULL CHECK (hour >= 0 AND hour <= 23),
    name TEXT NOT NULL,
    cell TEXT NOT NULL,
    pin TEXT NOT NULL,
    booked_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 빠른 검색을 위한 인덱스 생성
CREATE INDEX IF NOT EXISTS idx_prayer_bookings_day ON public.prayer_bookings(day_num);
CREATE INDEX IF NOT EXISTS idx_prayer_bookings_day_hour ON public.prayer_bookings(day_num, hour);

-- 2. 릴레이 스케줄 및 관리자 설정 테이블 (relay_config)
CREATE TABLE IF NOT EXISTS public.relay_config (
    id TEXT PRIMARY KEY DEFAULT 'main_config',
    config_data JSONB NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Row Level Security (RLS) 설정
ALTER TABLE public.prayer_bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.relay_config ENABLE ROW LEVEL SECURITY;

-- 기존 정책 삭제 (재실행 시 충돌 방지)
DROP POLICY IF EXISTS "모든 사용자 기도 신청 조회 허용" ON public.prayer_bookings;
DROP POLICY IF EXISTS "모든 사용자 기도 신청 등록 허용" ON public.prayer_bookings;
DROP POLICY IF EXISTS "모든 사용자 기도 신청 삭제 허용" ON public.prayer_bookings;

DROP POLICY IF EXISTS "모든 사용자 설정 조회 허용" ON public.relay_config;
DROP POLICY IF EXISTS "관리자 설정 등록 및 수정 허용" ON public.relay_config;

-- 성도 누구나 기도 현황 조회 및 신청 가능
CREATE POLICY "모든 사용자 기도 신청 조회 허용" 
ON public.prayer_bookings FOR SELECT USING (true);

CREATE POLICY "모든 사용자 기도 신청 등록 허용" 
ON public.prayer_bookings FOR INSERT WITH CHECK (true);

CREATE POLICY "모든 사용자 기도 신청 삭제 허용" 
ON public.prayer_bookings FOR DELETE USING (true);

-- 설정 테이블 정책
CREATE POLICY "모든 사용자 설정 조회 허용" 
ON public.relay_config FOR SELECT USING (true);

CREATE POLICY "관리자 설정 등록 및 수정 허용" 
ON public.relay_config FOR ALL USING (true) WITH CHECK (true);

-- 4. 실시간 동기화(Supabase Realtime) 활성화
-- 다른 성도가 신청/취소 시 화면 새로고침 없이 즉각 반영
BEGIN;
  DROP PUBLICATION IF EXISTS supabase_realtime;
  CREATE PUBLICATION supabase_realtime FOR TABLE public.prayer_bookings, public.relay_config;
COMMIT;

-- 5. 기본 설정 초기값 삽입 (없을 경우)
INSERT INTO public.relay_config (id, config_data, updated_at)
VALUES (
  'main_config',
  '{
    "startDate": "2026-08-18",
    "startDayNum": 134,
    "startRound": 6,
    "totalDays": 120,
    "excludeFriday": false,
    "excludeSunday": true,
    "leaderQueue": [
      { "name": "김용태", "role": "군단리더" },
      { "name": "이연경", "role": "군단리더" },
      { "name": "박진호", "role": "군단리더" },
      { "name": "김은진", "role": "군단리더", "note": "1차" },
      { "name": "이성령", "role": "군단리더" },
      { "name": "김태홍", "role": "군단리더", "note": "1차" },
      { "name": "천은빈", "role": "군단리더" },
      { "name": "유정심", "role": "리더" },
      { "name": "서진환", "role": "군단리더" },
      { "name": "최윤석", "role": "군단리더" },
      { "name": "김우람", "role": "군단리더" },
      { "name": "김은진", "role": "군단리더", "note": "2차" },
      { "name": "강수오", "role": "군단리더" },
      { "name": "김정금", "role": "군단리더" },
      { "name": "이성재", "role": "군단리더" },
      { "name": "김태홍", "role": "군단리더", "note": "2차" },
      { "name": "라하라", "role": "군단리더" },
      { "name": "김은진", "role": "군단리더", "note": "3차" },
      { "name": "장한나", "role": "군단리더" },
      { "name": "천시온", "role": "군단리더" },
      { "name": "곽신재", "role": "군단리더" },
      { "name": "이정화", "role": "군단리더" },
      { "name": "김성현", "role": "군단리더" },
      { "name": "류고운", "role": "군단리더" },
      { "name": "최순호", "role": "군단리더" }
    ],
    "blackoutDates": {}
  }'::jsonb,
  NOW()
)
ON CONFLICT (id) DO NOTHING;
