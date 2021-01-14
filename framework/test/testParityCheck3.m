nBitsInfo =7;
dbLim = 12;

% cod = ParityEncoder(nBitsInfo);
% decod = ParityDecoder(nBitsInfo);
cod = RepetitionEncoder(4);
decod = RepetitionDecoder(4);

map = Mapper(2, 'PSK', 'natural');
demap = Demapper(2, 'PSK', 'natural');

so = Source('Random', 1e6-1);
vecsi = so.step();

% OR:

% vec = dec2bin(0:((2^obj.nCodewordBits)-1), obj.nCodewordBits)-'0';
% vec = vec';
% vec=vec(:);
% vecsi = Signal(vec, 1, 'Bits');

res = zeros(dbLim+1,1);
for dbs = 0:dbLim
    ch = Channel('AWGN',dbs);
    
    coded = cod.step(vecsi);
    mapped = map.step(coded);
    noisy = ch.step(mapped);
    demapped = demap.step(noisy);
    out = decod.step(demapped);
    
%     mapped = map.step(vecsi);
%     noisy = ch.step(mapped);
%     out = demap.step(noisy);
    
    res(1+dbs) = mean(abs(double(out.selectFromBitToBitAsBitvector(1, out.lengthInBits)) - double(vecsi.selectFromBitToBitAsBitvector(1, vecsi.lengthInBits))));
    disp(dbs+" dB SNR: BER = "+res(1+dbs));
end

figure;plot(res)
% all(double(out.selectFromBitToBitAsBitvector(1, out.lengthInBits)) - double(vecsi.selectFromBitToBitAsBitvector(1, vecsi.lengthInBits)) == 0)

% histogram(sum(paritybits'))