TARGETS := getVideoFrameNumbers

CXXFLAGS := -Wall $(shell pkg-config --cflags opencv libavutil libavcodec libavformat libavdevice libavfilter libavresample libswscale libpostproc)
LDFLAGS := $(shell pkg-config --libs opencv libavutil libavcodec libavformat libavdevice libavfilter libavresample libswscale libpostproc)

CXX = g++

all : getVideoFrameNumbers.cpp
	$(CXX) -o getVideoFrameNumbers $(CXXFLAGS) $(LDFLAGS)  getVideoFrameNumbers.cpp