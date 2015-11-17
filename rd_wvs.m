function [adcp,wvstr]=rd_wvs(varargin)
%RD_WVS - read data from RDI ADCP file with wave bursts
% 
% RD_WVS(FNAME) - reads the contents of the RDI ADCP file, 
%   FNAME, which contains both waves and currents data.  With
%   no input arguements, the user will be prompted to select the 
%   file interactively (UIGETFILE). The currents data and 
%   configuration information are returned in the structure, 
%   ADCP.  Raw wave burst data and wave setup paramters 
%   are returned in WVSTR.
% 
% SYNTAX
%   [ADCP,WVSTR]=RD_WVS; 
%
%   [ADCP,WVSTR]=RD_WVS('C:\data\foo.000'); 
%
% NOTES
%   1) Much of this code is based on RDRADCP, by Rich Pawlowicsz, which can  
%      be downloaded <a href="http://www.eos.ubc.ca/~rich/#RDADCP">here</a>       
%   2) Only tested on firware version 16.28.
%
% REFERENCES
%   Teledyne RD Instruments (2007). Workhorse commands and output data
%       format. P/N 957-6156-00 (November 2007), 190 p.
%   Teledyne RD Instruments (2009). Wavesmon v. 3.05 user's guide.
%       P/N 957-6232-00 (January 2009). 60 p.

% Andrew Stevens 4/17/2009
% astevens@usgs.gov


if nargin<1
    [file, path] = uigetfile('*.000', 'Pick a .000-file');
    if path==0
        adcp=[];
        wvstr=[];
        return
    end
    fname=fullfile(path,file);
    
else
    fname=varargin{1};
    if ~exist(fname,'file')
        error('File not found. Try again.')
    end
end

fprintf('Opening file %s\n',fname);
tic
fd=fopen(fname,'r','ieee-le');
fseek(fd,0,'eof');
numbytes=ftell(fd);
frewind(fd)

%currents data structure
cstr=struct('number',[],'rtc',[],'BIT',[],...
    'ssp',[],'depth',[],'heading',[],...
    'pitch',[],'roll',[],'salinity',[],...
    'temperature',[],'mpt',[],'heading_std',...
    [],'pitch_std',[],'roll_std',[],'adc',[],...
    'error_status_wd',[],'pressure',[],...
    'pressure_std',[],'east_vel',[],...
    'north_vel',[],'vert_vel',[],'error_vel',...
    [],'corr',[],'intens',[],'percent',[]);

%waves data structure
wvstr=struct('burst',[],'ping',[],...
    'press',[],'surf_track',[],...
    'vel',[],'m_depth',[],'m_ssp',[],...
    'm_temp',[],'m_heading',[],...
    'std_heading',[],'m_pitch',[],...
    'std_pitch',[],'m_roll',[],...
    'std_roll',[],'config',[]);

