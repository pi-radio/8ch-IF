nFFT = 1024;
constellation = [1+1j 1-1j -1+1j -1-1j];

% Filling up subcarriers -450 to +450
txfd = zeros(1,nFFT);
for scIndex = -450:450
    if scIndex ~= 0
        txfd(nFFT/2 + 1 + scIndex) = constellation(randi(4));
    end
end
txfd = fftshift(txfd);

% This signal gets transmitted "over the air"
txtd = ifft(txfd);

% What if there is a timing offset
nOff = 1000;
pad = zeros(1,nOff-1);
rxtd = [txtd(nOff:nFFT) pad];

rxfd = fft(rxtd);

corrfd = rxfd .* conj(txfd);
corrtd = ifft(corrfd);
figure(1);
plot(mag2db(abs(corrtd)));
ylim([-60 20]);
xlim([-nFFT 2*nFFT]);
grid on; grid minor;

