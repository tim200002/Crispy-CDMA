set(0,'DefaultFigureWindowStyle','normal')

rootdir=pwd;

if findstr(rootdir,'\')
    subdir=strcat(rootdir,'\framework\enumerations'); addpath(subdir);
    subdir=strcat(rootdir,'\framework\testSounds'); addpath(subdir);
    subdir=strcat(rootdir,'\framework'); addpath(subdir);
    subdir=strcat(rootdir,'\BuildingBlocks'); addpath(subdir);
    subdir=strcat(rootdir,'\Skripts'); addpath(subdir);
    subdir=strcat(rootdir,'\TestImages'); addpath(subdir);

else %unix
    subdir=strcat(rootdir,'/framework/enumerations'); addpath(subdir);
    subdir=strcat(rootdir,'/framework/testSounds'); addpath(subdir);
    subdir=strcat(rootdir,'/framework'); addpath(subdir);
    subdir=strcat(rootdir,'/BuildingBlocks'); addpath(subdir);
     subdir=strcat(rootdir,'/Skripts'); addpath(subdir);
     subdir=strcat(rootdir,'/TestImages'); addpath(subdir);
end
