function [averagePrec, averageRec, results] = evalResult(gtE, label)

thr = 0.5;
assert(length(gtE) == length(label));
results = cell(length(gtE), 1);
for i = 1:length(gtE)
    Result = funEvalDetection(gtE{i}, label{i}, thr);
    results{i} = Result;
end

prec = 0;
rec = 0;
for i = 1:length(results)
prec = prec + results{i}.Prec;
rec = rec + results{i}.Rec;
end
averagePrec = prec / length(results);
averageRec = rec / length(results);

end