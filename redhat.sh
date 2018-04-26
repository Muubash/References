#!/usr/bin/env bash

# Script to captureID
cd /export/home/hxr66
rm -rf redhat_id_html_dump/*
rm -f redhat_id_html_dump/RedHat_Synp_Aff_Prds
rm -f redhat_id_html_dump/RedHat_Synp_Aff_Prd.csv

# Remove any blank lines if there are any from id list

sed -i '/^$/d' redhat_id_list

for i in $(cat redhat_id_list)
do
  /usr/java/jre1.8.0_162/bin/java -Dhttps.protocols=TLSv1.2 -Dhttps.proxyHost=proxy-system.wip.us.equifax.com -Dhttps.proxyPort=18717 -jar /export/home/sxm220/efurl-1.0-SNAPSHOT-exec.jar -url https://access.redhat.com/errata/${i} > redhat_id_html_dump/${i}.html
done

cd redhat_id_html_dump

for file in $(find . -type f -name "R*")
do
  w3m -dump $file > ${file}.txt
done



for i in $(find . -type f -name "*.txt")
do
# Captured data needed for 1st column
  echo ${i} | sed 's/^\.\///g;s/.html.txt//g' | sed '1 i\ID' | sed 's/^/,/g' > ${i}_ID
# Captured 2nd column data i.e., Synopsis
  cat ${i} | grep -A2 Synopsis | perl -pe 's/[^[:ascii:]]//g;' | sed '/^$/d;s/^/,/g' > ${i}_Synp
# Pasting side by side column 1 and 2 thats captured from above
  paste ${i}_ID ${i}_Synp | sed 's/^\t/, /g' > ${i}_ID_Synp
# capturing 3rd cloumn i.e. Affected Products
  awk '/Affected Products/{f=1} /Fixes/{f=0;print} f' ${i} | perl -pe 's/[^[:ascii:]]//g;' | sed '$!N;s/\n\s\s\s\s/ /;P;D' | grep -v Fixes | sed '/^$/d' | sed 's/^ *//g' |sed 's/^/,/g' >  ${i}_Aff_Prds
# pasting col-1,2 and col-3
  paste ${i}_ID_Synp ${i}_Aff_Prds | sed 's/^\t/, ,/g' >> RedHat_Synp_Aff_Prds
done
# We want ID, Synopsis, Affected Products only in 1st line
cat RedHat_Synp_Aff_Prds |  sed '2,$s/ID//' | sed '2,$s/Synopsis//' | sed '2,$s/Affected Products//' | sed 's/,//4' > RedHat_Synp_Aff_Prds.csv
echo "Thread ID, Synopsis, Affected Products are attached to this email" | mailx -s "Summary:Patching needed" -a RedHat_Synp_Aff_Prds.csv himabindu.rayadurgam@equifax.com

rm -f RedHat_Synp_Aff_Prds
rm -f RedHat_Synp_Aff_Prds.csv

                 
