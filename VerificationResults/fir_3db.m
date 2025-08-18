% MATLAB script to design and plot the FIR filter
Fs = 48000;           % sampling frequency in Hz
num_taps = 21;        % filter length
cutoff_norm = 0.2;    % normalized cutoff, 0.2 of Nyquist

% FIR design
b = fir1(num_taps-1, cutoff_norm, 'low'); % note num_taps-1 order
% frequency response
[H,F] = freqz(b, 1, 2048, Fs);

% magnitude in dB
mag_db = 20*log10(abs(H));

% find -3 dB cutoff
max_gain = max(mag_db);
idx_3db = find(mag_db <= max_gain - 3, 1, 'first');
cutoff_3db = F(idx_3db);

% plot
figure;
plot(F, mag_db);
hold on
yline(max_gain - 3, 'r--', '-3 dB line');
plot(cutoff_3db, mag_db(idx_3db), 'ro');
title(sprintf('FIR Filter | -3 dB cutoff at %.1f Hz', cutoff_3db));
xlabel('Frequency (Hz)');
ylabel('Magnitude (dB)');
grid on;

fprintf('Estimated -3 dB cutoff: %.1f Hz\n', cutoff_3db);
