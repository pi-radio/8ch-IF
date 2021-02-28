%
%   Make sure that all ADCs are synchronized. To set up the experiment,
%   connect the RFSoC to the breakout board (Avnet). Connect the P output
%   of DAC0 to the P input of ADC0. Connect the N output of DAC0 to the
%   N input of any other ADC i (such that 1 <= i <= 7). Now, we will test
%   whether ADC i is synchronizd with ADC 0. Prior to running this script,
%   make sure that you run open_sdr.
%

% 1. Set up the variables
nFFT = 1024;
nsamp = nFFT*2*nadc;
sdr0.set('nread', 0, 'nskip', 0);
sdr0.ctrlFlow();

% Subcarrier 100 corresponds to a tone at 96 MHz
% The DAC will transmit it at 1.096 GHz, since the IF freq is 1 GHz
scToUse = 100;

% 2. Initialize the TX waveform and send it to the RFSoC
txtd = zeros(nFFT, ndac);
for idac = 1:1 % Transmit from channel 1 (DAC 0)
	txfd = zeros(nFFT,1);
   	txfd(nFFT/2 + 1 + scToUse) = 1;
	txfd = fftshift(txfd);
	txtd(:,idac) = ifft(txfd);
end

txtd = txtd./abs(max(txtd))*32000;
sdr0.send(txtd);

% 3. Receive and Process
max_iter=10;
figure(1);
cal_factors_iters = zeros(max_iter,nadc);
scs = linspace(-nFFT/2, nFFT/2-1, nFFT);
for iter=1:max_iter
    rxtd = sdr0.recv(nsamp);
    
    if (1) % Plot the received spectrum for sanity checking
        for iadc=1:nadc
            td = rxtd(:,iadc);
            fd = fftshift(fft(td));
            subplot(2,4,iadc);
            plot(scs, mag2db(abs(fd)));
            grid on; grid minor;
            ylim([40 150]);
        end
    end

    % What is the factor at rxIndex = 1 (i.e., ADC0)
    td = rxtd(:,1);
    fd = fftshift(fft(td));
    fd_bin_ref = fd(nFFT/2 + 1 + scToUse);

    % What are the cal factors of every RX channel?
    for rxIndex = 1:8
        td = rxtd(:,rxIndex);
        fd = fftshift(fft(td));
        fd_bin = fd(nFFT/2 + 1 + scToUse);
        cal_factors_iters(iter,rxIndex) = fd_bin / fd_bin_ref;
    end
end

clc;
abs(cal_factors_iters)
rad2deg(angle(cal_factors_iters))

%
% Look at the output corresponding to channel i (ADC i-1). This should
% have stable amplitude and phase factors. Rerun the script with other
% channels in different tiles, to make sure they are all stable with
% respect to ADC 0. Another way of running the experiment is taking the
% signal from DAC 0, splitting it N ways, and feeding these signals into
% the ADCs. But you need to have the required splitters (with 50 ohm
% matched impedance) to do this.
%