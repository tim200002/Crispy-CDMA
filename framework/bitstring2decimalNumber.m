function decimal = bitstring2decimalNumber(stringMatrix)
% BITSTRING2DECIMALNUMBER converts a string matrix (not char arrays) of 
% binary numbers to a matrix of decimal numbers with same dimension
% e.g. stringMatrix = ["100","101";"011","001"]; -> output is [4,5;3,1]

stringvec = stringMatrix(:);
decimal = reshape(binaryVector2DecimalNumber(char(stringvec) - '0'), size(stringMatrix, 1), size(stringMatrix, 2));
end