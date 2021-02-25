addpath('../../');

% Parameters
ip = "10.1.1.43";	% IP Address 
mem = "bram";		% Memory type
isDebug = true;		% print debug messages
ndac = 8;			% num of D/A converters
nadc = 8;			% num of A/D converters

fs = 983.04e6;		% sample frequency
                    % (pre-interpolation on the TX)
                    % (post-decimation on the RX)
                    % The actual DACs and ADCs are clocked at 3932.16 MHz

% Create a Fully Digital SDR
sdr0 = piradio.sdr.FullyDigital('ip', ip, 'mem', mem, ...
	'ndac', ndac, 'nadc', nadc, 'isDebug', isDebug);

% Set the number of DACs and ADCs of the RFSoC
sdr0.fpga.set('ndac', ndac, 'nadc', nadc);

% Configure the RFSoC
sdr0.fpga.configure('../../config/rfsoc.cfg');

