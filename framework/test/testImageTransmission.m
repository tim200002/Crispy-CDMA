%%___________________________ PARAMETERS __________________________________
path = "c:\users\ephraim fuchs\desktop\";
inputImg = "inputImg40.JPG";
outputImg = "outputImg.JPG";
nsymbols = 16;
type = Mappingtype.QAM;
labeling = Labeling.Gray;
bitRate = 6000;
SNRdB = 15;
%% ========================================================================
sco = Scope();
nBitsCodeword = 15;
nBitsInfo = 5;
cod = BCHEncoder(nBitsCodeword, nBitsInfo);
decod = BCHDecoder(nBitsCodeword, nBitsInfo);
% cod = ParityEncoder(nBitsInfo);
% decod = ParityDecoder(nBitsInfo);
% cod = RepetitionEncoder(round(nBitsCodeword / nBitsInfo));
% decod = RepetitionDecoder(round(nBitsCodeword / nBitsInfo));
symbolRate = bitRate / log2(nsymbols);
samplesPerSymbol = round(sampleRate / symbolRate);
%% DATA GENERATION
dso = Source(Sourcetype.File, path + inputImg);
bitsignal = dso.signalout;
bitsignal.fs = bitRate;
%% CHANNEL CODING
% codedsig = cod.step(bitsignal);
codedsig = bitsignal; % without channel coding
%% MAPPING
map = Mapper(nsymbols, type, labeling);
symbolsignal = map.step(codedsig);
disp("message length: "+symbolsignal.length+" symbols");
%% AWGN
ch = Channel('AWGN', SNRdB);
noisysig = ch.step(symbolsignal);
%% DEMAPPING
demap = Demapper(nsymbols, type, labeling);
demappedsig = demap.step(noisysig);
%% CHANNEL DECODING
% decodedsig = decod.step(demappedsig);
decodedsig = demappedsig;
%% SAVE IT
dsi = Sink();
dsi.step(decodedsig);
dsi.saveBytesToFile(path + outputImg);