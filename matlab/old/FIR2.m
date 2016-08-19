function Hd = FIR2
%FIR2 Returns a discrete-time filter object.

% MATLAB Code
% Generated by MATLAB(R) 8.3 and the DSP System Toolbox 8.6.
% Generated on: 26-Jul-2016 12:44:49

% Equiripple Lowpass filter designed using the FIRPM function.

% All frequency values are in kHz.
Fs = 705.6;  % Sampling Frequency

N     = 32;      % Order
Fpass = 20;      % Passband Frequency
Fstop = 156.4;   % Stopband Frequency
Wpass = 1;       % Passband Weight
Wstop = 100000;  % Stopband Weight
dens  = 20;      % Density Factor

% Calculate the coefficients using the FIRPM function.
b  = firpm(N, [0 Fpass Fstop Fs/2]/(Fs/2), [1 1 0 0], [Wpass Wstop], ...
           {dens});
Hd = b;

% [EOF]
