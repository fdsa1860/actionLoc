function ratio = IoU(gtInt, dtInt)

U = max(gtInt(2), dtInt(2)) - min(gtInt(1), dtInt(1));
I = max(0, min(gtInt(2), dtInt(2)) - max(gtInt(1), dtInt(1)));
ratio = I / (U + eps);

end