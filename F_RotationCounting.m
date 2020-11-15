function results=F_RotationCounting(basedirectory,B_thre,iftophat)

d = dir([basedirectory,'Unroll','\*-Tile.tiff']);  
%isub = d(:).isdir; %# returns logical vector  
sampleSet = {d.name}';  
sampleSet(ismember(sampleSet,{'.','..'})) = [];  
sampleNum=length(sampleSet);
DropNumber=zeros(sampleNum,1);
Intense_thre=zeros(sampleNum,1);
H_Int_thre=zeros(sampleNum,1);
H_Area_thre=zeros(sampleNum,1);
H_iftophat=ones(sampleNum,1);
results=table(sampleSet,DropNumber,Intense_thre,H_Int_thre,H_Area_thre,H_iftophat);
load('Mask.mat');
BgCorrectDir=fullfile(basedirectory,'BgCorrected');
mkdir(BgCorrectDir);
FFTDir=fullfile(basedirectory,'FFT');
mkdir(FFTDir);
%RMLCDir=fullfile(basedirectory,'RemoveLC');
%mkdir(RMLCDir);
TophatDir=fullfile(basedirectory,'Tophat');
mkdir(TophatDir);
MarkerDir=fullfile(basedirectory,'Marked');
mkdir(MarkerDir);
for m=1:sampleNum
    fprintf('processing sample %d %s\n',m,sampleSet{m});
    %% image crop
    Imwidth=5820;
    I=imread(fullfile(basedirectory,'Unroll',sampleSet{m}));
    orighalfwidth=size(I,2)/2;
    I=I(:,orighalfwidth-Imwidth/2:orighalfwidth+Imwidth/2-1);
    %% background correct
    G=fspecial('gaussian',500,100);
    Is=double(imfilter(I,G,'replicate'));
    I_Bgcorrect=double(I)./(Is/mean(Is(:)));
    meanI=mean(I_Bgcorrect(:));
    I_Bgcorrect=I_Bgcorrect.*(2350/meanI);
    imwrite(uint16(I_Bgcorrect),fullfile(BgCorrectDir,sampleSet{m}));
    %% image FFT
    temp_fft=FFTmask.*fftshift(fft2(I_Bgcorrect));
    I_fft=real(ifft2(ifftshift(temp_fft)));
    imwrite(uint16(I_fft),fullfile(FFTDir,sampleSet{m}));
    %% remove large connected area
    H_Int_thre1=4000;
    H_Area_thre1=1000;
    I_H=zeros(size(I_fft));
    I_H(I_fft>H_Int_thre1)=1;  
    LargeConn = bwareaopen(I_H,H_Area_thre1,6);
    I_rmlc=I_fft.*(~LargeConn);
    I_rmlc(I_rmlc==0)=mean(I_fft(:));
    
    se = strel('disk',10,8);
    LargeConn=imdilate(LargeConn,se);
%    imwrite(uint16(I_rmlc),fullfile(RMLCDir,sampleSet{m}));
    %% image tophat
    if iftophat
        tophat_rad=6;
        se = strel('disk',tophat_rad);
        I2= imtophat(I_rmlc,se);
        I2=I2.*(~LargeConn);
        imwrite(uint16(I2),fullfile(TophatDir,sampleSet{m}));
    else
        I2=I_rmlc;
    end
    %% find local maxima
    I4=I2;
    I4(I4<B_thre)=0;
    I4=imgaussfilt(I4,3);
    LM=imregionalmax(I4);
    LMCenter = cell2mat(struct2cell(regionprops(LM,'centroid'))');
    PosNumber=size(LMCenter,1);
    LMintense=zeros(PosNumber,1);
    for n=1:size(LMCenter,1)
        LMintense(n)=I2(LMCenter(n,2),LMCenter(n,1));
    end
    results.DropNumber(m)=PosNumber;
    results.Intense_thre(m)=B_thre;
    results.H_Int_thre(m)=H_Int_thre1;
    results.H_Area_thre(m)=H_Area_thre1;
    results.H_iftophat(m)=iftophat;
    %% add marker for visualization
    imvi=uint8(I_Bgcorrect/25);
    RGB = insertMarker(imvi,LMCenter,'*','color','blue','size',5);
    imwrite(RGB,fullfile(MarkerDir,[sampleSet{m},'.jpg']));
    
end

