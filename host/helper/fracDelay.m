function op_blob = fracDelay(ip_blob,frac_delay,N)
    taps = zeros(0,0);
    for index=-100:100
        delay = index + frac_delay;
        taps = [taps sinc(delay)];
    end
    x = [ip_blob; ip_blob];
    x = x';
    y = conv(taps, x);
    op_blob = y(N/2 : N/2 + N - 1);
    op_blob = op_blob';
end

