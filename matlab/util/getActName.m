function actab = getActName(actfile, label)
%
% Get the action name from label and output to specified file
%
% Description actab = getActName(actfile, label) gets action name string by
% matching label value and action table entries.
%
% Inputs ------------------------------------------------------------------
%   o actfile : Path for action table file
%   o label   : Action label by which we extract action name string
% Outputs -----------------------------------------------------------------
%   o actab   : A cell containing action name string
% 
% By: Shitong Yao  // yshtng(at)gmail.com    
% 

% Look up action name from action table file
fid = fopen(actfile);
C = textscan(fid, '%d %s', 'delimiter', ':');
fclose(fid);

[~, idx] = ismember(label, C{1});
actab = C{2}(idx(idx~=0));
try
    assert(all(idx~=0), 'Label %d is not in action table!\n', label(idx==0));
catch err    
    disp(actab)
    error(err.message)
end

end

