/*
 * m_mexSampleSeg.cpp
 *
 * Created on: Feb 24, 2011
 * Author: Minh Hoai Nguyen, Carnegie Mellon University
 * Email:  minhhoai@cmu.edu, minhhoai@gmail.com
 */

#include "mex.h"
#include "m_event.h"

using namespace std;

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]){
   /* check for the proper no. of input and outputs */
   if (nrhs != 3) mexErrMsgTxt("Three input arguments are required");
   if (nlhs > 1) mexErrMsgTxt("Too many outputs");
   enum {D_IN =0, //time series
         EVT_IN,
         SD_IN
   };

   int d = mxGetM(prhs[D_IN]);
   int sd = (int) mxGetScalar(prhs[SD_IN]);
   Event ev;
   double *ev_ptr = mxGetPr(prhs[EVT_IN]);
   ev.s = ev_ptr[0] - 1;
   ev.e = ev_ptr[1] - 1;

   double *D = mxGetPr(prhs[D_IN]);
   double *raw_feat = new double[d*sd];
   sampleSeg(D, d, ev, sd, raw_feat);

   enum{
      FEAT_OUT = 0
   };

   plhs[FEAT_OUT] = mxCreateDoubleMatrix(sd*d, 1, mxREAL);
   double *raw_feat_out = mxGetPr(plhs[FEAT_OUT]);
   memcpy(raw_feat_out, raw_feat, sd*d*sizeof(double));
   delete [] raw_feat;
}
