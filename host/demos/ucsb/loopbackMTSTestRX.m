%
%   Make sure that all ADCs are synchronized. To set up the experiment,
%   connect the RFSoC to the breakout board (Avnet). Connect the P output
%   of DAC0 to the P input of ADC0. Connect the N output of DAC0 to the
%   N input of any other ADC i (such that 1 <= i <= 7). Now, we will test
%   whether ADC i is synchronizd with ADC 0. Prior to running this script,
%   make sure that you run open_sdr.
%

% 1. Initialize the TX waveform and send it to the RFSoC
nFFT = 1024;	% number of samples to generate for each DAC
scToUse = 100;

txtd = zeros(nFFT, ndac);
txfd = zeros(nFFT,1);
txfd(nFFT/2 + 1 + scToUse) = 1;
txfd = fftshift(txfd);
txtd(:,1) = ifft(txfd);
txtd = txtd./abs(max(txtd))*32000;

% Plot the TX data
scs = linspace(-nFFT/2, nFFT/2-1, nFFT);

figure(1);
clf;
for idac = 1:ndac
    subplot(2,4,idac);
    plot(scs,(abs(fftshift(fft(txtd(:,idac))))));
    axis tight;
    grid on; grid minor;
    ylabel('Magnitude [Abs]', 'interpreter', 'latex', 'fontsize', 12);
    xlabel('Subcarrier Index', 'interpreter', 'latex', 'fontsize', 12);
    title(sprintf('DAC %d', idac), 'interpreter', 'latex', 'fontsize', 14);
end

% Send the data to the DACs
sdr0.send(txtd);

% 2. Receive and Process
nread = nFFT/2; % read ADC data for 512 cc
nskip = 1024;	% skip ADC data for 1024 cc
nbatch = 10;	% num of batches to read

% Then, read data from the ADCs. Note that the returned data should be a
% tensor with dimensions: nsamp x ntimes x nadc
rxtd = sdr0.recv(nFFT, nskip, nbatch);

scs = linspace(-nFFT/2, nFFT/2-1, nFFT);
calFactorsIters = zeros(nbatch,nadc);
for ibatch=1:nbatch
    % Plot the frequency-domain signal
    figure(2);
    
    % What is the factor at rxIndex = 1 (i.e., ADC0)
    td = rxtd(:,ibatch,1);
    fd = fftshift(fft(td));
    fd_bin_ref = fd(nFFT/2 + 1 + scToUse);
    
    for iadc = 1:nadc
        subplot(2,nadc/2,iadc);
        plot(scs, 10*log10(abs(fftshift(fft(rxtd(:,ibatch,iadc))))));
        axis tight; grid on; grid minor;
        ylabel('Magnitude [dB]', 'interpreter', 'latex', 'fontsize', 12);
        xlabel('Subcarrier Index', 'interpreter', 'latex', 'fontsize', 12);
        title(sprintf('ADC %d', iadc), 'interpreter', 'latex', 'fontsize', 14);
        ylim([20 70]);
        
        td = rxtd(:,ibatch,iadc);
        fd = fftshift(fft(td));
        fd_bin = fd(nFFT/2 + 1 + scToUse);
        calFactorsIters(ibatch,iadc) = fd_bin / fd_bin_ref;
    end
    sgtitle(sprintf('Iteration %d', ibatch), 'interpreter', 'latex', 'fontsize', 14);
end

clc;
abs(calFactorsIters)
rad2deg(angle(calFactorsIters))

%
% Look at the output corresponding to channel i (ADC i-1). This should
% have stable amplitude and phase factors. Rerun the script with other
% channels in different tiles, to make sure they are all stable with
% respect to ADC 0. Another way of running the experiment is taking the
% signal from DAC 0, splitting it N ways, and feeding these signals into
% the ADCs. But you need to have the required splitters (with 50 ohm
% matched impedance) to do this.
%