function bytevec = bitvector2bytevector(bitvec)
% BITVECTOR2BYTEVECTOR converts a binary vector "bitvec" to an uint8 column 
% vector "bytevec"
% e.g. bitvector2bytevector([1 0 1 1 1 0 0 0 1 1 1 0 1 0 1 1]) -> [184;234]
% if length of bitvec is not a multiple of 8, the remaining bits are
% interpreted as the UPPER bits of a byte

bitvec = [bitvec(:); zeros(7 - mod(length(bitvec) - 1, 8), 1)]; % fill with zeros that length is multiple of 8
byteMat = reshape(bitvec(:), 8, length(bitvec) / 8)';
bytevec = uint8(binaryVector2DecimalNumber(byteMat));

end