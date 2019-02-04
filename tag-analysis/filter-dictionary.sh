cat images/tags/*|tr "," "\n"|sort|uniq|tr "[:upper:]" "[:lower:]"|sed '/^$/d;s/ /-/;s/^/^/;s/$/ /'|uniq >glove/grep-values.txt
grep -f grep-values.txt $1 >glove/filtered-dictionary.txt
