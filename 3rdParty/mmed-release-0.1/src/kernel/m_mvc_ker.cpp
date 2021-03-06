/*
 * m_mvc_ker.cpp
 *
 * Created on: Feb 8, 2011
 * Author: Minh Hoai Nguyen, Carnegie Mellon University
 * Email:  minhhoai@cmu.edu, minhhoai@gmail.com
 */

#include "m_mvc_ker.h"
#include <iostream>
#include <string>
#include <sstream>

using namespace std;

void
TimeSeries::getSegFeatVec(Event const& ev, double *feat){
   if (ker.nSegDiv == 1) getSegFeatVec_oneDiv(ev, feat);
   else {
      int fd_div = ker.get_fd_oneDiv(d);
      int evLen = ev.length();
      int divLen = evLen/ker.nSegDiv;

      int ev_i_s = ev.s;
      double *feat_ptr = feat;
      for (int i=0; i < ker.nSegDiv - 1; i++){
         getSegFeatVec_oneDiv(Event(ev_i_s, ev_i_s + divLen - 1), feat_ptr);
         ev_i_s += divLen;
         feat_ptr += fd_div;
      }
      getSegFeatVec_oneDiv(Event(ev_i_s, ev.e), feat_ptr);
   }
}

void
TimeSeries::getSegFeatVec_oneDiv(Event const& ev, double *feat){
   double *raw_feat; // raw feature vector
   int raw_dim;      // dimension of raw feature vector
   if (featType == FEAT_BAG) {
      raw_dim = d;
      raw_feat = new double[raw_dim];
      memcpy(raw_feat, IntD + d*(ev.e + 1), d*sizeof(double)); // raw_feat = IntD(:, ev.e+1)
      cblas_daxpy(d, -1.0, IntD + d*ev.s, 1, raw_feat, 1);     // raw_feat = raw_feat - IntD(:,ev.s)
   } else if (featType == FEAT_ORDER) { // interpolation
      raw_dim = d*sd;
      raw_feat = new double[raw_dim];
      sampleSeg(D, d, ev, sd, raw_feat);
   } else if (featType == FEAT_ENDDIFF){
      raw_dim = d;
      raw_feat = new double[raw_dim];
      memcpy(raw_feat, D + d*ev.e, d*sizeof(double));
      cblas_daxpy(d, -1.0, D + d*ev.s, 1, raw_feat, 1);
   }

   if ((ker.kerType == KER_CHI2) || (ker.kerType == KER_INTER)){
      int d2 = 2*ker.kerN + 1;
      memset(feat, 0, fd*sizeof(double)); // this is absolutely necessary

      double sum = cblas_dasum(raw_dim, raw_feat, 1);
      cblas_dscal(raw_dim, 1/sum, raw_feat, 1); // raw_feat = raw_feat/sum(raw_feat);

      for (int i=0; i < raw_dim; i++){
         vl_homogeneouskernelmap_evaluate_d(ker.kerMap, feat + i*d2, 1, raw_feat[i]);
      }

   } else if (ker.kerType == KER_LINEAR){
      double nrm2 = cblas_dnrm2(raw_dim, raw_feat, 1);
      cblas_dscal(raw_dim, 1/nrm2, raw_feat, 1); // raw_feat = raw_feat/sum(raw_feat);
      memcpy(feat, raw_feat, raw_dim*sizeof(double));
   } else if (ker.kerType == KER_LINEAR_NONORM){
      memcpy(feat, raw_feat, raw_dim*sizeof(double));
   } else if (ker.kerType == KER_LINEAR_LENGTHNORM){
      cblas_dscal(raw_dim, 1.0f/ev.length(), raw_feat, 1);
      memcpy(feat, raw_feat, raw_dim*sizeof(double));
   }
   delete [] raw_feat;
}




void
TimeSeries::setSegLst(int minSegLen, int maxSegLen, int stride){
   if (maxSegLen > n) maxSegLen = n;
   if (minSegLen > maxSegLen) return;
   if ((stride < 1) || (minSegLen < 1) ) throw(-1);

   int r = (n-minSegLen)/stride;
   for (int e = minSegLen - 1 + r*stride; e >= 0; e-= stride){ // prefer segments starting at 0 rather than ending at n-1
      for (int l=minSegLen; l <= maxSegLen; l+=stride){
         int s = e - l + 1;
         if (s < 0) break;
         segLst.push_back(ExEvent(s, e));
      }
   }
   reverse(segLst.begin(), segLst.end());
}

void
TimeSeries::setEvtLst(int stride, int maxEvLen){
   if (!gtEv.isEmpty()) {
      if (stride < 1) throw -1;
      for (int e= gtEv.e; e >= gtEv.s; e-=stride){
         if (e - gtEv.s >= maxEvLen) evtLst.push_back(ExEvent(e - maxEvLen + 1, e));
         else evtLst.push_back(ExEvent(gtEv.s, e));
      }

      reverse(evtLst.begin(), evtLst.end());
   }
}

void
TimeSeries::cacheSegLstFeats(){
   isSegFeatCached = true;
   cacheLst(segLst);
}

