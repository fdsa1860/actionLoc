/*
 * m_mexEval_ker.cpp
 *
 * Created on: Feb 9, 2011
 * Author: Minh Hoai Nguyen, Carnegie Mellon University
 * Email:  minhhoai@cmu.edu, minhhoai@gmail.com
 */

#include "mex.h"
#include "../common/m_event.h"
#include "m_mvc_ker.h"

using namespace std;

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]){
   /* check for the proper no. of input and outputs */
   if (nrhs != 5) mexErrMsgTxt("five input arguments are required");
   //   if (nlhs > 2) mexErrMsgTxt("Too many outputs");
   enum {D_IN =0, //time series
         W_IN,    //weight vector
         B_IN,    //scalar offset
         KOPT_IN, //kernel options
         SOPT_IN  //segment search options
   };

   int n = mxGetN(prhs[D_IN]);
   int d = mxGetM(prhs[D_IN]);
   double b = mxGetScalar(prhs[B_IN]);
   double *w = mxGetPr(prhs[W_IN]);
   Kernel ker;
   ker.kerType = (int) mxGetScalar(mxGetField(prhs[KOPT_IN],0, "type"));
   ker.kerN = (int) mxGetScalar(mxGetField(prhs[KOPT_IN], 0, "n"));
   ker.kerL = mxGetScalar(mxGetField(prhs[KOPT_IN], 0, "L"));
   mxArray *nSegDiv_ptr = mxGetField(prhs[KOPT_IN], 0, "nSegDiv");
   if (nSegDiv_ptr != NULL) {
      ker.nSegDiv = (int) mxGetScalar(nSegDiv_ptr);
      if (ker.nSegDiv < 1) mexErrMsgTxt("ker.nSegDiv must be >= 1");
   } else ker.nSegDiv = 1;

   int fd, sd;
   int featType = (int) mxGetScalar(mxGetField(prhs[KOPT_IN], 0, "featType"));
   if (featType == FEAT_ORDER) {
      sd = (int) mxGetScalar(mxGetField(prhs[KOPT_IN], 0, "sd"));
      fd = ker.get_fd(sd*d);
   } else if ((featType == FEAT_BAG) || (featType == FEAT_ENDDIFF)){
      fd = ker.get_fd(d);
   } else {
      mexErrMsgTxt("Unknown feature option");
   }
   if (fd != mxGetNumberOfElements(prhs[W_IN])){
      mexErrMsgTxt("length of w is inconsistent with the dimension of data");
   }

   if (ker.kerType == KER_INTER){
      ker.kerMap = vl_homogeneouskernelmap_new (VlHomogeneousKernelIntersection, ker.kerN, ker.kerL);
   } else if (ker.kerType == KER_CHI2){
      ker.kerMap = vl_homogeneouskernelmap_new (VlHomogeneousKernelChi2, ker.kerN, ker.kerL);
   } else if ((ker.kerType != KER_LINEAR) && (ker.kerType != KER_LINEAR_NONORM) &&
         (ker.kerType != KER_LINEAR_LENGTHNORM)) {
      mexErrMsgTxt("unknown or unsupported kernel type");
   }


   int minSegLen  = (int) mxGetScalar(mxGetField(prhs[SOPT_IN], 0, "minSegLen"));
   int maxSegLen  = (int) mxGetScalar(mxGetField(prhs[SOPT_IN], 0, "maxSegLen"));
   int segStride  = (int) mxGetScalar(mxGetField(prhs[SOPT_IN], 0, "segStride"));

   if ((minSegLen < 1) || (maxSegLen < minSegLen) || (segStride < 1))
      mexErrMsgTxt("invalid options for cOpt");
   if (minSegLen > n) mexErrMsgTxt("minimum segment length is greater than the time series length");
   if (maxSegLen > n) maxSegLen = n;

   int DETECT_OUT = 0;
   plhs[DETECT_OUT] = mxCreateDoubleMatrix(3, n, mxREAL);
   double *detect_out = mxGetPr(plhs[DETECT_OUT]);

   TimeSeries TS;
   TS.D = mxGetPr(prhs[D_IN]);
   TS.n = n;
   TS.d = d;
   TS.fd = fd;
   TS.ker = ker;
   TS.featType = featType;
   if (featType == FEAT_BAG){
      TS.IntD = new double[d*(n+1)];
      cmpIntIm(TS.D, d, n, TS.IntD);
   } else if (featType == FEAT_ORDER){
      TS.sd = sd;
   }

   TS.setSegLst(minSegLen, maxSegLen, segStride);
   TS.updateSegLstVals(w, b);

   Event mxEv;
   double newVal, mxVal = - numeric_limits<double>::infinity();
   int curIdx = 0, segLstSz = TS.segLst.size();
   for (int t=0; t < n; t++){
      if (curIdx < segLstSz){ // there are more segments to consider
         ExEvent curSeg = TS.segLst[curIdx];
         while (curSeg.e <= t){
            newVal = curSeg.val;
            if (newVal > mxVal){
               mxVal = newVal;
               mxEv.s = curSeg.s;
               mxEv.e = curSeg.e;
            }
            curIdx++;
            if (curIdx >= segLstSz) break;
            curSeg = TS.segLst[curIdx];
         }
      }
      *detect_out++ = mxEv.s + 1;
      *detect_out++ = mxEv.e + 1;
      *detect_out++ = mxVal;
   }
}
