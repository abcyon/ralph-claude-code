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
- **실행 전 질문**: plan 시작 전에 loop 자동 연결 여부 확인:
  ```
  plan 완료 후 loop를 자동으로 시작할까? (y/n)
  ```
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
- **완료 감지**: `.ralph_pid` 프로세스가 종료될 때까지 폴링 (5초 간격). 종료 후 `.ralph_status`에 `Done.` 포함 여부로 정상 완료 판별.
- **완료 후 동작**:
  - 정상 완료 + 사전 질문에서 y 답변 → loop 자동 시작 (`/ralph-loop` 흐름 그대로 실행)
  - 정상 완료 + 사전 질문에서 n 답변 → "loop 시작할까? (y/n)" 재질문
    - y → loop 시작
    - n → 종료
  - 비정상 종료 (강제 kill 등, `Done.` 없음) → loop 시작하지 않고 종료

#### Acceptance Criteria

- [ ] `/ralph-plan` (no args) → `./loop.sh plan 1` 실행
- [ ] `/ralph-plan 3` → `./loop.sh plan 3` 실행
- [ ] 실행 명령에 `unset CLAUDECODE &&` 포함
- [ ] `loop.sh` 없음 → 오류 + 안내
- [ ] `PROMPT_plan.md` 없음 → 오류 + 안내
- [ ] 출력이 현재 Claude 컨텍스트에 누적되지 않음 (로그 파일 리다이렉트)
- [ ] `.ralph_plan.log` 실행마다 생성/덮어씀
- [ ] 실행 전 "loop 자동 시작할까?" 질문
- [ ] plan 완료 감지: `.ralph_pid` 프로세스 종료 + `.ralph_status`에 `Done.` 확인
- [ ] 정상 완료 + 사전 y → loop 자동 시작
- [ ] 정상 완료 + 사전 n → loop 재질문 후 사용자 선택
- [ ] 비정상 종료 (`Done.` 없음) → loop 시작하지 않음

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
- **`Total: N`** — 태스크 총 개수 high-water mark (헤더 3번째 줄에 기록, 루프 내내 유지)
- 이터레이션 실행 중: IMPLEMENTATION_PLAN.md 태스크 목록 + 현재 실행 중인 항목 `[→]` 표시
- 이터레이션 완료 후: IMPLEMENTATION_PLAN.md 재읽어 최신 체크박스 상태 반영
- 토큰 한도 대기 중: `[!] Token limit — retrying at HH:MM:SS` 표시
- 전체 완료 시: 종료 시각 + `Done.` 표기

**`Total: N` high-water mark 규칙:**
- 매 `update_status` 호출 시 IMPLEMENTATION_PLAN.md의 현재 총 태스크 수(`[x]` + `[→]` + `[ ]`) 계산
- 현재 총 수 > 기존 `MAX_TOTAL`이면 `MAX_TOTAL` 갱신 (태스크 추가 반영)
- 현재 총 수 < 기존 `MAX_TOTAL`이면 `MAX_TOTAL` 유지 (태스크 정리 후에도 보존)
- `.ralph_status`에 `Total: $MAX_TOTAL` 로 기록

loop.sh가 수행해야 하는 추가 동작:

- 매 이터레이션 완료 후 IMPLEMENTATION_PLAN.md의 미완료 항목(`- [ ]`) 수 확인
- 미완료 항목 0개 → 루프 종료 (`Done.` 기록)
- claude 비정상 종료 시 출력에서 retry-after 파싱 → target time + 5분 대기
- PID 기록: `echo $$ > .ralph_pid`
- 종료 시 `.ralph_pid` 파일 삭제 (정상/비정상 종료 모두): `trap 'rm -f .ralph_pid' EXIT`

#### loop.sh Acceptance Criteria

