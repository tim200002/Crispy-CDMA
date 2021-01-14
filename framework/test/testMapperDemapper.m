%%
nsymbols = 16;
type = Mappingtype.QAM;
labeling = Labeling.Gray;
numberOfBits = 2^13;
SNRindB = 20;

%binvec = (dec2bin(0:nsymbols-1) - '0')';
%bitsignal = Signal(binvec(:), 1, 'bitarray', []);

dso = Source(Sourcetype.Random, numberOfBits);
bitsignal = dso.signalout;

map = Mapper(nsymbols, type, labeling);
timesig = map.step(bitsignal);
% timesig.data
% plot(timesig.data, 'o');

ch = Channel('awgn', SNRindB);
noisysig = ch.step(timesig);

plot(noisysig.data, '.');

%%
demap = Demapper(nsymbols, type, labeling);
outsi = demap.step(timesig);
% demap.estsymbols
% outsi.data

% all(0==binvec(:) - double(bytevector2bitvector(outsi.data))) % should be true
% all(0==bitsignal.data - outsi.data) % should be true