pos=0;
wvind=1;
cind=1;
h=waitbar(0);
while pos<numbytes
    msg=dec2hex(fread(fd,1,'uint16'),4);
    if isempty(msg)
        break
    end
    
    switch msg
        case '797F' % wave header
            [hdr,pos]=rd_wavehdr(fd); 
        case '0103' %wave fixed leader
            [wvb,pos]=rd_wvb(fd,hdr.nbyte,pos); 
            fprintf('Reading burst : %d\n',wvb.burstnum)
           
        case '0203' %wave ping
            [wvsp,pos]=rd_wvp(fd,wvb,hdr.nbyte,pos); 
            
            try
                wvstr(wvind).burst=wvb.burstnum;
                wvstr(wvind).ping(wvsp.ping)=...
                    wvsp.ping;
                wvstr(wvind).press(wvsp.ping)=...
                    wvsp.press;
                wvstr(wvind).surf_track(1:4,wvsp.ping)=...
                    wvsp.surf_track;
                wvstr(wvind).vel(1:(wvb.binsOut)*4,wvsp.ping)=...
                    wvsp.vel;
            catch %#ok
                break
            end
            
        case '0303' %waves last leader
            
            [ldd,pos]=rd_llead(fd,hdr.nbyte,pos); 
            
            
            if wvind==1;
                fn=fieldnames(ldd);
            end
            
            wvstr(wvind).config=wvb;
            for i=1:length(fn);
                wvstr(wvind).(fn{i})=...
                    ldd.(fn{i});
            end
                   
            %pre-allocate output array
            if wvind==1
                nbursts=round(numbytes/pos);
                wvstr=repmat(wvstr,nbursts,1);
            end
            
            wvind=wvind+1;  
           
            waitbar(pos/numbytes,h,{'Reading .000 file...'...
                ;sprintf('%d%% complete',...
                round((pos/numbytes)*100))});
            set(h,'name',sprintf('RDWVS %0.0f%% Complete',...
                (pos/numbytes)*100))
          
        case '7F7F' %currents header
            [chdr,pos]=rd_chdr(fd); 
            

        case '0000' %fixed header
            
            [cfg,pos]=rd_fixseg(fd,...
                chdr.dat_offsets(2)-chdr.dat_offsets(1),pos); 

            
        case '0080' %ensemble
            
            if chdr.ndat>=3
                nbyte=chdr.dat_offsets(3)-chdr.dat_offsets(2);
                [ens,pos]=rd_ens(fd,nbyte,pos);  

                if cind==1
                    fc=fieldnames(ens);
                end
                for i=1:length(fc);
                    cstr(cind).(fc{i})=...
                        ens.(fc{i});
                end
            
            else
                
                nbyte=chdr.nbyte-chdr.dat_offsets(2);
                fseek(fd,nbyte+pos-ftell(fd),'cof');
            end
                       
            
        case '0100' %velocities

            vels=fread(fd,[4 cfg.n_cells],'int16')'*.001;     % m/s
            cstr(cind).east_vel =vels(:,1);
            cstr(cind).north_vel=vels(:,2);
            cstr(cind).vert_vel =vels(:,3);
            cstr(cind).error_vel=vels(:,4);
          
            nbyte=chdr.dat_offsets(4)-chdr.dat_offsets(3);
            fseek(fd,nbyte+pos-ftell(fd),'cof');
            pos=ftell(fd);
            
        case '0200',  % Correlations
            cstr(cind).corr=fread(fd,[4 cfg.n_cells],'uint8')';
            
            nbyte=chdr.dat_offsets(5)-chdr.dat_offsets(4);
            fseek(fd,nbyte+pos-ftell(fd),'cof');
            pos=ftell(fd);
            
        case '0300',  % Echo Intensities
            cstr(cind).intens=fread(fd,[4 cfg.n_cells],'uint8')';
            
            nbyte=chdr.dat_offsets(6)-chdr.dat_offsets(5);
            fseek(fd,nbyte+pos-ftell(fd),'cof');
            pos=ftell(fd);
            
        case '0400',  % Percent good
            cstr(cind).percent=fread(fd,[4 cfg.n_cells],'uint8')';
            
            nbyte=chdr.nbyte-chdr.dat_offsets(6);
            fseek(fd,nbyte+pos-ftell(fd)+2,'cof');   
            pos=ftell(fd);
            
            %pre-allocate output array
            if cind==1
                ncbursts=round(numbytes/pos);
                cstr=repmat(cstr,ncbursts,1);
            end
            
            cind=cind+1;
            
        otherwise
            fprintf('MSG = %s\n',msg)
    end
    

    
end

close(h);
fclose(fd);

fprintf('Done reading %s\n',fname);
toc

cstr=cstr(1:cind-1);
wvstr=wvstr(1:wvind-1);

%repackage the currents data
dats=arrayfun(@(x)([x.rtc(1); x.rtc(2:end)-2000]),...
    cstr,'uni',0); %the 2000 is a hack, look into this if your 
                   %dates look bad

adcp.mtime=cellfun(@(x)(datenum(x(1),x(2),x(3),x(4),...
    x(5),x(6))),dats);
