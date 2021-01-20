clear all
codeLength =4;
headerLength = 16;
fc = 13e3;
samplesPerSymbol=16;
audioDeviceId=1;
 
 %% Receive Signal
 sink = Sink(Sourcetype.Audiodevice,audioDeviceId,48000,'16-bit integer',4096);
 receivedSignal = source.step();


%% Demdoulation
signalToBeDemodulated = receivedSignal;

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


%% CDMA Decode Signal
pamDemapper = PAMDemapper(codeLength);
demappedSignal = pamDemapper.step(signalWithoutHeader);

cdmaDecoder = CDMADecoder(codeLength);


%% Convert Back to Image
res1 = cdmaDecoder.step(demappedSignal,1);
res2 = cdmaDecoder.step(demappedSignal,2);
res3 = cdmaDecoder.step(demappedSignal,3);

resStream(1,:)=res1.data';
resStream(2,:)=res2.data';
resStream(3,:)=res3.data';

deserializer = ImageDeserializer();
img=deserializer.GetImageFromBitVector(resStream)

