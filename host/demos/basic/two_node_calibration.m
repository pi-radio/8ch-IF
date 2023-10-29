%% TWO-NODE CALIBRATIONS

% In this example, sdr0 is the node under calibration.
% The "helper" is sdr1.

% To perform calibration, first configure the hardware to operate
% at 58 GHz. The self-cal requires this frequency.

addpath('../../');
addpath('../../helper');
isDebug = false;		% print debug messages

ip = "10.1.1.43";	% IP Address
sdr0 = piradio.sdr.FullyDigital('ip', ip, 'isDebug', isDebug, ...
    'figNum', 100, 'name', 'lamarr-rev3.1-0001');

ip = "10.1.1.44";	% IP Address
sdr1 = piradio.sdr.FullyDigital('ip', ip, 'isDebug', isDebug, ...
    'figNum', 101, 'name', 'lamarr-rev3.1-0002');

sdr0.fpga.configure('../../config/rfsoc.cfg');
sdr1.fpga.configure('../../config/rfsoc.cfg');

sdr0.lo.configure('../../config/lmx_pdn.txt');
sdr1.lo.configure('../../config/lmx_pdn.txt');
sdr0.lo.configure('../../config/lmx_hedy_lamarr_58ghz.txt');
sdr1.lo.configure('../../config/lmx_hedy_lamarr_58ghz.txt');

% Power down all LTC5594 and HMC630x chips
sdr0.ltc.configure(10, '../../config/ltc5594_pdn.txt');
sdr1.ltc.configure(10, '../../config/ltc5594_pdn.txt');
sdr0.rffeTx.configure(10, '../../config/hmc6300_pdn.txt');
sdr1.rffeTx.configure(10, '../../config/hmc6300_pdn.txt');
sdr0.rffeRx.configure(10, '../../config/hmc6301_pdn.txt');
sdr1.rffeRx.configure(10, '../../config/hmc6301_pdn.txt');

sdr0.set_switches('off');
sdr1.set_switches('off');

% Bring up all TX and RX channels on sdr0
sdr0.ltc.configure(10, '../../config/ltc5594_pup.txt');
sdr0.rffeTx.configure(10, '../../config/hmc6300_registers.txt');
sdr0.rffeRx.configure(10, '../../config/hmc6301_registers.txt');

% Bring up the reference TX and RX channel on sdr1
refTxIndex = 1;
refRxIndex = 1;
sdr1.ltc.configure(refTxIndex, '../../config/ltc5594_pup.txt');
sdr1.rffeTx.configure(refTxIndex, '../../config/hmc6300_registers.txt');
sdr1.rffeRx.configure(refRxIndex, '../../config/hmc6301_registers.txt');

clear ip isDebug;

%% Calibrate of the RX array


nFFT = 1024;
nread = nFFT;
nskip = 1024*3;	% skip ADC data
ntimes = 100;	% num of batches to read

% Generate the TX waveform
scMin = -400;
scMax = 400;
niter =  1;
constellation = [1+1j 1-1j -1+1j -1-1j];

% expType = 1: Make initial measurements of the fractional timing offset
%
% expType = 2: Correct the fractional offsets and see if the residual
% errors are close to 0. Also measure the integer timing offsets. We do not
% expect integer timing offsets with ~2GHz sampling rate. So we just
% measure the integer timing offsets, make sure it's zero, but do not
% present code to correct it (this would be extremely simple to do). Also,
% measure the per-channel phase offset.
%
% expType = 3: Also correct the phase offsets, and make sure that the
% errors are now close to 0.

% How many unique fractional timing offsets are we going to search through?
nto = 31;
figure(3); clf;

pdpStore = zeros(sdr0.nch, 3, niter, ntimes, nFFT);

