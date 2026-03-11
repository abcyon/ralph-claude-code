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

## 3. 실행

아래 명령을 백그라운드로 실행해. 출력은 `.ralph_plan.log`로 리다이렉트:

```bash
./loop.sh plan N > .ralph_plan.log 2>&1 &
echo $! > .ralph_pid
```

## 4. 결과 출력

실행 후 아래 형식으로 안내:

```
✅ /ralph_plan 시작 (plan mode, N회)

진행 상황 확인:
  cat .ralph_status        # 체크리스트
  tail -f .ralph_plan.log  # 전체 로그

중단하려면: kill $(cat .ralph_pid)
```
