
nBitsSim = 1e5;
dBProbes = -10:15;


% trier for coderates:
% mat=bchnumerr(511); [mat(:,2) ./ mat(:,1), mat(:,2)]


%% approx. coderate = 2/3 -> BCH is much better
nBitsSim = 1e6;
paren=ParityEncoder(2); paren.getCoderate
bchen = BCHEncoder(511,340); bchen.getCoderate

%% approx. coderate = 0.5 -> BCH is better from 11dB
nBitsSim = 1e5;
paren=ParityEncoder(3); paren.getCoderate
bchen = BCHEncoder(511,259); bchen.getCoderate
repen = RepetitionEncoder(2); repen.getCoderate

%% approx. coderate = 1/3 -> BCH is better
paren=ParityEncoder(5); paren.getCoderate
bchen = BCHEncoder(15,5); bchen.getCoderate
repen = RepetitionEncoder(3); repen.getCoderate

%% approx. coderate = 0.25 -> BCH is better
paren=ParityEncoder(7); paren.getCoderate
bchen = BCHEncoder(63,16); bchen.getCoderate
repen = RepetitionEncoder(4); repen.getCoderate

%% approx. coderate = 0.095 -> BCH is better
paren=ParityEncoder(20); paren.getCoderate
bchen = BCHEncoder(511,49); bchen.getCoderate

%% approx. coderate = 0.054 -> parity is better in a range
nBitsSim = 1e4;
paren=ParityEncoder(36); paren.getCoderate
bchen = BCHEncoder(511,28); bchen.getCoderate
repen = RepetitionEncoder(18); repen.getCoderate

%% approx.  coderate = 0.01 -> parity is better
nBitsSim = 1e3;
paren=ParityEncoder(180); paren.getCoderate
bchen = BCHEncoder(1023,11); bchen.getCoderate
repen = RepetitionEncoder(100); repen.getCoderate
% ers1.errorratios = 0.4853    0.4817    0.4811    0.4747    0.4715    0.4562    0.4349    0.4152    0.3577    0.2994    0.2262    0.1865    0.1272    0.0786    0.0417    0.0198    0.0070
% ers2.errorratios = 0.4647    0.4599    0.4544    0.4495    0.4392    0.4417    0.4195    0.4217    0.3999    0.3970    0.3827    0.3711    0.3474    0.3277    0.3130    0.2941    0.2655



paren.getMinimumHammingDist
bchen.getMinimumHammingDist
repen.getMinimumHammingDist




figure;
ers1 = ErrorratioSimulator(nBitsSim,Mapper(64, 'QAM','GRay'),paren);
ers1.dBProbes = dBProbes;
ers1.simulateAndPlot('BER');

hold on;
ers2 = ErrorratioSimulator(nBitsSim,Mapper(64, 'QAM','GRay'),bchen);
ers2.dBProbes = dBProbes;
ers2.simulateAndPlot('BER')















%% coderate 0.5; repetition encoder; parity is much better
nBitsSim = 1e5;
paren=ParityEncoder(3); paren.getCoderate
repen = RepetitionEncoder(2); repen.getCoderate
figure;
ers1 = ErrorratioSimulator(nBitsSim,Mapper(64, 'QAM','GRay'),paren);
ers1.dBProbes = dBProbes;
ers1.simulateAndPlot('BER');
hold on;
ers2 = ErrorratioSimulator(nBitsSim,Mapper(64, 'QAM','GRay'),repen);
ers2.dBProbes = dBProbes;
ers2.simulateAndPlot('BER')


%% coderate 0.25; repetition encoder -> parity is better
nBitsSim = 1e5;
paren=ParityEncoder(7); paren.getCoderate
repen = RepetitionEncoder(4); repen.getCoderate
figure;
ers1 = ErrorratioSimulator(nBitsSim,Mapper(64, 'QAM','GRay'),paren);
ers1.dBProbes = dBProbes;
ers1.simulateAndPlot('BER');
hold on;
ers2 = ErrorratioSimulator(nBitsSim,Mapper(64, 'QAM','GRay'),repen);
ers2.dBProbes = dBProbes;
ers2.simulateAndPlot('BER')


%% coderate 1/11; repetition encoder -> rep is much better
nBitsSim = 1e4;
paren=ParityEncoder(21); paren.getCoderate
repen = RepetitionEncoder(11); repen.getCoderate
figure;
ers1 = ErrorratioSimulator(nBitsSim,Mapper(64, 'QAM','GRay'),paren);
ers1.dBProbes = dBProbes;
ers1.simulateAndPlot('BER');
hold on;
ers2 = ErrorratioSimulator(nBitsSim,Mapper(64, 'QAM','GRay'),repen);
ers2.dBProbes = dBProbes;
ers2.simulateAndPlot('BER')


%% coderate 0.01; repetition encoder is much better
nBitsSim = 3e3;
paren=ParityEncoder(180); paren.getCoderate
repen = RepetitionEncoder(100); repen.getCoderate
figure;
ers1 = ErrorratioSimulator(nBitsSim,Mapper(64, 'QAM','GRay'),paren);
ers1.dBProbes = dBProbes;
ers1.simulateAndPlot('BER');
hold on;
ers2 = ErrorratioSimulator(nBitsSim,Mapper(64, 'QAM','GRay'),repen);
ers2.dBProbes = dBProbes;
ers2.simulateAndPlot('BER')





%% not usable
% paren = ParityEncoder(180);
% parde = paren.getDecoder();
% paren.getCoderate
% 
% bchen=BCHEncoder(1023,11);
% bchde =bchen.getDecoder;
% bchen.getCoderate
% 
% sour = Source('rand');
% bits = sour.step(1,1e5);
% 
% cod1= paren.step(bits);
% cod2 = bchen.step(bits);
% 
% cod1.lengthInBits
% cod2.lengthInBits
% 
% % res1=parde.step(cod1);
% % res2=bchde.step(cod2);
% % countBiterrors(res1,res2)
% 
% ratioOfToggledBits = 0.1;
% 
% totalBits = min(cod1.lengthInBits,cod2.lengthInBits);
% numberOfToggledBits = ratioOfToggledBits * totalBits;