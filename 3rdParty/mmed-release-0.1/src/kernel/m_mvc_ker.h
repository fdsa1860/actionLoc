/*
 * m_mvc_ker.h
 * MVC: most violated constraint
 *
 * Created on: Feb 8, 2011
 * Author: Minh Hoai Nguyen, Carnegie Mellon University
 * Email:  minhhoai@cmu.edu, minhhoai@gmail.com
 */

#ifndef M_MVC_KER_H_
#define M_MVC_KER_H_

#include "../common/m_event.h"
#include <limits>
#include <string>
#include <vector>

extern "C" {
   #include <vl/homkermap.h>
//  #include <vl/mathop.h>
}

enum{
   KER_CHI2 = 0,
   KER_INTER,
   KER_LINEAR,
   KER_LINEAR_NONORM,
   KER_CHI2_NONORM,  // not currently supported
   KER_INTER_NONORM, // not currently supported
   KER_LINEAR_LENGTHNORM,
};

enum{
   FEAT_BAG = 0, // before normalization (if any) feature vector of a segment is the sum of
                 // feature vectors inside the segment
   FEAT_ORDER, // before normalization (if any), we make ordered sampling of feature vectors inside
               // the segment and concatenate them (row-by-row) to make feature vector for the segment
   FEAT_ENDDIFF, // before normalization (if any), the feature vector of a segment is the difference
};



class ExEvent:public Event{
public:
   ExEvent():Event(){val = 0;};
   ExEvent(int s_, int e_):Event(s_,e_){};

   double *feat;
   double val;

};

class Kernel{ //wrapper for kernel
public:
   VlHomogeneousKernelMap *kerMap;
   int kerN;
   double kerL;
   int kerType;
   int nSegDiv; // number of segment division

   int get_fd(int d) const{
      return get_fd_oneDiv(d)*nSegDiv;
   }

   int get_fd_oneDiv(int d) const{
      int fd;
      if ((kerType == KER_LINEAR) || (kerType == KER_LINEAR_NONORM) ||
          (kerType == KER_LINEAR_LENGTHNORM)) fd = d;
      else fd = d*(2*kerN + 1);
      return fd;
   }
};


class TimeSeries{ // time series class
public:
   int d, fd, n;
   int featType;
   Kernel ker;
   double *D; // D is d*n matrix
   double *mu; //a 1*n vector, for slack variable rescaling
   ExEvent gtEv;
   bool isGtEvFeatCached, isSegFeatCached, isEvtFeatCached; // mark if the feature vectors are cached
   std::vector<ExEvent> segLst; // list of segments to be considered, sorted by end frames and tie breaking using start frames
   std::vector<ExEvent> evtLst; // list of truncated events to be considered, sorted by end frames

   TimeSeries();

   void setSegLst(int minSegLen, int maxSegLen, int stride); //set the segment list
   void setEvtLst(int stride, int maxEvLen); // set the list of truncated events
   void cacheSegLstFeats();
   void cacheEvtLstFeats();
   void updateSegLstVals(double const* w, double const& b);
   void updateEvtLstVals(double const* w, double const& b);
   void updateAllVals(double const* w, double const& b);

   // when the event hasn't started, the detector should output "no"
   double findMVC1(Event &mvc1);
   // when the event has started, the detector should output "yes"
   double findMVC2(int &t2, Event &mvc2);
   // when the event is partially observed, the truncated event must be THE output
   double findMVC3(int &t3, Event &mvc3);
   // when the whole sequence has been observed, the event must be THE output
   double findMVC4(Event &mvc4);

   std::string str();

   ~TimeSeries();

   // Most important function of all
   void getSegFeatVec(Event const& ev, double *feat);

   // specific to FEAT_BAG
   double *IntD; // d*(n+1) matrix for the integral image

   // specific to FEAT_ORDER
   int sd; // number of samples per segment

protected:
   void cacheLst(std::vector<ExEvent> &lst);
   void updateLstVals_cached(std::vector<ExEvent> &lst, double const* w, double const& b);
   void updateLstVals(std::vector<ExEvent> &lst, double const* w, double const& b);
   void getSegFeatVec_oneDiv(Event const& ev, double *feat); // segment feature vector without segment division
};


#endif /* M_MVC_KER_H_ */
