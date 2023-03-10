clear all
codeLength =4;
headerLength = 20;
fc = 13e3;
samplesPerSymbol=15;
audioDeviceId=6;

magnitudeScope = Scope(ScopeYAxis.Magnitude);
scope = Scope();


 
 %% Receive Signal
 source = Source(Sourcetype.Audiodevice,audioDeviceId,48000,'16-bit integer',16384);
 receivedSignal = source.step(30*48e3);
    scope.plotTimeDomain(receivedSignal);



%% Demdoulation
signalToBeDemodulated = Signal(receivedSignal.data, receivedSignal.fs);
scope.plotTimeDomain(signalToBeDemodulated);
mixer = Mixer(Mixertype.Cosine, fc);
synchronizer = Synchronizer(fc);



%Remove Pilot
[pilotIndex, significant] = synchronizer.step(signalToBeDemodulated)
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

shortendSignal = Signal(signalWithoutHeader.data(1:length), signalWithoutHeader.fs)



%% CDMA Decode Signal
pamDemapper = PAMDemapper(codeLength);
demappedSignal = pamDemapper.step(shortendSignal);

cdmaDecoder = CDMADecoder(codeLength);


%% Convert Back to Image
res1 = cdmaDecoder.step(demappedSignal,1);
res2 = cdmaDecoder.step(demappedSignal,2);
res3 = cdmaDecoder.step(demappedSignal,3);

resStream(1,:)=res1.data';
resStream(2,:)=res2.data';
resStream(3,:)=res3.data';

figure(2)
deserializer = ImageDeserializer(4);
img=deserializer.GetImageFromBitVector(resStream,32,32);

%% Compare
compare = true;
if compare
load('Variables/bitSignal1.mat');
load('Variables/bitSignal2.mat');
load('Variables/bitSignal3.mat');
analyzer = Analyzer();
analyzer.plotBitErrorRateOverTime(res1,bitSignal1,100);
end

