/*
 * m_mexF1curve.cpp
 * Compute the F1 curve
 *
 * Created on: Feb 16, 2011
 * Author: Minh Hoai Nguyen, Carnegie Mellon University
 * Email:  minhhoai@cmu.edu, minhhoai@gmail.com
 */

#include "mex.h"
#include "m_event.h"
#include <vector>
#include <algorithm>
#include <iostream>

using namespace std;

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]){
   /* check for the proper no. of input and outputs */
   if (nrhs != 3) mexErrMsgTxt("Three input arguments are required");
   if (nlhs > 2) mexErrMsgTxt("Too many outputs");

   enum {
      DETECTOUT_IN = 0, // 3*n matrix for output of a detector
      LB_IN, // ground truth event
      STRIDE_IN // step size
   };

   double *detectOut = mxGetPr(prhs[DETECTOUT_IN]);
   double *lb_ptr = mxGetPr(prhs[LB_IN]);
   Event gtEv;
   gtEv.s = (int) *lb_ptr++ - 1;
   gtEv.e = (int) *lb_ptr++ - 1;

   double stride = mxGetScalar(prhs[STRIDE_IN]);

   Event detectEv;
   double val;
   int t, l = gtEv.length() - 1;
   vector<double> F1s;
   vector<double> NT2Ds;
   double NT2D = 0;
   do {
      NT2Ds.push_back(NT2D);
      t = floor(gtEv.s + l*NT2D);
      val = detectOut[3*t + 2];
      if (val > 0) {
         detectEv.s = detectOut[3*t] - 1;
         detectEv.e = detectOut[3*t+1] - 1;

//         F1s.push_back(1 - detectEv.deltaLoss(gtEv));
         F1s.push_back(1 - detectEv.deltaLoss(Event(gtEv.s, t))); // F1 score wrt the truncated event
      } else {
         F1s.push_back(0);
      }

      NT2D += stride;
   } while (NT2D <= 1);

   enum{
      NT2DS_OUT = 0,
      F1S_OUT
   };

   int nStep = NT2Ds.size();
   plhs[NT2DS_OUT] = mxCreateDoubleMatrix(1, nStep, mxREAL);
   plhs[F1S_OUT] = mxCreateDoubleMatrix(1, nStep, mxREAL);
   double *NT2Ds_out = mxGetPr(plhs[NT2DS_OUT]);
   double *F1s_out = mxGetPr(plhs[F1S_OUT]);
   for (int i=0; i < nStep; i++){
      *NT2Ds_out++ = NT2Ds[i];
      *F1s_out++ = F1s[i];
   }
}
