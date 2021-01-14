function bitvec = bytevector2bitvector(bytevec)
% BYTEVECTOR2BITVECTOR outputs an uint8 column vector "bitvec" 
% (with length = 8*length(bytevec)) containing only zeros/ones
% every entry of bytevec is converted to a 8 bit vector (e.g. 2 -> 00000010
% and not 2 -> 10)
% this vectors are concatenated

bitvec = uint8(dec2bin(bytevec, 8) - '0');
bitvec = bitvec'; % because the following line's command selects column wise
bitvec = bitvec(1:end)'; % to column vector
end