function Hd = FIR

h1 = FIR1;
h2 = FIR2;
h3 = FIR3;

h1 = upsample( h1, 4 ); % 4Fs * 4Fs = 16Fs

%fvtool( dfilt.dffir( h1 ), dfilt.dffir( h2 ) );

Hd = conv( h1, h2 );
Hd = Hd( 1:length( Hd ) - 3 );
Hd = upsample( Hd, 32 ); % 16Fs * 32Fs = 512Fs

%fvtool( dfilt.dffir( Hd ), dfilt.dffir( h3 ) );

Hd = conv( Hd, h3 );
Hd = Hd( 1:length( Hd ) - 31 );
%fvtool( dfilt.dffir( Hd ) );

Hd = Hd/max(Hd);
Hd = Hd * 0.995;

%fvtool( dfilt.dffir( Hd ) );
