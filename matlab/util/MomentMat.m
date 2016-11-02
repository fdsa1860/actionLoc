classdef MomentMat < handle
    properties
        vec;
        len;
        Mi;
        mOrd;
        nVar;
        Dict;
        Indx;
        basis;
    end
    methods
        function obj = MomentMat(nVar, mOrd)
            obj.nVar = nVar;
            obj.mOrd = mOrd;
            [obj.Dict,obj.Indx] = momentPowers(0, nVar, 2*mOrd);
            [obj.basis,~] = momentPowers(0, nVar, mOrd);
            obj.Mi = getMomInd(obj.Dict, obj.basis, 0, obj.Indx, 0);
            obj.len = 0;
        end
        function obj = add(obj, dataIn)
            [d, n] = size(dataIn);
            newVec = zeros(1, length(obj.Indx));
            for i = 1:length(newVec)
                newVec(i) = sum( prod(bsxfun(@power, dataIn', obj.Dict(i,:)),2) ) / n;
            end
            if obj.len == 0
                obj.vec = newVec;
                obj.len = n;
            else
                w1 = obj.len / (obj.len + n);
                w2 = n / (obj.len + n);
                obj.vec = w1 * obj.vec + w2 * newVec;
                obj.len = obj.len + n;
            end
        end
        function Mat = getMat(obj)
            Mat = reshape(obj.vec(obj.Mi), size(obj.Mi));
        end
        function MatInv = getMatInv(obj)
            Mat = obj.getMat;
            MatInv = inv(Mat);
        end
        function basis = getBasis(obj)
            basis = obj.basis;
        end
    end
end