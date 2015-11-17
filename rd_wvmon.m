function [wvstr,varargout] = rd_wvmon(varargin)
% RD_WVMON - read binary .wvs file
%
%   WVSTR = RD_WVMON - reads the binary output files from
%   Teledyne RDI's program, WAVESMON.  WVSTR is a structure
%   array containing wave paramaters as well as  non-directional
%   and directional spectra. Without inputs, the user will be
%   prompted to select one or more .WVS files.
%
%   WVSTR = RD_WVMON(fname) - reads the data in the specified file.
%   Multiple files may be passed to RD_WVMON using a cell array of
%   input file names. If mutliple files are specified, it is assumed
%   the configuration data and frequency and direction bins are the
%   same for all files.
%
%   WVSTR = RD_WVMON(fname,'bursts',[n1 n2]) - trims output to specified
%   bursts from data files.  In the case of multiple files, bursts are
%   re-numbered and n1 and n2 refer to final burst numbering.
%
%   OUTPUT STRUCTURE - Data from specified data files will be combined
%   into a single output structure with the following fields:
%       'burst_num'   - burst number
%       'environment' - structure array containing information in the
%                       variable leader with environmental conditions
%       'mtime'       - datenum (mid-burst)
%       'hsig'        - significant wave height (m)
%       'tpeak'       - peak wave period (s)
%       'dpeak'       - peak wave direction (deg)
%       'davg'        - mean wave direction (deg)
%       'freq'        - frequency bins for wave spectra (bin centers)
%       'direction'   - direction bins for directional spectra (bin
%                       centers, sorted)
%       'pspec'       - 1D spectra based on pressure sensor (mm/sqrt(Hz))
%       'vspec'       - 1D spectra based on velocity (mm/sqrt(Hz))
%       'sspec'       - 1D spectra based on surface track (mm/sqrt(Hz))
%       'dspec'       - directional spectra mm^2/Hz/cycle
%       'config'      - structure array containing parameters used to
%                       process the raw time-series
%
%   OPTIONAL OUTPUT
%       [...,RDATA] = RD_WVMON(fname) - Also provides raw time-series
%           from each of the ADCPs sensors (pressure, velocity, surface
%           track).  Each burst contains a cell array of samples.
%
%   NOTE ON DIRECTIONAL SPECTRA
%       Binning of directional spectra in the WVS files are based on the 
%       average heading of the burst, and thus can change over the 
%       deployment. RD_WVMON performs interpolation create common 
%       directional bins for all files being processed. Bins are sorted.
%
% SEE ALSO RD_WVS

% Andrew Stevens
% 11/09/2012
% last modified 10/5/2015

%this code is basically a wrapper for rd_waves and facilitates
%batch processing

%inputs and (some) error checking
narginchk(0,3);
nargoutchk(1,2);

p=inputParser;
func=@(x)(ischar(x) | iscell(x) | isempty(x));
addOptional(p,'filepath',[], func);
addOptional(p,'bursts',[],@(y)(validateattributes(y,{'numeric'},...
    {'nondecreasing','nonnegative','numel',2})));

p.parse(varargin{:});
opt=p.Results;


if isempty(opt.filepath)
    [filename, pathname] = uigetfile( ...
        {'*.wvs', 'WVS Files (*.WVS)'},...
        'Select a  file','multiselect','on');
    
    if iscell(opt.filepath);
        fname=cellfun(@(x)([pathname,x]),filename,'un',0)';
        fname=cellstr(cat(1,fname{:}));
    else
        if filename==0;
            wvstr=[];
            if nargout==2;
                varargout{1}=[];
            end
            return
        end
        
        fname=[pathname,filename];
    end
else
    if ~iscellstr(opt.filepath) && ~ischar(opt.filepath)
        error(['Input argument should be a ',...
            'string or cell array of strings.'])
    else
        fname=opt.filepath;
    end
end

if ~iscell(fname)
    fname={fname};
end

%make sure all the files exist
fidx=cellfun(@(x)(exist(x,'file')),fname);
if any(fidx==0)
    error('Specified file(s) not found.')
end

%do work son!
if nargout==1
    wvdata = cellfun(@(x)(rd_waves(x)),fname);
else
    [wvdata,rawdata] = cellfun(@(x)(rd_waves(x)),fname);
end

if length(fname)==1
    wvstr=wvdata;
    if exist('rawdata','var')
        rdata=rawdata;
        varargout{1}=rdata;
    end
else %smoosh data into a single structure
    %sort the files based on time
    [~,tidx]=sort(arrayfun(@(x)(x.mtime(1)),wvdata));
    
    %strip out the config, freq, and direction
    fields=fieldnames(wvdata);
    fields_out={'config';'freq';'direction'};
    
    data2=arrayfun(@(y)(cellfun(@(x)(y.(x)),...
        fields_out,'un',0)),wvdata,'un',0);
    
    wvdata=rmfield(wvdata,fields_out);
    fields2=fieldnames(wvdata);
    cwd=struct2cell(wvdata);
    cws=cwd(:,tidx);
    
    
    wvstr=cell2struct(cell(length(fields),1),fields);
    nfields=size(cws,1);
    cdata=cell(nfields,1);
    for i =1:nfields
        if size(cws{i},3) ==1
            cdata{i}=cell2mat(cws(i,:));
        else
            cdata{i}=cat(3,cws{i,:}); %dspec
        end
        wvstr.(fields2{i})=cdata{i};
    end
    
    %assumes config, freq and direc are same for all files selected
    for i=1:length(fields_out);
        wvstr.(fields_out{i})=data2{1}{i};
        
    end
    
    %re-order burst num
    wvstr.burst_num=1:numel(wvstr.mtime);
    
    
    %deal with the raw time-series (if requested)
    if nargout==2
        rfields=fieldnames(rawdata);
        raw=struct2cell(rawdata);
        rdata=cell2struct(cell(length(rfields),1),rfields);
        for i =1:length(rfields);
            if iscell(raw{i,1})
                rdata.(rfields{i})=cat(2,raw{i,:});
            else
                rdata.(rfields{i})=cell2mat(raw(i,:));
            end
        end
        varargout{1}=rdata;
    end
    
    
end

%limit the burst numbers if requested
%trim the output to total number of bursts
if ~isempty(opt.bursts)
    if opt.bursts(1)>wvstr.burst_num(end)
        disp('Specified bursts not valid. No burst trimming performed')
        return
    end
    if opt.bursts(2)>wvstr.burst_num(end);
        opt.bursts(2)=wvstr.burst_num(end);
    end
    
    tfields={'burst_num'
        'environment'
        'mtime'
        'hsig'
        'tpeak'
        'dpeak'
        'davg'
        'pspec'
        'vspec'
        'sspec'
        'dspec'};
    for i=1:length(tfields);
        if ~strcmpi('dspec',tfields{i})
            wvstr.(tfields{i})= ...
                wvstr.(tfields{i})(:,opt.bursts(1):opt.bursts(2));
        else
            
            wvstr.(tfields{i})= ...
                wvstr.(tfields{i})(:,:,opt.bursts(1):opt.bursts(2));
        end
    end
    
    %raw data
     if nargout==2
         rfields=fieldnames(rdata);
         for i=1:length(rfields)
             rdata.(rfields{i})=...
                 rdata.(rfields{i})(opt.bursts(1):opt.bursts(2));
         end
         varargout{1}=rdata;
     end
         
         
    
end









