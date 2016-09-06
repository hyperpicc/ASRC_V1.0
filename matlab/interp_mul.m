function x = interp_mul( a, b, c )
	
	a = fi( a, 1, 14, 13 );
	b = fi( b, 1, 14, 11 );
	c = fi( c, 1, 14, 11 );

	d = fi( a * b * c, 1, 24, 23 );
	x = d.int;

end