- [ ] `.ralph_status`에 태스크 체크리스트 표시 (IMPLEMENTATION_PLAN.md 기반)
- [ ] IMPLEMENTATION_PLAN.md 없으면 태스크 목록 생략 (헤더만 표시)
- [ ] 이터레이션 완료 후 미완료 항목 0개이면 루프 자동 종료
- [ ] 루프 종료 시 `.ralph_status`에 `Done.` + 종료 시각 기록
- [ ] rate limit 오류 시 retry-after 파싱 후 target + 5분 대기
- [ ] 파싱 실패 시 5분 고정 대기
- [ ] 대기 중 `.ralph_status`에 재시도 예정 시각 표시
- [ ] `.ralph_pid`에 PID 기록
- [ ] 종료 시 (정상/비정상 모두) `.ralph_pid` 파일 삭제
- [ ] `.ralph_status`에 `Total: N` 기록 (high-water mark)
- [ ] 태스크 추가 시 Total 증가, 태스크 정리 후에도 Total 유지

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
- TOTAL = `.ralph_status`의 `Total: N` 값 (high-water mark, loop.sh가 기록)
- PENDING = `.ralph_status`의 `[ ]` + `[→]` 줄 수
- COMPLETED = TOTAL - PENDING (태스크 정리 후에도 정확한 완료 수 유지)
- ETA = `경과 시간 ÷ 완료 태스크 수 × 남은 태스크 수`

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
- [ ] TOTAL은 `.ralph_status`의 `Total: N` 값 사용 (태스크 정리 후에도 유지)
- [ ] COMPLETED = TOTAL - PENDING (PENDING은 현재 `[ ]` + `[→]` 수)
- [ ] 태스크가 IMPLEMENTATION_PLAN.md에서 정리돼도 진행률 정확히 유지
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

## Bug Fixes

### `write_tasks()` — Status Legend 줄이 태스크로 파싱되는 버그

**Current Behavior**: IMPLEMENTATION_PLAN.md 상단의 Status Legend 섹션:
```
- [ ] = not started
- [→] = in progress
- [x] = complete
```
이 줄들이 `write_tasks()` awk 패턴에 매칭되어 실제 태스크로 `.ralph_status`에 기록됨. 결과적으로 진행률 카운트가 부풀려지고(`[x] = complete`가 완료 태스크로 카운트), `[→] = not started — running...` 등 오염된 태스크가 표시됨.

**Expected Behavior**: Legend 줄 무시. `write_tasks()`에서 체크박스 마커 제거 후 텍스트가 `= `으로 시작하는 줄은 건너뜀.

**Fix**: `write_tasks()` awk 블록에서 marker 제거 후 `if (line ~ /^=/) next` 추가.

**Regression Guard**: 정상 태스크(`- [ ] **실제 태스크 설명**`)는 영향 없음.

#### Acceptance Criteria

- [ ] `- [ ] = not started` 줄이 `.ralph_status` 태스크 목록에 포함되지 않음
- [ ] `- [x] = complete` 줄이 완료 태스크로 카운트되지 않음
- [ ] `- [→] = in progress` 줄이 진행 중 태스크로 표시되지 않음
- [ ] 정상 태스크는 그대로 파싱됨

### `status.sh` — `grep -c` 0개 매치 시 PENDING 이중 출력 버그

**Current Behavior**: `PENDING=$(grep -Ec '^\[ \]|^\[→\]' .ralph_status 2>/dev/null || echo "0")` — `grep -c`는 매치 0개일 때 `"0"` 출력 + exit code 1 반환. `|| echo "0"`도 실행되어 `PENDING="0\n0"`. 이후 `$((TOTAL - PENDING))` 산술식에서 오류 발생:
```
./status.sh: line 70: 0
0: syntax error in expression (error token is "0")
```

**Expected Behavior**: `PENDING`이 항상 단일 숫자(0 이상)로 설정됨.

**Fix**: `|| echo "0"` 제거 후 `PENDING=${PENDING:-0}` 로 기본값 처리.
```bash
PENDING=$(grep -Ec '^\[ \]|^\[→\]' .ralph_status 2>/dev/null)
PENDING=${PENDING:-0}
```

동일 패턴이 `loop-scripts.md` status.sh 템플릿에도 존재 → 동시 수정 필요.

**Regression Guard**: PENDING > 0인 경우 동작 변화 없음.

#### Acceptance Criteria

- [ ] IMPLEMENTATION_PLAN.md 존재 + 미완료 태스크 없을 때 `status.sh` 오류 없이 실행됨
- [ ] `PENDING=0` 일 때 `[████████████████] N/N 100% 완료!` 표시
- [ ] `loop-scripts.md` status.sh 템플릿도 동일하게 수정됨

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
