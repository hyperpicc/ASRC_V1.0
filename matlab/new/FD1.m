function Hd = FD1
%FD1 Returns a discrete-time filter object.

% MATLAB Code
% Generated by MATLAB(R) 8.3 and the Signal Processing Toolbox 6.21.
% Generated on: 10-Aug-2016 09:46:19

% Equiripple Lowpass filter designed using the FIRPM function.

% All frequency values are in kHz.
Fs = 176400;  % Sampling Frequency

N     = 246;    % Order
Fpass = 20000;  % Passband Frequency
Fstop = 24100;  % Stopband Frequency
Wpass = 1;      % Passband Weight
Wstop = 60000;  % Stopband Weight
dens  = 16;     % Density Factor

% Calculate the coefficients using the FIRPM function.
b1  = firpm(N, [0 Fpass Fstop Fs/2]/(Fs/2), [1 1 0 0], [Wpass Wstop], ...
           {dens});
b1 = upsample( b1, 32 );
Hd1 = dfilt.dffir(b1);

% All frequency values are in kHz.
Fs = 5644800;  % Sampling Frequency

N     = 320;     % Order
Fpass = 20000;   % Passband Frequency
Fstop = 156400;  % Stopband Frequency
Wpass = 1;       % Passband Weight
Wstop = 60000;   % Stopband Weight
dens  = 16;      % Density Factor

% Calculate the coefficients using the FIRPM function.
b2  = firpm(N, [0 Fpass Fstop Fs/2]/(Fs/2), [1 1 0 0], [Wpass Wstop], ...
           {dens});
Hd2 = dfilt.dffir(b2);

Hd = conv( b1, b2 );
Hd = Hd( 1:length( Hd ) - 31 );
Hd = Hd/max(Hd);
Hd = Hd * 0.995;

%fvtool(Hd1, Hd2 );

% [EOF]
