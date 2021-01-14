function antiGrayCodeSeries = getAntiGrayCodeSeries(nBits)
% GETANTIGRAYCODESERIES calculates the anti gray code number series
% output is a 2^nBits x nBits matrix of 0/1 (type: double)

graySeries = [zeros(2^(nBits-1), 1) getGrayCodeSeries(nBits - 1)];

graySeriesInv = zeros(2^(nBits-1), nBits);
graySeriesInv(graySeries == 0) = 1;

antiGrayCodeSeries = zeros(2^nBits, nBits);
antiGrayCodeSeries(1:2:2^nBits, :) = graySeries(1:end, :);
antiGrayCodeSeries(2:2:2^nBits, :) = graySeriesInv(1:end, :);

end

% 
% % build generation matrix:
% genMat = triu(ones(nBitsEven), 1);
% genMat(1, end) = 0;
% genMat(end, :) = 1;
% 
% binaryVectors = dec2bin(0:2^nBits-1, nBitsEven) - '0';
% binaryVectors = mod(binaryVectors * genMat, 2);