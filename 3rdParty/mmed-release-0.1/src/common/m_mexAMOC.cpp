/*
 * m_mexAMOC.cpp
 *    compute the Activity Monitoring Operating Curve
 *
 * Created on: Jan 19, 2011
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
   if (nrhs != 2) mexErrMsgTxt("two input arguments are required");
   if (nlhs > 4) mexErrMsgTxt("Too many outputs");

   int DETECTSCORE_IN = 0; // a 1*n cell structure of 1 dimensional vectors
   int LB_IN          = 1; // ground truth event, 2*n matrix

   int n = mxGetNumberOfElements(prhs[DETECTSCORE_IN]); // number of time series
   int ns[n]; // length of each time series
   double *detectVals[n]; // detection values
   for (int i=0; i <n; i++){
      mxArray *dV_i = mxGetCell(prhs[DETECTSCORE_IN],i);
      int nC = mxGetN(dV_i);
      int nR = mxGetM(dV_i);
      if ((nC != 1) && (nR != 1)) mexErrMsgTxt("detectionScores{i} must be a vector");
      ns[i] = nC*nR;
      detectVals[i] = mxGetPr(dV_i);
   }

   double *lb_ptr = mxGetPr(prhs[LB_IN]);
   Event gtLbs[n];
   for (int i=0; i <n; i++){
      gtLbs[i].s = (int)*lb_ptr++ - 1;
      gtLbs[i].e = (int)*lb_ptr++ - 1;
   }

   vector<double> potThresh; // potential thresholds

   int nPos = 0;
   for (int i=0; i < n; i++){
      int n_i = ns[i];
      if (gtLbs[i].isEmpty()){ // no event
         potThresh.push_back(detectVals[i][n_i - 1]);
      } else if (gtLbs[i].s > 0) { // event does not start right away
         potThresh.push_back(detectVals[i][gtLbs[i].s-1]);
         nPos++;
      } else nPos++;
   }
   int nNeg = potThresh.size();
   int nPosOver2 = nPos/2;

//   double minThresh = *min_element(potThresh.begin(), potThresh.end()) - 1;
   double minThresh = - numeric_limits<double>::infinity();
   potThresh.push_back(minThresh);
   sort(potThresh.begin(), potThresh.end());

   int nStep = potThresh.size();

   enum{
      FPR_OUT = 0,
      MEDNT2D_OUT, // median of NT2Ds, NT2D can be inf
      MEANNT2DCAP_OUT, // mean of NT2Ds, NT2D is capped at 1.
      THRESH_OUT //threshold values
   };

   plhs[FPR_OUT] = mxCreateDoubleMatrix(nStep, 1, mxREAL);
   plhs[MEDNT2D_OUT] = mxCreateDoubleMatrix(nStep, 1, mxREAL);
   plhs[MEANNT2DCAP_OUT] = mxCreateDoubleMatrix(nStep, 1, mxREAL);
   plhs[THRESH_OUT] = mxCreateDoubleMatrix(nStep, 1, mxREAL);

   double *FPR_out = mxGetPr(plhs[FPR_OUT]);
   double *medNT2D_out = mxGetPr(plhs[MEDNT2D_OUT]);
   double *meanNT2D_cap_out = mxGetPr(plhs[MEANNT2DCAP_OUT]);
   double *thresh_out = mxGetPr(plhs[THRESH_OUT]);

   for (int j=0; j < nStep; j++){
      double thresh = potThresh[j];
      int nFP = potThresh.end() - upper_bound(potThresh.begin() + j, potThresh.end(), thresh);
      double FPR = ((double)nFP)/nNeg;
      vector<double> NT2Ds;
      vector<double> NT2Ds_cap; // NT2D capped at 1
      for (int i=0; i < n; i++){
         int n_i = ns[i];
         if (gtLbs[i].isEmpty()) continue; // the event must happen
         int detectTime = upper_bound(detectVals[i], detectVals[i] + n_i, thresh) - detectVals[i];
         double NT2D;
         if (detectTime >= n_i) {
            NT2D = numeric_limits<double>::infinity();
         } else if (detectTime < gtLbs[i].s){
            NT2D = 0;
         } else {
            NT2D = ((double)(detectTime - gtLbs[i].s + 1))/(gtLbs[i].length());
         }
         NT2Ds.push_back(NT2D);

         double NT2D_cap;
         if (detectTime >= gtLbs[i].e){
            NT2D_cap = 1;
         } else if (detectTime < gtLbs[i].s){
            NT2D_cap = 0;
         } else {
            NT2D_cap = ((double)(detectTime - gtLbs[i].s + 1))/(gtLbs[i].length());
         }
         NT2Ds_cap.push_back(NT2D_cap);
      }

      nth_element(NT2Ds.begin(), NT2Ds.begin() + nPosOver2, NT2Ds.end());
      double medianNT2D = NT2Ds[nPosOver2]; //has to retrieve element NT2Ds[nPosOver2];

      double meanNT2D_cap = 0;
      for (int i=0; i < NT2Ds_cap.size(); i++) meanNT2D_cap += NT2Ds_cap[i];
      meanNT2D_cap /= NT2Ds_cap.size();

      *FPR_out++ = FPR;
      *medNT2D_out++ = medianNT2D;
      *meanNT2D_cap_out++ = meanNT2D_cap;
      *thresh_out++ = thresh;
   }
}
