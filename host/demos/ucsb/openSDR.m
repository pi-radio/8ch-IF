%% Add the folder containing +piradio to the MATLAB path.
addpath('../../');

%% Parameters
ip = "10.1.1.43";	% IP Address
isDebug = true;		% print debug messages

%% Create a Fully Digital SDR
sdr0 = piradio.sdr.FullyDigital('ip', ip, 'isDebug', isDebug);

% Configure the RFSoC
sdr0.fpga.configure('../../config/rfsoc.cfg');

% Read some parameters of the SDR in local variables
nadc = sdr0.fpga.nadc;  % num of A/D converters
ndac = sdr0.fpga.ndac;  % num of D/A converters
nch = sdr0.nch;         % num of channels