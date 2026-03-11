# Spec: /ralph-plan & /ralph-loop Commands + loop.sh 동작

## Overview

Two slash commands that run `loop.sh` from within Claude Code — no external shell needed.
Execution output is redirected to a log file to avoid context accumulation.
Progress is tracked via `.ralph_status` file and optionally via `status.sh`.

---

## Current Behavior (변경 전)

| 항목 | 현재 동작 |
|---|---|
| 중첩 세션 | `CLAUDECODE` env var 미해제 → Claude Code 내부 실행 시 중첩 오류 |
| 상태 표시 | `.ralph_status`에 iteration 번호만 표시 (태스크 목록 없음) |
| 토큰 부족 | `sleep 5` 고정 후 재시도 (retry-after 파싱 없음) |
| 완료 감지 | MAX_ITERATIONS 도달 시만 종료 (구현 완료 감지 없음) |
| 실시간 모니터링 | `status.sh` 없음 |

---

## Expected Behavior (변경 후)

### 1. 중첩 세션 오류 회피

`/ralph-plan`, `/ralph-loop` 커맨드에서 loop.sh 실행 시 `unset CLAUDECODE` 선행:

```bash
unset CLAUDECODE && ./loop.sh plan N > .ralph_plan.log 2>&1 &
unset CLAUDECODE && ./loop.sh N > .ralph_loop.log 2>&1 &
```

### 2. `status.sh` — 실시간 진행 상황 확인

새 스크립트 `status.sh`. 초 단위 자동 갱신:

```bash
./status.sh          # 기본: 2초마다 갱신
./status.sh 5        # 5초마다 갱신
```

출력 형식:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Ralph Status  [2026-03-11 14:35:22]  Elapsed: 00:03:21
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Mode: build | Iteration: 3 | Branch: main
Started: 2026-03-11 14:32:01

── Tasks ──────────────────────────────
[x] DB 스키마 설계 및 마이그레이션
[x] 사용자 인증 API 구현
[ ] 대시보드 데이터 집계 로직
[ ] 프론트엔드 컴포넌트 연결
[ ] E2E 테스트 작성
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

- `IMPLEMENTATION_PLAN.md` 없으면 `.ralph_status` 내용만 표시
- 로그 출력 없음 (너무 길어 가독성 저해)
- Ctrl+C로 종료

### 3. `.ralph_status` 포맷 변경

Iteration은 헤더에 정보성으로만 표기. 태스크 목록은 `IMPLEMENTATION_PLAN.md`의 `- [ ]` / `- [x]` 항목을 그대로 반영.

실행 중:

```
Mode: build | Iteration: 3 | Branch: main
Started: 2026-03-11 14:32:01

[x] DB 스키마 설계 및 마이그레이션
[x] 사용자 인증 API 구현
[→] 대시보드 데이터 집계 로직 — running...
[ ] 프론트엔드 컴포넌트 연결
[ ] E2E 테스트 작성
```

완료 시:

```
Mode: build | Iteration: 5 | Branch: main
Started: 2026-03-11 14:32:01 | Finished: 2026-03-11 14:45:10

[x] DB 스키마 설계 및 마이그레이션
[x] 사용자 인증 API 구현
[x] 대시보드 데이터 집계 로직
[x] 프론트엔드 컴포넌트 연결
[x] E2E 테스트 작성

Done.
```

- `IMPLEMENTATION_PLAN.md` 없으면 태스크 목록 생략 (헤더만 표시)
- 현재 실행 중인 항목은 `[→] ... — running...` 으로 표시 (첫 번째 `[ ]` 항목)

### 4. 토큰 부족 시 대기 후 재시도

claude 종료 코드가 비정상(≠0)이고 출력에서 rate limit / token 관련 오류 감지 시:

1. claude 출력(스트림 JSON)에서 `retry-after` 또는 타임스탬프 파싱 시도
2. 파싱 성공: `target_time + 5분` 까지 대기
3. 파싱 실패: 5분 고정 대기
4. 대기 중 `.ralph_status`에 남은 시간 표시:
   ```
   [!] Token limit — retrying at 14:52:00 (5분 후)
   ```
5. 대기 완료 후 동일 이터레이션 재시도 (ITERATION 증가 없음)

rate limit 외 다른 오류(브랜치 변경, 파일 없음 등)는 기존 동작 유지.

### 5. 구현 완료 시 루프 자동 종료

매 이터레이션 완료 후 `IMPLEMENTATION_PLAN.md`를 확인:
- 파일 내 `- [ ]` 항목이 0개이면 → 완료로 판단, 루프 종료
- 종료 전 `.ralph_status`에 `Done.` 기록

판단 조건: `grep -c '^\s*- \[ \]\|^\s*- \[→\]' IMPLEMENTATION_PLAN.md` == 0 (미완료 `[ ]` + 진행 중 `[→]` 모두 카운트)

---

## Commands

### `/ralph-plan [n]`

