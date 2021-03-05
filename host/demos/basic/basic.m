%% DEMO: Basic Tx/Rx with the Pi-Radio 140 GHz, 8 channel SDR

%% Packages
% Add the folder containing +piradio to the MATLAB path.
addpath('../../');

%% Parameters
ip = "10.1.1.43";	% IP Address
isDebug = true;		% print debug messages
txPower = 32000;    % transmit

%% Create a Fully Digital SDR
sdr0 = piradio.sdr.FullyDigital('ip', ip, 'isDebug', isDebug);

% Configure the RFSoC
sdr0.fpga.configure('../../config/rfsoc.cfg');

%% Send data 
nFFT = 1024;	% number of FFT points
scToUse = 25;   % select a subcarrier to generate data for each DAC

% Initialize the tx data
txtd = zeros(nFFT, sdr0.nch);
for ich = 1:sdr0.nch
    txfd = zeros(nFFT,1);
    txfd(nFFT/2 + 1 + scToUse) = 1;
    txfd = fftshift(txfd);
    txtd(:,ich) = ifft(txfd);
end

% Normalize the energy of the tx array and scale with txPower.
txtd = txPower*txtd./max(abs(txtd));

% Plot the tx data
scs = linspace(-nFFT/2, nFFT/2-1, nFFT);

figure(1);
clf;
for ich = 1:sdr0.nch
    subplot(2,4,ich);
    plot(scs,(abs(fftshift(fft(txtd(:,ich))))));
    axis tight;
    grid on; grid minor;
    ylabel('Magnitude [Abs]', 'interpreter', 'latex', 'fontsize', 12);
    xlabel('Subcarrier Index', 'interpreter', 'latex', 'fontsize', 12);
    title(sprintf('Channel %d', ich), 'interpreter', 'latex', 'fontsize', 14);
end

% Send the data to the DACs
sdr0.send(txtd);

%% Receive data from the ADCs

% To read data from the ADCs we use the `recv` method of the FullyDigital
% sdr class. This method has 3 arguments. 
% * nsamp: number of continuous samples to read
% * nskip: number of samples to skip
% * nbatch: number of batches

nFFT = 1024;	% num of FFT points
nskip = 1024;	% skip ADC data for 1024 cc
nbatch = 32769;	% num of batches

rxtd = sdr0.recv(nFFT, nskip, nbatch);

scs = linspace(-nFFT/2, nFFT/2-1, nFFT);

for ibatch=nbatch-40:nbatch
    % Plot the frequency-domain signal
    f = figure(2);
    for ich = 1:sdr0.nch
        subplot(2,sdr0.nch/2,ich);
        plot(scs, 10*log10(abs(fftshift(fft(rxtd(:,ibatch,ich))))));
        axis tight; grid on; grid minor;
        ylabel('Magnitude [dB]', 'interpreter', 'latex', 'fontsize', 12);
        xlabel('Subcarrier Index', 'interpreter', 'latex', 'fontsize', 12);
        title(sprintf('Channel %d', ich), 'interpreter', 'latex', 'fontsize', 14);
        ylim([20 70]);
    end
    sgtitle(sprintf('Iteration %d', ibatch), 'interpreter', 'latex', 'fontsize', 14);
end

%% Close the TCP Connections and clear the Workspace variables
clear sdr0;
clear ich ibatch ip isDebug scToUse txPower;
clear nbatch nskip scs nFFT rxtd txfd txtd;