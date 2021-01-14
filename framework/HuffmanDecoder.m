classdef HuffmanDecoder < handle
% HUFFMANDECODER is a class for decoding Huffman encoded binary signal
% objects.

    properties
        symbols % preimages of codewords
        invtree % inverse tree; obj.invtree(1,:) are the sibling nodes of obj.invtree(2,:)
        nNodes  % number of nodes of tree
        nLeaves % number of leaves of tree
    end
    
    methods
        function obj = HuffmanDecoder(symbols, tree)
            obj.symbols = symbols;
            [~, nodesIndices] = sort(tree); % nodesIndices contains the indices of obj.symbols
            obj.invtree = reshape(nodesIndices, 2, numel(nodesIndices) / 2); % tree has an even length and numel(nodesIndices) is even, because every node has 0 or 2 children
            obj.nNodes = max(tree); % the last node's number is the maximum node number
            obj.nLeaves = min(tree) - 1; % because the minimum value of tree is the first non-leaf node
        end
        
        function decoded = step(obj, signal)
        % STEP maps the Huffman codewords in "signal" to a binary Signal
        % object "decoded".
        % The last incomplete codeword is ignored.
            
            bitvec = signal.selectFromBitToBitAsBitvector(1, signal.lengthInBits); % convert signal to bitarray
            
            decodedIdx = []; % stores indices in obj.symbols array
            posInvTree = obj.nNodes; % set position in inverse tree to root node
            for actualIndex = 1:length(bitvec) % go bit-wise through signal and meanwhile move the position in the inverse tree 
                posInvTree = obj.invtree(bitvec(actualIndex) + 1, posInvTree - obj.nLeaves); % choose the left (0) or right (1) node depending on the actual bit 
                if posInvTree <= obj.nLeaves % if leaf of tree, that is, an entire codeword is determined
                    decodedIdx = [decodedIdx; posInvTree]; % concatenate the index of new found symbol
                    posInvTree = obj.nNodes; % set position in inverse tree to root node
                end
            end
            decoded = obj.symbols(decodedIdx, :)'; % finally maps indices in obj.symbols to symbols
            if ischar(obj.symbols)
                decoded = uint8(decoded(:));
            end
            decoded = Signal(decoded, signal.fs, 'Bytes', signal.details);
        end
    end
end