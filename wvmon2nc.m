
direc=['x:\e6410\projects\mcr_onr\moorings\',...
    'tripod_data\MCR13W1T\wh3796\WAVES\'];

%WVS files
files=dir([direc,'*.WVS']);
wvpaths=arrayfun(@(x)([direc,x.name]),files,'un',0);
wvs=rd_wvmon(wvpaths);

%metadata
meta=rd_wvmon_meta([direc,'wvs_meta.txt']);


fname=[direc,'MCRW1T_wvs.nc'];
ncid=netcdf.create(fname,'CLOBBER');

%write out global attributes
%start with user supplied metadata
varid = netcdf.getConstant('GLOBAL');
fields=fieldnames(meta);
for i=1:length(fields)
    netcdf.putAtt(ncid,varid,fields{i},meta.(fields{i}));

end

%wavesmon config
cfields=fieldnames(wvs.config);
for i=1:length(cfields)
    if ~isstruct(wvs.config.(cfields{i}));
        netcdf.putAtt(ncid,varid,cfields{i},wvs.config.(cfields{i}));
    else
        dfields=fieldnames(wvs.config.(cfields{i}));
        for j=1:length(dfields)
            netcdf.putAtt(ncid,varid,dfields{j},...
                wvs.config.(cfields{i}).(dfields{j}));
        end
    end
    
end

%define data dimensions
timedim=netcdf.defDim(ncid,'time',numel(wvs.mtime));
latdim=netcdf.defDim(ncid,'lat',1);
londim=netcdf.defDim(ncid,'lon',1);
freqdim=netcdf.defDim(ncid,'frequency',numel(wvs.freq));
dirdim=netcdf.defDim(ncid,'direction',numel(wvs.direction));

%grab sea surface height from environment struct
wvs.hght=arrayfun(@(x)(x.avg_depth),wvs.environment);

%fill bad values

%fill Value
variables={'hsig','wh_4061',[0 100];... %column 2 is valid range
    'dpeak','wdir_4062',[0 360];...
    'tpeak','wp_4063',[0 100];...
    'hght','hght_18', [0 1000];...
    'pspec','pspec',[0 inf];...
    'vspec','vspec',[0 inf];...
    'sspec','sspec',[0 inf];...
    'dspec','dspec',[0 inf]};
fun=@(x,y)(x<=y(1) | x>=y(2) | isnan(x)) ;
for i=1:size(variables,1);
    wvs.(variables{i,1})(fun(wvs.(variables{i,1}),...
        variables{i,3}))=1e35;
end



%variable definition
%time
varid=netcdf.defVar(ncid,'time','double',timedim);
netcdf.putAtt(ncid,varid,'units','True Julian Day');
netcdf.putAtt(ncid,varid,'epic_code',624);
netcdf.putAtt(ncid,varid,'datum',['Time (UTC) in True ',...
    'Julian Days: 2440000 = 0000 h on May 23, 1968']);
netcdf.putAtt(ncid,varid,'NOTE',['Decimal Julian day [days] = ',...
    'time [days] + ( time2 [msec] / 86400000 [msec/day]']);

%time2
varid=netcdf.defVar(ncid,'time2','double',timedim);
netcdf.putAtt(ncid,varid,'units','msec since 0:00 GMT');
netcdf.putAtt(ncid,varid,'epic_code',624);
netcdf.putAtt(ncid,varid,'datum',['Time (UTC) in True ',...
    'Julian Days: 2440000 = 0000 h on May 23, 1968']);
netcdf.putAtt(ncid,varid,'NOTE',['Decimal Julian day [days] = ',...
    'time [days] + ( time2 [msec] / 86400000 [msec/day]']);

%burst
varid=netcdf.defVar(ncid,'burst','double',timedim);
netcdf.putAtt(ncid,varid,'units','count');
netcdf.putAtt(ncid,varid,'long_name','Burst Number');
netcdf.putAtt(ncid,varid,'FillValue',1e35);

%lat
varid=netcdf.defVar(ncid,'lat','double',latdim);
netcdf.putAtt(ncid,varid,'units','degree_north');
netcdf.putAtt(ncid,varid,'epic_code',500);
netcdf.putAtt(ncid,varid,'long_name','latitude');
netcdf.putAtt(ncid,varid,'datume','WGS84');

%lon
varid=netcdf.defVar(ncid,'lon','double',londim);
netcdf.putAtt(ncid,varid,'units','degree_east');
netcdf.putAtt(ncid,varid,'epic_code',502);
netcdf.putAtt(ncid,varid,'long_name','longitude');
netcdf.putAtt(ncid,varid,'datume','WGS84');

%hsig
varid=netcdf.defVar(ncid,'wh_4061','double',timedim);
netcdf.putAtt(ncid,varid,'long_name','Significant Wave Height (m)');
netcdf.putAtt(ncid,varid,'units','m');
netcdf.putAtt(ncid,varid,'epic_code',4061);
netcdf.putAtt(ncid,varid,'FillValue',1e35);
netcdf.putAtt(ncid,varid,'minimum',min(wvs.hsig(wvs.hsig~=1e35)));
netcdf.putAtt(ncid,varid,'maximum',max(wvs.hsig(wvs.hsig~=1e35)));
netcdf.putAtt(ncid,varid,'valid_range',[0 100]);
netcdf.putAtt(ncid,varid,'sensor_type','RD Instruments ADCP');
netcdf.putAtt(ncid,varid,'initial_sensor_height',...
    str2double(meta.transducer_offset_from_bottom));

%direction
varid=netcdf.defVar(ncid,'wdir_4062','double',timedim);
netcdf.putAtt(ncid,varid,'long_name','Peak Wave Direction (degrees North)');
netcdf.putAtt(ncid,varid,'units','degrees');
netcdf.putAtt(ncid,varid,'epic_code',4062);
netcdf.putAtt(ncid,varid,'FillValue',1e35);
netcdf.putAtt(ncid,varid,'minimum',min(wvs.dpeak(wvs.dpeak~=1e35)));
netcdf.putAtt(ncid,varid,'maximum',max(wvs.dpeak(wvs.dpeak~=1e35)));
netcdf.putAtt(ncid,varid,'valid_range',[0 360]);
netcdf.putAtt(ncid,varid,'sensor_type','RD Instruments ADCP');
netcdf.putAtt(ncid,varid,'initial_sensor_height',...
    str2double(meta.transducer_offset_from_bottom));

%peak period
varid=netcdf.defVar(ncid,'wp_4063','double',timedim);
netcdf.putAtt(ncid,varid,'long_name','Peak Wave Period (s)');
netcdf.putAtt(ncid,varid,'units','s');
netcdf.putAtt(ncid,varid,'epic_code',4064);
netcdf.putAtt(ncid,varid,'FillValue',1e35);
netcdf.putAtt(ncid,varid,'minimum',min(wvs.tpeak(wvs.tpeak~=1e35)));
netcdf.putAtt(ncid,varid,'maximum',max(wvs.tpeak(wvs.tpeak~=1e35)));
netcdf.putAtt(ncid,varid,'valid_range',[0 100]);
netcdf.putAtt(ncid,varid,'sensor_type','RD Instruments ADCP');
netcdf.putAtt(ncid,varid,'initial_sensor_height',...
    str2double(meta.transducer_offset_from_bottom));

%height
varid=netcdf.defVar(ncid,'hght_18','double',timedim);
netcdf.putAtt(ncid,varid,'long_name','Height of the Sea Surface (m)');
netcdf.putAtt(ncid,varid,'units','m');
netcdf.putAtt(ncid,varid,'epic_code',18);
netcdf.putAtt(ncid,varid,'NOTE','height of sea surface relative to sensor');
netcdf.putAtt(ncid,varid,'FillValue',1e35);
netcdf.putAtt(ncid,varid,'minimum',min(wvs.hght(wvs.hght~=1e35)));
netcdf.putAtt(ncid,varid,'maximum',max(wvs.hght(wvs.hght~=1e35)));
netcdf.putAtt(ncid,varid,'valid_range',[0 1000]);
netcdf.putAtt(ncid,varid,'sensor_type','RD Instruments ADCP');
netcdf.putAtt(ncid,varid,'initial_sensor_height',...
    str2double(meta.transducer_offset_from_bottom));



%frequency 
varid=netcdf.defVar(ncid,'frequency','double',freqdim);
netcdf.putAtt(ncid,varid,'long_name','Frequency (Hz)');
netcdf.putAtt(ncid,varid,'units','Hz');
netcdf.putAtt(ncid,varid,'NOTE','frequency at the center of each frequency band');
netcdf.putAtt(ncid,varid,'minimum',min(wvs.freq));
netcdf.putAtt(ncid,varid,'maximum',max(wvs.freq));
netcdf.putAtt(ncid,varid,'sensor_type','RD Instruments ADCP');
netcdf.putAtt(ncid,varid,'initial_sensor_height',...
    str2double(meta.transducer_offset_from_bottom));

%direction
varid=netcdf.defVar(ncid,'direction','double',dirdim);
netcdf.putAtt(ncid,varid,'long_name','Direction (degrees)');
netcdf.putAtt(ncid,varid,'units','degrees');
netcdf.putAtt(ncid,varid,'NOTE','direction at center of each direction slice');
netcdf.putAtt(ncid,varid,'minimum',min(wvs.direction));
netcdf.putAtt(ncid,varid,'maximum',max(wvs.direction));
netcdf.putAtt(ncid,varid,'sensor_type','RD Instruments ADCP');
netcdf.putAtt(ncid,varid,'initial_sensor_height',...
    str2double(meta.transducer_offset_from_bottom));

%pspec
varid=netcdf.defVar(ncid,'pspec','double',[freqdim timedim]);
netcdf.putAtt(ncid,varid,'long_name',['Pressure-derived ',...
    'Non-directional Wave Height Spectrum (mm/sqrt(Hz))']);
netcdf.putAtt(ncid,varid,'units','mm/sqrt(Hz)');
netcdf.putAtt(ncid,varid,'NOTE','Use caution: all spectra are provisional.');
netcdf.putAtt(ncid,varid,'minimum',min(wvs.pspec(:)));
netcdf.putAtt(ncid,varid,'maximum',max(wvs.pspec(:)));
netcdf.putAtt(ncid,varid,'FillValue',1e35);
netcdf.putAtt(ncid,varid,'sensor_type','RD Instruments ADCP');
netcdf.putAtt(ncid,varid,'initial_sensor_height',...
    str2double(meta.transducer_offset_from_bottom));

%vspec
varid=netcdf.defVar(ncid,'vspec','double',[freqdim timedim]);
netcdf.putAtt(ncid,varid,'long_name',['Velocity-derived ',...
    'Non-directional Wave Height Spectrum (mm/sqrt(Hz))']);
netcdf.putAtt(ncid,varid,'units','mm/sqrt(Hz)');
netcdf.putAtt(ncid,varid,'NOTE','Use caution: all spectra are provisional.');
netcdf.putAtt(ncid,varid,'minimum',min(wvs.pspec(:)));
netcdf.putAtt(ncid,varid,'maximum',max(wvs.pspec(:)));
netcdf.putAtt(ncid,varid,'FillValue',1e35);
netcdf.putAtt(ncid,varid,'sensor_type','RD Instruments ADCP');
netcdf.putAtt(ncid,varid,'initial_sensor_height',...
    str2double(meta.transducer_offset_from_bottom));

%sspec
varid=netcdf.defVar(ncid,'sspec','double',[freqdim timedim]);
netcdf.putAtt(ncid,varid,'long_name',['Surface Track-derived ',...
    'Non-directional Wave Height Spectrum (mm/sqrt(Hz))']);
netcdf.putAtt(ncid,varid,'units','mm/sqrt(Hz)');
netcdf.putAtt(ncid,varid,'NOTE','Use caution: all spectra are provisional.');
netcdf.putAtt(ncid,varid,'minimum',min(wvs.pspec(:)));
netcdf.putAtt(ncid,varid,'maximum',max(wvs.pspec(:)));
netcdf.putAtt(ncid,varid,'FillValue',1e35);
netcdf.putAtt(ncid,varid,'sensor_type','RD Instruments ADCP');
netcdf.putAtt(ncid,varid,'initial_sensor_height',...
    str2double(meta.transducer_offset_from_bottom));

%dspec
varid=netcdf.defVar(ncid,'dspec','double',[dirdim freqdim timedim]);
netcdf.putAtt(ncid,varid,'long_name',['Directional Wave Energy ',...
    'Spectrum (mm^2/Hz/degree)']);
netcdf.putAtt(ncid,varid,'units','mm^2/Hz/degree');
netcdf.putAtt(ncid,varid,'NOTE','Use caution: all spectra are provisional.');
netcdf.putAtt(ncid,varid,'minimum',min(wvs.pspec(:)));
netcdf.putAtt(ncid,varid,'maximum',max(wvs.pspec(:)));
netcdf.putAtt(ncid,varid,'FillValue',1e35);
netcdf.putAtt(ncid,varid,'sensor_type','RD Instruments ADCP');
netcdf.putAtt(ncid,varid,'initial_sensor_height',...
    str2double(meta.transducer_offset_from_bottom));

netcdf.close(ncid);

%latitude, longitude (why are they variables and not global atts?)
ncwrite(fname,'lat',str2double(meta.latitude));
ncwrite(fname,'lon',str2double(meta.longitude));
ncwrite(fname,'frequency',wvs.freq);
ncwrite(fname,'direction',wvs.direction);

%julian time, ugggh
jd=datenum2julian(wvs.mtime);
time=fix(jd);
time2=(jd-time).*86400000;
ncwrite(fname,'time',time);
ncwrite(fname,'time2',time2);

%write the data
for i=1:size(variables,1);
    ncwrite(fname,variables{i,2},wvs.(variables{i,1}))
end


    
    
