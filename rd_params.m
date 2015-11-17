function [params,pos]=rd_params(fd)

params.hsig1=fread(fd,1,'short')/1000;
params.tp1=fread(fd,1,'short')/10;
params.dp1=fread(fd,1,'short');
fseek(fd,2,'cof');
params.hsig2=fread(fd,1,'short')/1000;
params.tp2=fread(fd,1,'short')/10;
params.dp2=fread(fd,1,'short');
params.dmean=fread(fd,1,'short');

pos=ftell(fd);
