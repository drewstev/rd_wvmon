function meta=rd_wvmon_meta(varargin)
% read_wvmon_meta - read meta parameter file
%
% file should be a list of property/values pairs
% separated by an equal sign, tab delimited

if nargin>0
    fname=varargin{1};
    if ~exist(fname,'file')    
    error('File not found.')
    end
else
    [filename, pathname] = uigetfile( ...
        {'*.*', 'All Files (*.*)'},...
        'Select a File');
    if filename==0
        meta=[];
        return
    else
        fname=[pathname,filename];
    end
end

fid=fopen(fname);
names = textscan(fid,'%s%*[^\n]');
names=names{1};
frewind(fid);
data=textscan(fid,'%*s =%[^\n]');
data=data{1};
data2=cellfun(@(x)(textscan(x,'%s','delimiter','\t')),data);

fclose(fid);
meta=cell2struct(cat(1,data2{:}),names);
