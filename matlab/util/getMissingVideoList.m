function missingVideoList = getMissingVideoList(file1, file2)

list1 = textread(file1,'%s');
list2 = textread(file2,'%s');
missingVideoList = cell(1, 1000);
count = 1;
for i = 1:length(list1)
	if any(strcmp(list1{i}, list2))
		continue;
	end
	missingVideoList{count} = list1{i};
	count = count + 1;
end
missingVideoList(count:end) = [];

fid = fopen('missingVideos.txt','w');
for i = 1:length(missingVideoList)
	fprintf(fid, '%s\n', missingVideoList{i});
end
fclose(fid);

end
