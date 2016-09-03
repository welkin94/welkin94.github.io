# 在Opencv中实现Matlab的bwareaopen函数功能

在Matlab中，我们通常利用bwareaopen函数去除八邻域内面积小于一定值的连通域。Opencv里没有特定的函数实现该功能，但我们可以自己设计一个孔洞填充/小区域去除的方式来实现。下面是实现的代码。


```C++
#include <cv.h>  
#include <highgui.h>  
#include <opencv2/imgproc/imgproc.hpp>    
#include <opencv2/highgui/highgui.hpp>    
#include <iostream>    
#include <vector>    
  
  
using namespace cv;  
using namespace std;  
  
void RemoveSmallRegion(Mat& Src, Mat& Dst, int AreaLimit=50, int CheckMode=1, int NeihborMode=0);  
  
int main()    
{    
    double t = (double)getTickCount();  
  
    char* imagePath = "E:\\SVM\\局部.jpg";  
    char* OutPath = "E:\\SVM\\局部_去除孔洞.jpg";  
      
    Mat Src = imread(imagePath, CV_LOAD_IMAGE_GRAYSCALE);  
    Mat Dst = Mat::zeros(Src.size(), CV_8UC1);  
      
  
    //二值化处理  
    for(int i = 0; i < Src.rows; ++i)    
    {    
        uchar* iData = Src.ptr<uchar>(i);  
        for(int j = 0; j < Src.cols; ++j)    
        {    
            if(iData[j] == 0 || iData[j]==255) continue;  
            else if (iData[j] < 10)    
            {    
                iData[j] = 0;    
                //cout<<'#';  
            }    
            else if (iData[j] > 10)    
            {    
                iData[j] = 255;   
                //cout<<'!';  
            }    
        }    
    }    
    cout<<"Image Binary processed."<<endl;  
  
    RemoveSmallRegion(Src, Dst, 20, 1, 1);  
    RemoveSmallRegion(Dst, Dst, 20, 0, 0);  
    cout<<"Done!"<<endl;  
    imwrite(OutPath, Dst);  
          
    t = ((double)getTickCount() - t)/getTickFrequency();  
    cout<<"Time cost: "<<t<<" sec."<<endl;  
  
    return 0;    
}    
  
//CheckMode: 0代表去除黑区域，1代表去除白区域; NeihborMode：0代表4邻域，1代表8邻域;  
void RemoveSmallRegion(Mat& Src, Mat& Dst, int AreaLimit, int CheckMode, int NeihborMode)  
{     
    int RemoveCount=0;       //记录除去的个数  
    //记录每个像素点检验状态的标签，0代表未检查，1代表正在检查,2代表检查不合格（需要反转颜色），3代表检查合格或不需检查  
    Mat Pointlabel = Mat::zeros( Src.size(), CV_8UC1 );  
      
    if(CheckMode==1)  
    {  
        cout<<"Mode: 去除小区域. ";  
        for(int i = 0; i < Src.rows; ++i)    
        {    
            uchar* iData = Src.ptr<uchar>(i);  
            uchar* iLabel = Pointlabel.ptr<uchar>(i);  
            for(int j = 0; j < Src.cols; ++j)    
            {    
                if (iData[j] < 10)    
                {    
                    iLabel[j] = 3;   
                }    
            }    
        }    
    }  
    else  
    {  
        cout<<"Mode: 去除孔洞. ";  
        for(int i = 0; i < Src.rows; ++i)    
        {    
            uchar* iData = Src.ptr<uchar>(i);  
            uchar* iLabel = Pointlabel.ptr<uchar>(i);  
            for(int j = 0; j < Src.cols; ++j)    
            {    
                if (iData[j] > 10)    
                {    
                    iLabel[j] = 3;   
                }    
            }    
        }    
    }  
  
    vector<Point2i> NeihborPos;  //记录邻域点位置  
    NeihborPos.push_back(Point2i(-1, 0));  
    NeihborPos.push_back(Point2i(1, 0));  
    NeihborPos.push_back(Point2i(0, -1));  
    NeihborPos.push_back(Point2i(0, 1));  
    if (NeihborMode==1)  
    {  
        cout<<"Neighbor mode: 8邻域."<<endl;  
        NeihborPos.push_back(Point2i(-1, -1));  
        NeihborPos.push_back(Point2i(-1, 1));  
        NeihborPos.push_back(Point2i(1, -1));  
        NeihborPos.push_back(Point2i(1, 1));  
    }  
    else cout<<"Neighbor mode: 4邻域."<<endl;  
    int NeihborCount=4+4*NeihborMode;  
    int CurrX=0, CurrY=0;  
    //开始检测  
    for(int i = 0; i < Src.rows; ++i)    
    {    
        uchar* iLabel = Pointlabel.ptr<uchar>(i);  
        for(int j = 0; j < Src.cols; ++j)    
        {    
            if (iLabel[j] == 0)    
            {    
                //********开始该点处的检查**********  
                vector<Point2i> GrowBuffer;                                      //堆栈，用于存储生长点  
                GrowBuffer.push_back( Point2i(j, i) );  
                Pointlabel.at<uchar>(i, j)=1;  
                int CheckResult=0;                                               //用于判断结果（是否超出大小），0为未超出，1为超出  
  
                for ( int z=0; z<GrowBuffer.size(); z++ )  
                {  
  
                    for (int q=0; q<NeihborCount; q++)                                      //检查四个邻域点  
                    {  
                        CurrX=GrowBuffer.at(z).x+NeihborPos.at(q).x;  
                        CurrY=GrowBuffer.at(z).y+NeihborPos.at(q).y;  
                        if (CurrX>=0&&CurrX<Src.cols&&CurrY>=0&&CurrY<Src.rows)  //防止越界  
                        {  
                            if ( Pointlabel.at<uchar>(CurrY, CurrX)==0 )  
                            {  
                                GrowBuffer.push_back( Point2i(CurrX, CurrY) );  //邻域点加入buffer  
                                Pointlabel.at<uchar>(CurrY, CurrX)=1;           //更新邻域点的检查标签，避免重复检查  
                            }  
                        }  
                    }  
  
                }  
                if (GrowBuffer.size()>AreaLimit) CheckResult=2;                 //判断结果（是否超出限定的大小），1为未超出，2为超出  
                else {CheckResult=1;   RemoveCount++;}  
                for (int z=0; z<GrowBuffer.size(); z++)                         //更新Label记录  
                {  
                    CurrX=GrowBuffer.at(z).x;   
                    CurrY=GrowBuffer.at(z).y;  
                    Pointlabel.at<uchar>(CurrY, CurrX) += CheckResult;  
                }  
                //********结束该点处的检查**********  
  
  
            }    
        }    
    }    
  
    CheckMode=255*(1-CheckMode);  
    //开始反转面积过小的区域  
    for(int i = 0; i < Src.rows; ++i)    
    {    
        uchar* iData = Src.ptr<uchar>(i);  
        uchar* iDstData = Dst.ptr<uchar>(i);  
        uchar* iLabel = Pointlabel.ptr<uchar>(i);  
        for(int j = 0; j < Src.cols; ++j)    
        {    
            if (iLabel[j] == 2)    
            {    
                iDstData[j] = CheckMode;   
            }    
            else if(iLabel[j] == 3)  
            {  
                iDstData[j] = iData[j];  
            }  
        }    
    }   
      
    cout<<RemoveCount<<" objects removed."<<endl;  
}  

```