for expType = 1:3
    expType
    
    maxPos = zeros(sdr0.nch, niter, ntimes);
    maxVal = zeros(sdr0.nch, niter, ntimes);
    intPos = zeros(sdr0.nch, niter, ntimes);
    pk     = zeros(sdr0.nch, niter, ntimes);
        
    for iter = 1:niter
        fprintf('\n');
        txfd = zeros(nFFT, 1);
        txtd = zeros(nFFT, sdr0.nch);
        
        for scIndex = scMin:scMax
            if scIndex ~= 0
                txfd(nFFT/2 + 1 + scIndex, 1) = constellation(randi(4));
            end
        end

        txfd(:,1) = fftshift(txfd(:,1));
        txtd(:,1) = ifft(txfd(:,1));

        m = max(abs(txtd(:,1)));
       
        % Scale and send the signal
        txtd = txtd/m*15000;
        sdr1.send(txtd); % The "helper" sdr1 does the transmitting
        
        % Receive the signal
        rxtd = sdr0.recv(nread,nskip,ntimes);
        size(rxtd);
        
        for rxIndex=1:sdr0.nch
            fprintf('\n');
            tos = linspace(-0.5, 0.5, nto);
            for ito = 1:nto
                to = tos(ito);
                fprintf('.');
                for itimes=1:ntimes
                    if (expType == 1)
                        rxtdShifted = fracDelay(rxtd(:,itimes,rxIndex), to, nFFT);
                    elseif (expType == 2)
                        rxtdShifted = fracDelay(rxtd(:,itimes,rxIndex), to + sdr0.calRxDelay(rxIndex), nFFT);
                    elseif (expType == 3)
                        rxtdShifted = fracDelay(rxtd(:,itimes,rxIndex), to + sdr0.calRxDelay(rxIndex), nFFT);
                        rxtdShifted = rxtdShifted * exp(1i*sdr0.calRxPhase(rxIndex));
                    end
                    rxfd = fft(rxtdShifted);
                    corrfd = rxfd .* conj(txfd);
                    corrtd = ifft(corrfd);
                    
                    [~, pos] = max(abs(corrtd));
                    val = corrtd(pos);
                    if abs(val) > abs(maxVal(rxIndex, iter, itimes))
                        % We have bound a "better" timing offset
                        maxVal(rxIndex, iter, itimes) = abs(val);
                        maxPos(rxIndex, iter, itimes) = tos(ito);
                        intPos(rxIndex, iter, itimes) = pos;
                        
                        % Measure the phase at the "best" to
                        pk(rxIndex, iter, itimes) = val;
                        pdpStore(rxIndex, expType, iter, itimes, :) = corrtd;
                        
                    end % if abs(val) > ...
                end % itimes
            end % ito
        end % rxIndex        
    end % iter
    
    % Calculate the fractional and integer timing offsets
    cols = 'mrgbcykm'; % Colors for the plots
    figure(3);
    for rxIndex=1:sdr0.nch
        
        % Fractional
        l = maxPos(rxIndex, :, :) - maxPos(1,:,:);
        l = reshape(l, 1, []);
        l = (wrapToPi(l*2*pi))/(2*pi);
        if (expType == 1)
            figure(3);
            subplot(6,1,1);
            plot(l, cols(rxIndex));
            title('Pre-Cal: Fractional Timing Offsets');
            xlabel('Iteration (Unsorted)');
            hold on;
            ylim([-0.5 0.5]);
            c = sum(exp(1j*2*pi*l));
            c = angle(c);
            c = c /(2*pi);
            sdr0.calRxDelay(rxIndex) = (1)*c;
        elseif (expType == 2)
            figure(3);
            subplot(6,1,2);
            plot(l, cols(rxIndex));
            title('Post-Cal: Fractional Timing Offsets')
            xlabel('Iteration (Unsorted)');
            hold on;
            ylim([-0.5 0.5]);
        end
        
        % Integer
        l = intPos(rxIndex, :, :) - intPos(1, :, :);
        l = reshape(l, 1, []);
        l = sort(l);
        if (expType == 2)
            figure(3);
            subplot(6,8,16+rxIndex);
            plot(l, cols(rxIndex));
            title('Pre-Cal: Integer Timing Off.');
            hold on;
            ylim([-10 10]); grid on;
            medianIndex = length(l) / 2;
            sdr0.calRxDelay(rxIndex) = sdr0.calRxDelay(rxIndex) + l(medianIndex);
        elseif (expType == 3)
            figure(3);
            subplot(6,8,32+rxIndex);
            plot(l, cols(rxIndex));
            title('Post-Cal: Integer Timing Off.');
            hold on;
            ylim([-10 10]); grid on;
        end
        
        % Phase
        lRef = pk(1, :, :);
        lRef = reshape(lRef, 1, []);
        lRx = pk(rxIndex, :, :);
        lRx = reshape(lRx, 1, []);
        
        if (expType == 2)
            subplot(6,1,4);
            ph = wrapToPi(angle(lRx) - angle(lRef));
            plot(ph, cols(rxIndex)); hold on;
            ylim([-pi pi]);
            title('Pre-Cal: LO Phase Offsets');
            l = angle(sum(exp(1j*ph)));
            sdr0.calRxPhase(rxIndex) = (-1)*l;
        elseif (expType == 3)
            subplot(6,1,6);
            ph = wrapToPi(angle(lRx) - angle(lRef));
            plot(ph, cols(rxIndex)); hold on;
            ylim([-pi pi]);
            title('Post-Cal: LO Phase Offsets');
        end
        
    end % rxIndex
