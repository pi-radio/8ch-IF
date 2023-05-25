%% Add the folder containing +piradio to the MATLAB path.
addpath('../../');

% Parameters
ip = "192.168.1.101";	% IP Address
isDebug = false;		% print debug messages

% Create a Fully Digital SDR
sdr0 = piradio.sdr.FullyDigital('ip', ip, 'isDebug', isDebug, ...
    'figNum', 100, 'name', 'v3-revB-0001');

% Configure the RFSoC
sdr0.fpga.configure('../../config/rfsoc.cfg');

%% Configure the LO
sdr0.lo.configure('../../config/lmx_pdn.txt');
sdr0.lo.configure('../../config/lmx_hedy_lamarr_58ghz.txt');


%% Power Down the LTC
sdr0.ltc.configure(1, '../../config/ltc5594_pdn.txt');
sdr0.ltc.configure(2, '../../config/ltc5594_pdn.txt');
sdr0.ltc.configure(3, '../../config/ltc5594_pdn.txt');
sdr0.ltc.configure(4, '../../config/ltc5594_pdn.txt');
sdr0.ltc.configure(5, '../../config/ltc5594_pdn.txt');
sdr0.ltc.configure(6, '../../config/ltc5594_pdn.txt');
sdr0.ltc.configure(7, '../../config/ltc5594_pdn.txt');
sdr0.ltc.configure(8, '../../config/ltc5594_pdn.txt');

% Power up the LTC
chId = 8;
sdr0.ltc.configure(chId, '../../config/ltc5594_pup.txt');
%sdr0.ltc.configure(2, '../../config/ltc5594_pup.txt');
%sdr0.ltc.configure(3, '../../config/ltc5594_pup.txt');
%sdr0.ltc.configure(4, '../../config/ltc5594_pup.txt');
%sdr0.ltc.configure(5, '../../config/ltc5594_pup.txt');
%sdr0.ltc.configure(6, '../../config/ltc5594_pup.txt');
%sdr0.ltc.configure(7, '../../config/ltc5594_pup.txt');
%sdr0.ltc.configure(8, '../../config/ltc5594_pup.txt');

sdr0.rffeTx.configure(10, '../../config/hmc6300_pdn.txt');
sdr0.rffeRx.configure(10, '../../config/hmc6301_pdn.txt');
sdr0.rffeTx.configure(chId, '../../config/hmc6300_registers.txt');
%sdr0.rffeTx.configure(chId, '../../config/hmc6300_registers_evk.txt');

%% Configure the Switches
sdr0.obsCtrl.configure(0);

%% Generate the data
nFFT = 1024;	% number of FFT points
txPower = 1000*10;
scMin = 100;
scMax = 100;
constellation = [1+1j 1-1j -1+1j -1-1j];
txtd = zeros(nFFT, sdr0.nch);
for ich = 1:8
    txfd = zeros(nFFT,1);
    for scIndex = scMin:100:scMax
        if scIndex == 0
            continue;
        end
        txfd(nFFT/2 + 1 + scIndex) = constellation(randi(4));
    end
    
    txfd = fftshift(txfd);
    txtd(:,ich) = ifft(txfd);
end

% Normalize the energy of the tx array and scale with txPower.
txtd = txPower*txtd./max(abs(txtd));

% Send the data to the DACs
sdr0.send(txtd);

%% Receive data

% Configure the Switches
%sdr0.set_switches("normal");

nFFT = 1024;
nskip = 1024*3;	% skip ADC data
nbatch = 100;	% num of batches


for ind = 1:3
    rxtd = sdr0.recv(nFFT, nskip, nbatch);
end

