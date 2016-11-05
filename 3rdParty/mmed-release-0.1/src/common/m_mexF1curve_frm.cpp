/*
 * m_mexF1curve_frm.cpp
 *
 * Created on: Feb 19, 2011
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
   if (nrhs != 3) mexErrMsgTxt("three input arguments are required");
   if (nlhs > 2) mexErrMsgTxt("Too many outputs");

   enum {
      FRMSCORES_IN = 0, // 1*n matrix for detection score, frame-based
      LB_IN, // ground truth event
      STRIDE_IN // step size
   };

   int n = mxGetNumberOfElements(prhs[FRMSCORES_IN]);
   double *frmScores = mxGetPr(prhs[FRMSCORES_IN]);

   double *lb_ptr = mxGetPr(prhs[LB_IN]);
   Event gtEv;
   gtEv.s = (int) *lb_ptr++ - 1;
   gtEv.e = (int) *lb_ptr++ - 1;

   double stride = mxGetScalar(prhs[STRIDE_IN]);

   int nPos[n]; // number of positive scores from the beginning
   int nPosAfterEvStart[n]; // number of positive scores from the event start
   if (frmScores[0] > 0) nPos[0] = 1;
   else nPos[0] = 0;
   for (int i=1; i < n; i++){
      if (frmScores[i] > 0) nPos[i] = nPos[i-1] + 1;
      else nPos[i] = nPos[i-1];
   }
   if (frmScores[gtEv.s] > 0) nPosAfterEvStart[gtEv.s] = 1;
   else nPosAfterEvStart[gtEv.s] = 0;
   for (int i=gtEv.s+1; i <= gtEv.e; i++){
      if (frmScores[i] > 0) nPosAfterEvStart[i] = nPosAfterEvStart[i-1] + 1;
      else nPosAfterEvStart[i] = nPosAfterEvStart[i-1];
   }

   double F1;
   int t, l = gtEv.length() - 1;
   vector<double> F1s;
   vector<double> NT2Ds;
   double NT2D = 0;
   Event trEv;
   trEv.s = gtEv.s;
   do {
      NT2Ds.push_back(NT2D);
      t = floor(gtEv.s + l*NT2D);
      trEv.e = t;
      F1 = ((double)(2*nPosAfterEvStart[t]))/(nPos[t] + trEv.length());
      F1s.push_back(F1);
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