end % expType

% Stop the "helper" sdr1 transmission and do a dummy read at sdr0
txtd = zeros(nFFT, sdr1.nch);
sdr1.send(txtd);
pause(1);
rxtd = sdr0.recv(nread, nskip, ntimes);

% Clear workspace variables
clear constellation expType iter maxPos maxVal nFFT niter rxtd scIndex;
clear scMin scMax txfd txIndex txtd m nread nskip nsamp ntimes;
clear ans corrfd corrtd diff iiter itimes ito nto pos rxfd rxtdShifted;
clear to tos val cols diffMatrix resTimingErrors toff vec medianIndex;
clear intPeakPos intpos c lRef lTx pk ar intPos l ph lRx rxIndex;
clear pdpStore txChId;


%% Figure out what scaling to use at the TX to cal the TX array
clc;
nFFT = 1024;
nread = nFFT; % read ADC data for 256 cc (4 samples per cc)
nskip = nFFT*3;   % skip ADC data for this many cc
ntimes = 60;    % Number of batches to receive
scMin = -400;
scMax = 400;
constellation = [1+1j 1-1j -1+1j -1-1j];

sf = ones(sdr0.nch, 1);
acc = zeros(sdr0.nch, 1);
for expType = 1:2
    for txIndex = 1:sdr0.nch
        txfd = zeros(nFFT, sdr0.nch);
        txtd = zeros(nFFT, sdr0.nch);
        for scIndex = scMin:scMax
            if scIndex ~= 0                  
                txfd(nFFT/2 + 1 + scIndex, txIndex) = constellation(randi(4));
            end
        end % scIndex
        txfd(:,txIndex) = fftshift(txfd(:,txIndex));
        txtd(:,txIndex) = ifft(txfd(:,txIndex));
    
        txtd = txtd * 10000 * sf(txIndex);
        sdr0.send(txtd);
    
        rxtdOriginal = sdr1.recv(nread, nskip, ntimes);

        for itimes = 1:ntimes
            rxtd = rxtdOriginal(:, itimes, refRxIndex);
    
            rxfd = fft(rxtd);
            corr_fd = txfd(:, txIndex) .* conj(rxfd);
            corr_td = ifft(corr_fd);
            
            if itimes == 1
                figure(1);
                subplot(2, 8, txIndex + (expType-1)*sdr0.nch);
                plot(mag2db(abs(corr_td))); grid on;
                ylim([80 120]);
                xlim([1 1024]);
            end

            if (expType == 1)
                [val, ~] = max(abs(corr_td));
                acc(txIndex) = acc(txIndex) + val;
    
                if (itimes == ntimes)
                    sf(txIndex) = 1/acc(txIndex);

                    if (txIndex == 8)
                        sf = 1 * sf / max(sf);
                    end
                end
    
            end % if expType == 1
        end

    end % txIndex
end % expType loop

% Stop the sdr0 transmissions and do a dummy read at sdr1
txtd = zeros(nFFT, sdr0.nch);
sdr0.send(txtd);
pause(1);
rxtd = sdr1.recv(nread, nskip, ntimes);

clear acc constellation corr_fd corr_td expType itimes nFFT nread nskip;
clear ntimes pdpStore rxfd rxtd rxtdOriginal scIndex;
clear scMin scMax txChId txfd txIndex txtd val;

