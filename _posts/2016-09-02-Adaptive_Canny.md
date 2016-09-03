---
layout: post
cover: 'assets/images/cover3.jpg'
title: Canny自适应边缘检测（openCV）
date:   2016-09-03 10:18:00
tags: 图像处理 去噪
subclass: 'post tag-test tag-content'
categories: 'casper'
navigation: True
logo: 'assets/images/ghost.png'
---
# Canny自适应边缘检测（openCV）

Canny算子是一种常用的边缘检测算子，其在opencv中的形式如下
```C++
void cvCanny( const CvArr* image, 
CvArr* edges, 							
double threshold1,
double threshold2, 									   
int aperture_size=3 );
```
其中
  - image 单通道输入图像.
  - edges 单通道存储边缘的输出图像
  - threshold1 第一个阈值
  - threshold2 第二个阈值
  - aperture_size Sobel算子内核大小

在OpenCV中，Canny算子的检测速度较快，且准确率较高。但Canny算子的上下阈值均需要手动输入，使得其实用性下降。
本文的算法实现了Canny算子的自适应阈值，其具体实现如下：


```C++
#include <cv.h>  
#include <highgui.h>  
#include <math.h>  
#include <iostream>  
  
using namespace std;  
  
void AdaptiveFindThreshold(const CvArr* image, double *low, double *high, int aperture_size=3);  
void _AdaptiveFindThreshold(CvMat *dx, CvMat *dy, double *low, double *high);  
  
int main(int argc, char** argv)  
{  
    IplImage* pImg = NULL;      
    IplImage* pCannyImg = NULL;  
  
    double low_thresh = 0.0;  
    double high_thresh = 0.0;  
  
    if( argc == 2 && (pImg = cvLoadImage( argv[1], 0)) != 0 )     
    {             
        pCannyImg = cvCreateImage(cvGetSize(pImg), IPL_DEPTH_8U, 1);  
          
        CvMat *dx = (CvMat*)pImg;  
        CvMat *dy = (CvMat*)pCannyImg;  
        if(low_thresh == 0.0 && high_thresh == 0.0)  
        {    
            AdaptiveFindThreshold(pImg, &low_thresh, &high_thresh);  
            cout << "low_thresh:  " << low_thresh << endl;  
            cout << "high_thresh: " << high_thresh << endl;  
        }  
        cvCanny(pImg, pCannyImg, low_thresh, high_thresh, 3);     
  
        cvNamedWindow("src", 1);     
        cvNamedWindow("canny",1);     
  
        cvShowImage( "src", pImg );     
        cvShowImage( "canny", pCannyImg );     
  
        cvWaitKey(0);      
  
        cvDestroyWindow( "src" );     
        cvDestroyWindow( "canny" );     
  
        cvReleaseImage( &pImg );      
        cvReleaseImage( &pCannyImg );      
    }  
    return 0;   
}  
  
void AdaptiveFindThreshold(const CvArr* image, double *low, double *high, int aperture_size)  
{                                                                                
    cv::Mat src = cv::cvarrToMat(image);                                     
    const int cn = src.channels();                                           
    cv::Mat dx(src.rows, src.cols, CV_16SC(cn));                             
    cv::Mat dy(src.rows, src.cols, CV_16SC(cn));                             
                                                                                 
    cv::Sobel(src, dx, CV_16S, 1, 0, aperture_size, 1, 0, cv::BORDER_REPLICATE);  
    cv::Sobel(src, dy, CV_16S, 0, 1, aperture_size, 1, 0, cv::BORDER_REPLICATE);  
                                                                                 
    CvMat _dx = dx, _dy = dy;                                                
    _AdaptiveFindThreshold(&_dx, &_dy, low, high);                           
                                                                                 
}                                                                                
                                                                                 
// 仿照matlab，自适应求高低两个门限                                              
void _AdaptiveFindThreshold(CvMat *dx, CvMat *dy, double *low, double *high)     
{                                                                                
    CvSize size;                                                             
    IplImage *imge=0;                                                        
    int i,j;                                                                 
    CvHistogram *hist;                                                       
    int hist_size = 255;                                                     
    float range_0[]={0,256};                                                 
    float* ranges[] = { range_0 };                                           
    double PercentOfPixelsNotEdges = 0.7;                                    
    size = cvGetSize(dx);                                                    
    imge = cvCreateImage(size, IPL_DEPTH_32F, 1);                            
    // 计算边缘的强度, 并存于图像中                                          
    float maxv = 0;                                                          
    for(i = 0; i < size.height; i++ )                                        
    {                                                                        
        const short* _dx = (short*)(dx->data.ptr + dx->step*i);          
        const short* _dy = (short*)(dy->data.ptr + dy->step*i);          
        float* _image = (float *)(imge->imageData + imge->widthStep*i);  
        for(j = 0; j < size.width; j++)                                  
        {                                                                
            _image[j] = (float)(abs(_dx[j]) + abs(_dy[j]));          
            maxv = maxv < _image[j] ? _image[j]: maxv;               
                                                                             
        }                                                                
    }                                                                        
    if(maxv == 0){                                                           
        *high = 0;                                                       
        *low = 0;                                                        
        cvReleaseImage( &imge );                                         
        return;                                                          
    }                                                                        
                                                                                 
    // 计算直方图                                                            
    range_0[1] = maxv;                                                       
    hist_size = (int)(hist_size > maxv ? maxv:hist_size);                    
    hist = cvCreateHist(1, &hist_size, CV_HIST_ARRAY, ranges, 1);            
    cvCalcHist( &imge, hist, 0, NULL );                                      
    int total = (int)(size.height * size.width * PercentOfPixelsNotEdges);   
    float sum=0;                                                             
    int icount = hist->mat.dim[0].size;                                      
                                                                                 
    float *h = (float*)cvPtr1D( hist->bins, 0 );                             
    for(i = 0; i < icount; i++)                                              
    {                                                                        
        sum += h[i];                                                     
        if( sum > total )                                                
            break;                                                   
    }                                                                        
    // 计算高低门限                                                          
    *high = (i+1) * maxv / hist_size ;                                       
    *low = *high * 0.4;                                                      
    cvReleaseImage( &imge );                                                 
    cvReleaseHist(&hist);                                                    
}               
```

