%% DEMO: Basic Tx/Rx with the Pi-Radio FD platform

%% Packages
% Add the folder containing +piradio to the MATLAB path.
addpath('../../');

%% Parameters
ip = "10.113.5.6";	% IP Address 
mem = "bram";		% Memory type
isDebug = true;		% print debug messages
ndac = 8;			% num of D/A converters
nadc = 8;			% num of A/D converters
nsamp = 1024;		% num of samples
fsamp = 983.04e6;	% sample frequency
fc = 100e6;

%% Create a Fully Digital SDR
sdr0 = piradio.sdr.FullyDigital('ip', ip, 'mem', mem, 'isDebug', isDebug);

%% Configure the RFSoC
sdr0.fpga.configure('../../config/rfsoc.cfg');

%% Create some time-domain samples
t = (0:nsamp-1)';

txtd = zeros(nsamp, ndac);
for idac = 1:ndac
	txtd(:,idac) = sin(2*pi*t*fc/fsamp) + 1j*sin(2*pi*t*fc/fsamp);
end

txtd = txtd./abs(max(txtd))*32767;
%% Plot the tx data
f = linspace(-fsamp/2, fsamp/2, nsamp);

figure(1);
clf;
for idac = 1:ndac
	subplot(2,4,idac);
	plot(f*1e-6, 10*log10(abs(fftshift(fft(txtd(:,idac))))));
	axis tight;
	ylabel('Magnitude [dB]', 'interpreter', 'latex', 'fontsize', 12);
	xlabel('Frequency [MHz]', 'interpreter', 'latex', 'fontsize', 12);
	title(sprintf('DAC %d', idac), 'interpreter', 'latex', 'fontsize', 14);
end

%% Send the data to the DACs
tmp = zeros(2, size(txtd,1), size(txtd,2));

% Create the complex input data to int16
tmp(1,:,:) = swapbytes(int16(imag(txtd)));
tmp(2,:,:) = swapbytes(int16(real(txtd)));

tmp = reshape(tmp,2*2,[],ndac);

txtd = zeros(4, size(txtd,1)*size(txtd,2)/2);
for idac = 1:ndac
	txtd(:,idac:ndac:end) = reshape(tmp(:,:,idac),4,[]);
end

% flatten the time domain tx vector;
txtd = reshape(txtd,[],1);

% Send the data to the RFSoC
sdr0.send(txtd);

%% Receive data from the ADCs
nsamp = 8192;
rxtd = sdr0.recv(nsamp);

% process the received samples
tmp = zeros(2,size(rxtd,1)/32,8);
rxtd = double(reshape(rxtd,2,[]));
idx = 1;
for iadc = 1:2:2*nadc
	tmp(:,:,idx) = rxtd(:,iadc:2*nadc:end) + 1j*rxtd(:,(iadc+1):2*nadc:end);
	idx = idx + 1;
end
rxtd = reshape(tmp, [], nadc);

%% Plot the rx data
f = linspace(-fsamp/2, fsamp/2, nsamp/(2*nadc));

figure(1);
clf;
for iadc = 1:nadc
	subplot(2,4,iadc);
	plot(f*1e-6, 10*log10(abs(fftshift(fft(rxtd(:,iadc))))));
	axis tight;
	ylabel('Magnitude [dB]', 'interpreter', 'latex', 'fontsize', 12);
	xlabel('Frequency [MHz]', 'interpreter', 'latex', 'fontsize', 12);
	title(sprintf('ADC %d', iadc), 'interpreter', 'latex', 'fontsize', 14);
end