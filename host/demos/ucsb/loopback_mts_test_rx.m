% The goal of this file is to make sure that the RX-side
% 1. Set up the variables
nFFT = 1024;
nsamp = nFFT*2*nadc;
sdr0.set('nread', 0, 'nskip', 0);
sdr0.ctrlFlow();
scToUse = 100; % Expecting a tone at (1.096 - 1.000) GHz - 96 MHz

% 2. Initialize the TX waveform
txtd = zeros(nFFT, ndac);
for idac = 1:1
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
cal_factors_iters = zeros(max_iter,8);
scs = linspace(-nFFT/2, nFFT/2-1, nFFT);
for iter=1:max_iter
    rxtd = sdr0.recv(nsamp);
    
    if (1)
        for iadc=1:nadc
            td = rxtd(:,iadc);
            fd = fftshift(fft(td));
            subplot(2,4,iadc);
            plot(scs, mag2db(abs(fd)));
            grid on; grid minor;
            ylim([40 150]);
        end
    end

    % What is the factor at rxIndex = 1
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

cal_factors = zeros(1,8);
for rxIndex = 1:8
    for iter=1:max_iter
        cal_factors(rxIndex) = cal_factors(rxIndex) + cal_factors_iters(iter,rxIndex);
    end
    cal_factors(rxIndex) = cal_factors(rxIndex) / max_iter; % Normalize Amplitudes
end

clc;
abs(cal_factors_iters)
rad2deg(angle(cal_factors_iters))
%abs(cal_factors)
%rad2deg(angle(cal_factors))
%node1.cal_factors = cal_factors;