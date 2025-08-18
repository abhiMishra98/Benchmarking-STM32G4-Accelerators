% === Parameters ===
csv_file = 'C:\Users\abhim\OneDrive\Documents\Waveforms\20250627-mATLAB-0005.csv';  % update as needed
Fs = 48000;                        % Sampling frequency in Hz

% === Load Data ===
data = readmatrix(csv_file);
if size(data, 2) < 2
    error('CSV must contain at least two columns: input and output signals.');
end

input = data(:,1);
output = data(:,2);

% === Normalize Signals ===
input = input - mean(input);
output = output - mean(output);

% === FFT Analysis ===
N = length(input);
f = (0:N-1)*(Fs/N);  % Frequency vector

INPUT_FFT = abs(fft(input));
OUTPUT_FFT = abs(fft(output));

% Keep only one-sided spectrum
half_N = floor(N/2);
f = f(1:half_N);
INPUT_FFT = INPUT_FFT(1:half_N);
OUTPUT_FFT = OUTPUT_FFT(1:half_N);

% === Gain in dB ===
gain = 20*log10(OUTPUT_FFT ./ (INPUT_FFT + 1e-12));  % small epsilon to avoid div0

% === Find -3 dB Cutoff ===
% skip DC bin (bin 1)
[max_gain, max_idx] = max(gain(2:end));
max_idx = max_idx + 1; % correct for offset

cutoff_idx = find(gain(max_idx:end) <= max_gain - 3, 1, 'first');
if isempty(cutoff_idx)
    warning('No -3 dB cutoff found above max bin');
    cutoff_freq = NaN;
else
    cutoff_idx = cutoff_idx + max_idx - 1;  % correct to global index
    cutoff_freq = f(cutoff_idx);
end

% === Plot ===
figure;
plot(f, gain);
xlabel('Frequency (Hz)');
ylabel('Gain (dB)');
title(['Filter Gain | -3 dB Cutoff @ ', num2str(cutoff_freq, '%.1f'), ' Hz']);
grid on;
xlim([0 Fs/2]);
hold on;
yline(-3, '--r', '-3 dB line');
if ~isnan(cutoff_freq)
    xline(cutoff_freq, '--g', sprintf('%.1f Hz', cutoff_freq));
end
hold off;

% === Print Result ===
fprintf('Estimated -3 dB Cutoff Frequency: %.1f Hz\n', cutoff_freq);