%% Calibrate of the TX array
% This script calibrates the TX-side timing and phase offsets. The TX under
% calibration is sdr0, and the reference RX is sdr1.

% Configure the RX number of samples, etc
nFFT = 1024;
nread = nFFT; % read ADC data for 256 cc (4 samples per cc)
nskip = nFFT*5;   % skip ADC data for this many cc
ntimes = 50;    % Number of batches to receive
% Generate the TX waveform
scMin = -400;
scMax = 400;
niter =  1;
constellation = [1+1j 1-1j -1+1j -1-1j];


% expType = 1: Make initial measurements of the fractional timing offset
%
% expType = 2: Correct the fractional offsets and see if the residual
% errors are close to 0. Also measure the integer timing offsets. We do not
% expect integer timing offsets with ~1GHz sampling rate. Also,
% measure the per-channel phase offset.
%
% expType = 3: Also correct the phase offsets, and make sure that the
% errors are now close to 0.

% How many unique fractional timing offsets are we going to search through?
nto = 31;
figure(3); clf;

pdpStore = zeros(sdr0.nch, 3, niter, ntimes, nFFT);

for expType=1:3
    maxPos = zeros(sdr0.nch, niter, ntimes);
    maxVal = zeros(sdr0.nch, niter, ntimes);
    intPos = zeros(sdr0.nch, niter, ntimes);
    pk     = zeros(sdr0.nch, niter, ntimes);
    
    for iter=1:niter
        fprintf('\n');
        txfd = zeros(nFFT, sdr0.nch);
        txtd = zeros(nFFT, sdr0.nch);
        
        m = 0;
        for txIndex=1:sdr0.nch
            for scIndex = scMin:scMax
                if scIndex ~= 0                  
                    txfd(nFFT/2 + 1 + scIndex, txIndex) = constellation(randi(4));
                end
            end % scIndex
            txfd(:,txIndex) = fftshift(txfd(:,txIndex));
            txtd(:,txIndex) = ifft(txfd(:,txIndex)) * sf(txIndex);
                       
            m = max(max(abs(txtd(:,txIndex))), m);
                        
            if (expType == 2)
                txtd(:,txIndex) = fracDelay(txtd(:,txIndex), sdr0.calTxDelay(txIndex), nFFT);
            elseif (expType == 3)
                txtd(:,txIndex) = exp(1j*sdr0.calTxPhase(txIndex)) * fracDelay(txtd(:,txIndex), sdr0.calTxDelay(txIndex), nFFT);
            end
        end % txIndex
        
        % Scale and send the signal from sdr0
        txtd = txtd/m*4000;
        sdr0.send(txtd);
        
        % Receive the signal from the "helper" sdr1
        rxtd = sdr1.recv(nread,nskip,ntimes);
        size(rxtd);
        
        for txIndex=1:sdr0.nch
            fprintf('\n');
            tos = linspace(-0.5, 0.5, nto);
            for ito = 1:nto
                to = tos(ito);
                fprintf('.');
                for itimes=1:ntimes

                    rxtdShifted = fracDelay(rxtd(:,itimes,refRxIndex), to, nFFT);
                    
                    rxfd = fft(rxtdShifted);
                    corrfd = zeros(nFFT, sdr0.nch);
                    corrtd = zeros(nFFT, sdr0.nch);
                    
                    corrfd(:,txIndex) = conj(txfd(:,txIndex)) .* (rxfd);
                    corrtd(:,txIndex) = ifft(corrfd(:,txIndex));
                    
                    [~, pos] = max(abs(corrtd(:,txIndex)));
                    val = corrtd(pos, txIndex);
                    if abs(val) >= abs(maxVal(txIndex, iter, itimes))
                        % We have bound a "better" timing offset
                        maxVal(txIndex, iter, itimes) = abs(val);
                        maxPos(txIndex, iter, itimes) = tos(ito);
                        intPos(txIndex, iter, itimes) = pos;
                        
                        pdpStore(txIndex, expType, iter, itimes, :) = corrtd(:,txIndex);
                        
                        % Measure the phase at the "best" to
                        pk(txIndex, iter, itimes) = val;
                        
                    end % if abs(val) > ...
                end % itimes
            end % ito
        end % txIndex
    end % iter
    
    
    % Calculate the fractional and integer timing offsets
    cols = 'mrgbcykr'; % Colors for the plots
    figure(3);
    for txIndex=1:sdr0.nch
        
        % Fractional
        l = maxPos(txIndex, :, :) - maxPos(1, :, :);
        l = reshape(l, 1, []);
        
        if (expType == 1)
            figure(3);
            subplot(6,1,1);
            plot(l, cols(txIndex));
            title('Pre-Cal: Fractional Timing Offsets');
            xlabel('Iteration (Unsorted)');
            hold on;
            ylim([-1 1]);
            c = sum(exp(1j*2*pi*l));
            c = angle(c);
            c = c /(2*pi);
            sdr0.calTxDelay(txIndex) = c;
        elseif (expType == 2)
            figure(3);
            subplot(6,1,2);
            plot(l, cols(txIndex)); grid on;
            title('Post-Cal: Fractional Timing Offsets')
            xlabel('Iteration (Unsorted)');
            hold on;
            ylim([-1 1]);
        end
        
        % Integer
        l = intPos(txIndex, :, :) - intPos(1, :, :);
        l = reshape(l, 1, []);
        l = sort(l);
        if (expType == 2)
            figure(3);
            subplot(6,8,16+txIndex);
            plot(l, cols(txIndex)); grid on;
            title('Pre-Cal: Integer Timing Offsets');
            hold on;
            medianIndex = length(l)/2;
            sdr0.calTxDelay(txIndex) = sdr0.calTxDelay(txIndex) + l(medianIndex);
        elseif expType == 3
            figure(3);
            subplot(6,8,32+txIndex);
            plot(l, cols(txIndex)); grid on;
            title('Post-Cal: Integer Timing Offsets');
            hold on;
        end
        
        % Phase
        lRef = pk(1, :, :);
        lRef = reshape(lRef, 1, []);
        lTx = pk(txIndex, :, :);
        lTx = reshape(lTx, 1, []);
        
        if (expType == 2)
            subplot(6,1,4);
            ph = wrapToPi(angle(lTx) - angle(lRef));
            plot(ph, cols(txIndex)); hold on;
            ylim([-pi pi]);
            title('Pre-Cal: LO Phase Offsets');
            l = angle(sum(exp(1j*ph)));
            sdr0.calTxPhase(txIndex) = (-1)*l;
        elseif (expType == 3)

            
            subplot(6,1,6);
            ph = wrapToPi(angle(lTx) - angle(lRef));
            plot(ph, cols(txIndex)); hold on;
            ylim([-pi pi]);
            title('Post-Cal: LO Phase Offsets');
        end
        
    end % txIndex
