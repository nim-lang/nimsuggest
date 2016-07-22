rm -fr expected_tmp
cp -r expected expected_tmp
tmp="<<<__TEST_DIRECTORY__>>>"
grep -hlr $tmp ./expected_tmp | xargs sed -i.bak -e "s:${tmp}:${PWD}:g"
