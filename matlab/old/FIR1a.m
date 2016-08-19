function Hd = FIR1a
%FIR1 Returns a discrete-time filter object.

% MATLAB Code
% Generated by MATLAB(R) 8.5 and the DSP System Toolbox 9.0.
% Generated on: 29-Apr-2016 10:39:50

% Equiripple Lowpass filter designed using the FIRPM function.

% All frequency values are in Hz.
Fs = 705600;  % Sampling Frequency

N     = 1016;    % Order
Fpass = 20000;  % Passband Frequency
Fstop = 24100;  % Stopband Frequency
Wpass = 1;      % Passband Weight
Wstop = 5000000;  % Stopband Weight
dens  = 20;     % Density Factor

% Calculate the coefficients using the FIRPM function.
h1 = firpm(N, [0 Fpass Fstop Fs/2]/(Fs/2), [1 1 0 0], [Wpass Wstop], ...
           {dens});
Hd = h1;
