아래 흐름대로 진행해줘.

## 1. 인수 파싱

사용자가 입력한 숫자가 있으면 그것을 N으로 사용. 없으면 N=1.

## 2. 사전 점검

다음 순서로 확인:

0. `.ralph_pid` 파일이 존재하고, 해당 PID 프로세스가 살아있으면:
   ```
   ⚠️ 이미 실행 중인 ralph 프로세스가 있어 (PID: <pid>).
   기존 프로세스를 중단하고 새로 시작할까? (y/n)
   ```
   → y면 `kill <pid>`, `.ralph_pid` 삭제 후 계속. n이면 중단.

1. `loop.sh` 없으면:
   ```
   ❌ loop.sh를 찾을 수 없어.
   먼저 /ralph-spec으로 스펙을 작성하고, /ralph-setup으로 초기 설정을 해줘.
   ```
   → 여기서 중단.

2. `PROMPT_plan.md` 없으면:
   ```
   ❌ PROMPT_plan.md를 찾을 수 없어.
   /ralph-setup을 먼저 실행해줘.
   ```
   → 여기서 중단.

## 3. 실행 전 질문

plan 시작 전에 loop 자동 연결 여부 확인:

```
plan 완료 후 loop를 자동으로 시작할까? (y/n)
```

사용자 답변을 `AUTO_LOOP` 변수로 기억해둬 (y 또는 n).

## 4. 실행

아래 명령을 백그라운드로 실행해. 출력은 `.ralph_plan.log`로 리다이렉트:

```bash
unset CLAUDECODE && ./loop.sh plan N > .ralph_plan.log 2>&1 &
echo $! > .ralph_pid
```

## 5. 결과 출력

실행 후 아래 형식으로 안내:

```
✅ /ralph-plan 시작 (plan mode, N회)

진행 상황 확인:
  ./status.sh              # 실시간 상태
  cat .ralph_status        # 체크리스트
  tail -f .ralph_plan.log  # 전체 로그

중단하려면: kill $(cat .ralph_pid)
```

## 6. 완료 감지 + auto-chaining

plan 프로세스 완료를 감지해야 해. 아래 로직을 실행:

1. `.ralph_pid`의 PID 프로세스가 종료될 때까지 5초 간격으로 폴링 (`kill -0 <pid>` 체크)
2. 프로세스 종료 후 `.ralph_status` 파일에 `Done.` 문자열이 포함되어 있는지 확인

**정상 완료 (`Done.` 있음):**
- `AUTO_LOOP`가 y → `/ralph-loop` 흐름을 자동 시작 (사전 점검부터 실행까지 그대로 수행)
- `AUTO_LOOP`가 n → 사용자에게 재질문:
  ```
  plan이 완료됐어. loop를 시작할까? (y/n)
  ```
  - y → `/ralph-loop` 흐름 시작
  - n → 종료

**비정상 종료 (`Done.` 없음):**
- loop 시작하지 않고 종료. 아래 메시지 출력:
  ```
  ⚠️ plan이 비정상 종료됐어. 로그를 확인해봐:
    tail -50 .ralph_plan.log
  ```
