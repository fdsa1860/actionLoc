/*
 * m_mexCmpF1Score.cpp
 *
 * Created on: Jan 12, 2011
 * Author: Minh Hoai Nguyen, Carnegie Mellon University
 * Email:  minhhoai@cmu.edu, minhhoai@gmail.com
 */

#include "mex.h"
#include "m_event.h"

using namespace std;

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]){
   /* check for the proper no. of input and outputs */

   if (nrhs != 3) mexErrMsgTxt("three input arguments are required");
   //   if (nlhs > 2) mexErrMsgTxt("Too many outputs");

   int DETECTSEGS_IN = 0; // Detector output, 3*n matrix, for [s, e, val];
   int GTEV_IN        = 1; // ground truth event
   int THRES_IN      = 2; // threshold value positive detection


   double *DetectSegs = mxGetPr(prhs[DETECTSEGS_IN]);
   int n = mxGetN(prhs[DETECTSEGS_IN]);
   double *gtEvPtr = mxGetPr(prhs[GTEV_IN]);
   Event gtEv;
   gtEv.s = *gtEvPtr++ - 1;
   gtEv.e = *gtEvPtr++ - 1;
   double thres = mxGetScalar(prhs[THRES_IN]);

   int F1_OUT = 0;
   plhs[F1_OUT] = mxCreateDoubleMatrix(1, n, mxREAL);
   double *F1_out = mxGetPr(plhs[F1_OUT]);

   if (gtEv.isEmpty()){
      for (int t= 0; t < n; t++){
         if (DetectSegs[3*t + 2] > thres) F1_out[t] = 0; // false alarm
         else F1_out[t] = 1; // true rejection
      }
   } else {
      for (int t=0; t < gtEv.s; t++){ // the event hasn't started
         if (DetectSegs[3*t + 2] > thres) F1_out[t] = 0; // false alarm
         else F1_out[t] = 1; // true rejection
      }
      for (int t = gtEv.s; t < n; t++){ // the event has started
         Event truncEv(gtEv.s, min(gtEv.e, t));
         if (DetectSegs[3*t + 2] > thres) {
            Event predEv(DetectSegs[3*t] -1, DetectSegs[3*t+1] -1);
            F1_out[t] = 1 - truncEv.deltaLoss(predEv);
         } else {
            F1_out[t] = 0; // false rejection
         }
      }
   }
}
