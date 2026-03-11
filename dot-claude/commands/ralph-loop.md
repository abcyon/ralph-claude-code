아래 흐름대로 진행해줘.

## 1. 인수 파싱

사용자가 입력한 숫자가 있으면 그것을 N으로 사용. 없으면 N=5.

## 2. 사전 점검 + 실행 (단일 Bash 호출)

아래 스크립트를 **하나의 Bash 호출**로 실행해. 출력 코드를 파싱해서 후속 처리:

```bash
if [ -f .ralph_pid ] && kill -0 "$(cat .ralph_pid 2>/dev/null)" 2>/dev/null; then
  echo "CONFLICT:$(cat .ralph_pid)"
elif [ ! -f loop.sh ]; then
  echo "MISSING:loop.sh"
elif [ ! -f PROMPT_build.md ]; then
  echo "MISSING:PROMPT_build.md"
elif [ ! -f IMPLEMENTATION_PLAN.md ]; then
  echo "NO_PLAN"
else
  unset CLAUDECODE && ./loop.sh N > .ralph_loop.log 2>&1 &
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
  unset CLAUDECODE && ./loop.sh N > .ralph_loop.log 2>&1 &
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

- `MISSING:PROMPT_build.md` →
  ```
  ❌ PROMPT_build.md를 찾을 수 없어.
  /ralph-setup을 먼저 실행해줘.
  ```
  → 여기서 중단.

- `NO_PLAN` → 아래 메시지 출력 후 사용자에게 확인:
  ```
  ⚠️ IMPLEMENTATION_PLAN.md가 없어. /ralph-plan을 먼저 실행하는 걸 권장해.
  그냥 진행할까? (y/n)
  ```
  → y면 아래를 **하나의 Bash 호출**로 실행:
  ```bash
  unset CLAUDECODE && ./loop.sh N > .ralph_loop.log 2>&1 &
  PID=$!
  echo "$PID" > .ralph_pid
  echo "STARTED:$PID"
  ```
  → n이면 중단.

- `STARTED:<pid>` → 정상 시작. 3단계로 진행.

## 3. 결과 출력

실행 후 아래 형식으로 안내:

```
✅ /ralph-loop 시작 (build mode, N회)

진행 상황 확인:
  ./status.sh              # 실시간 상태
  cat .ralph_status        # 체크리스트
  tail -f .ralph_loop.log  # 전체 로그

중단하려면: kill $(cat .ralph_pid)
```
