function decimal = binaryVector2DecimalNumber(binvec)
% BINARYVECTOR2DECIMALNUMBER converts the matrix "binvec" (with dimensions
% numberEntries x bitDepth) to a vector "decimal" of decimal numbers
% e.g. binvec = [1 0 0;1 0 1;0 1 1;0 0 1]; -> output is [4;5;3;1]

    powerTwo = 2 .^ (size(binvec, 2)-1:-1:0);
    decimal = double(binvec) * powerTwo';
end