end % expType

% Stop the sdr0 transmissions and do a dummy read at sdr1
txtd = zeros(nFFT, sdr0.nch);
sdr0.send(txtd);
pause(1);
rxtd = sdr1.recv(nread, nskip, ntimes);

% Clear workspace variables
clear constellation expType iter maxVal nFFT niter rxtd scIndex;
clear scMin scMax txfd txIndex txtd m nread nskip nsamp ntimes;
clear ans corrfd corrtd diff iiter itimes ito nto pos rxfd rxtdShifted;
clear to tos val cols diffMatrix resTimingErrors toff vec ;
clear intPeakPos intpos c lRef lTx pk ar intPos l ph medianIndex;




%% Stop transmitting and do a dummy read on both nodes
nFFT = 1024;
nread = nFFT;
nskip = nFFT * 3;
ntimes = 100;
txtd = zeros(nFFT, sdr0.nch);
sdr0.send(txtd);
sdr0.recv(nread,nskip,ntimes);

clear nFFT nskip ntimes nread txtd;

%% Debug by looking at pdpStore
figure(1); clf; clc;
for txIndex = 8:8
    a = pdpStore(txIndex, 1, 1, 1, :);
    b = reshape(a, [1024 1]);
    c = mag2db(abs(b));
    subplot(2, 4, txIndex)
    plot(c); grid on; grid minor;
    [val, pos] = max(c);
    pos
end



