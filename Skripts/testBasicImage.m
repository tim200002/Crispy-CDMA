clear all
profile on
codeLength =4;
headerLength = 16;
fc = 14e3;
samplesPerSymbol=15;
symbolRate = 0.8e3;

amplitudeScope = Scope(ScopeYAxis.Magnitude);
dbScope = Scope(ScopeYAxis.dB);
scope = Scope();
analyzer = Analyzer();

 %% Serialize Image
serializer = ImageSerializer('TestImages/tvTestScreen32x32.jpg',4);
deserializer = ImageDeserializer(4);


signal = serializer.GenerateRGBBitStream();

cdmaEncoder = CDMAEncoder(codeLength);
signal_length = 1000;
bitSignal1=Signal(double(signal(1,:)),symbolRate);
bitSignal2=Signal(double(signal(2,:)),symbolRate);
bitSignal3=Signal(double(signal(3,:)),symbolRate);

%% CDMA Encode Signal
cdmaSignal1 = cdmaEncoder.step(bitSignal1,1);
cdmaSignal2 = cdmaEncoder.step(bitSignal2,2);
cdmaSignal3 = cdmaEncoder.step(bitSignal3,3);

addedSignal =cdmaSignal1+cdmaSignal2+cdmaSignal3;

pamMapper = PAMMapper(codeLength);
afterMapper = pamMapper.stepForExactly3Signals(addedSignal);


%% Add Header
header = Header(headerLength);

headerSignal = header.addHeader(afterMapper);

%% Modulation
 pilotInserter = PilotInserter(fc);
 mixer = Mixer(Mixertype.Cosine, fc);
 pulseShaper = Pulseshaper(Impulsetype.RaisedCosine, samplesPerSymbol);
 
 pulseShapedSignal = pulseShaper.step(headerSignal);
 mixedSignal = mixer.step(pulseShapedSignal);
 pilotedSignal = pilotInserter.step(mixedSignal);
 modulatedSignal = Signal(pilotedSignal.data/4,pilotedSignal.fs);
%  figure(1)
%  amplitudeScope.plotFrequencyDomain(modulatedSignal);


 %% Channel
channel = Channel('awgn', -10);

afterChannel = channel.step(modulatedSignal);

%% Demdoulation
signalToBeDemodulated = afterChannel;

mixer = Mixer(Mixertype.Cosine, fc);
synchronizer = Synchronizer(fc);



%Remove Pilot
pilotIndex = synchronizer.step(signalToBeDemodulated);
removedPilot = Signal(signalToBeDemodulated.data(pilotIndex:end), signalToBeDemodulated.fs);

%Mix Down
demixedSignal = mixer.step(removedPilot);

%Filter
load('filter.mat');
filter = Filter(demixedSignal.fs, Num);
filteredSignal = filter.step(demixedSignal);

%Extratct time Discrete Points
symbolIndex = [1: samplesPerSymbol: filteredSignal.length];
timediscreteSignal = Signal(filteredSignal.data(symbolIndex)*2, filteredSignal.fs/16);

demodulatedSignal = timediscreteSignal;

%Remove HEader
header = Header(headerLength);
[signalWithoutHeader, length] = header.removeHeaderAndGetLength(demodulatedSignal);

analyzer.plotConstellation(signalWithoutHeader, [-0.75,-0.25,0.25,0.75]);
%% CDMA Decode Signal
pamDemapper = PAMDemapper(codeLength);
demappedSignal = pamDemapper.stepForExactly3Signals(signalWithoutHeader);

cdmaDecoder = CDMADecoder(codeLength);


%% Convert Back to Image
res1 = cdmaDecoder.step(demappedSignal,1);
[bitErrorRate, numberOfErrors] = analyzer.calculateBitErrorRate(bitSignal1, res1)
analyzer.plotBitErrorRateOverTime(bitSignal1, res1, 100);
res2 = cdmaDecoder.step(demappedSignal,2);
res3 = cdmaDecoder.step(demappedSignal,3);

resStream(1,:)=res1.data';
resStream(2,:)=res2.data';
resStream(3,:)=res3.data';

figure(2)
img = deserializer.GetImageFromBitVector(resStream,32,32);

