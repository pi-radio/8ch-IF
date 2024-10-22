%% Add the folder containing +piradio to the MATLAB path.
addpath('../../');

% Parameters
ip = "192.168.137.52";	% IP Address
isDebug = false;		% print debug messages

% Create a Fully Digital SDR
sdr0 = piradio.sdr.FullyDigital('ip', ip, 'isDebug', isDebug, ...
    'figNum', 100, 'name', 'fr3-01');

% Configure the RFSoC. Use the file corresponding to the desired frequency
sdr0.fpga.configure('../../config/rfsoc.cfg');

% A channel ID of 10 refers to "all channels".
% Otherwise channels are numbered 1 through 8.

txChId = 8;
rxChId = 1;


 %% Simple TX and RX test with a single channel

clc;
nFFT = 1024;	% number of FFT points
txPower = 30000; % Do not exceed 30000
scMin = -199;
scMax = 200;
constellation = [1+1j 1-1j -1+1j -1-1j];

txtd = zeros(nFFT, sdr0.nch);       
txfd = zeros(nFFT, sdr0.nch);

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

%% Receive data

nskip = 1024*3; % skip ADC data
nbatch = 10;	% num of batches

freqs = ["6.5e9", "10.0e9", "14.0e9", "17.0e9"];
nFreq = size(freqs, 2);

niter = 1;
figure(1); clf;

% Set this to true when measuring the system response in cabled mode.
% Set it to false, when running the channel sounder over the air
measureSystemResponse = false;
systemResponses = ones(nFFT, nFreq);

