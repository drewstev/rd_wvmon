function [wvldr,pos]=rd_wvldr(fd,nbyte)

start_time=fread(fd,8,'uint8');
cen=str2double(sprintf('%2.2d00',start_time(1)));
wvldr.start_time=datenum(cen+start_time(2),start_time(3),...
    start_time(4),start_time(5),start_time(6),...
    start_time(7)+start_time(8)/100);

end_time=fread(fd,8,'uint8');
cen=str2double(sprintf('%2.2d00',end_time(1)));
wvldr.end_time=datenum(cen+end_time(2),end_time(3),...
    end_time(4),end_time(5),end_time(6),...
    end_time(7)+end_time(8)/100);

wvldr.freq_low=fread(fd,1,'ushort')/1000;
wvldr.avg_depth=fread(fd,1,'ulong')/1000;
wvldr.instrument_height=fread(fd,1,'ulong')/100;
wvldr.bin_map=fread(fd,128,'uint8'); %come back to this
fread(fd,1,'uchar');
wvldr.press_pcgood=fread(fd,1,'uchar');
wvldr.avg_sos=fread(fd,1,'ushort');
wvldr.avg_temp=fread(fd,1,'ushort');
wvldr.surf_pcgood=fread(fd,1,'uchar');
wvldr.vel_pcgood=fread(fd,1,'uchar');
wvldr.heading_offset=fread(fd,1,'short');
wvldr.surf_std=fread(fd,1,'ulong')*100;
wvldr.vel_std=fread(fd,1,'ulong')*100;
wvldr.press_std=fread(fd,1,'ulong')*100;
wvldr.dspec_cutoff=fread(fd,1,'ulong')/1000;
wvldr.vspec_cutoff=fread(fd,1,'ulong')/1000;
wvldr.pspec_cutoff=fread(fd,1,'ulong')/1000;
wvldr.sspec_cutoff=fread(fd,1,'ulong')/1000;
wvldr.x_current=fread(fd,1,'short')/1000;
wvldr.y_current=fread(fd,1,'short')/1000;
wvldr.avg_pitch=fread(fd,1,'short')/100;
wvldr.avg_roll=fread(fd,1,'short')/100;
wvldr.avg_heading=fread(fd,1,'short')/100;
wvldr.n_samp=fread(fd,1,'short');
wvldr.hs_limit_ratio=fread(fd,1,'short');


fseek(fd,nbyte-ftell(fd),'cof');

pos=ftell(fd);