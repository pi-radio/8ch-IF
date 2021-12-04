%% Set up the Hardware
addpath('../../');

% Parameters
isDebug = false;		% print debug messages

% Create a Fully Digital SDR (the DUT), and the SigGen SDR
sdr0 = piradio.sdr.FullyDigital('ip', "10.1.1.43", 'isDebug', isDebug, ...
    'figNum', 100, 'name', 'DUT');
%sdr1 = piradio.sdr.FullyDigital('ip', "10.1.1.44", 'isDebug', isDebug, ...
%    'figNum', 101, 'name', 'SigGen');

% Configure both RFSoC boards
sdr0.fpga.configure('../../config/rfsoc.cfg');
%sdr1.fpga.configure('../../config/rfsoc_siggen.cfg');

% Configure the LMX chip on the DUT
sdr0.lo.configure('../../config/lmx_registers_58ghz_for_v3.txt');

% Configure the HMC6300 TX chip (currently under test) on the DUT
%   The first parameter is the TX index:
%       Use {1,2,3,4,5,6,7,8} to configure the primary TX channels
%       Use {9} to configure the reference TX channel
%       Use {10} to configure all primary TX channels
%   The second parameter is the file name:
%       hmc6300_registers.txt   % (configure for external LO and power on)
%sdr0.rffeTx.configure(10, '../../config/hmc6300_registers.txt');

% Configure the HMC6301 Reference RX chip on the DUT
%   The first parameter is the RX index:
%       Use {1,2,3,4,5,6,7,8} to configure the primary RX channels
%       Use {9} to configure the reference RX channel
%       Use {10} to configure all primary RX channels
%   The second parameter is the file name:
%       hmc6301_registers.txt   % (configure for external LO and power on)
%       hmc6301_pdn.txt         % (power down the HMC6301)
sdr0.rffeRx.configure(9, '../../config/hmc6301_registers.txt');
sdr0.rffeRx.configure(10, '../../config/hmc6301_registers.txt');

% Configure the Switches
sdr0.set_switches("normal");

%% Generate the data on SigGen
nFFT = 1024;	% number of FFT points
txPower = 10000*1;
scMin = -400;
scMax = -400;
constellation = [1+1j 1-1j -1+1j -1-1j];
txtd = zeros(nFFT, sdr0.nch);
for ich = 1:8
    txfd = zeros(nFFT,1);
    for scIndex = scMin:scMax
        txfd(nFFT/2 + 1 + scIndex) = constellation(randi(4));
    end
    
    txfd = fftshift(txfd);
    txtd(:,ich) = ifft(txfd);
end

% Normalize the energy of the tx array and scale with txPower.
txtd = txPower*txtd./max(abs(txtd));

% Send the data from SigGen
sdr0.send(txtd);

%% Receive data
nskip = 1024*3;	% skip ADC data
nbatch = 200;	% num of batches

for tries=1:10
    rxtd = sdr0.recv(nFFT, nskip, nbatch);
end
