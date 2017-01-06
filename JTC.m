%% 读入图像
clear all;
close all;
N1=768;%屏幕范围
N2=1024;
test_item = 'eo';%控制测试对象
if test_item == 'ee'
    im_1=imread('E.bmp');%图像1
    im_2=imread('E.bmp');%图像2
else
    im_1=imread('E.bmp');%图像1
    im_2=imread('O.bmp');%图像2
end    
ob_1_raw=double(rgb2gray(im_1));
ob_2_raw=double(rgb2gray(im_2));
% figure,subplot(121),imshow(ob_1,[]);
% subplot(122),imshow(ob_2,[]);
%% 把输入图像置于同一平面；
place1 = 0.32;%图像E位置，区间0-1
place2 = 1 - place1;%图像O位置
size_aim =40;%图像目的大小，范围0-N
size_ac = size(ob_1_raw);
compress =  size_aim/size_ac(1);%图像微缩倍数
ob_1 = imresize(ob_1_raw,compress);
ob_2 = imresize(ob_2_raw,compress);

[m10,n10]=size(ob_1);
[m20,n20]=size(ob_2);
m1=floor(m10/2);
m2=floor(m20/2);
n1=floor(n10/2);
n2=floor(n20/2);
input=zeros(N1,N2);
input(N1/2-m1+1:N1/2+m10-m1,round(N2*place1)-n1+1:round(N2*place1)+n10-n1)=ob_1;
input(N1/2-m2+1:N1/2+m20-m2,round(N2*place2)-n2+1:round(N2*place2)+n20-n2)=ob_2;
input_s1=zeros(N1,N2);
input_s1(N1/2-m1+1:N1/2+m10-m1,round(N2*place1)-n1+1:round(N2*place1)+n10-n1)=ob_1;
input_s2=zeros(N1,N2);
input_s2(N1/2-m2+1:N1/2+m20-m2,round(N2*place2)-n2+1:round(N2*place2)+n20-n2)=ob_2;
if test_item == 'ee'
    stf=figure('NumberTitle','off','Name','ee物面');
    imshow(input,[]);
    saveas(stf,'ee_40','jpg');
else
    stf=figure('NumberTitle','off','Name','eo物面');
    imshow(input,[]);
    saveas(stf,'eo_40','jpg');
end   

%%
% input_edge=edge(input,'canny');%滤波
input_edge=input;
input_edge_s1=input_s1;
input_edge_s2=input_s2;
% figure,imshow(input_edge,[]);
%% 
%相关计算
input_fft=fft2(input_edge);
input_fft_s1=fft2(input_edge_s1);
input_fft_s2=fft2(input_edge_s2);

input_fftshift=fftshift(input_fft);
input_fftshift_s1=fftshift(input_fft_s1);
input_fftshift_s2=fftshift(input_fft_s2);

input_abs=abs(input_fftshift);
input_abs_s1=abs(input_fftshift_s1);
input_abs_s2=abs(input_fftshift_s2);

% input_abs=input_fftshift.*conj(input_fftshift);
% input_abs_s1=input_fftshift_s1.*conj(input_fftshift_s1);
% input_abs_s2=input_fftshift_s2.*conj(input_fftshift_s2);


if test_item == 'ee'
    stf=figure('NumberTitle','off','Name','ee频率谱')
    imshow(abs(input_abs),[]);
    shading interp;
    saveas(stf,'ee_freq_40','jpg');
else
    stf=figure('NumberTitle','off','Name','eo频率谱')
    imshow(abs(input_abs),[]);
    shading interp;
    saveas(stf,'eo_freq_40','jpg');
end   
output_ifft=fft2(input_abs);
output_ifft_s1=fft2(input_abs_s1);
output_ifft_s2=fft2(input_abs_s2);

output=fftshift(output_ifft);
output_s1=fftshift(output_ifft_s1);
output_s2=fftshift(output_ifft_s2);
%% 
%物面部分
if test_item == 'ee'
    stf=figure('NumberTitle','off','Name','ee像面三维图');
    mesh(abs(output));
    shading interp;
    saveas(stf,'ee_3d_40','jpg');
    stf=figure('NumberTitle','off','Name','ee像面灰度图');%由于自相关峰峰过亮，做平方根处理突出图像中互相关峰
    imshow(abs(sqrt(output)),[]);
    saveas(stf,'ee_grey_40','jpg');
else
    stf=figure('NumberTitle','off','Name','eo像面三维图');
    mesh(abs(output));
    shading interp;
    saveas(stf,'eo_3d_40','jpg');
    stf=figure('NumberTitle','off','Name','eo像面灰度图');%由于自相关峰峰过亮，做平方根处理突出图像中互相关峰
    imshow(abs(sqrt(output)),[]);
    saveas(stf,'eo_grey_40','jpg');
end  



% figure('NumberTitle','off','Name','像面三维图(对数变换)');
% mesh(log(1+abs(output)));
% shading interp;

% figure('NumberTitle','off','Name','像面');
% imshow(output,[]);

% figure('NumberTitle','off','Name','像面(对数变换)');
% imshow(log(1+abs(output)),[]);
% %%
% %频率相减滤波
% output_filt_single = abs(output-output_s2);
% output_filt = abs(output-output_s1-output_s2);
% %
% % figure('NumberTitle','off','Name','高通滤波后像面三维图(对数变换)');
% % mesh(log(1+abs(output_filt)));
% % shading interp;
% 
% figure('NumberTitle','off','Name','滤波后像面三维图');
% mesh(abs(output_filt));
% shading interp;
% 
% figure('NumberTitle','off','Name','去除单次自相干结果后像面三维图');
% mesh(abs(output_filt_single));
% shading interp;