function [strk,pos]=rd_strk(fd,nbyte)

strk.n_beams=fread(fd,1,'uchar');
strk.n_samp=fread(fd,1,'ushort');
strk.surf=reshape(fread(fd,strk.n_beams*strk.n_samp,...
    'long'),strk.n_samp,strk.n_beams);

fseek(fd,nbyte-ftell(fd),'cof');

pos=ftell(fd);
