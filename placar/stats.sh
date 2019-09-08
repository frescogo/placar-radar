#!/bin/sh

# ./stats.sh > relatorios/ranking.md
# :%!sort -n -r -k3

STATS=../../analise/stats

echo "\`\`\`"
echo "ESQ          DIR            PTS    QDS    KMH"
echo "---------------------------------------------"
for i in relatorios/*.txt; do
    #echo $i
    base=`basename $i .txt`
    lua5.3  $STATS/parse.lua $i /tmp
    python3 $STATS/histogram.py "/tmp/$base.py" relatorios/
done
echo "\`\`\`"

