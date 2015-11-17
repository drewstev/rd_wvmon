function [dspec,pos]=rd_spec2d(fd,nbyte)

dspec.n_freq=fread(fd,1,'ushort');
dspec.n_dir=fread(fd,1,'ushort');
dspec.isgood=fread(fd,1,'ushort');
dspec.val=reshape(fread(fd,...
    dspec.n_freq*dspec.n_dir,'uint32'),...
    dspec.n_dir,dspec.n_freq);


fseek(fd,nbyte-ftell(fd),'cof');
pos=ftell(fd);