- **Argument**: `n` = number of iterations (default: `1`)
- **사전 점검** (순서대로):
  1. `.ralph_pid` 존재 + PID 살아있으면 → 기존 프로세스 중단 여부 확인 (y/n)
  2. `loop.sh` 없으면 → 오류 + `/ralph-spec` → `/ralph-setup` 안내
  3. `PROMPT_plan.md` 없으면 → 오류 + `/ralph-setup` 안내
- **실행**: `unset CLAUDECODE && ./loop.sh plan N > .ralph_plan.log 2>&1 &`
- **로그**: `.ralph_plan.log` (실행마다 덮어씀)
- **실행 후 안내**:
  ```
  ✅ /ralph-plan 시작 (plan mode, N회)

  진행 상황 확인:
    ./status.sh          # 실시간 상태
    cat .ralph_status    # 체크리스트
    tail -f .ralph_plan.log  # 전체 로그

  중단하려면: kill $(cat .ralph_pid)
  ```

#### Acceptance Criteria

- [ ] `/ralph-plan` (no args) → `./loop.sh plan 1` 실행
- [ ] `/ralph-plan 3` → `./loop.sh plan 3` 실행
- [ ] 실행 명령에 `unset CLAUDECODE &&` 포함
- [ ] `loop.sh` 없음 → 오류 + 안내
- [ ] `PROMPT_plan.md` 없음 → 오류 + 안내
- [ ] 출력이 현재 Claude 컨텍스트에 누적되지 않음 (로그 파일 리다이렉트)
- [ ] `.ralph_plan.log` 실행마다 생성/덮어씀

---

### `/ralph-loop [n]`

- **Argument**: `n` = number of iterations (default: `5`)
- **사전 점검** (순서대로):
  1. `.ralph_pid` 존재 + PID 살아있으면 → 기존 프로세스 중단 여부 확인 (y/n)
  2. `loop.sh` 없으면 → 오류 + `/ralph-spec` → `/ralph-setup` 안내
  3. `PROMPT_build.md` 없으면 → 오류 + `/ralph-setup` 안내
  4. `IMPLEMENTATION_PLAN.md` 없으면 → 경고 + `/ralph-plan` 먼저 실행 권장 (y/n)
- **실행**: `unset CLAUDECODE && ./loop.sh N > .ralph_loop.log 2>&1 &`
- **로그**: `.ralph_loop.log` (실행마다 덮어씀)
- **실행 후 안내**:
  ```
  ✅ /ralph-loop 시작 (build mode, N회)

  진행 상황 확인:
    ./status.sh          # 실시간 상태
    cat .ralph_status    # 체크리스트
    tail -f .ralph_loop.log  # 전체 로그

  중단하려면: kill $(cat .ralph_pid)
  ```

#### Acceptance Criteria

- [ ] `/ralph-loop` (no args) → `./loop.sh 5` 실행
- [ ] `/ralph-loop 20` → `./loop.sh 20` 실행
- [ ] 실행 명령에 `unset CLAUDECODE &&` 포함
- [ ] `loop.sh` 없음 → 오류 + 안내
- [ ] `PROMPT_build.md` 없음 → 오류 + 안내
- [ ] `IMPLEMENTATION_PLAN.md` 없음 → 경고 + 확인 요청
- [ ] 출력이 현재 Claude 컨텍스트에 누적되지 않음
- [ ] `.ralph_loop.log` 실행마다 생성/덮어씀

---

## `loop.sh` 동작 요구사항

loop.sh가 `.ralph_status`에 기록해야 하는 내용:

- 실행 시작 시: mode, iteration 번호, branch, 시작 시각
- 이터레이션 실행 중: IMPLEMENTATION_PLAN.md 태스크 목록 + 현재 실행 중인 항목 `[→]` 표시
- 이터레이션 완료 후: IMPLEMENTATION_PLAN.md 재읽어 최신 체크박스 상태 반영
- 토큰 한도 대기 중: `[!] Token limit — retrying at HH:MM:SS` 표시
- 전체 완료 시: 종료 시각 + `Done.` 표기

loop.sh가 수행해야 하는 추가 동작:

- 매 이터레이션 완료 후 IMPLEMENTATION_PLAN.md의 미완료 항목(`- [ ]`) 수 확인
- 미완료 항목 0개 → 루프 종료 (`Done.` 기록)
- claude 비정상 종료 시 출력에서 retry-after 파싱 → target time + 5분 대기
- PID 기록: `echo $$ > .ralph_pid`

#### loop.sh Acceptance Criteria

- [ ] `.ralph_status`에 태스크 체크리스트 표시 (IMPLEMENTATION_PLAN.md 기반)
- [ ] IMPLEMENTATION_PLAN.md 없으면 태스크 목록 생략 (헤더만 표시)
- [ ] 이터레이션 완료 후 미완료 항목 0개이면 루프 자동 종료
- [ ] 루프 종료 시 `.ralph_status`에 `Done.` + 종료 시각 기록
- [ ] rate limit 오류 시 retry-after 파싱 후 target + 5분 대기
- [ ] 파싱 실패 시 5분 고정 대기
- [ ] 대기 중 `.ralph_status`에 재시도 예정 시각 표시
- [ ] `.ralph_pid`에 PID 기록

