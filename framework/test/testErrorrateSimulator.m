% all channel encoder have coderate 1/3
cod = {ParityEncoder(5)};
cod{2} = RepetitionEncoder(3);
cod{3} = HammingEncoder(2);
cod{4} = BCHEncoder(15, 5);
legendText = {};
map = Mapper(16, 'QAM', 'gray');
for idxCod = 1:length(cod)
ers = ErrorratioSimulator(1e6, map, cod{idxCod});
ers.dBProbes = 0:13;
ers.simulateAndPlot('BER')
hold on;
legendText{end+1} = class(cod{idxCod});
end
legend(legendText);