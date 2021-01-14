% comparison between source (JPEG) and channel coded (1) and unencoded (2) transmission
%%___________________________ PARAMETERS __________________________________
path = "";
inputImg = "testImage.png";
nsymbols = 16;
type = Mappingtype.QAM;
labeling = Labeling.Gray;
bitRate = 6000;
SNRdB = 4;
%% ========================================================================
sco = Scope();
symbolRate = bitRate / log2(nsymbols);
%% DATA GENERATION
sou = Source(Sourcetype.Imagefile, path + inputImg);
bitsignal1 = JPEGCompressImage(path+inputImg, 30);
bitsignal2 = sou.signalout;
bitsignal1.fs = bitRate;
bitsignal2.fs = bitRate;

compressRate = bitsignal1.lengthInBits / bitsignal2.lengthInBits;
disp("JPEG compressing rate: "+compressRate);
%% CHANNEL CODING
% cod = HammingEncoder(3);
% decod = HammingDecoder(3);
% nBitsCodeword = 255;
% nBitsInfo = ceil(nBitsCodeword * compressRate);
% cod   = BCHEncoder(nBitsCodeword, nBitsInfo);
% decod = BCHDecoder(nBitsCodeword, nBitsInfo);
nBitsInfo = ceil(2 / compressRate - 1); % formula for parity encoder coderate approximately equal to  compress rate
cod = ParityEncoder(nBitsInfo);
decod = ParityDecoder(nBitsInfo);
% cod = RepetitionEncoder(round(nBitsCodeword / nBitsInfo));
% decod = RepetitionDecoder(round(nBitsCodeword / nBitsInfo));
disp("code rate (should be greater than JPEG compressrate): "+cod.getCoderate); % cod = ParityEncoder(128);cod.getCoderate
codedsig1 = cod.step(bitsignal1); % JPEG with Channel coding; raw image without channel coding to get nearly equal length
%% MAPPING
map = Mapper(nsymbols, type, labeling);
symbolsignal1 = map.step(codedsig1);
symbolsignal2 = map.step(bitsignal2);
disp("message length JPEG: "+symbolsignal1.length+" symbols");
disp("message length raw image data: "+symbolsignal2.length+" symbols");
disp("thus ratio JPEG/RAW: "+symbolsignal1.length / symbolsignal2.length);
%% AWGN
ch = Channel('AWGN', SNRdB);
noisysig1 = ch.step(symbolsignal1);
noisysig2 = ch.step(symbolsignal2);
disp("passed through AWGN");
% DEMAPPING
demap = Demapper(nsymbols, type, labeling);
demappedsig1 = demap.step(noisysig1);
demappedsig2 = demap.step(noisysig2);
disp("demapped symbols");
% CHANNEL DECODING
decodedsig1 = decod.step(demappedsig1);
disp("decoded channel");
% PLOT IT
subplot(2, 1, 1);
image(JPEGDecompressImage(decodedsig1))

subplot(2, 1, 2);
ordered = reshape(demappedsig2.data, 3, 750,1000);
ordered = (shiftdim(ordered, 1));
image(ordered);
disp("ready");