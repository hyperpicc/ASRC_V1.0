function x = filter_lookup( h, i )

    i = mod( i, length(h)-1 ) + 1;
    x = double(h( i ));

end

