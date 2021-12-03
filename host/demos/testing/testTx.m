% Configure the Switches
%sdr0.set_switches("testTxArray");

% Generate the data
nFFT = 1024;	% number of FFT points
txPower = 10000*1;
scMin = -200;
scMax = -200;
constellation = [1+1j 1-1j -1+1j -1-1j];
txtd = zeros(nFFT, sdr0.nch);
for ich = 8:8
    txfd = zeros(nFFT,1);
    for scIndex = scMin:scMax
        txfd(nFFT/2 + 1 + scIndex) = constellation(randi(4));
    end
    
    txfd = fftshift(txfd);
    txtd(:,ich) = ifft(txfd);
end

% Normalize the energy of the tx array and scale with txPower.
txtd = txPower*txtd./max(abs(txtd));

% Send the data to the DACs
sdr0.send(txtd);

% Receive data
nskip = 1024*3;	% skip ADC data
nbatch = 200;	% num of batches

rxtd = sdr0.recv(nFFT, nskip, nbatch);