adcp.number=[cstr(:).number];
adcp.heading=[cstr(:).heading];
adcp.pitch=[cstr(:).pitch];
adcp.roll=[cstr(:).roll];
adcp.heading_std =[cstr(:).heading_std];
adcp.pitch_std=[cstr(:).pitch_std];
adcp.roll_std=[cstr(:).roll_std];
adcp.depth=[cstr(:).depth];
adcp.temperature=[cstr(:).temperature];
adcp.salinity=[cstr(:).salinity];
adcp.pressure=[cstr(:).pressure]./1000;
adcp.pressure_std=[cstr(:).pressure_std];
adcp.range=cfg.ranges;
adcp.east_vel=cell2mat(arrayfun(@(x)(x.east_vel),...
    cstr,'uni',0)');
adcp.north_vel=cell2mat(arrayfun(@(x)(x.north_vel),...
    cstr,'uni',0)');
adcp.vert_vel=cell2mat(arrayfun(@(x)(x.vert_vel),...
    cstr,'uni',0)');
adcp.error_vel=cell2mat(arrayfun(@(x)(x.error_vel),...
    cstr,'uni',0)');
adcp.corr=reshape(cell2mat(arrayfun(@(x)(x.corr),...
    cstr,'uni',0)),[numel(adcp.range),numel(adcp.mtime),...
    cfg.n_beams]);
adcp.intens=reshape(cell2mat(arrayfun(@(x)(x.intens),...
    cstr,'uni',0)),[numel(adcp.range),numel(adcp.mtime),...
    cfg.n_beams]);
adcp.config=cfg;

%subfunctions-------------------------------------------------------------
function [hdr,pos]=rd_wavehdr(fd)
% Reads a Header

pos=ftell(fd);
hdr.nbyte=fread(fd,1,'uint16');
fseek(fd,1,'cof'); %spare
hdr.nt=fread(fd,1,'uint8'); %data types
hdr.off=fread(fd,1,'uint16'); %offsets


%--------------------------------------------------------------------------
function [wvb,pos]=rd_wvb(fd,nbyte,pos)
%read wave fixed leader

wvb.firmware=fread(fd,1,'uint8')+fread(fd,1,'uint8')/100;
config=fread(fd,2,'uint8');
wvb.numbeams=getopt(bitand(config(2),16)==16,4,5);
wvb.beam_freq=getopt(bitand(config(1),7),75,150,300,600,1200,2400,38);
wvb.beam_pattern=getopt(bitand(config(1),8)==8,'concave','convex'); % 1=convex,0=concave
wvb.orientation=getopt(bitand(config(1),128)==128,'down','up');    % 1=up,0=down
wvb.beam_angl=getopt(bitand(config(2),3),15,20,30);
wvb.nbins=fread(fd,1,'uint8');
wvb.samp=fread(fd,1,'uint16');
wvb.binlen=fread(fd,1,'uint16');
wvb.tbp=fread(fd,1,'uint16');
wvb.tbb=fread(fd,1,'uint16');
wvb.distMidBin1=fread(fd,1,'uint16');
wvb.binsOut=fread(fd,1,'uint8');
fseek(fd,2,'cof'); %skip selected data 
wvb.dwsBitmap=fread(fd,16,'uint8');
wvb.dwsBins=find(strcmpi('1',cellstr(cell2mat(...
    cellstr(rot90(dec2bin(flipud(wvb.dwsBitmap),8),2))')')));
wvb.velBitmap=fread(fd,16,'uint8');
wvb.velBins=find(strcmpi('1',cellstr(cell2mat(...
    cellstr(rot90(dec2bin(flipud(wvb.velBitmap),8),2))')')));
wvb.startTime=fread(fd,8,'uint8');
wvb.burstnum=fread(fd,1,'uint32');
wvb.serialnum=fread(fd,8,'uint8');
wvb.temp=fread(fd,1,'uint16')/100;

fseek(fd,nbyte+pos-ftell(fd),'cof');

pos=ftell(fd);

%-------------------------------------------------------------------------
function [wvp,pos]=rd_wvp(fd,wvb,nbyte,pos)
% read wave ping statement

wvp.ping=fread(fd,1,'uint16');
wvp.etime=fread(fd,1,'uint32');
wvp.press=fread(fd,1,'uint32');
wvp.surf_track=fread(fd,4,'uint32')./1000;
wvp.vel=fread(fd,(wvb.binsOut)*4,'int16'); % numbins comes from wvb.binsOut
fseek(fd,4,'cof');

fseek(fd,nbyte+pos-ftell(fd),'cof');
pos=ftell(fd);

%--------------------------------------------------------------------------
function [ldd,pos]=rd_llead(fd,nbyte,pos)
%read last leader

ldd.m_depth=fread(fd,1,'uint16')./10; %m
ldd.m_ssp=fread(fd,1,'uint16');
ldd.m_temp=fread(fd,1,'uint16')/100;
ldd.m_heading=fread(fd,1,'uint16')/100;
ldd.std_heading=fread(fd,1,'uint16')/100;
ldd.m_pitch=fread(fd,1,'int16')/100;
ldd.std_pitch=fread(fd,1,'uint16')/100;
ldd.m_roll=fread(fd,1,'int16')/100;
ldd.std_roll=fread(fd,1,'uint16')/100;

fseek(fd,nbyte+pos-ftell(fd),'cof');

pos=ftell(fd);

%-------------------------------------------------------------------------
function [hdr,pos]=rd_chdr(fd)
% Reads a current Header
hdr.nbyte          =fread(fd,1,'int16');
fseek(fd,1,'cof');
hdr.ndat=fread(fd,1,'int8');
hdr.dat_offsets    =fread(fd,hdr.ndat,'int16');
pos=ftell(fd);


%-------------------------------------------------------------------------
function [cfg,pos]=rd_fixseg(fd,nbyte,pos)
% Reads the configuration data from the fixed leader

cfg.name='wh-adcp';
cfg.sourceprog='instrument';  % default - depending on what data blocks are
% around we can modify this later in rd_buffer.
cfg.prog_ver       =fread(fd,1,'uint8')+fread(fd,1,'uint8')/100;

if fix(cfg.prog_ver)==4 || fix(cfg.prog_ver)==5,
    cfg.name='bb-adcp';
elseif fix(cfg.prog_ver)==8 || fix(cfg.prog_ver)==9 || ...
        fix(cfg.prog_ver)==16,  cfg.name='wh-adcp';
elseif fix(cfg.prog_ver)==14 || fix(cfg.prog_ver)==23, % phase 1 and phase 2
    cfg.name='os-adcp';
else
    cfg.name='unrecognized firmware version'   ;
end;

config         =fread(fd,2,'uint8');  % Coded stuff
cfg.config          =[dec2base(config(2),2,8) '-' dec2base(config(1),2,8)];
cfg.beam_angle     =getopt(bitand(config(2),3),15,20,30);
cfg.numbeams       =getopt(bitand(config(2),16)==16,4,5);
cfg.beam_freq      =getopt(bitand(config(1),7),75,150,300,600,1200,2400,38);
cfg.beam_pattern   =getopt(bitand(config(1),8)==8,...
    'concave','convex'); % 1=convex,0=concave
cfg.orientation    =getopt(bitand(config(1),128)==128,...
    'down','up');    % 1=up,0=down
cfg.simflag        =getopt(fread(fd,1,'uint8'),'real',...
    'simulated'); % Flag for simulated data
fseek(fd,1,'cof');
cfg.n_beams        =fread(fd,1,'uint8');
cfg.n_cells        =fread(fd,1,'uint8');
cfg.pings_per_ensemble=fread(fd,1,'uint16');
cfg.cell_size      =fread(fd,1,'uint16')*.01;	 % meters
cfg.blank          =fread(fd,1,'uint16')*.01;	 % meters
cfg.prof_mode      =fread(fd,1,'uint8');         %
cfg.corr_threshold =fread(fd,1,'uint8');
cfg.n_codereps     =fread(fd,1,'uint8');
cfg.min_pgood      =fread(fd,1,'uint8');
cfg.evel_threshold =fread(fd,1,'uint16');
cfg.time_between_ping_groups=sum(fread(fd,3,'uint8').*[60 1 .01]');%seconds
coord_sys      =fread(fd,1,'uint8');  % Lots of bit-mapped info
cfg.coord=dec2base(coord_sys,2,8);
cfg.coord_sys      =getopt(bitand(bitshift(coord_sys,-3),3),'beam',...
    'instrument','ship','earth');
cfg.use_pitchroll  =getopt(bitand(coord_sys,4)==4,'no','yes');
cfg.use_3beam      =getopt(bitand(coord_sys,2)==2,'no','yes');
cfg.bin_mapping    =getopt(bitand(coord_sys,1)==1,'no','yes');
cfg.xducer_misalign=fread(fd,1,'int16')*.01;    % degrees
cfg.magnetic_var   =fread(fd,1,'int16')*.01;	% degrees
cfg.sensors_src    =dec2base(fread(fd,1,'uint8'),2,8);
cfg.sensors_avail  =dec2base(fread(fd,1,'uint8'),2,8);
cfg.bin1_dist      =fread(fd,1,'uint16')*.01;	% meters
cfg.xmit_pulse     =fread(fd,1,'uint16')*.01;	% meters
cfg.water_ref_cells=fread(fd,2,'uint8');
cfg.fls_target_threshold =fread(fd,1,'uint8');
fseek(fd,1,'cof');
cfg.xmit_lag       =fread(fd,1,'uint16')*.01; % meters
cfg.b_serialnum      =fread(fd,8,'uint8');
cfg.sysbandwidth  =fread(fd,2,'uint8');
cfg.syspower      =fread(fd,1,'uint8');
cfg.ranges=cfg.bin1_dist+(0:cfg.n_cells-1)'*cfg.cell_size;
if cfg.orientation==1, cfg.ranges=-cfg.ranges; end

fseek(fd,nbyte+pos-ftell(fd),'cof');


pos=ftell(fd);

%-------------------------------------------------------------------------
function [ens,pos]=rd_ens(fd,nbyte,pos)
% read ensemble currents data

ens.number         =fread(fd,1,'uint16');
ens.rtc            =fread(fd,7,'uint8');
ens.number         =ens.number+65536*fread(fd,1,'uint8');
ens.BIT            =fread(fd,1,'uint16');
ens.ssp            =fread(fd,1,'uint16');
ens.depth          =fread(fd,1,'uint16')*.1;   % meters
ens.heading        =fread(fd,1,'uint16')*.01;  % degrees
ens.pitch          =fread(fd,1,'int16')*.01;   % degrees
ens.roll           =fread(fd,1,'int16')*.01;   % degrees
ens.salinity       =fread(fd,1,'int16');       % PSU
ens.temperature    =fread(fd,1,'int16')*.01;   % Deg C
ens.mpt            =sum(fread(fd,3,'uint8').*[60 1 .01]'); % seconds
ens.heading_std    =fread(fd,1,'uint8');     % degrees
ens.pitch_std      =fread(fd,1,'int8')*.1;   % degrees
ens.roll_std       =fread(fd,1,'int8')*.1;   % degrees
ens.adc            =fread(fd,8,'uint8');

ens.error_status_wd=fread(fd,1,'uint32');
fseek(fd,2,'cof');   
ens.pressure       =fread(fd,1,'uint32');  
ens.pressure_std   =fread(fd,1,'uint32');
fseek(fd,1,'cof');

cent=fread(fd,1,'uint8');            
ens.rtc=fread(fd,7,'uint8');   
ens.rtc=ens.rtc+cent*100;

fseek(fd,nbyte+pos-ftell(fd),'cof');
pos=ftell(fd);

function opt=getopt(val,varargin)
% Returns one of a list (0=first in varargin, etc.)
if val+1>length(varargin),
	opt='unknown';
else
   opt=varargin{val+1};
end;

