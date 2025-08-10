#!/bin/sh

public="/home/downovsyndrom.sk/web/v16/sites/default/files/"
info_file="_info.txt"
extract_file="extract.sh"

echo "#!/bin/sh\n" > ${extract_file}

list_file=$1

#loop_set=`cat ${list_file} | grep "public://" | sed "s@public://@${public}@"`

galleries=`cat ${list_file} | grep "public://" | sed "s@\",\".*@@;s@\"@@" | uniq | sort`

#echo $galleries

for i in ${galleries}
do
	echo "Gallery: "$i
	mkdir -p $i

	cat media_gallery_images_D7.csv | egrep "\"${i}\"" | sort | sed "s@public://\(.*\)@\1,\"${public}\1@" > ${i}/${info_file}

	cat ${i}/${info_file} | sed "s@[^,]*,[^,]*,[^,]*,[^,]*,\([^,]*\)@cp -v \1 ${i}\/@" >> ${extract_file}
done

echo "Extract file for the listed galleries created: ${extract_file}"

