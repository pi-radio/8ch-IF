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
nfft = 1024;	% number of samples to generate for each DAC

% Initialize the tx data
txtd = zeros(nfft, ndac);
for idac = 1:ndac
	txfd = zeros(nfft,1);
	txfd = fftshift(txfd);
	txfd(25) = 1;
	txtd(:,idac) = ifft(txfd);
end

txtd = txtd./abs(max(txtd))*32000;

% Plot the tx data
scs = linspace(-nfft/2, nfft/2-1, nfft);

figure(1);
clf;
for idac = 1:ndac
	subplot(2,4,idac);
	plot(scs,(abs(fftshift(fft(txtd(:,idac))))));
	axis tight;
	grid on; grid minor;
	ylabel('Magnitude', 'interpreter', 'latex', 'fontsize', 12);
	xlabel('Subcarrier Index', 'interpreter', 'latex', 'fontsize', 12);
	title(sprintf('DAC %d', idac), 'interpreter', 'latex', 'fontsize', 14);
end

% Send the data to the DACs
sdr0.send(txtd);

%% Receive continous data from the ADCs
nfft = 1024;
nsamp = nfft*2*nadc;
sdr0.set('nread', 0, 'nskip', 0);
sdr0.ctrlFlow();
rxtd = sdr0.recv(nsamp);

% Plot the rx data
scs = linspace(-nfft/2, nfft/2-1, nfft);

figure(1);
clf;
for iadc = 1:nadc
	subplot(2,nadc/2,iadc);
	plot(scs, 10*log10(abs(fftshift(fft(rxtd(:,iadc))))));
	axis tight;
	grid on; grid minor;
	ylabel('Magnitude [dB]', 'interpreter', 'latex', 'fontsize', 12);
	xlabel('Subcarrier Index', 'interpreter', 'latex', 'fontsize', 12);
	title(sprintf('ADC %d', iadc), 'interpreter', 'latex', 'fontsize', 14);
end

%% Receive discontinus data from the ADCs
nread = nfft/2; % read ADC data for 512 cc
nskip = 512; % skip ADC data for 512 cc

% First, set the read and skip timings
sdr0.set('nread', nread, 'nskip', nskip);
sdr0.ctrlFlow();

% Then, read data from the ADCs. Note that the returned data should be a
% tensor with dimensions: nsamp x ntimes x nadc
nsamp = 2*nfft*2*nadc;
rxtd = sdr0.recv(nsamp);

ntimes = nsamp/16/nfft;
for itimes=1:1
	for iadc = 1:nadc
		subplot(2,nadc/2,iadc);
		plot(scs, 10*log10(abs(fftshift(fft(rxtd(:,itimes,iadc))))));
		axis tight;
		ylabel('Magnitude [dB]', 'interpreter', 'latex', 'fontsize', 12);
		xlabel('Subcarrier Index', 'interpreter', 'latex', 'fontsize', 12);
		title(sprintf('ADC %d', iadc), 'interpreter', 'latex', 'fontsize', 14);
	end
end

%% Close the TCP Connections
clear sdr0