function [vspec,pos]=rd_spec(fd,nbyte)

vspec.n_freq=fread(fd,1,'ushort');
vspec.val=fread(fd,vspec.n_freq,'long');

fseek(fd,nbyte-ftell(fd),'cof');
pos=ftell(fd);