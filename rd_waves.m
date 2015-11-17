function [wvstr,varargout]=rd_waves(fname)
% workhorse behind rd_wvmon

fd=fopen(fname,'r','ieee-le');
fseek(fd,0,'eof');
numbytes=ftell(fd);
frewind(fd)

pos=0;
wvind=0;
h=waitbar(0);
while pos<numbytes
    msg=dec2hex(fread(fd,1,'uint16'),4);
    if isempty(msg)
        break
    end
    switch msg
        case '7A7F'
            [hdr,pos]=rd_hdr(fd,pos);
            ntype=1;
            
            
        case '0001' %fixed leader
            ntype=ntype+1;
            [ldr,pos]=rd_ldr(fd,hdr.offsets(ntype));
            
            
        case '0002' %variable leader
            ntype=ntype+1;
            wvind=wvind+1;
            [wvldr,pos]=rd_wvldr(fd,hdr.offsets(ntype));
            
            
            if wvind==1;
                
                %estimate n bursts in file
                n_bursts=floor(numbytes/(hdr.offsets(end)-hdr.offsets(2)));
                
                %calculate the frequencies
                cor=linspace(1/ldr.NFFTSmpls,...
                    (1/ldr.SampleRate)*2,ldr.NFreqBins);
                cen=cor+(diff(cor(1:2))/2);
                
                %set up output
                wvstr=struct('burst_num',zeros(1,n_bursts),...
                    'environment',repmat(wvldr,1,n_bursts),...
                    'mtime',zeros(1,n_bursts),...
                    'hsig',zeros(1,n_bursts),...
                    'tpeak',zeros(1,n_bursts),...
                    'dpeak',zeros(1,n_bursts),...
                    'davg',zeros(1,n_bursts),...
                    'freq',cen,...
                    'direction',zeros(ldr.NDir,n_bursts),...
                    'pspec',zeros(ldr.NFreqBins,n_bursts),...
                    'vspec',zeros(ldr.NFreqBins,n_bursts),...
                    'sspec',zeros(ldr.NFreqBins,n_bursts),...
                    'dspec',zeros(ldr.NDir,ldr.NFreqBins,n_bursts),...
                    'config',ldr);
                
                rdata=struct('start_time',zeros(1,n_bursts),...
                    'end_time',zeros(1,n_bursts),...
                    'vel',[],...
                    'pres',[],....
                    'surf',[]);
                rdata.vel=cell(1,n_bursts);
                rdata.pres=cell(1,n_bursts);
                rdata.surf=cell(1,n_bursts);
                
                
                
            end
            
            wvstr.burst_num(wvind)=wvind;
            wvstr.environment(wvind)=wvldr;
            wvstr.mtime(wvind)=wvstr.environment(wvind).start_time +...
                ((wvstr.environment(wvind).end_time - ...
                wvstr.environment(wvind).start_time)/2);
            
            set(h,'name',sprintf('RD_WVMON %0.0f%% Complete',...
                (wvind/n_bursts)*100));
            waitbar(wvind/n_bursts,h,{'Reading .000 file...';...
                sprintf('%d%% complete',...
                round((wvind/n_bursts)*100))});
            
        case '0003' %velocity time-series
            ntype=ntype+1;
            [vel,pos]=rd_vel(fd,hdr.offsets(ntype));
            rdata.vel{wvind}=vel.samps;
            rdata.start_time(wvind)=wvstr.environment(wvind).start_time;
            rdata.end_time(wvind)=wvstr.environment(wvind).end_time;
            
            
        case '0005' %surface track time-series
            ntype=ntype+1;
            [strk,pos]=rd_strk(fd,hdr.offsets(ntype));
            rdata.surf{wvind}=strk.surf;
            rdata.start_time(wvind)=wvstr.environment(wvind).start_time;
            rdata.end_time(wvind)=wvstr.environment(wvind).end_time;
            
        case '0006' %pressure time-series
            ntype=ntype+1;
            [pres,pos]=rd_pres(fd,hdr.offsets(ntype));
            rdata.pres{wvind}=pres.val;
            rdata.start_time(wvind)=wvstr.environment(wvind).start_time;
            rdata.end_time(wvind)=wvstr.environment(wvind).end_time;
            
        case '0007' %velocity spectra
            ntype=ntype+1;
            [vspec,pos]=rd_spec(fd,hdr.offsets(ntype));
            vspec.val(wvstr.freq>wvstr.environment(wvind).vspec_cutoff)=0;
            wvstr.vspec(:,wvind)=vspec.val;
            
        case '0008' %surface track spectra
            ntype=ntype+1;
            [sspec,pos]=rd_spec(fd,hdr.offsets(ntype));
            sspec.val(wvstr.freq>wvstr.environment(wvind).sspec_cutoff)=0;
            wvstr.sspec(:,wvind)=sspec.val;
            
        case '0009' %pressure spectra
            ntype=ntype+1;
            [pspec,pos]=rd_spec(fd,hdr.offsets(ntype));
            pspec.val(wvstr.freq>wvstr.environment(wvind).pspec_cutoff)=0;
            wvstr.pspec(:,wvind)=pspec.val;
            
        case '000A' %directional spectra
            ntype=ntype+1;
            [dspec,pos]=rd_spec2d(fd,hdr.offsets(ntype));
            
            % deal with the directions not starting at 0
            % first direction may vary if plaform moves
            first_bin=floor(wvldr.heading_offset);
            if first_bin<0;
                first_bin=first_bin+360;
            end
            d_bins=(first_bin:(360/ldr.NDir):...
                (360/ldr.NDir)*(ldr.NDir-1)+first_bin)';
            d_bins=(d_bins+(d_bins+(360/ldr.NDir)-1))/2;
            d_bins(d_bins>360)=d_bins(d_bins>360)-360;
            
            
            [direction,didx]=sort(d_bins);
            dsort=dspec.val(didx,:);
            dsort(:,wvstr.freq>wvstr.environment(wvind).dspec_cutoff)=0;
            wvstr.direction(:,wvind)=direction;
            wvstr.dspec(:,:,wvind)=dsort;
            
            
        case '000B' %wave parameters
            [params,pos]=rd_params(fd);
            wvstr.hsig(wvind)=params.hsig1;
            wvstr.tpeak(wvind)=params.tp1;
            wvstr.dpeak(wvind)=params.dp1;
            wvstr.davg(wvind)=params.dmean;
        otherwise
            fprintf('MSG = %s\n',msg)
    end
    
    
end

close(h);
fclose(fd);

if exist('wvstr','var')
    %trim the output to total number of bursts
    tfields={'burst_num'
        'environment'
        'mtime'
        'hsig'
        'tpeak'
        'dpeak'
        'davg'
        'direction'
        'pspec'
        'vspec'
        'sspec'
        'dspec'};
    for i=1:length(tfields);
        if ~strcmpi('dspec',tfields{i})
            wvstr.(tfields{i})=wvstr.(tfields{i})(:,1:wvind);
        else
            
            wvstr.(tfields{i})=wvstr.(tfields{i})(:,:,1:wvind);
        end
    end
    
    %deal with the variable directions
    dint=(360/ldr.NDir);
    di=(dint:dint:360)'-(dint/2);
    
    
    for i=1:length(wvind)
        for j=1:ldr.NFreqBins
            wvstr.dspec(:,j,i)=interp1(wvstr.direction(:,i),...
                wvstr.dspec(:,j,i),di,'linear','extrap');
        end
        
    end
    wvstr.direction=di;
    
    if nargout==2
        varargout{1}=rdata;
    end
    
else
    wvstr=[];
    
    if nargout==2
        varargout{1}=[];
        
    end
end



