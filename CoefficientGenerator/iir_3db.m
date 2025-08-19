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
% measured_amplitude_raw = [2.97,3.096,3.204,3.21,3.21,3.206,3.190,2.730,2.241,1.868,1.494,1.307,1.121,0.934,0.747,0.76467,0.7468,0.560,0.560,0.560,0.5601,0.5602,0.560,0.560,0.560,0.560,0.560,0.560,0.560,0.560];

% measured_amplitude_raw = [3.024,3.100,3.216,3.226,3.230,3.230,3.224,2.910,2.311,1.838,1.542,1.308,1.121,0.9343,0.8408,0.7907,0.7477,0.6541,0.6544,0.5607,0.5608,0.5607,0.5606,0.5139,0.5606,0.5607,0.5608,0.5606,0.6544,0.7008];
% measured_amplitude_raw = [0.9808,0.9808,0.9808,1.027,1.027,1.074,1.074,1.121,1.168,1.168,1.261,1.261,1.3,1.459,1.6,1.67,.1823,1.960,2.137,2.324,2.513,2.7,2.8,2.809,2.798,2.653,2.466,2.2,2.012,1.849];
% measured_amplitude_raw = [3.117,3.194,3.224,3.226,3.228,3.230,3.226,3.016,2.410,1.927,1.588,1.160,1.211,1.028,0.9343,0.8408,0.7477,0.7475,0.6543,0.6074,0.5606,0.6074,0.6073,0.6073,0.6073,0.5606,0.6075,0.6542,0.701,0.7476];
% measured_amplitude_raw = [2.509,2.584,2.809,3.124,3.216,3.210,3.036,2.450,1.965,1.544,1.261,1.028,0.9343,0.7474,0.7005,0.6538,0.5603,0.5604,0.5136,0.4667,0.4667,0.4667,0.4668,0.4609,0.4667,0.4668,0.4668,0.5135,0.5603,0.5603];
% measured_amplitude_raw = [3.056,3.180,3.212,3.225,3.225,3.225,3.225,2.910,2.280,1.883,1.540,1.261,1.027,0.9808,0.841,0.747,0.700,0.7006,0.6076,0.6076,0.6076,0.5608,0.561,0.561,0.561,0.5609,0.6076,0.6077,0.6075,0.7006];
% measured_amplitude_raw = [1.783,1.873,1.965,2.030,2.059,2.070,1.897,1.694,1.308,1.028,0.8411,0.7475,0.6071,0.5605,0.4671,0.4206,0.3728,0.3728,0.3728,0.2803,0.2803,0.2803,0.2803,0.2803,0.2803,0.2803,0.2803,0.3271,0.3738,0.3738];
% measured_amplitude_raw = [3.048,3.150,3.211,3.216,3.224,3.229,3.2226,2.909,2.280,1.844,1.507,1.290,1.060,0.9441,0.8635,0.8244,0.8210,0.8170,0.8207,0.7908,0.7599,0.7599,0.780,0.7931,0.8809,0.7909,0.7909,0.7909,0.7909,0.7909];
% measured_amplitude_raw = [0.9809,0.9810,1.027,1.027,1.027,1.027,1.027,1.121,1.121,1.215,1.215,1.308,1.384,1.495,1.590,1.690,1.787,1.977,2.096,2.350,2.544,2.723,2.797,2.797,2.756,2.540,2.392,2.205,2.003,1.916];

% Best value until now
% measured_amplitude_raw = [2.925,2.756,2.529,2.400,2.130,2.089,1.847,1.682,1.568,1.463,1.355,1.261,1.215,1.168,1.121,1.074,1.074,1.028,0.9808,0.9808,0.9808,0.9808,0.9342,0.9342,0.9342,0.9808,0.9808,0.9808,0.9808,1.028];
% ////////////////////

%For FMAC - IIR 
measured_amplitude_raw = [2.963,2.917,2.861,2.701,2.597,2.438,2.348,2.285,2.211,2.120,2.020,1.924,1.780,1.826,1.739,1.736,1.697,1.652,1.592,1.541,1.544,1.552,1.540,1.549,1.549,1.549,1.549,1.549,1.642,1.638];
% For CMSIS - IIR
measured_amplitude_raw = [2.967,2.918,2.780,2.700,2.606,2.453,2.348,2.280,2.215,2.122,2.031,1.850,1.745,1.828,1.742,1.735,1.682,1.650,1.639,1.541,1.540,1.542,1.553,1.552,1.554,1.554,1.541,1.541,1.641,642];


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



