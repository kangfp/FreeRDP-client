#!/usr/bin/env python3
"""验证看门狗包装脚本的三种场景:
A. 父进程被 SIGKILL (模拟应用崩溃/强退) -> 子进程应在 ~2s 内被终止, 参数文件被清理
B. 父进程向包装器发 SIGTERM (正常断开) -> 子进程退出, 退出码透传
C. 子进程自行退出 -> 包装器随之退出, 退出码透传, 参数文件清理
"""
import os, signal, subprocess, sys, time, tempfile

SCRIPT = r'''
PARENT=$PPID
"$1" "/args-from:file:$2" &
CHILD=$!
cleanup() {
    kill -TERM "$CHILD" 2>/dev/null
    i=0
    while [ "$i" -lt 30 ] && kill -0 "$CHILD" 2>/dev/null; do
        sleep 0.1
        i=$((i + 1))
    done
    kill -KILL "$CHILD" 2>/dev/null
}
trap cleanup TERM INT
while kill -0 "$PARENT" 2>/dev/null && kill -0 "$CHILD" 2>/dev/null; do
    sleep 1
done
cleanup
wait "$CHILD"
STATUS=$?
rm -f "$2"
exit $STATUS
'''

def make_args():
    fd, path = tempfile.mkstemp(prefix="rdptest_", suffix=".args")
    with os.fdopen(fd, "w") as f:
        f.write("/v:127.0.0.1\n/port:9\n/cert:ignore\n/log-level:ERROR\n")
    os.chmod(path, 0o600)
    return path

def descendants(pid):
    out = subprocess.run(["pgrep", "-P", str(pid)], capture_output=True, text=True).stdout.split()
    return [int(x) for x in out]

def alive(pid):
    try:
        os.kill(pid, 0)
        return True
    except ProcessLookupError:
        return False
    except PermissionError:
        return True

failures = []

# ---- 场景 A: 父进程被 SIGKILL ----
# 结构: python(父) -> sh(看门狗) -> sdl-freerdp
# python fork 一个中间父进程, 中间父进程启动 sh 后被 SIGKILL
args = make_args()
mid = os.fork()
if mid == 0:
    # 中间父进程: 启动看门狗后等待被杀
    sh = subprocess.Popen(["/bin/sh", "-c", SCRIPT, "watchdog", "sdl-freerdp", args])
    print(f"[A] 中间父进程 pid={os.getpid()}, 看门狗 pid={sh.pid}", flush=True)
    time.sleep(30)
    os._exit(0)
time.sleep(2.5)  # 等 freerdp 起来
sh_pids = descendants(mid)
assert sh_pids, "看门狗未启动"
sh_pid = sh_pids[0]
rdp_pids = descendants(sh_pid)
print(f"[A] 看门狗={sh_pid}, freerdp={rdp_pids}", flush=True)
os.kill(mid, signal.SIGKILL)
os.waitpid(mid, 0)
deadline = time.time() + 6
while time.time() < deadline and (alive(sh_pid) or any(alive(p) for p in rdp_pids)):
    time.sleep(0.3)
ok_a = not alive(sh_pid) and not any(alive(p) for p in rdp_pids) and not os.path.exists(args)
print(f"[A] 父进程被强杀后: 看门狗存活={alive(sh_pid)}, freerdp存活={[alive(p) for p in rdp_pids]}, 参数文件残留={os.path.exists(args)} -> {'PASS' if ok_a else 'FAIL'}")
if not ok_a:
    failures.append("A")
    for p in [sh_pid] + rdp_pids:
        try: os.kill(p, signal.SIGKILL)
        except ProcessLookupError: pass

# ---- 场景 B: SIGTERM 给看门狗, 退出码透传 ----
args = make_args()
sh = subprocess.Popen(["/bin/sh", "-c", SCRIPT, "watchdog", "sdl-freerdp", args])
time.sleep(2.5)
rdp_pids = descendants(sh.pid)
sh.send_signal(signal.SIGTERM)
try:
    rc = sh.wait(timeout=8)
except subprocess.TimeoutExpired:
    sh.kill(); rc = "TIMEOUT"
ok_b = isinstance(rc, int) and not any(alive(p) for p in rdp_pids) and not os.path.exists(args)
print(f"[B] SIGTERM: 退出码={rc}, freerdp残留={[alive(p) for p in rdp_pids]}, 文件残留={os.path.exists(args)} -> {'PASS' if ok_b else 'FAIL'}")
if not ok_b: failures.append("B")

# ---- 场景 C: 子进程自行退出 (用 /usr/bin/false 模拟, 退出码 1) ----
args = make_args()
sh = subprocess.Popen(["/bin/sh", "-c", SCRIPT, "watchdog", "/usr/bin/false", args])
try:
    rc = sh.wait(timeout=8)
except subprocess.TimeoutExpired:
    sh.kill(); rc = "TIMEOUT"
ok_c = rc == 1 and not os.path.exists(args)
print(f"[C] 子进程自退: 退出码={rc} (期望 1), 文件残留={os.path.exists(args)} -> {'PASS' if ok_c else 'FAIL'}")
if not ok_c: failures.append("C")

sys.exit(1 if failures else 0)
