
% Add the folder containing +piradio to the MATLAB path.
addpath('../../');

% Parameters
ip = "10.1.1.43";	% IP Address
isDebug = true;		% print debug messages
ndac = 8;			% num of D/A converters
nadc = 8;			% num of A/D converters
fs = 983.04e6;		% sample frequency

% Create a Fully Digital SDR
sdr0 = piradio.sdr.FullyDigital('ip', ip, 'ndac', ndac, 'nadc', nadc, 'isDebug', isDebug);

% Configure the RFSoC
sdr0.fpga.configure('../../config/rfsoc.cfg');