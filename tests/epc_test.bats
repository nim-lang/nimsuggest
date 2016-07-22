#!/usr/bin/env bats

# >&2 is needed to avoid output pollution
# (see also https://github.com/sstephenson/bats)
bash ./replace.sh >&2

setup() {
  rm -f ./epc_port
  # Clear previous received message
  rm -f received/*
  if pgrep nimsuggest; then
    pkill -9 -x nimsuggest
  fi
}

teardown() {
  if pgrep nimsuggest; then
    pkill -9 -x nimsuggest
  fi
}

@test "EPC: check EPC mock command" {
  # Test mocked EPC's call command
  # Note that if this test is fail, all EPC's tests will be failed.
  nim c -r ./epc_mock_test.nim
}

@test "EPC: def method" {
  nim e -d:sug:def -d:line:9 -d:col:3 epc_call.nims > message
  FILE=epc_def ./epc_suggest_test
}

@test "EPC: sug method" {
  nim e -d:sug:sug -d:line:13 -d:col:2 epc_call.nims > message
  FILE=epc_sug ./epc_suggest_test
}

@test "EPC: use method" {
  nim e -d:sug:use -d:line:9 -d:col:3 epc_call.nims > message
  FILE=epc_use ./epc_suggest_test
}

@test "EPC: dus method" {
  nim e -d:sug:dus -d:line:9 -d:col:3 epc_call.nims > message
  FILE=epc_dus ./epc_suggest_test
}

@test "EPC: chk method" {
  nim e -d:sug:chk -d:line:-1 -d:col:-1 epc_call.nims > message
  FILE=epc_chk ./epc_suggest_test
}

@test "EPC: check config.nims loading" {
  nim e -d:sug:chk -d:line:-1 -d:col:-1 -d:prjpath:$PWD/config_nims_test.nim \
      epc_call.nims > message
  FILE=epc_config_nims SAMPLE=config_nims_test.nim ./epc_suggest_test
}
