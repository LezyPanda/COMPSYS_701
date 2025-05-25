% SG_filter.m
% Generate SG signal and apply programmable moving average filter (L=4 or L=8)
% Clear workspace
clear; clc;

% Define parameters (same as SG.m)
rng(0);               % Seed for reproducibility
fs  = 16000;          % Sampling frequency
f0  = 50;             % Fundamental frequency
T   = 1/f0;
cycles = 5;
duration = cycles * T;
t = 0:1/fs:duration;
w0 = 2*pi*f0;

% Generate input signal (no quantization)
signal = 0.3 + ...
         5   * sin(w0 * t + 2.5) + ...
         1.5 * sin(3 * w0 * t + 1.3) + ...
         0.75* sin(5 * w0 * t + 1.0) + ...
         0.375* sin(7 * w0 * t + 0.6) + ...
         0.1875*sin(9 * w0 * t + 0.3) + ...
         randn(size(t))*10^(-21/20);

% Choose moving average window length L (4 or 8)
L = 8;  % change to 8 as needed

% Pad signal with zeros for boundary handling
Xpad = [signal, zeros(1,L-1)];
N = length(signal);
Y   = zeros(1, N);

% Compute moving average Y(i) = mean(X(i:i+L-1))
for i = 1:N
    Y(i) = sum(Xpad(i:i+L-1)) / L;
end

% Plot original and filtered signals side by side
figure;
subplot(2,1,1);
plot(t, signal);
title('Original Signal');
xlabel('Time (s)'); ylabel('Amplitude'); grid on;

subplot(2,1,2);
stairs(t, Y, 'r');
title(['Moving Average Filtered (L=', num2str(L), ')']);
xlabel('Time (s)'); ylabel('Amplitude'); grid on;

% Store filtered result for further processing
dataFilename = sprintf('filtered_signal_L%d.mat', L);
save(dataFilename, 'Y', 't', 'L');

disp(['Filtered signal saved to ', dataFilename]);

% Quantize filtered signal for VHDL ROM (n-bit)
n = 8;  % bit depth for ROM
% scale Y to integer range [0, 2^n-1]
qY = round((Y - min(Y)) / (max(Y) - min(Y)) * (2^n - 1));
Nq = length(qY);

% Write VHDL package with filtered ROM
fidV = fopen('filter_rom_pkg.vhd','w');
fprintf(fidV,[...
'library ieee;\n' ...
'use ieee.std_logic_1164.all;\n' ...
'use ieee.numeric_std.all;\n\n' ...
'package filter_rom_pkg is\n' ...
'  constant ROM_DEPTH : integer := %d;\n' ...
'  type rom_t is array (0 to ROM_DEPTH-1) of std_logic_vector(%d downto 0);\n' ...
'  constant FILTER_ROM : rom_t := (\n'], Nq, n-1);
for idx = 1:Nq
    if idx < Nq
        fprintf(fidV,'    x"%02X",\n', qY(idx));
    else
        fprintf(fidV,'    x"%02X"\n', qY(idx));
    end
end
fprintf(fidV,[...
'  );\n' ...
'end package filter_rom_pkg;\n']);
fclose(fidV);
disp('VHDL package filter_rom_pkg.vhd generated');

% --- Correlation of filtered signal ---
nCorr = 3;  % half-window for correlation (2*nCorr total)
correlation = zeros(1, N);
for k = nCorr+1:N-nCorr
    corrVal = 0;
    for i = 0:nCorr-1
        corrVal = corrVal + Y(k+i) * Y(k-i-1);
    end
    correlation(k) = corrVal;
end

% Quantize correlation for VHDL ROM (p-bit)
p = 16;  % bit depth for correlation ROM
corrQ = round((correlation - min(correlation)) / (max(correlation) - min(correlation)) * (2^p - 1));
Nc = length(corrQ);

% Write VHDL package for correlation ROM
fidC = fopen('correlation_rom_pkg.vhd','w');
fprintf(fidC,[...    
'library ieee;\n' ...
'use ieee.std_logic_1164.all;\n' ...
'use ieee.numeric_std.all;\n\n' ...
'package correlation_rom_pkg is\n' ...
'  constant ROM_DEPTH : integer := %d;\n' ...
'  type rom_t is array (0 to ROM_DEPTH-1) of std_logic_vector(%d downto 0);\n' ...
'  constant CORRELATION_ROM : rom_t := (\n'], Nc, p-1);
for idx = 1:Nc
    if idx < Nc
        fprintf(fidC,'    x"%s",\n', dec2hex(corrQ(idx), ceil(p/4)));
    else
        fprintf(fidC,'    x"%s"\n', dec2hex(corrQ(idx), ceil(p/4)));
    end
end
fprintf(fidC,[...
'  );\n' ...
'end package correlation_rom_pkg;\n']);
fclose(fidC);
disp('VHDL package correlation_rom_pkg.vhd generated');
