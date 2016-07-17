rm -fr tmp
cp -r expected tmp
tmp="<<<__TEST_DIRECTORY__>>>"
grep -hlr $tmp ./tmp | xargs sed -i.bak -e "s:${tmp}:${PWD}:g"
