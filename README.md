# rd_wvmon
Read binary output files from RD Instruments Wavesmon (.WVS)
WVSTR = rd_wvmon - reads the binary output files from
    Teledyne RDI's program, WAVESMON.  WVSTR is a structure
    array containing wave paramaters as well as  non-directional
    and directional spectra. Without inputs, the user will be
    prompted to select one or more .WVS files.
 
    WVSTR = rd_wvmon(fname) - reads the data in the specified file.
    Multiple files may be passed to rd_wvmon using a cell array of
    input file names. If mutliple files are specified, it is assumed
    the configuration data and frequency and direction bins are the
    same for all files.
 
    WVSTR = rd_wvmon(fname,'bursts',[n1 n2]) - trims output to specified
    bursts from data files.  In the case of multiple files, bursts are
    re-numbered and n1 and n2 refer to final burst numbering.
 
    OUTPUT STRUCTURE - Data from specified data files will be combined
    into a single output structure with the following fields:
        'burst_num'   - burst number
        'environment' - structure array containing information in the
                        variable leader with environmental conditions
        'mtime'       - datenum (mid-burst)
        'hsig'        - significant wave height (m)
        'tpeak'       - peak wave period (s)
        'dpeak'       - peak wave direction (deg)
        'davg'        - mean wave direction (deg)
        'freq'        - frequency bins for wave spectra (bin centers)
        'direction'   - direction bins for directional spectra (bin
                        centers, sorted)
        'pspec'       - 1D spectra based on pressure sensor (mm/sqrt(Hz))
        'vspec'       - 1D spectra based on velocity (mm/sqrt(Hz))
        'sspec'       - 1D spectra based on surface track (mm/sqrt(Hz))
        'dspec'       - directional spectra mm^2/Hz/cycle
        'config'      - structure array containing parameters used to
                        process the raw time-series
 
    OPTIONAL OUTPUT
        [...,RDATA] = rd_wvmon(fname) - Also provides raw time-series
            from each of the ADCPs sensors (pressure, velocity, surface
            track).  Each burst contains a cell array of samples.
 
    NOTE ON DIRECTIONAL SPECTRA
        Binning of directional spectra in the WVS files are based on the 
        average heading of the burst, and thus can change over the 
        deployment. rd_wvmon performs interpolation create common 
        directional bins for all files being processed. Bins are sorted.
 
  SEE ALSO rd_wvs
