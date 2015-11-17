function [pres,pos]=rd_pres(fd,nbyte)

pres.n_samp=fread(fd,1,'ushort');
pres.val=fread(fd,pres.n_samp,'ushort');

fseek(fd,nbyte-ftell(fd),'cof');

pos=ftell(fd);