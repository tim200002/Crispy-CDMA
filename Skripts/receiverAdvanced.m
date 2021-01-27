clear all
profile on
codeLength =4;
headerLength = 16;
fc = 13e3;
samplesPerSymbol=15;
symbolRate = 0.8e3;

lastTime = now - 15*1000;
delay = 15;


%Must result in fs = 48e3
samplesPerSymbol=15;
symbolRate = 0.8e3;

audioDeviceId=6;


amplitudeScope = Scope(ScopeYAxis.Magnitude);
dbScope = Scope(ScopeYAxis.dB);
scope = Scope();

done = false;

 %% Serialize Image
serializer = AdvancedImageSerializer('TestImages/tvTestScreen.jpg', 4);
deserializer = AdvancedImageDeserializer(4,true);

while 1
%Only Send every 15 seconds

while now < lastTime + delay*1000 
    pause(1);
end

lastTime = now;

 %% Receive Signal
 source = Source(Sourcetype.Audiodevice,audioDeviceId,48000,'16-bit integer',16384);
 receivedSignal = source.step(20*48e3);



%% Demdoulation
signalToBeDemodulated = Signal(receivedSignal.data*2, receivedSignal.fs);

mixer = Mixer(Mixertype.Cosine, fc);
synchronizer = Synchronizer(fc);



%Remove Pilot
[pilotIndex, significant] = synchronizer.step(signalToBeDemodulated)
if ~significant
    break
end
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
demappedSignal = pamDemapper.stepForExactly3Signals(shortendSignal);

cdmaDecoder = CDMADecoder(codeLength);


%% Convert Back to Image
res1 = cdmaDecoder.step(demappedSignal,1);
res2 = cdmaDecoder.step(demappedSignal,2);
res3 = cdmaDecoder.step(demappedSignal,3);

resStream(1,:)=res1.data';
resStream(2,:)=res2.data';
resStream(3,:)=res3.data';


deserializer.AddIncomingSignal(resStream);

end
imshow(deserializer.img);
