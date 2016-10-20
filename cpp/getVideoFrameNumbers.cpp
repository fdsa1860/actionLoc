#include <opencv2/opencv.hpp>
#include <cstring>
#include <iostream>
#include <fstream>


using namespace std;
using namespace cv;

int main(int argc, char** argv)
{
//    std::string file = "~/research/data/activitynet/video/activitynet_02_drinkBeer.mp4";
    if (argc < 2)
    {
        cout << "Need one and only one argument" << endl;
        return(1);
    }
    
    string videoName;
    ifstream input;
    ofstream output;
    int nFrame;
    
    input.open(argv[1],ios::in);
    output.open("output.txt", ios::out);
    if (!input.is_open())
    {
        cout << "Cannot open input file " << argv[1] << endl;
    }
    {
        while(getline(input, videoName))
        {
            VideoCapture cap(videoName);
            if(!cap.isOpened())
            cout << videoName << " cannot be opened" << endl;
            return -1;
            nFrame = cap.get(CV_CAP_PROP_FRAME_COUNT);
            output << nFrame << endl;
        }
    }
    
    cout << "done!" << endl;
}