function x = interp_mul( a, b, c )
		
	b = fi( b, 1, 13, 10 );
	c = fi( c, 1, 13, 10 );

	d = fi( a * b.double * c.double, 1, 18, 17 );
	x = d.double;

end

