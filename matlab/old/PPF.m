function Hd = PPF

h1 = PPF1;
h2 = PPF2;

h1 = upsample( h1, 32 ); % 16Fs * 32Fs = 512Fs

%fvtool( dfilt.dffir( h1 ), dfilt.dffir( h2 ) );

Hd = conv( h1, h2 );
Hd = Hd( 1:length( Hd ) - 31 );

Hd = Hd/max(Hd);
Hd = Hd * 0.995;

%fvtool( dfilt.dffir( Hd ) );
