BCH_Codes = bchnumerr(127);
usedCode = 15;
CodewordLength =BCH_Codes(usedCode,1);
nBitsInfo = BCH_Codes(usedCode,2);
dmin = BCH_Codes(usedCode,3);

coderate = nBitsInfo/CodewordLength;
dBs = [-8:10];

% cod = RepetitionEncoder(1/coderate);
% decod = RepetitionDecoder(1/coderate);
% cod = ParityEncoder(nBitsInfo);
% decod = ParityDecoder(nBitsInfo);
% cod = HammingEncoder(2);
% decod = HammingDecoder(2);
cod = BCHEncoder(CodewordLength, nBitsInfo);
decod = BCHDecoder(CodewordLength, nBitsInfo);

so = Source('Random', 1e6-1);
map = Mapper(2, 'PSK', 'natural');
demap = Demapper(2, 'PSK', 'natural');
vecsi = so.step();

% vec = (dec2bin(0:((2^obj.nCodewordBits)-1), obj.nCodewordBits)-'0')';
% vecsi = Signal(vec(:), 1, 'Bits');

res = zeros(length(dBs),1);
for k = 1:length(dBs)
    dB = dBs(k);
    ch = Channel('AWGN',dB);
    
    coded = cod.step(vecsi);
    mapped = map.step(coded);
    noisy = ch.step(mapped);
    demapped = demap.step(noisy);
    out = decod.step(demapped);
    
    minCommonLength = min(out.lengthInBits, vecsi.lengthInBits);
    res(k) = mean(abs(double(out.selectFromBitToBitAsBitvector(1, minCommonLength)) - double(vecsi.selectFromBitToBitAsBitvector(1, minCommonLength))));
    disp(dB+"dB: "+res(k));
    drawnow;
end

hold on; plot(dBs-10*log10(coderate),log10(res+eps));
if exist('legend_string','var')
    legend_string{length(legend_string)+1} = sprintf('C_R %.3f, BCH(%d, %d,%d)',coderate,CodewordLength,nBitsInfo,dmin);
else
     legend_string{1} = sprintf('C_R %.3f, BCH(%d, %d,%d)',coderate,CodewordLength,nBitsInfo,dmin);
end
legend(legend_string);
xlabel('SNR in dB')
ylabel ('log_{10}(BER)')
% figure;plot(res)
% title("coderate "+cod.getCoderate)
% all(double(out.selectFromBitToBitAsBitvector(1, out.lengthInBits)) - double(vecsi.selectFromBitToBitAsBitvector(1, vecsi.lengthInBits)) == 0)