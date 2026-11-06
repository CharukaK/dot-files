#!/bin/sh
address=""
stop_run() {
  if [ -n "$address" ]; then
    '/home/charuka/.local/bin/hc' kill "$address" >/dev/null 2>&1 || true
  fi
}
trap 'stop_run; exit 143' HUP INT TERM
existing=$('/home/charuka/.local/bin/hc' ls --json --label 'herdr.schedule=mw5700so-9g42ht')
existing_code=$?
[ "$existing_code" -eq 0 ] || exit "$existing_code"
case "$existing" in
  *'"terminals":[]'*) ;;
  *) printf '%s\n' "A previous run is still live; skipping."; exit 0 ;;
esac
run_id="$(date -u +%Y%m%dT%H%M%SZ)-$$"
started=$('/home/charuka/.local/bin/hc' 'run' '--bg' '--json' '--no-parent' '--cwd' '/home/charuka/yo/hee' '--label' 'herdr.space=schedule-mw5700so-9g42ht' '--label' 'herdr.schedule=mw5700so-9g42ht' --label "herdr.tab=schedule-mw5700so-9g42ht-$run_id" --label "herdr.run=$run_id" -- '/usr/bin/zsh' '-lic' ''\''pi'\''')
start_code=$?
printf '%s\n' "$started"
[ "$start_code" -eq 0 ] || exit "$start_code"
address=$(printf '%s\n' "$started" | sed -n 's/.*"address":"\([^"]*\)".*/\1/p')
[ -n "$address" ] || exit 1
'/home/charuka/.local/bin/hc' send "$address" 'You say hello and create a dated txt file' || { stop_run; exit 1; }
tries=0
while [ "$tries" -lt 120 ]; do
  current=$('/home/charuka/.local/bin/hc' get "$address" --json) || break
  case "$current" in
    *'"state":"finished"'*) break ;;
    *'"status":'*'"state":"working"'*|*'"status":'*'"state":"blocked"'*|*'"status":'*'"state":"error"'*|*'"status":'*'"state":"idle"'*|*'"status":'*'"state":"done"'*) break ;;
  esac
  tries=$((tries + 1))
  sleep 0.5
done
while :; do
  waited=$('/home/charuka/.local/bin/hc' wait --json --timeout 31536000 "$address")
  wait_code=$?
  printf '%s\n' "$waited"
  case "$waited" in
    *'"status":"blocked"'*|*'"status":"error"'*)
      while :; do
        sleep 15
        current=$('/home/charuka/.local/bin/hc' get "$address" --json) || exit "$wait_code"
        case "$current" in
          *'"state":"finished"'*) exit "$wait_code" ;;
          *'"status":'*'"state":"blocked"'*|*'"status":'*'"state":"error"'*) ;;
          *) break ;;
        esac
      done
      ;;
    *)
      '/home/charuka/.local/bin/hc' kill "$address" >/dev/null 2>&1 || true
      exit "$wait_code"
      ;;
  esac
done
