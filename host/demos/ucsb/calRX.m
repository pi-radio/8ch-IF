%  Calibrate the RX Array (UCSB 140 GHz, 8 channel IF). Adjust the RX-side
%  IF and LO frequencies in such a way so as to get a deterministic tone at
%  the RX. In this experiment, we expect the baseband signal to come in at
%  96 MHz (i.e., subcarrier index 100).

% 1. Initialize experiment parameters
nFFT = 1024;
scToUse = 100;

% 2. Receive and Process
nskip = 1024;	% skip 1024 samples after every batch
nbatch = 40;	% num of batches to read

% Read data from the ADCs. Note that the returned data should be a
% tensor with dimensions: nsamp x ntimes x nadc
rxtd = sdr0.recv(nFFT, nskip, nbatch);

scs = linspace(-nFFT/2, nFFT/2-1, nFFT);
calFactorsIters = zeros(nbatch, nadc);

for ibatch = 1:nbatch
    % What is the factor at rxIndex = 1 (i.e., ADC0)
    td = rxtd(:,ibatch,1);
    fd = fftshift(fft(td));
    fd_bin_ref = fd(nFFT/2 + 1 + scToUse);
    
    for iadc = 1:sdr0.nch
        if (true)  % Do we want to lot things out?
            figure(2);
            subplot(2,nadc/2,iadc);
            plot(scs, 10*log10(abs(fftshift(fft(rxtd(:,ibatch,iadc))))));
            axis tight; grid on; grid minor;
            ylabel('Magnitude [dB]', 'interpreter', 'latex', 'fontsize', 12);
            xlabel('Subcarrier Index', 'interpreter', 'latex', 'fontsize', 12);
            title(sprintf('ADC %d', iadc), 'interpreter', 'latex', 'fontsize', 14);
            ylim([20 70]);
        end
        
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

%% Clear the Workspace variables
clear ans calFactorsIters fd fd_bin fd_bin_ref iadc ibatch nbatch;
clear nFFT nskip rxtd scs scToUse tx txfd td txtd;