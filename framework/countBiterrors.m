function result = countBiterrors(binsignal1, binsignal2)
% COUNTBITERRORS counts the number of positions, where the Signal object
% "binsignal1" differs to "binsignal2".
% If lengths of the signals do not match, count only the first biterrors
% to the length of the shorter signal.

if isa(binsignal1, 'Signal') && isa(binsignal2, 'Signal')
    commonLength = min(binsignal1.lengthInBits, binsignal2.lengthInBits);
    bitsig1 = binsignal1.selectFromBitToBitAsBitvector(1, commonLength);
    bitsig2 = binsignal2.selectFromBitToBitAsBitvector(1, commonLength);
    result = sum(xor(bitsig1, bitsig2));
else % isa(binsignal1, 'double') && isa(binsignal2, 'double')
    commonLength = min(length(binsignal1), length(binsignal2));
    result = sum(xor(binsignal1(1:commonLength), binsignal2(1:commonLength)));
end
end