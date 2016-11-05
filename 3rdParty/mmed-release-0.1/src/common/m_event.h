/*
 * m_event.h
 *
 * Created on: Jan 6, 2011
 * Author: Minh Hoai Nguyen, Carnegie Mellon University
 * Email:  minhhoai@cmu.edu, minhhoai@gmail.com
 */

#ifndef M_EVENT_H_
#define M_EVENT_H_

#include <math.h>
#include <stdlib.h>
#include <stdio.h>
#include <limits>
#include <algorithm>
#include <gsl/gsl_cblas.h>
#include <string>
#include <time.h>


class Event{
public:
   int s, e;
   Event(int s_, int e_){ s = s_; e = e_; }
   Event(){s = -1; e = -1;}
   Event(const Event& other){ s = other.s; e = other.e;};
   bool isEmpty() const;
   double deltaLoss(Event const& otherEv) const;
   int length() const;
//   bool operator < (const Event & otherEv) const{
//      if (e < otherEv.e) return true;
//      if ((e == otherEv.e) && (s <= otherEv.s)) return true;
//      return false;
//   }
   std::string str();
};

double diffclock(clock_t clock1,clock_t clock2);
void   cmpIntIm(double const *D, int d, int n, double *IntD);
void   cmpIntIm_1D(double const *D, int n, double *IntD);
void   sampleSeg(double const *D, int d, Event const& ev, int sd, double *raw_feat);

#endif /* M_EVENT_H_ */