for iter = 1:niter
    for iFreq = 1:nFreq

        % Configure the Pi-Radio board frequency and receive
        c = sprintf("http://192.168.137.51:5111/high_lo?freq=%s", freqs(iFreq));
        fprintf(c)

    
        rxtd_orig = sdr0.recv(nFFT, nskip, nbatch, 0);
        rxtd = rxtd_orig(:, 1, rxChId);

        rxfd = fft(rxtd);
        figure(1); 

        % 1. Plot the Frequency domain
        subplot(4, 3, (iFreq-1)*3 + 1);
        plot(fftshift(mag2db(abs(rxfd))));
        
        % 2A. Measure the True Peak location. Use this in Phase 3.
        corr_fd = txfd(:, txChId) .* conj(rxfd);
        corr_td = ifft(corr_fd);
        p = (mag2db(abs(corr_td)));
        grid on;
        [val, pos] = max(p);
        pos = nFFT - pos + 2;
        
        % Calculate the system response
        rxtd = zeros(nFFT, 1);
        for ibatch = 1:nbatch
            rxtd = rxtd + rxtd_orig(:, ibatch, rxChId);
        end

        rxtd = [rxtd(pos:nFFT); rxtd(1:pos-1)];
        if measureSystemResponse == true
            rxfd = fft(rxtd);
            G_fd = rxfd .* conj(txfd(:, txChId));
            t = fftshift(G_fd); % Human
            
            for sc = scMin:scMax
                if sc == 0
                    continue;
                end
                t(nFFT/2 + 1 + sc) = 1 / t(nFFT/2 + 1 + sc); % Calculate the inverse system response
            end

            systemResponses(:, iFreq) = fftshift(t); % In Machine order
            % This saves the inverse of the system response.
        end

        % 2B. Plot the PDP, after correcting for the system responses.
        % Also, use only the occupied subcarriers

        % Restore rxtd to be only the first symbol
        %rxtd = rxtd_orig(:, 1, rxChId);
        %rxtd = [rxtd(pos:nFFT); rxtd(1:pos-1)];

        subplot(4, 3, (iFreq-1)*3 + 2);
        rxfd = fft(rxtd);
        rxfd_h = fftshift(rxfd);    % Human
        rxfd_h = rxfd_h(nFFT/2 + 1 + scMin: nFFT/2 + 1 + scMax); % Human truncated
        rxfd_m = fftshift(rxfd_h); % Machine truncated
        
        txfd_h = fftshift(txfd(:, txChId)); % Human
        txfd_h = txfd_h(nFFT/2 + 1 + scMin : nFFT/2 + 1 + scMax); % Human truncated
        txfd_m = fftshift(txfd_h); % Machine truncated

        G_fd = systemResponses(:, iFreq);   % Machine
        G_fd = fftshift(G_fd);  % Human
        G_fd = G_fd(nFFT/2 + 1 + scMin : nFFT/2 + 1 + scMax); % Human truncated
        G_fd = fftshift(G_fd); % Machine truncated

        corr_fd = rxfd_m .* conj(txfd_m) .* G_fd;
        corr_td = ifft(corr_fd);
        p = fftshift(mag2db(abs(corr_td)));
        plot(p);        
        grid on;
        
        % 3. Plot the Constellation
        subplot(4, 3, (iFreq-1)*3 + 3);
        rxfd_equalized = zeros(nFFT, 1);
        
        for ibatch = 1:nbatch
            if mod(ibatch, 2) == 1
                % We have a Pilot
                h = zeros(nFFT, 1);
                rxtd = rxtd_orig(:, ibatch, rxChId);
                rxtd = [rxtd(pos:nFFT); rxtd(1:pos-1)];
                rxfd = fft(rxtd); % MATLAB Order
                for sc = 1:nFFT
                    if sc == 0
                        continue;
                    end
                    h(sc) = rxfd(sc) / txfd(sc, txChId);
                end

                h = fftshift(h); % We are in Human Order
                h = h(nFFT/2 + scMin + 1 : nFFT/2 + scMax + 1);
                
                % Smooth the channel estimates
                xi = linspace(scMin, scMax, scMax-scMin+1);
                h_smoothed = csaps(xi, h, 0.5, xi);
                
                if (false) % Should we plot the channel estimates and smoothed channel estimates?
                    figure(100);
                    % Plot un-smoothed channel estimates
                    subplot(2,1,1);
                    plot(abs(h)); hold on;
                    subplot(2,1,2);
                    plot(rad2deg(angle(h))); hold on;

                    % Plot smoothed channel estimates
                    subplot(2,1,1);
                    p = plot(abs(h_smoothed)); hold on;
                    p.LineWidth = 4;
                    subplot(2,1,2);
                    plot(rad2deg(angle(h_smoothed))); hold on;
                    figure(1);
                end

                h_new = zeros(nFFT, 1);
                h_new(nFFT/2 + scMin + 1 : nFFT/2 + scMax + 1) = h_smoothed;
                h = fftshift(h_new);              

            else
                s = 0; % Needed to calculate SNR
                n = 0; % Needed to calculate SNR

                % We have a data symbol
                rxtd = rxtd_orig(:, ibatch, rxChId);
                rxtd = [rxtd(pos:nFFT); rxtd(1:pos-1)];
                rxfd = fft(rxtd); % MATLAB order
                for sc = 1:nFFT
                    rxfd_equalized(sc) = rxfd(sc) / h(sc);
                end
                figure(1);
                subplot(4, 3, (iFreq-1)*3 + 3);
                plot(rxfd_equalized, '.');
                xlim([-1.5 1.5]);
                ylim([-1.5 1.5]);

                rxfd_equalized = fftshift(rxfd_equalized); % Human order
                for sc = scMin:scMax
                    if sc == 0
                        continue;
                    end

                    s = s + 2; % Each QPSK symbol has an energy of 2
                    xn = abs(real(rxfd_equalized(nFFT/2 + sc + 1))) - 1; % We subtract 1, since that's the ideal real component
                    yn = abs(imag(rxfd_equalized(nFFT/2 + sc + 1))) - 1; % We subtract 1, since that's the ideal imag component
                    n = n + xn^2 + yn^2;
                    snr = 10*log10(s/n);
                end % sc
                
            end % pilot or data

        end % batch

    end % freq

end % iter