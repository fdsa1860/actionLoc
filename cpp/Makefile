TARGETS := getVideoFrameNumbers

CXXFLAGS := -Wall $(shell pkg-config --cflags opencv)
LDFLAGS := $(shell pkg-config --libs opencv)

CXX = g++

all : getVideoFrameNumbers.cpp
	$(CXX) -o getVideoFrameNumbers $(CXXFLAGS) $(LDFLAGS)  getVideoFrameNumbers.cpp
