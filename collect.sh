#!/bin/sh
# Emits TYPE<TAB>KB<TAB>PID<TAB>NAME<TAB>DETAIL per line, sorted, capped.
# P = process (killable), F = free (pinned), S = system bucket, T = total.
# Process rows use private memory (resident - shared) so they sum to AnonPages;
# RSS would double-count shared pages and overshoot MemTotal against the buckets.

CAP=60

# comm alone is useless for interpreters and browser helpers: six identical
# "python3" rows, a dozen "chromium". Resolve a distinguishing detail, but only
# for rows that survive the cap, otherwise this forks for 250 processes.
detail_for() {
  _pid=$1
  _comm=$2
  _cmd=$(tr '\0' '\n' < "/proc/$_pid/cmdline" 2>/dev/null)
  [ -z "$_cmd" ] && return

  _t=$(printf '%s\n' "$_cmd" | sed -n 's/^--type=//p' | head -1)
  if [ -n "$_t" ]; then
    printf '%s' "$_t"
    return
  fi

  case "$_comm" in
    python*|node|bun|ruby|perl|java)
      _s=$(printf '%s\n' "$_cmd" | sed -n '2,$p' | grep -v '^-' | head -1)
      [ -n "$_s" ] && printf '%s' "$(basename "$_s")"
      ;;
    claude|bash|sh|zsh|fish|nvim|vim|git)
      _c=$(readlink "/proc/$_pid/cwd" 2>/dev/null)
      [ -n "$_c" ] && printf '%s' "$(basename "$_c")"
      ;;
  esac
}

{
  awk 'FNR==1{
    split(FILENAME,a,"/"); pid=a[3]; kb=($2-$3)*4
    if (kb>0) {
      c=""; f="/proc/" pid "/comm"; getline c < f; close(f)
      if (c!="") printf "P\t%d\t%s\t%s\n", kb, pid, c
    }
  }' /proc/[0-9]*/statm 2>/dev/null

  awk '
  /^MemTotal:/{t=$2} /^MemFree:/{f=$2} /^MemAvailable:/{av=$2} /^Buffers:/{b=$2} /^Cached:/{c=$2}
  /^Shmem:/{sh=$2} /^Slab:/{sl=$2} /^PageTables:/{pt=$2}
  /^KernelStack:/{ks=$2} /^VmallocUsed:/{vm=$2}
  END{
    printf "S\t%d\t-\tPage cache\n", c-sh
    printf "S\t%d\t-\tKernel slab\n", sl
    printf "S\t%d\t-\ttmpfs / shm\n", sh
    printf "S\t%d\t-\tDisk buffers\n", b
    printf "S\t%d\t-\tKernel\n", pt+ks+vm
    printf "F\t%d\t-\tAvailable\n", av
  }' /proc/meminfo 2>/dev/null

  for z in /sys/block/zram*/mm_stat; do
    [ -r "$z" ] || continue
    awk -v n="$(basename "$(dirname "$z")")" '$3>0{printf "S\t%d\t-\t%s (compressed swap)\n", $3/1024, n}' "$z"
  done 2>/dev/null
} | sort -t"$(printf '\t')" -k2 -rn | head -n "$CAP" | while IFS="$(printf '\t')" read -r type kb pid name; do
  if [ "$type" = "P" ]; then
    printf '%s\t%s\t%s\t%s\t%s\n' "$type" "$kb" "$pid" "$name" "$(detail_for "$pid" "$name")"
  else
    case "$name" in
      "Page cache")   d="reclaimable file cache" ;;
      "Disk buffers") d="reclaimable block cache" ;;
      "Available")    d="usable right now" ;;
      "Kernel slab")  d="kernel internal structures" ;;
      "Kernel")       d="memory maps, overhead" ;;
      *)              d="" ;;
    esac
    printf '%s\t%s\t%s\t%s\t%s\n' "$type" "$kb" "$pid" "$name" "$d"
  fi
done

awk '/^MemTotal:/{printf "T\t%d\t-\ttotal\t\n", $2}' /proc/meminfo 2>/dev/null
