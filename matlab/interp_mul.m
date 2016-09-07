function x = interp_mul( a, b, c, wid )
	
	a = fi( a, 1, 18, 17 );
	b = fi( b, 1, 18, 15 );
	c = fi( c, 1, 18, 15 );

	d = fi( a * b * c, 1, wid, wid-1 );
	x = d.int;

end

