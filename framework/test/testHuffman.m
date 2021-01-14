%%
huco = HuffmanEncoder();
path = "c:\users\ephraim fuchs\desktop\";
inputText = "somewhat.txt";
so = Source('File', path+inputText);
sig1 = so.step;
huco.countByteOccurrences(sig1);
huco.generateFullDictionary;
huco.plotTree
sampleText='hallo dies ist ein example test text. viel spaﬂ beim codieren.%&()[] und so weiter mit den Sonderzeichen....';
uncoded = Signal(uint8(sampleText), 1, 'Bytes');
coded = huco.step(uncoded, 8);
hude = HuffmanDecoder(huco.symbols, huco.tree);
decoded = hude.step(coded);
decoded.printDataAsText;

%%
huco = HuffmanEncoder();
binvec = dec2bin([1 2 2 3 4 2 3 4 4 4 4 2 2 2 5 2 3 3 1 3 5 6 4 6 4 3 5 4 3 2 1 1 1 6 5], 3) - '0';
binvec = binvec';
binvec = binvec(:);
sig1 = Signal(binvec, 1, 'bit');
huco.countBitvectorOccurrences(sig1, 3);
huco.symbols
huco.occurrences
huco.generateDistinctDictionary;
huco.symbols
huco.occurrences
huco.dict.keys
huco.dict.values
huco.plotTree
binvec2 = dec2bin([4 3 2 5 4 2 1 3 4 5 6 4 3 1 2 3 4 5 1 1 1 1 4 5 6 6], 3) - '0';
binvec2 = binvec2';
binvec2 = binvec2(:);
uncoded = Signal(binvec2, 1, 'bits');
coded = huco.step(uncoded, 3);
hude = HuffmanDecoder(huco.symbols, huco.tree);
hude.step(coded)

%%
occurrences = [0.05,0.05,0.1,0.15,0.15,0.5];
symbols = ['a';'r';'d';'i';'n';'u'];
huco = HuffmanEncoder();
huco.occurrences = occurrences;
huco.symbols = symbols;
huco.generateDistinctDictionary;
huco.dict.keys
huco.dict.values

uncoded = Signal(uint8('inurdiarrrinddiardnru'), 1, 'Bytes');
coded = huco.step(uncoded, 8);
hude = HuffmanDecoder(huco.symbols, huco.tree);
hude.step(coded)'