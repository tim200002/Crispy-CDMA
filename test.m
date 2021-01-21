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

done = false;
 
 %% Serialize Image
serializer = AdvancedImageSerializer('TestImages\tvTestScreen.jpg', 4);
deserializer = AdvancedImageDeserializer(4,false);

while done == false

[signal, done]=serializer.getNextSignal();
if done
    break;
end
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
afterMapper = pamMapper.step(addedSignal);

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
 %amplitudeScope.plotFrequencyDomain(modulatedSignal);



%% Channel
channel = Channel('awgn', 3);

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

deserializer.AddIncomingSignal(resStream);

end
profsave
profile off
imshow(deserializer.img);