%% Add the folder containing +piradio to the MATLAB path.
addpath('../../');

% Parameters
ip = "10.1.1.43";	% IP Address
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
txPower = 30000/16;
scMin = -350;
scMax = 350;
constellation = [1+1j 1-1j -1+1j -1-1j];
txtd = zeros(nFFT, sdr0.nch);

txfd = zeros(nFFT,1);
for scIndex = scMin:scMax
    if scIndex == 0
        continue;
    end
    txfd(nFFT/2 + 1 + scIndex) = constellation(randi(4));
end

% All TX channels sending the same data
txfd = fftshift(txfd);
for ich = 1:8
    txtd(:,ich) = ifft(txfd);
end


% Normalize the energy of the tx array and scale with txPower.
txtd = txPower*txtd./max(abs(txtd));

% Send the data to the DACs
sdr0.send(txtd);

% Receive data

% Configure the Switches
%sdr0.set_switches("normal");

nFFT = 1024;
nskip = 1024*3;	% skip ADC data
nbatch = 100;	% num of batches


for ind = 1:3
    rxtd = sdr0.recv(nFFT, nskip, nbatch);
end

% Received data and SNR
figure(1);
subplot(2,2,1);
a = rxtd(:, 1, 6);
b = ((fftshift(abs(fft(a)))));
plot(mag2db(b), 'LineWidth', 4);
grid on; grid minor;
totSig2 = sum(abs(b(163:863)) .* abs(b(163:863)));
S = totSig2 / (863-163+1);
totNoiA2 = sum(abs(b(1:162)) .* abs(b(1:162)));
totNoiB2 = sum(abs(b(864:1024)) .* abs(b(864:1024)));
totNoise2 = totNoiA2 + totNoiB2;
N = totNoise2 / (162+161);
SNR = 10*log10(S/N);
s = sprintf('SNR = %4.2f dB', SNR);
title(s, 'FontSize', 44);
ylim([40 100]);
clc;
txtd = txtd(:, 1);
%txfd = fft(txtd);
%a = [txtd(100:1024); txtd(1:99)];
rxfd = fft(a);
corrfd = txfd .* conj(rxfd);
corrtd = ifft(corrfd);

subplot(2, 2, 2);
plot(mag2db(abs(corrtd)), 'LineWidth', 4);
title('Correlation Output (dB)', 'FontSize', 44);
ylim([20 100]); grid on;
[val, loc] = max(abs(corrtd));
loc = loc+0; % add a timing offset to test
a = [a(1024-loc+2:1024); a(1:1024-loc+1)];
a = fftshift(fft(a));
txfd = fftshift(txfd);
rxfd = a;

h = zeros(nFFT, 1);
t_hat = zeros(nFFT, 1);
for sc = scMin:scMax
    if sc == 0
        continue;
    end

    if (mod(sc, 5) == 0)
        % Pilot
        h(nFFT/2 + 1 + sc) = rxfd(nFFT/2 + 1 + sc) / txfd(nFFT/2 + 1+ sc);
        h_temp = h(nFFT/2 + 1 + sc);
    else
        % Data
        t_hat(nFFT/2 + 1 + sc) = rxfd(nFFT/2 + 1 + sc) /(h_temp);
    end

end
subplot(2,2,3);
plot(real(h), 'o'); hold on; 
plot(imag(h), 'o'); hold on;
plot(abs(h), 'o'); hold off;
legend('Real', 'Imag', 'Abs');
title('Measured H Channel', 'FontSize', 44);

subplot(2,2,4);
plot(real(t_hat), imag(t_hat), '.', 'MarkerSize', 20)
grid on;
ylim([-2 2]);
xlim([-2 2]);
n = 0;
s = 0;
for sc = scMin:scMax
    if sc == 0
        continue;
    end
    if (mod(sc,5) == 0)
        continue;
    end

    % power domain calculations
    s = s + 2; % since it is QPSK
    x = abs(real(t_hat(nFFT/2 + 1 + sc))) - 1;
    y = abs(imag(t_hat(nFFT/2 + 1 + sc))) - 1;
    n = n + x^2 + y^2;
end
snr = 10*log10(s/n);
s = sprintf('ZF Equalized Symbols. SNR = %2.2f dB', snr)
title(s, 'FontSize', 44);

