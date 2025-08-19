clc;
clear all;
close all;


%% IIR LP EMA design
Fs = 48000;           % sampling frequency in Hz
alpha = 0.7;          % smoothing factor (adjust as needed)

% filter coefficients
b = alpha;
% a = [1 -(1 - alpha)];
a = [1, (alpha - 1)];  %For FMAC implementation

% frequency response
[H,F] = freqz(b, a, 2048, Fs);

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
title(sprintf('IIR EMA Filter | -3 dB cutoff at %.1f Hz', cutoff_3db));
xlabel('Frequency (Hz)');
ylabel('Magnitude (dB)');
grid on;

fprintf('Estimated -3 dB cutoff: %.1f Hz\n', cutoff_3db);

%% Q15 conversion
q15_scale = 2^15;

b_q15 = round(b * q15_scale); %Conversion to actual coefficients
b_q15 = max(min(b_q15, 32767), -32768); %clipping to keep in Q15 range

a_q15 = round(a * q15_scale);
a_q15 = max(min(a_q15, 32767), -32768);


%% Write to header/source
header_path = "D:\STM32G4\Benchmarking-STM32G4-Accelerators\BenchmarkingAccelerators\Core\Inc\filter_coeffs.h";
source_path = "D:\STM32G4\Benchmarking-STM32G4-Accelerators\BenchmarkingAccelerators\Core\Src\filter_coeffs.c";

% header file
fid = fopen(header_path, 'w');
fprintf(fid, "#ifndef FILTER_COEFFS_H\n#define FILTER_COEFFS_H\n\n");
fprintf(fid, "#include <stdint.h>\n\n");
% fprintf(fid, "#define EMA_NUM_B_COEFFS %d\n", numel(b_q15));
% fprintf(fid, "#define EMA_NUM_A_COEFFS %d\n", numel(a_q15));
fprintf(fid, "#define EMA_NUM_B_COEFFS 1\n");
fprintf(fid, "#define EMA_NUM_A_COEFFS 1\n");
fprintf(fid, "extern int16_t ema_b_coeffs[EMA_NUM_B_COEFFS];\n");
fprintf(fid, "extern int16_t ema_a_coeffs[EMA_NUM_A_COEFFS];\n\n");
fprintf(fid, "#endif // IIR_COEFFS_H\n");
fclose(fid);

% source file
fid = fopen(source_path, 'w');
fprintf(fid, '#include "filter_coeffs.h"\n\n');
fprintf(fid, "int16_t ema_b_coeffs[EMA_NUM_B_COEFFS] = { %d };\n", b_q15);
fprintf(fid, "int16_t ema_a_coeffs[EMA_NUM_A_COEFFS] = { ");
fprintf(fid, "%d", -a_q15(2));
% fprintf(fid, "%d", -a_q15(2)); For IIR FMAC implementation . FMAC
% requires the coefficients to be negated
fprintf(fid, " };\n");
fclose(fid);

fprintf("Q15 IIR coefficients written to:\n%s\n%s\n", header_path, source_path);


x = [zeros(1,5), ones(1,15) * 1000];
y = filter(b, a, x);
disp([x' y'])  % compare input vs output



%% Measured comparison (with DC offset handling)
measured_freq = 1000:1000:30000;

%For FMAC - IIR 
measured_amplitude_raw = [2.963,2.917,2.861,2.701,2.597,2.438,2.348,2.285,2.211,2.120,2.020,1.924,1.780,1.826,1.739,1.736,1.697,1.652,1.592,1.541,1.544,1.552,1.540,1.549,1.549,1.549,1.549,1.549,1.642,1.638];
% For CMSIS - IIR
measured_amplitude_raw = [2.967,2.918,2.780,2.700,2.606,2.453,2.348,2.280,2.215,2.122,2.031,1.850,1.745,1.828,1.742,1.735,1.682,1.650,1.639,1.541,1.540,1.542,1.553,1.552,1.554,1.554,1.541,1.541,1.641,1.642];

dc_offset      = 1.5;    % V  (what you subtract in firmware)
input_pk       = 1.5;    % V  (because 1.8 Vpp / 2)

% 1) subtract the offset from BOTH peaks
Vpk_pos =  measured_amplitude_raw/2;          % positive peak above centre
Vpk_neg = -measured_amplitude_raw/2;          % negative peak below centre
pk_plus  =  dc_offset + Vpk_pos;
pk_minus =  dc_offset + Vpk_neg;

% 2) centre the waveform (remove offset)
Vpk_centre = (pk_plus - dc_offset);   % =  Vpp_raw/2  (numerically identical)

% 3) dB wrt the 0.9 V input peak
measured_dB = 20*log10(Vpk_centre / input_pk);

% 4) theoretical curve
theo_dB = 20*log10(abs(H));

% 5) plot
figure;
plot(F, theo_dB, 'b','LineWidth',1.5); hold on;
plot(measured_freq, measured_dB,'ro','MarkerSize',8,'LineWidth',1.5);
xlabel('Frequency (Hz)');
ylabel('Magnitude (dB)');
legend('Theoretical (freqz)','Measured (oscilloscope)');
title('IIR EMA Filter – Theoretical vs Measured');
grid on;


% --- draw -3 dB horizontal line and (optional) vertical cutoff marker ---
max_gain2 = max(theo_dB);                 % 0 dB at DC for EMA
y3db      = max_gain2 - 3;                % -3 dB level
yline(y3db,'k--','-3 dB','LabelVerticalAlignment','bottom');

% (optional) also mark the -3 dB cutoff frequency with a vertical line
idx_3db = find(theo_dB <= y3db, 1, 'first');
fc = F(idx_3db);
xline(fc,'k:',['f_c \approx ' num2str(fc,'%.1f') ' Hz']);

minVal = floor(min([theo_dB(:); measured_dB(:)]))-1;
ylim([minVal 0]);

