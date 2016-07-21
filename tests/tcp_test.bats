#!/usr/bin/env bats

# >&2 is needed to avoid output pollution
# (see also https://github.com/sstephenson/bats)
bash ./replace.sh >&2

setup() {
  if pgrep nimsuggest; then
    pkill -9 -x nimsuggest
  fi
}

teardown() {
  if pgrep nimsuggest; then
    pkill -9 -x nimsuggest
  fi
}

@test "TCP: def method" {
  echo "def sample.nim:9:3" > message
  FILE=tcp_def ./tcp_suggest_test
}

@test "TCP: sug method" {
  echo "sug sample.nim:13:2" > message
  FILE=tcp_sug ./tcp_suggest_test
}

@test "TCP: use method" {
  echo "use sample.nim:9:3" > message
  FILE=tcp_use ./tcp_suggest_test
}

@test "TCP: dus method" {
  echo "dus sample.nim:9:3" > message
  FILE=tcp_dus ./tcp_suggest_test
}

@test "TCP: highlight method" {
  echo "highlight sample.nim:-1:-1" > message
  FILE=tcp_highlight ./tcp_suggest_test
}

@test "TCP: chk method" {
  echo "chk sample.nim:-1:-1" > message
  FILE=tcp_chk ./tcp_suggest_test
}

@test "TCP: outline method" {
  echo "outline sample.nim:-1:-1" > message
  FILE=tcp_outline ./tcp_suggest_test
}

@test "TCP: check config.nims loading" {
  echo "chk config_nims_test.nim:-1:-1" > message
  FILE=tcp_config_nims SAMPLE=config_nims_test.nim ./tcp_suggest_test
}
