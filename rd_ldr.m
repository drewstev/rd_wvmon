function [ldr,pos]=rd_ldr(fd,nbyte)

fseek(fd,1,'cof');
ldr.RecTimeSeries=fread(fd,1,'uchar');
ldr.RecSpectra=fread(fd,1,'uchar');
ldr.RecDirSpec=fread(fd,1,'uchar');
ldr.EPB=fread(fd,1,'ushort');
ldr.TBE=fread(fd,1,'ushort')/100;
ldr.TBB=fread(fd,1,'ushort');
ldr.BinSize=fread(fd,1,'ushort');
ldr.Bin1Middle=fread(fd,1,'ushort');
ldr.NBins=fread(fd,1,'uchar');
ldr.NVelBins=fread(fd,1,'uchar');
fseek(fd,1,'cof');
ldr.NBeams=fread(fd,1,'uchar');
ldr.BeamConf=fread(fd,1,'uchar');
data_source=char(fread(fd,1,'uchar')); %#ok
switch upper(data_source)
    case 'V'
        ldr.WaveParamSource='velocity';
    case 'P'
        ldr.WaveParamSource='pressure';
    case 'S'
        ldr.WaveParamSource='surface track';
end
ldr.NFFTSmpls=fread(fd,1,'ushort');
ldr.NDir=fread(fd,1,'ushort');
ldr.NFreqBins=fread(fd,1,'ushort');
window_type=fread(fd,1,'ushort');
switch window_type
    case 1
        ldr.WindowType='bartlet';
    case 0
        ldr.WindowType='none';
end
ldr.UsePress4Depth=fread(fd,1,'uchar');
ldr.UseSTrack4Depth=fread(fd,1,'uchar');
ldr.STrackSpec=fread(fd,1,'uchar');
ldr.PressSpec=fread(fd,1,'uchar');

%read data screening params 
scrn.VelMin=fread(fd,1,'short');
scrn.VelMax=fread(fd,1,'short');
scrn.VelSTD=fread(fd,1,'uchar');
scrn.VelMaxChange=fread(fd,1,'ushort');
scrn.VelPctGd=fread(fd,1,'uchar');
scrn.SurfMin=fread(fd,1,'long');
scrn.SurfMax=fread(fd,1,'long');
scrn.SurfSTD=fread(fd,1,'uchar');
scrn.SurfMaxChng=fread(fd,1,'long');
scrn.SurfPctGd=fread(fd,1,'uchar');
scrn.TBEMaxDev=fread(fd,1,'ushort');
scrn.HMaxDev=fread(fd,1,'ushort');
scrn.PRMaxDev=fread(fd,1,'ushort');
scrn.NomDepth=fread(fd,1,'ulong');
fseek(fd,1,'cof');
scrn.DepthOffset=fread(fd,1,'long');
scrn.Currents=fread(fd,1,'uchar');
scrn.SmallWaveFreq=fread(fd,1,'ushort')/100;
scrn.SmallWaveThresh=fread(fd,1,'short');
scrn.Tilts=fread(fd,1,'uchar');
scrn.FixedPitch=fread(fd,1,'short');
scrn.FixedRoll=fread(fd,1,'short');
scrn.BottomSlopeX=fread(fd,1,'short');
scrn.BottomSlopeY=fread(fd,1,'short');
scrn.Down=fread(fd,1,'uchar');
fseek(fd,16,'cof');

%continue with leader
vel_trans=fread(fd,1,'uchar');
if vel_trans==0
    ldr.TransV2Surf='off';
else
    ldr.TransV2Surf='on';
end
fseek(fd,1,'cof');
ldr.SampleRate=fread(fd,1,'float');
ldr.FreqThresh=fread(fd,1,'float');
fseek(fd,1,'cof');
ldr.RemoveBias=fread(fd,1,'uchar');
ldr.DirCutoff=fread(fd,1,'ushort');
ldr.HeadingVariation=fread(fd,1,'short')/100;
ldr.hSoftRev=fread(fd,1,'uchar');
ldr.ClipPwrSpec=fread(fd,1,'uchar');
units=fread(fd,1,'uchar');
switch units
    case 1
        ldr.DirP2='power';
    case 0
        ldr.DirP2='height';
end
ldr.Horizontal=fread(fd,1,'uchar');
ldr.data_screening=scrn;

fseek(fd,nbyte-ftell(fd),'cof');

pos=ftell(fd);




