아래 흐름대로 진행해줘.

## 1. 인수 파싱

사용자가 입력한 숫자가 있으면 그것을 N으로 사용. 없으면 N=1.

## 2. 실행 전 질문

plan 시작 전에 loop 자동 연결 여부 확인:

```
plan 완료 후 loop를 자동으로 시작할까? (y/n)
```

사용자 답변을 `AUTO_LOOP` 변수로 기억해둬 (y 또는 n).

## 3. 사전 점검 + 실행 (단일 Bash 호출)

아래 스크립트를 **하나의 Bash 호출**로 실행해. 출력 코드를 파싱해서 후속 처리:

```bash
if [ -f .ralph_pid ] && kill -0 "$(cat .ralph_pid 2>/dev/null)" 2>/dev/null; then
  echo "CONFLICT:$(cat .ralph_pid)"
elif [ ! -f loop.sh ]; then
  echo "MISSING:loop.sh"
elif [ ! -f PROMPT_plan.md ]; then
  echo "MISSING:PROMPT_plan.md"
else
  unset CLAUDECODE && ./loop.sh plan N > .ralph_plan.log 2>&1 &
  PID=$!
  echo "$PID" > .ralph_pid
  echo "STARTED:$PID"
fi
```

**출력 코드 처리:**

- `CONFLICT:<pid>` → 아래 메시지 출력 후 사용자에게 확인:
  ```
  ⚠️ 이미 실행 중인 ralph 프로세스가 있어 (PID: <pid>).
  기존 프로세스를 중단하고 새로 시작할까? (y/n)
  ```
  → y면 아래를 **하나의 Bash 호출**로 실행:
  ```bash
  kill <pid> 2>/dev/null; rm -f .ralph_pid; sleep 1
  unset CLAUDECODE && ./loop.sh plan N > .ralph_plan.log 2>&1 &
  PID=$!
  echo "$PID" > .ralph_pid
  echo "STARTED:$PID"
  ```
  → n이면 중단.

- `MISSING:loop.sh` →
  ```
  ❌ loop.sh를 찾을 수 없어.
  먼저 /ralph-spec으로 스펙을 작성하고, /ralph-setup으로 초기 설정을 해줘.
  ```
  → 여기서 중단.

- `MISSING:PROMPT_plan.md` →
  ```
  ❌ PROMPT_plan.md를 찾을 수 없어.
  /ralph-setup을 먼저 실행해줘.
  ```
  → 여기서 중단.

- `STARTED:<pid>` → 정상 시작. 4단계로 진행.

## 4. 결과 출력

실행 후 아래 형식으로 안내:

```
✅ /ralph-plan 시작 (plan mode, N회)

진행 상황 확인:
  ./status.sh              # 실시간 상태
  cat .ralph_status        # 체크리스트
  tail -f .ralph_plan.log  # 전체 로그

중단하려면: kill $(cat .ralph_pid)
```

## 5. 완료 감지 + auto-chaining

plan 프로세스 완료를 감지해야 해. 아래 로직을 실행:

1. `.ralph_pid`의 PID 프로세스가 종료될 때까지 **30초 간격**으로 폴링 (`kill -0 <pid>` 체크). **타임아웃 30분** — 30분 초과 시 폴링 중단 후 아래 메시지 출력:
   ```
   ⚠️ plan이 30분 이상 응답이 없어. 로그를 확인해봐:
     tail -50 .ralph_plan.log
   ```
2. 프로세스 종료 후 `.ralph_status` 파일에 `Done.` 문자열이 포함되어 있는지 확인

**정상 완료 (`Done.` 있음):**
- `AUTO_LOOP`가 y → `/ralph-loop` 흐름을 **사용자 개입 없이** 자동 시작. 아래 사전 점검은 모두 건너뜀:
  - PID 충돌 체크 — plan 프로세스가 이미 종료되어 `.ralph_pid` 삭제됨
  - IMPLEMENTATION_PLAN.md 확인 질문 — plan이 방금 완료됐으므로 존재 보장
  - 바로 `/ralph-loop`의 **3. 사전 점검 + 실행** 단계로 진입 (N=5 기본값).
- `AUTO_LOOP`가 n → 사용자에게 재질문:
  ```
  plan이 완료됐어. loop를 시작할까? (y/n)
  ```
  - y → `/ralph-loop` 흐름 시작 (전체 흐름, 사전 점검 포함)
  - n → 종료

**비정상 종료 (`Done.` 없음):**
- loop 시작하지 않고 종료. 아래 메시지 출력:
  ```
  ⚠️ plan이 비정상 종료됐어. 로그를 확인해봐:
    tail -50 .ralph_plan.log
  ```
