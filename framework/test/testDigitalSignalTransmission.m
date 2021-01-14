%%___________________________ PARAMETERS __________________________________
path = "";
inputText = "testDigitalSignalTransmission.m";
textOutFile = "textReceived.txt";
audioOutFile = "testDigitalOutput.wav";
audioInFile = "testDigitalRec.wma";%"testDigitalRecconv.wav";%"testDigitalRec.wma";
nsymbols = 16;
type = Mappingtype.QAM;
labeling = Labeling.Gray;
bitRate = 6000;
pulsetype = Impulsetype.RaisedCosine;
sampleRate = 96000;
mixtype = Mixertype.Complex;
carrierFreq = 6000;
% nSyncBits = 128; % number of synchronization bits
%% ========================================================================

sco = Scope();

symbolRate = bitRate / log2(nsymbols);
samplesPerSymbol = round(sampleRate / symbolRate);

%% DATA GENERATION
dso = Source(Sourcetype.File, path + inputText);
bitsignal = dso.signalout;
bitsignal.fs = bitRate;

% OR random data:
% dso = Source(Sourcetype.Random);
% bitsignal = dso.step(2^13);
% bitsignal.fs = bitRate;

% append sync bits:
% load('syncBits128.mat', 'syncbits')
% syncbits.fs = bitRate;
% bitsignal = [syncbits; bitsignal];


%% MAPPING
map = Mapper(nsymbols, type, labeling);
symbolsignal = map.step(bitsignal);

% figure;sco.yAxis = 'real';sco.plotTimeDomain(symbolsignal);
% figure;sco.yAxis = 'imag';sco.plotTimeDomain(symbolsignal);

%% PULSESHAPEING
psh = Pulseshaper(pulsetype, samplesPerSymbol);
shapedsig = psh.step(symbolsignal); % OR
% shapedsig = psh.stepAndPlot(symbolsignal);

% psh2= Pulseshaper('RootRaised', samplesPerSymbol);
% figure; shapedsig2 = psh2.stepAndPlot(symbolsignal);

% figure;sco.yAxis = 'real';sco.plotTimeDomain(shapedsig);
% figure;sco.yAxis = 'imag';sco.plotTimeDomain(shapedsig);

% figure;sco.plotEyeDiagram(shapedsig, 1/symbolRate, 0);

%  figure; testsymbolsignal = sampleWithPlot(shapedsig, symbolRate, 0);
%  sco.plotScatter(testsymbolsignal);

% figure;sco.yAxis = 'db';sco.plotFrequencyDomain(shapedsig);

%% MIXING
mixcomplex = Mixer(Mixertype.Complex, carrierFreq);
mixedsig = mixcomplex.step(shapedsig);

% figure;sco.yAxis = 'realandimag';sco.plotTimeDomain(mixedsig);
% figure;sco.yAxis = 'real';sco.plotFrequencyDomain(real(mixedsig));
% figure;sco.yAxis = 'db';  sco.plotFrequencyDomain(real(mixedsig));

%% WRITE AUDIO FILE
dsi2 = Sink();
dsi2.outputGaindB = -3;
dsi2.saveToAudioFile(mixedsig, path + audioOutFile);
dsi2.playAudio(mixedsig);

%% PLAY AND RECORD AUDIO % not usable
samplesPerFrame = 4096;
devsi = Sink(4, sampleRate, '16-bit integer');
devso = Source(Sourcetype.Audiodevice, 1, sampleRate, '16-bit integer', samplesPerFrame);
audsink = Sink();
for idx = 0:(floor(mixedsig.length / samplesPerFrame) - 1)
    devsi.step(mixedsig.selectFromTo(idx * samplesPerFrame + 1, idx * samplesPerFrame + samplesPerFrame));
    sig = devso.step();
    audsink.step(sig);
end
devsi.releaseDevice;
devso.releaseDevice;
aud = audsink.signalin; 
fs_rec = sampleRate;

figure; sco.plotTimeDomain(aud);

%% RECORD AUDIO
devso = Source(Sourcetype.Audiodevice, 1, sampleRate, '16-bit integer', 4096);
audsink = Sink();
while(1) % use Ctrl+C to stop recording
    sig = devso.step();
    audsink.step(sig);
end
devso.releaseDevice;
aud = audsink.signalin;
fs_rec = sampleRate;

%% READ AUDIO FROM FILE
[aud, fs_rec] = audioread(path + audioInFile);
aud = aud(:, 1); % only mono
aud = Signal(aud, fs_rec);

%% check input signal
player = audioplayer(aud.data, aud.fs);
player.play;
player.pause;

% figure;sco.yAxis = 'real';sco.plotTimeDomain(aud);
% figure;sco.yAxis = 'real';      sco.plotFrequencyDomain(aud);
% figure;sco.yAxis = 'db';        sco.plotFrequencyDomain(aud);

%% OPTIONAL: BYPASS
aud = real(mixedsig);

%% AWGN CHANNEL
ch = Channel('AWGN', 10);
aud = ch.step(aud);

