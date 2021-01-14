fc= 4e3;
fs = 48e3;
PilotAdder = PilotInserter(fc);
Sync = Synchronizer(fc);


testSignal = Signal(0.5*sin(2*pi*4.5e3/48e3*(1:10000)),fs);PilotAdder
testSignalPiloted = PilotAdder.step(testSignal);
figure(1);
subplot(3,1,1);

test = testSignalPiloted.data;
pwelch(test,[],[],[],fs);
subplot(3,1,2);
plot(test);

timeshift = randi([1000,2000],1,1);
Signalnoise = Signal(randn(timeshift,1),fs);

testSignalPilotedNoise = [Signalnoise; testSignalPiloted];

subplot(3,1,3);
plot(testSignalPilotedNoise.data);

[starindex,valid]=Sync.step(testSignalPilotedNoise);

errorindex = starindex-timeshift;
