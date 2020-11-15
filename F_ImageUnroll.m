function outdir=F_ImageUnroll(indir)

d = dir(fullfile(indir,'*.tif'));  
%isub = d(:).isdir; %# returns logical vector  
sampleSet = {d.name}';  
sampleSet(ismember(sampleSet,{'.','..'})) = [];    
outdir=fullfile(indir,'Unroll');
mkdir(outdir);
%% stack to tile V2 (psedu-TDI )

for n=1:length(sampleSet)
sampleName=sampleSet{n};
C = strsplit(sampleName,'.');
sampleName_split= C{1};
IMdir=[indir,sampleName];
FrameNum=length(imfinfo(IMdir));
clear MR
for i =1:FrameNum
    MR(:,:,i)=imread(IMdir,i);
  %  MR(:,:,i)=(imread([directory,'\Image1_',num2str(i),'.tif']));    
end  

% 
clear TileImage;
tilesize=size(MR,2);
tileNum=size(MR,3);
ImWidth=8;
j=1;
Intime=tilesize/ImWidth;
TileImage_Int=zeros(2048,tileNum*ImWidth+tilesize-ImWidth,Intime);
for i=1:tileNum
 %   disp(i);
TileImage_Int(:,(j-1)*ImWidth+1:(j-1)*ImWidth+tilesize,rem(i-1,Intime)+1)=MR(:,:,tileNum-i+1);
j=j+1;
end
TileImage=uint16(mean(TileImage_Int,3));
imwrite(TileImage,[outdir,'\',sampleName_split,'-Tile.tiff']);

end