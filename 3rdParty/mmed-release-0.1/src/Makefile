VL_DIR = $(HOME)/Research/code/toolbox/vlfeat-0.9.19
MATLABDIR ?= /Applications/MATLAB_R2015b.app
MACHINE = $(shell uname)
ifeq ($(MACHINE), Darwin)
	CBLAS = -L/usr/local/lib
	FRWKFLAGS = -bundle -framework CoreFoundation -framework IOKit
	CPLEX_DIR = /Users/hoai/Applications/IBM/ILOG/CPLEX_Studio124/
	CPLEX_INCLUDE = $(CPLEX_DIR)/cplex/include
	CPLEX_LIB = $(CPLEX_DIR)/cplex/lib/x86-64_darwin9_gcc4.0/static_pic
	CPLEX_CONCERT_INCLUDE = $(CPLEX_DIR)/concert/include
	CPLEX_CONCERT_LIB = $(CPLEX_DIR)/concert/lib/x86-64_darwin9_gcc4.0/static_pic
else
	CPLEX_DIR = /afs/cs.cmu.edu/local/ilog/amd64_fc5/10.0/ilog/
	CPLEX_INCLUDE = $(CPLEX_DIR)/cplex100/include/
	CPLEX_LIB = $(CPLEX_DIR)/cplex100/lib/x86-64_rhel4.0_3.4/static_pic/
	CPLEX_CONCERT_INCLUDE = $(CPLEX_DIR)/concert22/include
	CPLEX_CONCERT_LIB = $(CPLEX_DIR)/concert22/lib/x86-64_rhel4.0_3.4/static_pic/
endif

CXX = g++ #Compile using Stuffen
DEBUG=-g

LDFLAGS = -L$(CPLEX_LIB) -lilocplex -lcplex -L$(CPLEX_CONCERT_LIB) -lconcert $(LDFLAGS_NOCPLEX) $(CBLAS) -lgslcblas -lm -lpthread -L$(VL_DIR)/bin/maci64/ -lvl
CFLAGS = -O3 -fPIC -fexceptions -DNDEBUG -DIL_STD -I$(MATLABDIR)/extern/include -I$(CPLEX_INCLUDE)\
        -I$(CPLEX_CONCERT_INCLUDE) -I$(VL_DIR) -I/usr/local/include

ifeq ($(MACHINE), Darwin)
	MEX_OPTION= -cxx -largeArrayDims LD\#$(CXX) CXXFLAGS\#"$(CFLAGS)" LDFLAGS\#"$(FRWKFLAGS)" $(LDFLAGS)
else
	MEX_OPTION= -cxx -largeArrayDims LD\#$(CXX) CXXFLAGS\#"$(CFLAGS)" $(LDFLAGS)
endif

BIN = ../bin/
MEX = $(MATLABDIR)/bin/mex -cxx
MEX_EXT = $(shell $(MATLABDIR)/bin/mexext) 

#all: $(PROGS)
all: $(BIN)/m_mexCmpF1Score.$(MEX_EXT)\
	$(BIN)/m_mexAMOC.$(MEX_EXT)  $(BIN)/m_mexMMED_ker.$(MEX_EXT)\
	$(BIN)/m_mexEval_ker.$(MEX_EXT) $(BIN)/m_mexF1curve.$(MEX_EXT) $(BIN)/m_mexF1curve_frm.$(MEX_EXT)\
	$(BIN)/m_mexSampleSeg.$(MEX_EXT)
	
$(BIN)/m_event.o: ./common/m_event.cpp 
	$(CXX) $(CFLAGS) -o $@ -c $^

$(BIN)/m_mexCmpF1Score.o: ./common/m_mexCmpF1Score.cpp
	$(CXX) $(CFLAGS) -o $@ -c $^

$(BIN)/m_mexCmpF1Score.$(MEX_EXT): $(BIN)/m_mexCmpF1Score.o $(BIN)/m_event.o
	$(MEX) $(MEX_OPTION) -output $@ $^

$(BIN)/m_mexAMOC.o: ./common/m_mexAMOC.cpp
	$(CXX) $(CFLAGS) -o $@ -c $^

$(BIN)/m_mexAMOC.$(MEX_EXT): $(BIN)/m_mexAMOC.o $(BIN)/m_event.o
	$(MEX) $(MEX_OPTION) -output $@ $^
	
$(BIN)/m_mexF1curve.o: ./common/m_mexF1curve.cpp
	$(CXX) $(CFLAGS) -o $@ -c $^

$(BIN)/m_mexF1curve.$(MEX_EXT): $(BIN)/m_mexF1curve.o $(BIN)/m_event.o
	$(MEX) $(MEX_OPTION) -output $@ $^
	
$(BIN)/m_mexF1curve_frm.o: ./common/m_mexF1curve_frm.cpp
	$(CXX) $(CFLAGS) -o $@ -c $^

$(BIN)/m_mexF1curve_frm.$(MEX_EXT): $(BIN)/m_mexF1curve_frm.o $(BIN)/m_event.o
	$(MEX) $(MEX_OPTION) -output $@ $^

$(BIN)/m_mvc_ker.o: ./kernel/m_mvc_ker.cpp
	$(CXX) $(CFLAGS) -o $@ -c $^ 	

$(BIN)/m_mexMMED_ker.o: ./kernel/m_mexMMED_ker.cpp
	$(CXX) $(CFLAGS) -o $@ -c $^
	
$(BIN)/m_mexMMED_ker.$(MEX_EXT): $(BIN)/m_mexMMED_ker.o $(BIN)/m_event.o $(BIN)/m_mvc_ker.o
	$(MEX) $(MEX_OPTION) -output $@ $^ 	

$(BIN)/m_mexEval_ker.o: ./kernel/m_mexEval_ker.cpp
	$(CXX) $(CFLAGS) -o $@ -c $^

$(BIN)/m_mexEval_ker.$(MEX_EXT): $(BIN)/m_mexEval_ker.o $(BIN)/m_event.o $(BIN)/m_mvc_ker.o
	$(MEX) $(MEX_OPTION) -output $@ $^ 		

$(BIN)/m_test: ./kernel/m_test.cpp $(BIN)/m_event.o $(BIN)/m_mvc_ker.o
	$(CXX) $(LDFLAGS_NOCPLEX) $(CFLAGS) -o $@ $^
	
$(BIN)/m_mexSampleSeg.o: ./common/m_mexSampleSeg.cpp
	$(CXX) $(CFLAGS) -o $@ -c $^

$(BIN)/m_mexSampleSeg.$(MEX_EXT): $(BIN)/m_mexSampleSeg.o $(BIN)/m_event.o
	$(MEX) $(MEX_OPTION) -output $@ $^
	
clean:
	rm -f *~ $(BIN)/*.o $(BIN)/*.obj
