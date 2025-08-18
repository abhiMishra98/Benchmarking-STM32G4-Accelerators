% Q15 coefficients
b0_q15 = 158;
b1_q15 = 316;
b2_q15 = 158;
a1_q15 = -59227;
a2_q15 = 27099;

% convert to float
b0 = b0_q15 / 32768;
b1 = b1_q15 / 32768;
b2 = b2_q15 / 32768;
a1 = a1_q15 / 32768;
a2 = a2_q15 / 32768;

% Numerator and Denominator
b = [b0, b1, b2];
a = [1, -a1, -a2];

% frequency response
[H,F] = freqz(b,a,1024,48000);
mag_db = 20*log10(abs(H));

% find -3 dB point
max_gain = max(mag_db);
idx_3db = find(mag_db <= max_gain - 3, 1, 'first');
cutoff_freq = F(idx_3db);

% plot
figure;
plot(F,mag_db);
hold on;
yline(max_gain - 3,'r--','-3 dB line');
plot(cutoff_freq, mag_db(idx_3db), 'ro', 'MarkerFaceColor','r');
grid on;
xlabel('Frequency (Hz)');
ylabel('Gain (dB)');
title(['Q15 Butterworth filter | -3 dB at ', num2str(cutoff_freq, '%.1f'), ' Hz']);
