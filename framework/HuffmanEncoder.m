classdef HuffmanEncoder < handle
% HUFFMANENCODER is a class to generate a Huffman code based on training 
% data and encode binary Signal objects with this code
    
    properties
        nBitsBlock {mustBePositive} % number of bits of a block in the input signal
        dict containers.Map % maps preimages decimal/chararray to codewords (string containing 0 / 1)  % codeword for symbol x  is in obj.dict(x)
        tree  % contains links to parent nodes; the indication is the same as on obj.symbols, so obj.tree(x) refers to the same symbol as obj.symbols(x) 
        symbols % decimal or charvector as vector, preimages
        occurrences % occurrence of obj.symbols(x) is in obj.occurrences(x)
    end
    
    methods
        function obj = HuffmanEncoder(varargin)
        % no arguments
        % OR
        % (1) nBitsBlock: number of bits of a block in the input signal
        % (2) dict: as it is created by generateDistinctDictionary() or
        % generateFullDictionary()       
            
            if nargin == 2
                obj.nBitsBlock = varargin{1};
                obj.dict = varargin{2};    
            end
        end
        
        function coded = step(obj, signal)
        % STEP encodes the binary Signal object "signal"
            
            if isempty(obj.dict)
                error("no dictionary specified");
            end
            ordered = signal.divideInBitBlocks(obj.nBitsBlock, 'matrix', false);
            if numel(ordered) < signal.lengthInBits
                warning("only "+numel(ordered)+" of "+signal.lengthInBits+" bits processed");
            end
            if strcmpi(obj.dict.KeyType, 'char')
                rawsymbols = char(bin2dec(char(ordered + '0')));
            else
                rawsymbols = binaryVector2DecimalNumber(ordered);
            end
            coded = "";
            try
                for idx = 1:size(rawsymbols, 1)
                    coded = coded + obj.dict(rawsymbols(idx, :));
                end
            catch
                error("following symbol not found in dictionary: " + rawsymbols(idx, :));
            end
