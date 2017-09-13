#!/bin/bash - 

# outside 收信检查

# 
dir_cur=$(dirname $(readlink -f "$0"))
dir_docx=$dir_cur/docx
dir_raw=$dir_cur/raw
dir_book=$dir_cur/book
dir_pending=$dir_cur/pending

topics=("核心备案" "群聊脱水" "微博问答")
topics_abbr=("core" "by_date" "weibo_qa")

file_summary=$dir_book/SUMMARY.md

# 扫描目录 pending
[ `ls "$dir_pending/" | wc -l` -gt 0   ] ||  exit
for f in `ls $dir_pending/月*`
do
	# convert
	outfile=`echo $f |  egrep -o "[0-9]+\-[0-9]+"`
	outfile=$dir_raw/"by_date_"${outfile}.md
	echo $f
	echo $outfile
	pandoc -f docx -t markdown -o $outfile  $f

	# clean
	sed -i "s/<span.*span>//g" $outfile
	sed -i '1 i<!-- toc -->' $outfile
done


# 配置gitbook
rm -rfv $dir_book/core $dir_book/by_date $dir_book/weibo_qa
mkdir -p $dir_book/core $dir_book/by_date $dir_book/weibo_qa


echo '## 目录'  | tee  $file_summary

for indx in ${!topics[@]}
do
	# title 1 
	echo "* [${topics[$indx]}]" | tee -a  $file_summary
	topic=${topics[$indx]}
	abbr=${topics_abbr[$indx]}
	# title 2
	for f in `ls $dir_raw/${topics_abbr[$indx]}_*`
	do
		fn=`basename $f`
		fn=${fn/"$abbr"_/}
		echo \ \ * [${fn%.*}]\($abbr\/$fn\) | tee -a  $file_summary
		cp -v $f $dir_book/$abbr/$fn
	done
done

cd $dir_cur
# 生成站点
gitbook build book docs
#gitbook serve book

cd $dir_pending
info_commit=`ls 月*`
cd $dir_cur

echo $info_commit
# 自动发布
git add .
git commit -m "updated: $info_commit"
git push origin master



