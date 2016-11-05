/*
 * m_mexMMED_ker.cpp
 *
 * Created on: Feb 3, 2011
 * Author: Minh Hoai Nguyen, Carnegie Mellon University
 * Email:  minhhoai@cmu.edu, minhhoai@gmail.com
 */

#include "mex.h"
#include "../common/m_event.h"
#include <ilcplex/ilocplex.h>
#include <vector>
#include "m_mvc_ker.h"
#include <sys/times.h>
#include <sys/param.h>
#include <sstream>

extern "C" {
   #include <vl/homkermap.h>
}

#ifndef HZ
#define HZ 100
#endif

using namespace std;

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]){
   /* check for the proper no. of input and outputs */
   if (nrhs != 8) mexErrMsgTxt("8 input arguments are required");
   //   if (nlhs > 2) mexErrMsgTxt("Too many outputs");

   enum { D_IN = 0,  // data
          LB_IN,     // label
          C_IN,      // C for slack varialbes of SVM
          MU_IN,     // slack variable rescaling
          WINIT_IN,  // initial w
          KOPT_IN,   // kernel option
          TROPT_IN,  // training option for training the detector, valid entries are:
                     // 'instant', 'offline', 'instant+extent', 'offline+extent'
          CNSTROPT_IN, // constraint options
         };

   int MAX_ITER = 30;
   double STOPPING_TOL = 0.0001;
   int verbose = 1;

   int d = mxGetM(mxGetCell(prhs[D_IN],0)); // data dimension
   int n = mxGetNumberOfElements(prhs[D_IN]); // number of time series
   double *lb_ptr = mxGetPr(prhs[LB_IN]);
   if (mxGetNumberOfElements(prhs[MU_IN]) != (unsigned int) n)
      mexErrMsgTxt("Number of mu's are inconsistent");

   double C = (double) mxGetScalar(prhs[C_IN]);
   double *w_init = mxGetPr(prhs[WINIT_IN]);

   Kernel ker;
   ker.kerType = (int) mxGetScalar(mxGetField(prhs[KOPT_IN],0, "type"));
   ker.kerN = (int) mxGetScalar(mxGetField(prhs[KOPT_IN], 0, "n"));
   ker.kerL = mxGetScalar(mxGetField(prhs[KOPT_IN], 0, "L"));
   mxArray *nSegDiv_ptr = mxGetField(prhs[KOPT_IN], 0, "nSegDiv");
   if (nSegDiv_ptr != NULL) {
      ker.nSegDiv = (int) mxGetScalar(nSegDiv_ptr);
      if (ker.nSegDiv < 1) mexErrMsgTxt("ker.nSegDiv must be >= 1");
   } else ker.nSegDiv = 1;

   int fd, sd, featType = (int) mxGetScalar(mxGetField(prhs[KOPT_IN], 0, "featType"));
   if (featType == FEAT_ORDER) {
      sd = (int) mxGetScalar(mxGetField(prhs[KOPT_IN], 0, "sd"));
      if (sd < 2) mexErrMsgTxt("kOpt.sd must be >= 2");
      fd = ker.get_fd(sd*d);
   } else if ((featType == FEAT_BAG) || (featType == FEAT_ENDDIFF)){
      fd = ker.get_fd(d);
   } else {
      mexErrMsgTxt("Unknown feature option");
   }
   if (mxGetNumberOfElements(prhs[WINIT_IN]) != fd){
      mexErrMsgTxt("length of w_init is different from the dimension of feature vectors");
   }

   if (ker.kerType == KER_INTER){
      ker.kerMap = vl_homogeneouskernelmap_new (VlHomogeneousKernelIntersection, ker.kerN, ker.kerL);
   } else if (ker.kerType == KER_CHI2){
      ker.kerMap = vl_homogeneouskernelmap_new (VlHomogeneousKernelChi2, ker.kerN, ker.kerL);
   } else if ((ker.kerType != KER_LINEAR) && (ker.kerType != KER_LINEAR_NONORM) &&
         (ker.kerType != KER_LINEAR_LENGTHNORM)) {
      mexErrMsgTxt("m_mexInstantDetect_ker.cpp: unknown or unsupported kernel type");
   }

   char detectorOpt[100];
   mxGetString(prhs[TROPT_IN], detectorOpt, 100);
   if (strcmp(detectorOpt, "instant") && strcmp(detectorOpt, "offline") &&
       strcmp(detectorOpt, "instant+extent") && strcmp(detectorOpt, "offline+extent")){
      mexErrMsgTxt("Unknown detector option");
   }

   // pre-computed data structure for faster code
   int minSegLen  = (int) mxGetScalar(mxGetField(prhs[CNSTROPT_IN], 0, "minSegLen"));
   int maxSegLen  = (int) mxGetScalar(mxGetField(prhs[CNSTROPT_IN], 0, "maxSegLen"));
   int segStride  = (int) mxGetScalar(mxGetField(prhs[CNSTROPT_IN], 0, "segStride"));
   int trEvStride = (int) mxGetScalar(mxGetField(prhs[CNSTROPT_IN], 0, "trEvStride"));
   bool shldCacheSegFeat  = (bool) mxGetScalar(mxGetField(prhs[CNSTROPT_IN], 0, "shldCacheSegFeat"));
   bool shldCacheTrEvFeat = (bool) mxGetScalar(mxGetField(prhs[CNSTROPT_IN], 0, "shldCacheTrEvFeat"));
   mxArray *maxEvLen_ptr = mxGetField(prhs[CNSTROPT_IN], 0, "maxEvLen");
   int maxEvLen;
   if (maxEvLen_ptr != NULL) {
      maxEvLen = (int) mxGetScalar(maxEvLen_ptr);
      if (maxEvLen < 1) mexErrMsgTxt("maxEvLen >= 1");
   } else maxEvLen = numeric_limits<int>::max();


   //profiling code
   struct tms startTime,endTime;
   long realTime1,realTime2;
   realTime1 = times(&startTime);
   int nThing2Cache = 0;

   fprintf(stderr, "Setting up the time series\n");
   TimeSeries *TS = new TimeSeries[n];

   for (int i=0; i <n; i++){ //initialize time series
      mxArray *D_i = mxGetCell(prhs[D_IN],i);
      TS[i].n = mxGetN(D_i);
      if (d != (int)mxGetM(D_i)) mexErrMsgTxt("Data dimensions are inconsistent");
      TS[i].D = mxGetPr(D_i);
      TS[i].d = d;
      TS[i].gtEv.s = (int)*lb_ptr++ - 1;
      TS[i].gtEv.e = (int)*lb_ptr++ - 1;

      mxArray *mu_i = mxGetCell(prhs[MU_IN], i);
      if (mxGetN(mu_i) != (unsigned int) TS[i].n)
         mexErrMsgTxt("length of mu[i] is inconsistent with lengh of D[i]");
      TS[i].mu = mxGetPr(mu_i);
      TS[i].ker = ker;
      TS[i].fd = fd;

      TS[i].setSegLst(minSegLen, maxSegLen, segStride);
      TS[i].setEvtLst(trEvStride, maxEvLen);

      TS[i].featType = featType;
      if (featType == FEAT_BAG){
         TS[i].IntD = new double[d*(TS[i].n+1)];
         cmpIntIm(TS[i].D, d, TS[i].n, TS[i].IntD);
      } else if (featType == FEAT_ENDDIFF){
      } else if (featType == FEAT_ORDER){
         TS[i].sd = sd;
      }


      if (shldCacheSegFeat)  {
         TS[i].cacheSegLstFeats();
         nThing2Cache += TS[i].segLst.size();
      }
      if (shldCacheTrEvFeat) {
         TS[i].cacheEvtLstFeats();
         nThing2Cache += TS[i].evtLst.size();
      }
   }
   realTime2 = times(&endTime);
   fprintf(stderr, "setting up for nThing2Cache: %d, fd: %d\n", nThing2Cache, fd);
   fprintf(stderr, "time: user=%f, system=%f, real=%f\n",
         ((float)(endTime.tms_utime-startTime.tms_utime))/(HZ),
         ((float)(endTime.tms_stime-startTime.tms_stime))/(HZ),
         ((float)(realTime2-realTime1))/(HZ));
//   mexErrMsgTxt("Starting to optimize");



   if (verbose > 0) {
      fprintf(stderr, "n: %d, d: %d, C: %g, detectorOpt: %s\n", n, d, C, detectorOpt);
      fprintf(stderr, "kerType: %d, kerN: %d, kerL: %g, featType: %d, sd: %d, fd: %d\n",
            ker.kerType, ker.kerN, ker.kerL, featType, sd, fd);
      fprintf(stderr, "minSegLen: %d, maxSegLen: %d, segStride: %d, trEvStride: %d, "
            "shldCacheSegFeat: %d, shldCacheTrEvFeat: %d, maxEvLen: %d\n", minSegLen, maxSegLen,
            segStride, trEvStride, shldCacheSegFeat, shldCacheTrEvFeat, maxEvLen);

   }

   if (verbose > 1) {
      fprintf(stderr, "(i: ns s e): ");
      for (int i=0; i <n; i++) fprintf(stderr, "(%d: %d %d %d) ", i, TS[i].n, TS[i].gtEv.s, TS[i].gtEv.e);
      fprintf(stderr, "\n");
   }

   IloEnv env;
   try{
      IloModel mod(env);
      IloCplex cplex(mod);

      //variables
      IloNumVarArray var_w(env, fd, -IloInfinity, IloInfinity);
      IloNumVarArray var_xi(env, n, 0, IloInfinity);
      IloNumVar      var_b(env, -IloInfinity, IloInfinity);

      //associated values of the above variables
      IloNumArray num_w(env, fd), num_xi(env, n);
      IloNum      num_b = 0;
      for (int i=0; i < fd; i++) num_w[i]  = w_init[i]; // initialize w and xi
      for (int i=0; i <  n; i++) num_xi[i] = 0;

      //associated raw-data-structure values
      double w[fd], xi[n], b;

      // setting up the objective
      if (verbose > 1) fprintf(stderr, "Setting up the QP objective\n");
      IloExpr objExp(env);
      for (int i=0; i < fd; i++) objExp += 0.5*var_w[i]*var_w[i];
      double C_over_n = C/n;
      for (int i=0; i < n; i++) objExp += C_over_n*var_xi[i];
      mod.add(IloMinimize(env, objExp));
      objExp.end();

      // valid entry: CPX_ALG_AUTOMATIC, CPX_ALG_PRIMAL, CPX_ALG_DUAL, CPX_ALG_BARRIER
      int solverAlgo = CPX_ALG_DUAL;
      int solverVerbose = 0; //0: none, 1: iter info, 2: diagnostic info
      cplex.setParam(IloCplex::RootAlg, solverAlgo);
      cplex.setParam(IloCplex::BarDisplay, solverVerbose);
      cplex.setParam(IloCplex::SimDisplay, solverVerbose);


      double cnstr_w_coeff[fd], tmpFeatV[fd], cnstr_b_coeff, cnstr_scal; //coeff. vector for w, b, and scalar
      double xi_i, xi1, xi2, xi3, xi4, extraVio;
      int t2, t3, iter, nIter, nConstr = 0;
      Event mvc1, mvc2, mvc3, mvc4;
      vector<double> lbObjVals; // lower bound obj. values, non-decreasing function
      vector<double> ubObjVals; // upper bound obj. values, not a monotonic function
      double minUbObjVal = numeric_limits<double>::infinity(); // minimum of ubObjVals so far
      double curLbObjVal;

      if (verbose > 1) fprintf(stderr, "Setting up the initial constraints\n");
      IloConstraintArray var_constrs(env);
      for (int i=0; i<n; i++){// constraints for: full events must be detected
         if (!TS[i].gtEv.isEmpty()){
            // the max. length of gt event might be given, in this case
            // even the gtEv is strimed at the beginning.
            if (TS[i].gtEv.length() > maxEvLen) {
               TS[i].getSegFeatVec(Event(TS[i].gtEv.e - maxEvLen + 1, TS[i].gtEv.e), cnstr_w_coeff);
            } else TS[i].getSegFeatVec(TS[i].gtEv, cnstr_w_coeff);

            IloExpr constrExp(env);
            for (int k=0;k < fd;k++) constrExp += cnstr_w_coeff[k]*var_w[k];
            var_constrs.add(constrExp + var_b >= 1 - var_xi[i]);
            mod.add(var_constrs[nConstr++]);
            constrExp.end();
         }
      }

      if (verbose > 1) fprintf(stderr, "Before entering the constraint generation loop\n");
      for (iter =0; iter < MAX_ITER; iter++){ // constraint generation loop
         realTime1 = times(&startTime);
         fprintf(stderr, "iter: %d\n", iter + 1);

         for (int i=0; i < fd; i++) w[i] = num_w[i];
         for (int i=0; i < n; i++) xi[i] = num_xi[i];
         b = num_b;
         extraVio = 0;

         for (int i=0; i<n; i++){
            xi_i = xi[i];
            double extraVio_i = 0;
            TS[i].updateAllVals(w, b);
            xi1 = TS[i].findMVC1(mvc1);

            if (xi1 > xi_i) { // if no part of the event has been observed, there should be no detection
               if (verbose > 2) fprintf(stderr, "i: %d, xi_i: %g, xi1: %g, mvc1: %s\n", i, xi_i, xi1, mvc1.str().c_str());

               extraVio_i = max(extraVio_i, xi1 - xi_i);
               TS[i].getSegFeatVec(mvc1, cnstr_w_coeff);

               IloExpr constrExp(env);
               for (int k=0; k<fd; k++) constrExp += cnstr_w_coeff[k]*var_w[k];
               var_constrs.add(constrExp + var_b  <= -1 + var_xi[i]);
               mod.add(var_constrs[nConstr++]);
               constrExp.end();
            }

            if (!TS[i].gtEv.isEmpty()) { // if the gt event is not empty
               if ((!strcmp(detectorOpt, "instant") || !strcmp(detectorOpt, "instant+extent"))){
                  xi2 = TS[i].findMVC2(t2, mvc2);

                  if (xi2 > xi_i){ // partial event should be detected
                     if (verbose > 2) fprintf(stderr, "i: %d, xi_i: %g, xi2: %g, t2: %d\n", i, xi_i, xi2, t2);

                     extraVio_i = max(extraVio_i, xi2 - xi_i);
                     TS[i].getSegFeatVec(mvc2, cnstr_w_coeff);

                     cblas_dscal(fd, -TS[i].mu[t2], cnstr_w_coeff, 1);
                     cnstr_scal =     TS[i].mu[t2];
                     cnstr_b_coeff = -TS[i].mu[t2];

                     IloExpr constrExp(env);
                     for (int k=0; k < fd; k++) constrExp += cnstr_w_coeff[k]*var_w[k];
                     var_constrs.add(constrExp + cnstr_b_coeff*var_b + cnstr_scal <= var_xi[i]);
                     mod.add(var_constrs[nConstr++]);
                     constrExp.end();
                  }
               }

               if (!strcmp(detectorOpt, "instant+extent")){
                  xi3 = TS[i].findMVC3(t3, mvc3);
                  //xi3 = findMVC3_ker_old(TS[i], ker, w,    t3, mvc3);
                  if (xi3 > xi_i){ // temporal extent of partial event should be correctly output
                     if (verbose > 2) fprintf(stderr, "i: %d, xi3: %g, mvc3: %s, t3: %d\n", i, xi3, mvc3.str().c_str(), t3);

                     extraVio_i = max(extraVio_i, xi3 - xi_i);

                     TS[i].getSegFeatVec(mvc3, cnstr_w_coeff);
                     TS[i].getSegFeatVec(Event(TS[i].gtEv.s, t3), tmpFeatV);
                     cblas_daxpy(fd, -1.0, tmpFeatV, 1, cnstr_w_coeff, 1);
                     cblas_dscal(fd, TS[i].mu[t3], cnstr_w_coeff, 1);
                     cnstr_scal = TS[i].mu[t3]*Event(TS[i].gtEv.s, t3).deltaLoss(mvc3);

                     IloExpr constrExp(env);
                     for (int k=0; k<fd; k++) constrExp += cnstr_w_coeff[k]*var_w[k];
                     var_constrs.add(constrExp + cnstr_scal <= var_xi[i]);
                     mod.add(var_constrs[nConstr++]);
                     constrExp.end();
                  }
               }

               if ((!strcmp(detectorOpt, "offline+extent") || !strcmp(detectorOpt, "instant+extent"))){
                  xi4 = TS[i].findMVC4(mvc4);
                  //xi4 = findMVC4_ker_old(TS[i], ker, w, mvc4);
                  if (xi4 > xi_i){ // temporal extent of the full event should be correctly output
                     if (verbose > 2) fprintf(stderr, "i: %d, xi4: %g, mvc4: %s\n", i, xi4, mvc4.str().c_str());

                     extraVio_i = max(extraVio_i, xi4 - xi_i);

                     TS[i].getSegFeatVec(mvc4, cnstr_w_coeff);
                     TS[i].getSegFeatVec(TS[i].gtEv, tmpFeatV);
                     cblas_daxpy(fd, -1.0, tmpFeatV, 1, cnstr_w_coeff, 1);
                     cnstr_scal = TS[i].gtEv.deltaLoss(mvc4);

                     IloExpr constrExp(env);
                     for (int k=0;k < fd;k++) constrExp += cnstr_w_coeff[k]*var_w[k];
                     var_constrs.add(constrExp + cnstr_scal <= var_xi[i]);
                     mod.add(var_constrs[nConstr++]);
                     constrExp.end();
                  }
               }
            }
            extraVio += extraVio_i;
         }

         extraVio *= C_over_n;
         if (iter > 0){
            double curUbObjVal = curLbObjVal + extraVio;
            ubObjVals.push_back(curUbObjVal);
            if (curUbObjVal < minUbObjVal) minUbObjVal = curUbObjVal;
            double objValGap = minUbObjVal - curLbObjVal; // gap could < extraVio
            fprintf(stderr, "...curLbObjVal: %g, gap: %g\n", curLbObjVal, objValGap);
            if (objValGap < (STOPPING_TOL*curLbObjVal)) break;
         }

         // Optimize the problem and obtain the solution
         fprintf(stderr, "...optimizing QP, nConstr: %d", nConstr);
         if ( !cplex.solve() ) {
            env.error() << "Failed to optimize QP" << endl;
            throw(-1);
         }
         stringstream status;
         status << cplex.getStatus();
         fprintf(stderr, ", status: %s\n", status.str().c_str());

         curLbObjVal = cplex.getObjValue();
         cplex.getValues(num_w, var_w);
         cplex.getValues(num_xi, var_xi);
         try {
            num_b = cplex.getValue(var_b); //initially there might not have any constraint on b,
            //so var_b might not be set and this can throw an exception
         } catch  (IloException& e2){}

         lbObjVals.push_back(curLbObjVal);
         realTime2 = times(&endTime);
         fprintf(stderr, "...took user time=%fs\n",
               ((float)(endTime.tms_utime-startTime.tms_utime))/(HZ));

      }
      nIter = iter;

      //output
      enum{W_OUT = 0,
           B_OUT,
           XI_OUT,
           LBOBJVALS_OUT,
           UBOBJVALS_OUT
      };

      plhs[W_OUT] = mxCreateDoubleMatrix(fd, 1, mxREAL);
      double *w_out = mxGetPr(plhs[W_OUT]);
      memcpy(w_out, w, fd*sizeof(double));

      plhs[B_OUT] = mxCreateDoubleScalar(b);

      plhs[XI_OUT] = mxCreateDoubleMatrix(n, 1, mxREAL);
      double *xi_out = mxGetPr(plhs[XI_OUT]);
      memcpy(xi_out, xi, n*sizeof(double));

      plhs[LBOBJVALS_OUT] = mxCreateDoubleMatrix(nIter, 1, mxREAL);
      plhs[UBOBJVALS_OUT] = mxCreateDoubleMatrix(nIter, 1, mxREAL);
      double *lbObjVals_out = mxGetPr(plhs[LBOBJVALS_OUT]);
      double *ubObjVals_out = mxGetPr(plhs[UBOBJVALS_OUT]);
      for (int i=0; i < nIter; i++){
         lbObjVals_out[i] = lbObjVals[i];
         ubObjVals_out[i] = ubObjVals[i];
      }

   } catch (IloException& e) {
      cerr << "m_mexIntantDetect_ker: Concert exception caught: " << e << endl;
   } catch (exception& e) {
      cerr << "m_mexIntantDetect_ker: Standard exception caught: " << e.what() << endl;
   } catch (...) {
      cerr << "m_mexIntantDetect_ker: Unknown exception caught." << endl;
   }
   env.end();

   //free data
   delete [] TS;

   if ((ker.kerType == KER_CHI2)|| (ker.kerType == KER_INTER)){
      vl_homogeneouskernelmap_delete(ker.kerMap);
   }
}