void
TimeSeries::cacheEvtLstFeats(){
   isEvtFeatCached = true;
   cacheLst(evtLst);
}

void
TimeSeries::cacheLst(std::vector<ExEvent> &lst){
   for (int i=0; i < lst.size(); i++){
      lst[i].feat = new double[fd];
      getSegFeatVec(lst[i], lst[i].feat);
   }
}


void
TimeSeries::updateAllVals(double const* w, double const& b){
   updateSegLstVals(w, b);
   updateEvtLstVals(w, b);

   if (gtEv.isEmpty()){
      gtEv.val = 0;
   } else {
      if (isGtEvFeatCached) {
         gtEv.val = cblas_ddot(fd, w, 1, gtEv.feat, 1) + b;
      } else {
         gtEv.feat = new double[fd];
         getSegFeatVec(gtEv, gtEv.feat);
         gtEv.val = cblas_ddot(fd, w, 1, gtEv.feat, 1) + b;
         isGtEvFeatCached = true;
      }
   }
}

void TimeSeries::updateSegLstVals(double const* w, double const& b){
   if (isSegFeatCached) updateLstVals_cached(segLst, w, b);
   else updateLstVals(segLst, w, b);
}

void TimeSeries::updateEvtLstVals(double const* w, double const& b){
   if (isEvtFeatCached) updateLstVals_cached(evtLst, w, b);
   else updateLstVals(evtLst, w, b);
}

void
TimeSeries::updateLstVals_cached(std::vector<ExEvent> &lst, double const* w, double const& b){
   for (int i=0; i < lst.size(); i++){
      lst[i].val = cblas_ddot(fd, w, 1, lst[i].feat, 1) + b;
   }
}

void
TimeSeries::updateLstVals(std::vector<ExEvent> &lst, double const* w, double const& b){
   double feat[fd];
   for (int i=0; i < lst.size(); i++){
      getSegFeatVec(lst[i], feat);
      lst[i].val = cblas_ddot(fd, w, 1, feat, 1) + b;
   }
}


string
TimeSeries::str(){
   ostringstream rslt;

   rslt << "TrEvList: ";
   for (int i=0; i < evtLst.size(); i++){
      rslt << evtLst[i].str() << " ";
   }
   rslt << "\n" << "SegList: ";

   for (int i=0; i < segLst.size(); i++){
      rslt << segLst[i].str() << " ";
   }
   return rslt.str();
}


double
TimeSeries::findMVC1(Event &mvc1){
   double newVal, mxVal = - numeric_limits<double>::infinity();
   for (int i=0; i < segLst.size(); i++){
      if ((!gtEv.isEmpty()) && (segLst[i].e >= gtEv.s))
         break; // only consider segment when the event hasn't started
      newVal = segLst[i].val;
      if (newVal > mxVal){
         mxVal = newVal;
         mvc1  = segLst[i];
      }
   }
   return (1 + mxVal);
}


double
TimeSeries::findMVC2(int &t2, Event &mvc2){
   double newVal, mxVal = - numeric_limits<double>::infinity();
   int e;
   for (int i=0; i < evtLst.size(); i++){
      e = evtLst[i].e;
      newVal = mu[e]*(1 - evtLst[i].val);

      if (newVal > mxVal){
         mxVal = newVal;
         t2 = e;
         mvc2 = evtLst[i];
      }
   }
   return mxVal;
}

double
TimeSeries::findMVC3(int &t3, Event &mvc3){
   double newVal, mxVal = - numeric_limits<double>::infinity();

   for (int i= evtLst.size()-1; i >=0; i--){
      int t = evtLst[i].e; // the current time, the end of the current truncated event
      double trEvVal = evtLst[i].val;
      for (int j=0; j < segLst.size(); j++){
         if (segLst[j].e > t) break; // the end of the segment is after the current time

         newVal = mu[t]*(segLst[j].val - trEvVal + segLst[j].deltaLoss(evtLst[i]));
         if (newVal > mxVal){
            mxVal = newVal;
            t3 = t;
            mvc3 = segLst[j];
         }
      }
   }
   return mxVal;
}


double
TimeSeries::findMVC4(Event &mvc4){
   double newVal, mxVal = - numeric_limits<double>::infinity();

   for (int i=0; i < segLst.size(); i++){
      newVal = segLst[i].val;
      if ((newVal + 1)<= mxVal) continue;
      newVal += segLst[i].deltaLoss(gtEv);
      if (newVal > mxVal){
         mxVal = newVal;
         mvc4 = segLst[i];
      }
   }
   return mxVal - gtEv.val;
}


TimeSeries::TimeSeries(){
   isSegFeatCached  = false;
   isEvtFeatCached = false;
   isGtEvFeatCached = false;
}


TimeSeries::~TimeSeries(){
   if (isSegFeatCached)
      for (int i=0; i < segLst.size(); i++) delete segLst[i].feat;
   if (isEvtFeatCached)
      for (int i=0; i < evtLst.size(); i++) delete evtLst[i].feat;
   if (isGtEvFeatCached) delete [] gtEv.feat;
   if (featType == FEAT_BAG) delete [] IntD;
}
