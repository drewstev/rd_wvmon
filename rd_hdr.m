function [hdr,pos]=rd_hdr(fd,pos)

fseek(fd,2,'cof'); %spare1
hdr.size=fread(fd,1,'ulong');
fseek(fd,3,'cof'); %spares2-4
hdr.n_types=fread(fd,1,'uint8');
hdr.offsets=fread(fd,1*hdr.n_types,'ulong')+pos;
pos=ftell(fd);
