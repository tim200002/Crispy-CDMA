function grayCodeSeries = getGrayCodeSeries(nBits)
% GETGRAYCODESERIES calculates the gray code series with nBits.
% Output is a 2^nBits x nBits matrix of 0/1 (type: double).

% correct to next higher even number
% (because generation matrix works only with even bit lengths)
nBitsEven = 2 * ceil(nBits / 2);

% build generation matrix:
generationMatrix = eye(nBitsEven-1);
generationMatrix = [zeros(nBitsEven-1, 1) generationMatrix; zeros(1, nBitsEven)];
generationMatrix = generationMatrix + eye(nBitsEven);

grayCodeSeries = dec2bin(0:2^nBits-1, nBitsEven) - '0';
grayCodeSeries = mod(grayCodeSeries * generationMatrix, 2);

if(nBitsEven ~= nBits)
    % select relevant columns
    grayCodeSeries = grayCodeSeries(:, 2:end);
end

end