function cVid = convertVID(vid)

vid1 = regexprep(vid, '^v_', '');
vid2 = regexprep(vid1, '^([^A-Za-z])', 'x0x${sprintf(''%X'',unicode2native($1))}_', 'once');
cVid = regexprep(vid2, '([^\w])', '_0x${sprintf(''%X'', unicode2native($0))}_');

end