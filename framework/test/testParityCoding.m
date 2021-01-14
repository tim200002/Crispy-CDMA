% check minimum hamming dist

nInfoBits =3;

cod = ParityEncoder(nInfoBits);

map = Mapper(2, 'PSK', 'natural');
demap = Demapper(2, 'PSK', 'natural');


vec = dec2bin(0:((2^nInfoBits)-1), nInfoBits)-'0';
vec = vec';
vec=vec(:);
vecsi = Signal(vec, 1, 'Bits');

coded = cod.step(vecsi);



% other 'coded' variable: in ParityEncoder.step, after execution of 'coded = [ordered paritybits]';' 
coded = double(coded);
themin=Inf;
for idx=1:size(coded, 2)
    for idy = (idx+1):size(coded, 2)
        themin = min(themin,  sum(abs(coded(:, idx) - coded(:, idy)))  );
    end
end




%% check maximum correctable bits

nInfoBits =3;

cod = ParityEncoder(nInfoBits);
decod = cod.getDecoder;

nBitsCodeword = cod.nBitsCodeword;

bintable = dec2bin(0:((2^nBitsCodeword)-1), nBitsCodeword)-'0';
vec = bintable';
vec=vec(:);
vecsi = Signal(vec, 1, 'Bits'); % create signal of all possible incoming codewords

decoded = decod.step(vecsi);

res = decoded.divideInBitBlocks(nInfoBits, 'matrix', false);

result = countBiterrors(bintable(:,1:nInfoBits), res)


%% check maximum correctable bits No.2

nInfoBits = 7;
indicesToToggle = [1,4,3,5];

cod = ParityEncoder(nInfoBits);
decod = cod.getDecoder;

sour = Source('RAnd');
testsig = sour.step(1, nInfoBits);

sigcoded = cod.step(testsig);
bindat = sigcoded.selectFromBitToBitAsBitvector(1, sigcoded.lengthInBits)


bindat(indicesToToggle) = mod(bindat(indicesToToggle)+1,2);

sigcoded.data = bindat;

res = decod.step(sigcoded);

countBiterrors(testsig, res)