%% Add the folder containing +piradio to the MATLAB path.
addpath('../../');

% Parameters
ip = "10.1.1.43";	% IP Address
isDebug = false;		% print debug messages

% Create a Fully Digital SDR
sdr0 = piradio.sdr.FullyDigital('ip', ip, 'isDebug', isDebug, ...
    'figNum', 100, 'name', 'v3-revB-0001');

% Configure the RFSoC. Use the file corresponding to the desired frequency
sdr0.fpga.configure('../../config/rfsoc_55ghz.cfg');

%% Configure the LO, LTC5594, and HMC630x chips

% First, configure the LO
sdr0.lo.configure('../../config/lmx_pdn.txt');
sdr0.lo.configure('../../config/lmx_hedy_lamarr_55ghz.txt');


% A channel ID of 10 refers to "all channels".
% Otherwise channels are numbered 1 through 8.

txChId = 8;
rxChId = 8;

% Power down all the LTC5594 chips
sdr0.ltc.configure(10, '../../config/ltc5594_pdn.txt');

% Power up the LTC5594 chips that are required. (10 for all)
sdr0.ltc.configure(txChId, '../../config/ltc5594_pup.txt');

% Power down all the HMC630x chips
sdr0.rffeTx.configure(10, '../../config/hmc6300_pdn.txt');
sdr0.rffeRx.configure(10, '../../config/hmc6301_pdn.txt');

% Power up the HMC6300 and HMC6301 as required
sdr0.rffeTx.configure(txChId, '../../config/hmc6300_registers.txt');
sdr0.rffeRx.configure(rxChId, '../../config/hmc6301_registers.txt');

% Turn off the self-observation.
sdr0.set_switches('off');

 %% Simple TX and RX test with a single channel

clc;
nFFT = 1024;	% number of FFT points
txPower = 3000; % Do not exceed 30000
scMin = 100;
scMax = 100;
constellation = [1+1j 1-1j -1+1j -1-1j];

txtd = zeros(nFFT, sdr0.nch);       
txfd = zeros(nFFT, ...
    sdr0.nch);

for scIndex = scMin:scMax
    if scIndex == 0
        continue;
    end
    txfd(nFFT/2 + 1 + scIndex, txChId) = constellation(randi(4));
end

txfd(:, txChId) = fftshift(txfd(:, txChId));
txtd(:, txChId) = ifft(txfd(:, txChId));
txtd(:, txChId) = txPower*txtd(:, txChId)./max(abs(txtd(:, txChId)));

        
% Send the data to the DACs
sdr0.send(txtd);

% Receive data
nskip = 1024*3;	% skip ADC data
nbatch = 100;	% num of batches

rxtd = sdr0.recv(nFFT, nskip, nbatch);

% Channel Sounder

rxtd = sdr0.recv(nFFT, nskip, nbatch);
rxtd = rxtd(:, 1, rxChId);
rxfd = fft(rxtd);
figure(1); clf;

for txChId = 8:8
    corr_fd = txfd(:, txChId) .* conj(rxfd);
    corr_td = ifft(corr_fd);
    
    p = mag2db(abs(corr_td));
    subplot(4,2,txChId)
    plot(p);
    %ylim([60 120]);
    grid on;
    [val, pos] = max(p)
end



