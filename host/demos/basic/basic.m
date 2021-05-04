%% DEMO: Basic Tx/Rx with the Pi-Radio 140 GHz, 8 channel SDR

% Packages
% Add the folder containing +piradio to the MATLAB path.
addpath('../../');

% Parameters
ip = "10.1.1.43";	% IP Address
isDebug = true;		% print debug messages

% Create a Fully Digital SDR
sdr0 = piradio.sdr.FullyDigital('ip', ip, 'isDebug', isDebug);

% Configure the RFSoC
sdr0.fpga.configure('../../config/rfsoc.cfg');

%% Send data 
nFFT = 1024;	% number of FFT points
txPower = 10000*1;    % transmit
scMin = 417;
scMax = 417;
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

% Receive data from the ADCs

% To read data from the ADCs we use the `recv` method of the FullyDigital
% sdr class. This method has 3 arguments. 
% * nsamp: number of continuous samples to read
% * nskip: number of samples to skip
% * nbatch: number of batches

nFFT = 1024;	% num of FFT points
nskip = 1024*3;	% skip ADC data for 1024 cc
nbatch = 200;	% num of batches

rxtd = sdr0.recv(nFFT, nskip, nbatch);

scs = linspace(-nFFT/2, nFFT/2-1, nFFT);

for ibatch=1:2
    % Plot the frequency-domain signal
    f = figure(2);
    for ich = 1:sdr0.nch
        subplot(4,sdr0.nch/2,ich);
        plot(scs, mag2db(abs(fftshift(fft(rxtd(:,ibatch,ich))))));
        axis tight; grid on; grid minor;
        ylabel('Magnitude [dB]', 'interpreter', 'latex', 'fontsize', 12);
        xlabel('Subcarrier Index', 'interpreter', 'latex', 'fontsize', 12);
        title(sprintf('Channel %d', ich), 'interpreter', 'latex', 'fontsize', 14);
        ylim([40 140]);
        
        subplot(4,sdr0.nch/2,ich+8);
        plot(real(rxtd(:,ibatch,ich)), 'r'); hold on;
        plot(imag(rxtd(:,ibatch,ich)), 'b'); hold off;
        ylim([-30000 30000]);
    end
    sgtitle(sprintf('Iteration %d', ibatch), 'interpreter', 'latex', 'fontsize', 14);
end

peaks=zeros(1,nbatch);
phvec=zeros(1,nbatch);

for ibatch=1:nbatch
    td = rxtd(:, ibatch,5);
    fd = fftshift(fft(td));
    peaks(ibatch) = mag2db(abs(fd(nFFT/2 + 1 + scMin)));
    phvec(ibatch) = angle(fd(nFFT/2 + 1 + scMin));
end

figure(3);
subplot(2,1,1);
plot(peaks); grid on;
mean(peaks)
sqrt(var(peaks))
subplot(2,1,2);
plot(phvec);



%% Close the TCP Connections and clear the Workspace variables
clear sdr0;
clear ich ibatch ip isDebug scToUse txPower;
clear nbatch nskip scs nFFT rxtd txfd txtd;
clear all;
