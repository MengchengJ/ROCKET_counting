basedirectory='';
outdir=F_ImageUnroll(basedirectory);
results=F_RotationCounting(basedirectory,800,1);
%% 

writetable(results,fullfile(basedirectory,'results.csv'));