%%___________________________ PARAMETERS __________________________________
path = "D:\ABLAGE\Dokumente\Studium\Bachelorarbeit\BPuelMatlabModules\src\test\";
inputText = "testPlotEyeDiagram.m";
textOutFile = "textReceived.txt";
nsymbols = 2;
type = Mappingtype.PSK;
labeling = Labeling.Gray;
bitRate = 6000;
pulsetype = Impulsetype.Rectangular;
sampleRate = 48000;
%% ========================================================================

sco = Scope();
symbolRate = bitRate / log2(nsymbols);
samplesPerSymbol = round(sampleRate / symbolRate);

%% DATA GENERATION
dso = Source(Sourcetype.File, char(path + inputText));
bitsignal = dso.signalout.selectFromBitToBit(1, 1000);
bitsignal.fs = bitRate;

%% MAPPING
map = Mapper(nsymbols, type, labeling);
symbolsignal = map.step(bitsignal);

% figure;sco.yAxis = 'real';sco.plotTimeDomain(symbolsignal);
% figure;sco.yAxis = 'imag';sco.plotTimeDomain(symbolsignal);

%% PULSESHAPEING
psh = Pulseshaper(pulsetype, samplesPerSymbol);
%psh.fil = RaisedCosineFilter(sampleRate, 160,0.6,samplesPerSymbol);
% figure; plot(psh.fil.data);

shapedsig = psh.step(symbolsignal); % OR
% shapedsig = psh.stepAndPlot(symbolsignal);

 figure;sco.plotEyeDiagram(shapedsig, 1/symbolRate, 0);

% psh2= Pulseshaper('RootRaised', samplesPerSymbol);
% figure; shapedsig2 = psh2.stepAndPlot(symbolsignal);

% figure;sco.yAxis = 'real';sco.plotTimeDomain(shapedsig);
% figure;sco.yAxis = 'imag';sco.plotTimeDomain(shapedsig);


%  figure; testsymbolsignal = sampleWithPlot(shapedsig, symbolRate, 0);
%  sco.plotScatter(testsymbolsignal);

% figure;sco.yAxis = 'db';sco.plotFrequencyDomain(shapedsig);
