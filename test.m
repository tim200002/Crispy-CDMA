clear all
codeLength =4;
headerLength = 16;
 fc = 13e3;
 samplesPerSymbol=16;

 
 %% Serialize Image
serializer = ImageSerializer('TestImages\tvTestScreen32x32.jpg');
bitStream=serializer.GenerateRGBBitStream();
cdmaEncoder = CDMAEncoder(codeLength);
signal_length = 1000;
bitSignal1=Signal(double(bitStream(1,:)),1e3);
bitSignal2=Signal(double(bitStream(2,:)),1e3);
bitSignal3=Signal(double(bitStream(3,:)),1e3);

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
 modulatedSignal = pilotedSignal;



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

deserializer = ImageDeserializer();
img=deserializer.GetImageFromBitVector(resStream);