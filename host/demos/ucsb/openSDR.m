%% Add the folder containing +piradio to the MATLAB path.
addpath('../../');

%% Parameters
ip = "10.1.1.43";	% IP Address
isDebug = true;		% print debug messages

%% Create a Fully Digital SDR
sdr0 = piradio.sdr.FullyDigital('ip', ip, 'isDebug', isDebug, ...
    'figNum', 100, 'name', 'v3-revA-0001');

% Configure the RFSoC
sdr0.fpga.configure('../../config/rfsoc.cfg');

% Configure the LMX chip on the Pi-Radio v3 transceiver board.
sdr0.lo.configure('../../config/lmx_registers_58ghz_for_v3.txt');

% Configure the HMC6300 TX chips on the Pi-Radio v3 transceiver board.
%   The first parameter is the TX index:
%       Use {1,2,3,4,5,6,7,8} to configure the primary TX channels
%       Use {9} to configure the reference TX channel
%       Use {10} to configure all primary TX channels
%   The second parameter is the file name:
%       hmc6300_registers.txt   % (configure for external LO and power on)
%       hmc6300_pdn.txt         % (power down the HMC6300)
%sdr0.rffeTx.configure(1, '../../config/hmc6300_registers.txt');

% Configure the HMC6301 RX chips on the Pi-Radio v3 transceiver board.
%   The first parameter is the RX index:
%       Use {1,2,3,4,5,6,7,8} to configure the primary RX channels
%       Use {9} to configure the reference RX channel
%       Use {10} to configure all primary RX channels
%   The second parameter is the file name:
%       hmc6301_registers.txt   % (configure for external LO and power on)
%       hmc6301_pdn.txt         % (power down the HMC6301)
%sdr0.rffeRx.configure(10, '../../config/hmc6301_registers.txt');

% Read some parameters of the SDR in local variables
nadc = sdr0.fpga.nadc;  % num of A/D converters
ndac = sdr0.fpga.ndac;  % num of D/A converters
nch = sdr0.nch;         % num of channels