%% FIR design and export to STM32  — with measured overlay like EMA block
clc; clear; close all;

%% FIR design
Fs        = 48000;         % Hz
num_taps  = 62;
cutoff_n  = 0.20;          % normalized (0..1) of Nyquist

b = fir1(num_taps-1, cutoff_n, 'low');   % windowed-sinc
% For CMSIS-FIR filter
b = flip(b); 

% Theoretical response
[H,F]     = freqz(b, 1, 2048, Fs);
theo_dB   = 20*log10(abs(H) + eps);      % dB magnitude

% Theoretical -3 dB cutoff
y3db      = max(theo_dB) - 3;
idx_th    = find(theo_dB <= y3db, 1, 'first');
fc_theo   = F(idx_th);

fprintf('FIR (theoretical) -3 dB cutoff ≈ %.1f Hz\n', fc_theo);

%% Q15 export (unchanged)
q15_scale = 2^15;
b_q15     = round(b * q15_scale);
b_q15     = max(min(b_q15, 32767), -32768);

% --- write headers if you want (same as your code) ---
header_path = "D:\STM32G4\Benchmarking-STM32G4-Accelerators\BenchmarkingAccelerators\Core\Inc\filter_coeffs.h";
source_path = "D:\STM32G4\Benchmarking-STM32G4-Accelerators\BenchmarkingAccelerators\Core\Src\filter_coeffs.c";

% --- write filter_coeffs.h and filter_coeffs.c ---
num_taps_export = numel(b_q15);

% make sure folders exist
[hp,~] = fileparts(header_path); if ~isempty(hp), mkdir(hp); end
[sp,~] = fileparts(source_path); if ~isempty(sp), mkdir(sp); end

% header
fid = fopen(header_path,'w'); assert(fid>0,'Failed to open header_path');
fprintf(fid, ...
"#ifndef FILTER_COEFFS_H\n#define FILTER_COEFFS_H\n\n#include <stdint.h>\n\n#define NUM_TAPS %d\nextern const int16_t fir_coeffs[NUM_TAPS];\n\n#endif // FILTER_COEFFS_H\n", ...
num_taps_export);
fclose(fid);

% source
fid = fopen(source_path,'w'); assert(fid>0,'Failed to open source_path');
fprintf(fid, '#include "filter_coeffs.h"\n\nconst int16_t fir_coeffs[NUM_TAPS] = {\n    ');
for k = 1:num_taps_export
    fprintf(fid, "%d", b_q15(k));
    if k < num_taps_export, fprintf(fid, ", "); end
    if mod(k,8)==0 && k < num_taps_export, fprintf(fid, "\n    "); end
end
fprintf(fid, "\n};\n");
fclose(fid);

fprintf("Wrote %d taps to:\n  %s\n  %s\n", num_taps_export, header_path, source_path);


%% Measured data (example)
% Put your scope readings here. Use Vpp if you read Vpp; otherwise set the flag below.
measured_freq = 500:500:(500*10);
measured_amp  = [3.005,2.987,2.980,2.760,0.9808,0.0467,0.0467,0.0467,0.0467,0.0467]; % example values

% --- measurement conventions ---
measured_is_vpp = true;      % set false if the values above are already Vpk
input_vpp       = 1.5;       % the sine you inject (Vpp at the ADC front-end)
input_vpk       = input_vpp/2;

if measured_is_vpp
    meas_vpk = measured_amp/2;
else
    meas_vpk = measured_amp;
end

% Convert to dB relative to the input peak amplitude (same style as EMA block)

measured_dB = 20*log10(meas_vpk / input_vpk + eps);

% Measured -3 dB cutoff (coarse: first point below -3 dB)
idx_meas = find(measured_dB <= (max(measured_dB)-3), 1, 'first');
if ~isempty(idx_meas)
    fc_meas = measured_freq(idx_meas);
    fprintf('FIR (measured)     -3 dB cutoff ≈ %.1f Hz (coarse)\n', fc_meas);
else
    fc_meas = NaN;
    fprintf('FIR (measured)     -3 dB cutoff not found in provided points.\n');
end

%% Plot — same style as your EMA figure
figure;
plot(F, theo_dB, 'b-', 'LineWidth', 1.5); hold on;
plot(measured_freq, measured_dB, 'ro', 'MarkerSize', 7, 'LineWidth', 1.5);

% -3 dB line and cutoff markers
% yline(y3db, 'k--', '-3 dB', 'LabelVerticalAlignment','bottom');
% if ~isempty(idx_th), xline(fc_theo, 'k:', sprintf('f_c(th)\\approx %.0f Hz', fc_theo)); end
% if exist('fc_meas_refined','var')
%     xline(fc_meas_refined, 'r:', sprintf('f_c(meas)\\approx %.0f Hz', fc_meas_refined));
% elseif ~isnan(fc_meas)
%     xline(fc_meas, 'r:', sprintf('f_c(meas)\\approx %.0f Hz', fc_meas));
% end

% zoom where it matters
xlim([0 10e3]);                 % or whatever shows passband + transition well

ylim([-60 8]);

% mark worst-case stopband
stop_idx = F >= 6e3;            % start of stopband (set to your spec)
Astop = max(theo_dB(stop_idx)); % least attenuation (highest crest)
% yline(Astop,'m--',sprintf('Worst stopband = %.1f dB',Astop));

xlabel('Frequency (Hz)');
ylabel('Magnitude (dB re. input peak)');
title('FIR Low-pass — Theoretical vs Measured');
legend('Theoretical (freqz)','Measured','Location','SouthWest');
grid on;
