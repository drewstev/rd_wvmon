function [vel,pos]=rd_vel(fd,nbyte)

vel.n_beams=fread(fd,1,'uchar');
vel.n_bins=fread(fd,1,'uchar');
vel.n_samp=fread(fd,1,'ushort');
vel.samps=reshape(fread(fd,...
    vel.n_beams*vel.n_bins*vel.n_samp,'short'),...
    vel.n_samp,vel.n_beams*vel.n_bins);

fseek(fd,nbyte-ftell(fd),'cof');

pos=ftell(fd);