---

## `status.sh` 요구사항

신규 스크립트. `status.sh [interval]` (기본 2초):

- `.ralph_status` 파일 내용 출력
- Elapsed time 계산 (Started 시각 기준)
- 프로그레스 바 + 퍼센트 + ETA 표시 (태스크 목록 위에 배치)
- 로그 파일 출력 없음 (너무 길어 가독성 저해)
- `clear` 후 재출력 방식으로 초 단위 갱신
- Ctrl+C로 종료

### 출력 형식

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Ralph Status  [2026-03-11 14:35:22]  Elapsed: 00:03:21
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
▶ BUILD MODE  |  Iteration: 3  |  Branch: main
Started: 2026-03-11 14:32:01

── Progress ────────────────────────────
[████████░░░░░░░░]  5/8  62%  ETA: ~14분

── Tasks ───────────────────────────────
[x] DB 스키마 설계 및 마이그레이션
[x] 사용자 인증 API 구현
[→] 대시보드 데이터 집계 로직 — running...
[ ] 프론트엔드 컴포넌트 연결
[ ] E2E 테스트 작성

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Mode 표기 규칙:**
- plan 모드: `▶ PLAN MODE`
- build 모드: `▶ BUILD MODE`
- plan-work 모드: `▶ PLAN-WORK MODE`

**프로그레스 바:**
- 16칸 `█` / `░` 조합으로 진행률 시각화
- 완료(`[x]`) 태스크만 완료로 계산. 진행 중(`[→]`)은 미완료로 포함
- ETA = `경과 시간 ÷ 완료 태스크 수 × 남은 태스크 수` (완료 + 진행 중 포함)

**엣지 케이스별 출력:**

| 상황 | Progress 섹션 출력 |
|---|---|
| 완료 태스크 0개 | `[░░░░░░░░░░░░░░░░]  0/N   0%  ETA: 예측 중...` |
| 전체 완료 | `[████████████████]  N/N  100%  완료!` |
| IMPLEMENTATION_PLAN.md 없음 | `IMPLEMENTATION_PLAN.md 없음 — ./loop.sh plan 먼저 실행 필요` |

#### status.sh Acceptance Criteria

- [ ] `./status.sh` → 2초마다 갱신
- [ ] `./status.sh 5` → 5초마다 갱신
- [ ] `.ralph_status` 없으면 "ralph가 실행 중이지 않아" 메시지 출력
- [ ] Elapsed time 표시 (`00:03:21` 포맷)
- [ ] Mode가 `▶ PLAN MODE` / `▶ BUILD MODE` / `▶ PLAN-WORK MODE` 중 하나로 명확히 표시
- [ ] `── Progress ──` 섹션이 태스크 목록 위에 표시됨
- [ ] 프로그레스 바 16칸, 퍼센트, ETA 함께 표시
- [ ] 완료 태스크 0개 → ETA "예측 중..." 표시
- [ ] 전체 완료 → "완료!" 표시
- [ ] IMPLEMENTATION_PLAN.md 없음 → "plan 먼저 실행 필요" 메시지
- [ ] 로그 출력 없음
- [ ] Ctrl+C로 정상 종료

---

## Regression Guard

변경 후 깨지면 안 되는 기존 동작:

- `./loop.sh plan N` 직접 실행 (터미널 방식) 정상 동작
- `./loop.sh N` 직접 실행 정상 동작
- 브랜치 변경 guard (루프 중 브랜치 바뀌면 즉시 중단)
- `plan-work` 모드 동작
- git push 실패 시 루프 중단
- MAX_ITERATIONS 도달 시 종료

---

## Distribution

`dot-claude/commands/ralph-plan.md`, `ralph-loop.md` → `install.sh`로 `~/.claude/commands/`에 설치.
`loop.sh`, `status.sh` → `/ralph-setup` 커맨드가 프로젝트 루트에 생성.

---

## Edge Cases

- **IMPLEMENTATION_PLAN.md 없음**: `.ralph_status`에 태스크 목록 생략, 완료 감지 비활성화
- **retry-after 파싱 실패**: 5분 고정 대기
- **동시 실행**: 기존 PID 살아있으면 사용자에게 확인 요청
- **n=0**: 무제한 실행 (MAX_ITERATIONS=0)
- **status.sh + ralph_status 없음**: "ralph가 실행 중이지 않아" 출력 후 대기

---

## Non-Goals

- 웹 UI / 대시보드
- 팀 / 멀티유저 기능
- `status.sh` 외 별도 모니터링 도구
- retry-after 외 기타 오류에 대한 자동 복구
