function seqs_out = preProcessing(seqs, opt)
% preprocessing the sequences

if opt.diff == true
    seqs_out = cellfun( @(t) diff(t,[],2), seqs, 'UniformOutput', false);
elseif opt.removeMean == true
    seqs_out = cellfun( @removeMean, seqs, 'UniformOutput', false);
else
    seqs_out = seqs;
end

end