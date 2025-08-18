%% FIR design and export to STM32
Fs = 48000;           % sampling frequency in Hz
num_taps = 61;        % filter length
cutoff_norm = 0.2;    % normalized cutoff, 0.2 of Nyquist

% FIR design
b = fir1(num_taps-1, cutoff_norm, 'low');

% disp("Filter coefficients :");
% for i=1:length(b)
%     disp(b(i))
% end

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

%% Q15 conversion
q15_scale = 2^15;
b_q15 = round(b * q15_scale);
b_q15 = max(min(b_q15, 32767), -32768);  % saturate to int16 range

%% Write to header/source
header_path = "D:\STM32G4\Benchmarking-STM32G4-Accelerators\BenchmarkingAccelerators\Core\Inc\filter_coeffs.h";
source_path = "D:\STM32G4\Benchmarking-STM32G4-Accelerators\BenchmarkingAccelerators\Core\Src\filter_coeffs.c";

% header file
fid = fopen(header_path, 'w');
fprintf(fid, "#ifndef FILTER_COEFFS_H\n#define FILTER_COEFFS_H\n\n");
fprintf(fid, "#include <stdint.h>\n\n");
fprintf(fid, "#define NUM_TAPS %d\n", numel(b_q15));
fprintf(fid, "extern int16_t fir_coeffs[NUM_TAPS];\n\n");
fprintf(fid, "#endif // FILTER_COEFFS_H\n");
fclose(fid);

% source file
fid = fopen(source_path, 'w');
fprintf(fid, '#include "filter_coeffs.h"\n\n');
fprintf(fid, "int16_t fir_coeffs[NUM_TAPS] = {\n    ");
for i = 1:numel(b_q15)
    if mod(i,8)==0
        fprintf(fid, "%d,\n    ", b_q15(i));
    elseif i == numel(b_q15)
        fprintf(fid, "%d\n", b_q15(i));
    else
        fprintf(fid, "%d, ", b_q15(i));
    end
end
fprintf(fid, "};\n");
fclose(fid);

fprintf("Q15 coefficients written to:\n%s\n%s\n", header_path, source_path);


%Measured frequency and amplitude sample
% CMSIS FIR q15
measured_freq = [400,500,600,700,800,900,1200,1300,1400,1500,1600,1900,2000,2100,2200,2300,2400,2500,2600,2700];
measured_amplitude = [1.733,1.733,1.725,1.719,1.726,1.716,1.73,1.728,1.67,1.73,1.700,1.659,1.578,1.443,1.265,1.065,0.813,0.595,0.3914,0.205];

max_amp_db = max(measured_amplitude_db);
cutoff_level_db = max_amp_db - 3;
% Find index where amplitude goes below cutoff level
idx = find(measured_amplitude_db <= cutoff_level_db, 1, 'first');

if ~isempty(idx)
    cutoff_freq_measured = measured_freq(idx);
    fprintf('Measured cutoff frequency: %.2f Hz\n', cutoff_freq_measured);
else
    fprintf('No cutoff frequency found in measured data.\n');
end


% FMAC implementation
% measured_freq = [186.3,372.7,745.5,1305,1676,2050,2609,2983,3334,3726,4476,4842,5522,5595,5965,6342,6713,7071,7828];
% measured_amplitude = [3.199,3.199,3.195,3.152,3.128,3.045,2.794,2.240,2.546,2.241,1.868,1.490,1.307,0.9339,0.5603,0.5604,0.3735,0.1865,0.1865];
% 
% 
measured_amplitude_db = 20 * log(measured_amplitude/3.3);

theoretical_amp_db = 20*log10(abs(H));

figure;
plot(F, theoretical_amp_db, 'b-', 'LineWidth', 1.5); hold on;
plot(measured_freq, measured_amplitude_db, 'ro', 'MarkerSize', 8, 'LineWidth', 1.5);
xlabel('Frequency (Hz)');
ylabel('Magnitude (dB)');
legend('Theoretical (freqz)','Measured (oscilloscope)');
title('Filter Frequency Response: Theoretical vs Measured');
grid on;

% xlim([0 5000]);    % for example up to 5 kHz
% ylim([-40 5]);     % to better see passband detail
