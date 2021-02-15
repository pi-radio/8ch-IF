%% DEMO: Basic Tx/Rx with the Pi-Radio 140 GHz, 8 channel SDR

%% Packages
% Add the folder containing +piradio to the MATLAB path.
addpath('../../');

%% Parameters
ip = "10.113.5.6";	% IP Address 
mem = "bram";		% Memory type
isDebug = true;		% print debug messages
ndac = 8;			% num of D/A converters
nadc = 8;			% num of A/D converters
fs = 983.04e6;		% sample frequency

%% Create a Fully Digital SDR
sdr0 = piradio.sdr.FullyDigital('ip', ip, 'mem', mem, ...
	'ndac', ndac, 'nadc', nadc, 'isDebug', isDebug);

% Set the number of DACs and ADCs of the RFSoC
sdr0.fpga.set('ndac', ndac, 'nadc', nadc);

% Configure the RFSoC
sdr0.fpga.configure('../../config/rfsoc.cfg');

%% Create time-domain samples and send them to the DACs
fc = 25e6;		% carrier frequency
nsamp = 1024;	% number of samples to generate for each DAC

% Create a time-vector
t = (0:nsamp-1)';

% Initialize the tx data
txtd = zeros(nsamp, ndac);
for idac = 1:ndac
	% Create a complex 
	txtd(:,idac) = exp(1j*2*pi*t*idac*fc/fs);
end

txtd = txtd./abs(max(txtd))*32767;

% Plot the tx data
f = linspace(-fs/2, fs/2, nsamp);

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

% Send the data to the DACs
sdr0.send(txtd);

%% Receive continous data from the ADCs
nsamp = 8192;
sdr0.set('nread', 0, 'nskip', 0);
sdr0.ctrlFlow();
rxtd = sdr0.recv(nsamp);

% Plot the rx data
f = linspace(-fs/2, fs/2, nsamp/(2*nadc));

figure(1);
clf;
for iadc = 1:nadc
	subplot(2,nadc/2,iadc);
	plot(f*1e-6, 10*log10(abs(fftshift(fft(rxtd(:,iadc))))));
	axis tight;
	ylabel('Magnitude [dB]', 'interpreter', 'latex', 'fontsize', 12);
	xlabel('Frequency [MHz]', 'interpreter', 'latex', 'fontsize', 12);
	title(sprintf('ADC %d', iadc), 'interpreter', 'latex', 'fontsize', 14);
end

%% Receive discontinus data from the ADCs
nread = 512; % read ADC data for 512 cc
nskip = 512; % skip ADC data for 512 cc

% First, set the read and skip timings
sdr0.set('nread', nread, 'nskip', nskip);
sdr0.ctrlFlow();

% Then, read data from the ADCs. Note that the returned data should be a
% tensor with dimensions: ntimes x nsamp x 
nsamp = 32768;
rxtd = sdr0.recv(nsamp);

ntimes = (nsamp/16)/(2*nread);

f = linspace(-fs/2, fs/2, nsamp/16/ntimes);
for itimes=1:1
	for iadc = 1:nadc
		subplot(2,nadc/2,iadc);
		plot(f*1e-6, 10*log10(abs(fftshift(fft(rxtd(itimes,:,iadc))))));
		axis tight;
		ylabel('Magnitude [dB]', 'interpreter', 'latex', 'fontsize', 12);
		xlabel('Frequency [MHz]', 'interpreter', 'latex', 'fontsize', 12);
		title(sprintf('ADC %d', iadc), 'interpreter', 'latex', 'fontsize', 14);
	end
end

%% Close the TCP Connections
clear sdr0