%% SYNCHRONIZATION
% generate sync signal to compare
symbolsyncsig = map.step(syncbits);
shapedsyncsig = psh.step(symbolsyncsig, sampleRate);
mixedsyncsig = mixcomplex.step(shapedsyncsig);

signal1 = aud.data;
signal2 = mixedsyncsig.real.data;

signal1 = signal1 - mean(signal1);
signal2 = signal2 - mean(signal2);
signal1 = signal1 / max(signal1);
signal2 = signal2 / max(signal2);
correl  = xcorr(signal1, signal2); 
% figure; plot(real(correl))
[~, maxindx] = max(correl);
lag = length(signal1) - maxindx;

signal1 = signal1(1 - lag : end);
aud = Signal(signal1, aud.fs);

% figure;plot(real(signal1));figure;plot(real(signal2));
%% offsets tester
figure;trysignal = Signal(aud.data, fs_rec, 'Valueconti');checkOffsetWithScatterPlot2(trysignal, symbolRate, carrierFreq, psh.fil); % steps until sampling:

phaseoffset = 2 * pi * 0.97;
aud.fs = sampleRate + 0.438;
samplingoffset = 0.90;

%% MIXING
mix2 = Mixer(Mixertype.ComplexConjugate, carrierFreq);
mix2.memoryPhase = phaseoffset;
mixedrecsignal = mix2.step(aud);

% figure;sco.yAxis = 'real'; sco.plotTimeDomain(mixedrecsignal);
% figure;sco.yAxis = 'magni';sco.plotFrequencyDomain(mixedrecsignal);
% figure;sco.yAxis = 'db';   sco.plotFrequencyDomain(mixedrecsignal);

%% LOW PASS FILTERING
lpf = psh.fil; % for matched filter
demodrecsignal = lpf.step(mixedrecsignal);

% figure;sco.yAxis = 'real';sco.plotTimeDomain(demodrecsignal);
% figure;sco.yAxis = 'db';sco.yLimits = 1.3 * symbolRate / 2 * [-1 1];sco.plotFrequencyDomain(demodrecsignal);
% figure;sco.yAxis = 'db';sco.plotFrequencyDomain(lpf);

%% SAMPLING
% figure;sco.plotEyeDiagram(demodrecsignal, 1/symbolRate, samplingoffset);
% vs. figure;sco.plotEyeDiagram(shapedsig, 1/symbolRate, 0);

sam = Sampler(1, samplesPerSymbol);
sampled = sam.downsample(demodrecsignal, samplingoffset);
% figure; sampled = sam.downsampleWithPlot(demodrecsignal, samplingoffset);

% figure;sco.plotScatter(sampled);
% figure;stem(sampled.real.data);
%% AMPLITUDE CORRECTION
sorted = sort(sampled.real.data); % plot(sorted);
meanmax = mean(sorted(round(0.97 * end) : end));
correctedsignal = sampled * (max(real(map.symbols(:))) / meanmax);

% figure;map.plotConstellation;
% figure;stem(correctedsignal.real.data) % vs. figure; stem(symbolsignal.real.data, 'o')
% figure;histogram(correctedsignal.real.data);
%% DEMAPPING
demap = Demapper(nsymbols, type, labeling);
bitsignalrecon = demap.step(correctedsignal);

%% BIT SYNCHRONIZATION
bitsin  = double(bitsignal.selectFromBitToBitAsBitvector(1, 5000-1)');
bitsout = double(bitsignalrecon.selectFromBitToBitAsBitvector(1, 4000-1)');
bitsin  = bitsin - 0.5;%mean(bitsin);
bitsout = bitsout - 0.5;%mean(bitsout);
% bitsin  = bitsin / max(bitsin);
% bitsout = bitsout / max(bitsout);
correl  = xcorr(bitsin, bitsout);
figure;plot(correl); % expect peak at length(bitsin) - lag

% determine lag:
[~, maxindx] = max(correl);
lag = length(bitsin) - maxindx

% check lag with: ( blue circles and red diamonds have to be over each other)
% beginBit = 1;
% numberOfBits = 1500;
% figure;stem(lag+1:numberOfBits+lag, bitsin(beginBit : beginBit+numberOfBits-1), 'MarkerEdgeColor','blue', 'MarkerSize', 10);%original signal in blue
% hold on;
% stem(1:numberOfBits, bitsout(beginBit : beginBit+numberOfBits-1), 'diamondr');%recon signal in red
% hold off;

% remove lag:
if lag < 0
    bitsignalshifted = [Signal(ones(abs(lag), 1), bitsignalrecon.fs, 'Bits'); bitsignalrecon];
else
    bitsignalshifted = bitsignalrecon.selectFromBitToBit(lag + 1, bitsignalrecon.lengthInBits);
end

biterrorrate = countBiterrors(bitsignal, bitsignalshifted) / bitsignal.lengthInBits

%% SHOW IT
char(bitvector2bytevector(bitsignalshifted.selectFromBitToBitAsBitvector(1, bitsignalshifted.lengthInBits))')

%% SAVE IT
dsi = Sink();
dsi.step(bitsignalshifted);
dsi.saveBytesToFile(path + textOutFile);