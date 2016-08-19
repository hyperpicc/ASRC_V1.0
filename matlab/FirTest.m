function [ n ] = FirTest( ini, fct, D )

    h = fi(FIR, 1, 24, 23); h = h.int;
    j = diff(h);
    n = [];

    for i = ini+1:fct:length(h)
        c0 = h(i);
        
        h0 = -1 * ( D - 0 ) * ( D - 2 );
        h1 = 0.5 * ( D - 0 ) * ( D - 1 );
        
        j0 = 0;
        if i < length(j)
            j0 = j(i);
        end;
        
        j1 = 0;
        if i + 1 < length(j)
            j1 = j(i+1);
        end;
        j1 = j1 + j0;

	if i == ini + 1 + (fct*34)
		i-1
		i
		j0/2
		h0
		h0*j0

		j1/2
		h1
		h1*j1	

		(h0*j0 + h1*j1)

		c0
		c0 + (h0*j0 + h1*j1)
	end;
        
        n( end + 1 ) = c0 + (h0*j0 + h1*j1);
    end;

end