%             strlength(coded) / length(bitvec)
            coded = Signal(uint8(char(coded)' - '0'), signal.fs, 'Bits', signal.details);
        end
        
        function generateFullDictionary(obj, varargin)
        % GENERATEFULLDICTIONARY generates a dictionary on the basis of
        % the given Signal object.
        % 'Full' means, that symbols with occurrence == 0 are used in
        % the code.
        % arguments:
        % (1) obj: HuffmanEncoder object
        % (2) (optional) Signal object, of which the dictionary shall be generated
        % (3) (optional) bitlength of blocks, whose occurrences shall be counted
            
            if isempty(obj.occurrences) || isempty(obj.symbols)
                if nargin == 2
                    obj.countByteOccurrences(varargin{1}); % if no third argument given, use countByteOccurrences, so use 8 as bitlength
                elseif nargin == 3
                    obj.countBitvectorOccurrences(varargin{1}, varargin{2}); % if third argument given, use countBitvectorOccurrences
                else                    
                    error("no symbols or occurrences specified; use countByteOccurrences or countBitvectorOccurrences first");
                end
            end
            [nOccurrences, symbolindices] = sort(obj.occurrences); % symbolindices points onto entries in obj.symbols
            obj.generateTree(nOccurrences, symbolindices); % tree in obj.tree
            obj.assignCodewords;
        end
        
        function generateDistinctDictionary(obj, varargin)
        % GENERATEDISTINCTDICTIONARY generates a dictionary on the
        % basis of the given Signal object.
        % 'Distinct' means, that symbols with occurrence == 0 are NOT used in
        % the code.
        % arguments:
        % (1) obj: HuffmanEncoder object
        % (2) (optional) Signal object, of which the dictionary shall be generated
        % (3) (optional) bitlength of blocks, which occurrences shall be counted
            
            if isempty(obj.occurrences) || isempty(obj.symbols)
                if nargin == 2
                    obj.countByteOccurrences(varargin{1}); % if no third argument given, use countByteOccurrences, so use 8 as bitlength
                elseif nargin == 3
                    obj.countBitvectorOccurrences(varargin{1}, varargin{2}); % if third argument given, use countBitvectorOccurrences
                else                    
                    error("no symbols or occurrences specified; use countByteOccurrences or countBitvectorOccurrences first");
                end
            end
            nonZeroIndices = (obj.occurrences > 0);
            obj.occurrences = obj.occurrences(nonZeroIndices);
            obj.symbols = obj.symbols(nonZeroIndices, :);
            [nOccurrences, symbolindices] = sort(obj.occurrences); % symbolindices points onto entries in obj.symbols
            obj.generateTree(nOccurrences, symbolindices); % tree in obj.tree
            obj.assignCodewords; % codewords in obj.dict
        end
        
        function countByteOccurrences(obj, signal)
        % COUNTBYTEOCCURRENCES counts the number of occurrences of 
        % 8-bit-blocks contained in the Signal object "signal"
        
            obj.nBitsBlock = 8;
            if signal.signaltype == Signaltype.Bits
                selection = signal.selectFromBitToBit(1, signal.lengthInBits - mod(signal.lengthInBits, 8)).data'; % truncate and convert to bytes
            elseif signal.signaltype == Signaltype.Bytes
                selection = signal.data';
            else
                error("expected bytes or bits");
            end
            obj.symbols = (0:255)';
            obj.occurrences = histcounts(selection, 0:256); % 0:256 instead of 0:255 is necessary because of histcounts functionality
        end
        
        function countBitvectorOccurrences(obj, signal, nBitsBlock)
        % COUNTBITVECTOROCCURRENCES counts the number of occurrences of 
        % n-bit blocks in Signal object "signal"
        
            obj.nBitsBlock = nBitsBlock;
            if signal.signaltype ~= Signaltype.Bits
                error("only accept bits");
            end
            nCodewords = 2^nBitsBlock;
            obj.symbols = (0:(nCodewords-1))';
%             obj.symbols = dec2bin(0:(nCodewords-1), nBitsBitvector);
            decimal = signal.divideInBitBlocks(nBitsBlock, 'int', false);
            if floor(signal.lengthInBits / nBitsBlock) * nBitsBlock < signal.lengthInBits
                warning("only "+floor(signal.lengthInBits / nBitsBlock) * nBitsBlock+" of "+signal.lengthInBits+" bits processed");
            end
            obj.occurrences = histcounts(decimal', 0:nCodewords); % 0:nCodewords instead of 0:(nCodewords-1) is necessary because of histcounts functionality
        end
        
        function plotTree(obj)
        % PLOTTREE plots the Huffman tree of the code
        
            if isempty(obj.tree)
                error("no tree specified");
            end            
            treeplot([obj.tree 0])
        end
        
        function decod = getDecoder(obj)
        % GETDECODER returns the corresponding HuffmanDecoder object
        
            decod = HuffmanDecoder(obj.symbols, obj.tree);
        end
    end
    
    methods (Access = private)
        function generateTree(obj, nOccurrences, symbolindices)
            nCodewords = length(obj.occurrences);
            
            mat = []; % mat(:,1) contains occurrences; mat(:,2) contains index in obj.symbols corresponding the occurrences
            obj.tree = [];
            
            nodeCount = 0;
            actualLeaf = 2;
            mat(1, :) = [nOccurrences(1) symbolindices(1)];
            mat(2, :) = [nOccurrences(2) symbolindices(2)];
            sumOccurrences = sum(nOccurrences);
            
            while mat(1, 1) < sumOccurrences
                [min1, minidx1] = min(mat(:, 1)); % determine first minimum
                mat(minidx1, 1) = Inf; % so that it won't be found of the following min() call
                [min2, minidx2] = min(mat(:, 1)); % determine second minimum
                mat(minidx1, 1) = min1 + min2; % combine this minima in a new node
                nodeCount = nodeCount + 1;
                obj.tree(mat(minidx1, 2)) = nCodewords + nodeCount; % add new node to tree; the index 'mat(minidx1, 2)' in obj.tree refers to the same symbol as obj.symbols
                obj.tree(mat(minidx2, 2)) = nCodewords + nodeCount; % add new node to tree
                mat(minidx1, 2) = nCodewords + nodeCount; % new node can be combined with another node the next time
                mat(minidx2, :) = []; % clear combined node
                if actualLeaf + 1 <= length(nOccurrences) % add one or two new leaves if some left
                    actualLeaf = actualLeaf + 1;
                    mat = [mat; [nOccurrences(actualLeaf) symbolindices(actualLeaf)]];
                    if actualLeaf + 1 <= length(nOccurrences)
                        actualLeaf = actualLeaf + 1;
                        mat = [mat; [nOccurrences(actualLeaf) symbolindices(actualLeaf)]];
                    end
                end
            end
        end
        
        function assignCodewords(obj)
            nCodewords = length(obj.occurrences);
            [nodesSort, nodesIndices] = sort(obj.tree, 'descend'); % nodesIndices refer to the same symbols as obj.symbols
            codewords = strings(length(nodesIndices) + 1, 1); % create empty string "" array; codeword for obj.symbols(x) is in codewords(x)
            for idx = 1:length(nodesIndices)
                codewords(nodesIndices(idx)) = codewords(nodesSort(idx)) + string(mod(idx + 1, 2)); % builts codewords adding a "0" or "1" for even or odd idx
            end
            codewords = codewords(1:nCodewords); % only use the codewords for leaves of the tree; codeword for obj.symbols(x) is in codewords(x)
            
            if ischar(obj.symbols)
                mapkeys = num2cell(obj.symbols', 1); % adapts symbols, so that they can be used as keys of the Map
            else
                mapkeys = obj.symbols;
            end
            obj.dict = containers.Map(mapkeys, num2cell(codewords));
%            sum(strlength(codewords) .* obj.occurrences') / sum(obj.occurrences) % average codeword length
        end
    end
end