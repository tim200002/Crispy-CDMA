classdef Demapper < handle
% DEMAPPER is a class to map symbols of various modulations to binary 
% signals

    properties
        nsymbols {mustBePositive} % number of symbols of the mapping given with type
        estIndex % vector of positive integer between 1 .. nsymbols; estimated index in Mapper class mapping matrix
        type Mappingtype % enumeration of Mappingtype
        labeling Labeling % enumeration of Labeling
        labels % stored as string; is a matrix, if type==QAM
    end
    methods
        function obj = Demapper(numberOfSymbols, mappingType, labeling)
            obj.nsymbols = 2^(ceil(log2(numberOfSymbols))); % correct to next higher power of 2
            if obj.nsymbols ~= numberOfSymbols
                disp("changed number of symbols to next higher power of two: "+obj.nsymbols);
            end
            obj.type = mappingType;
            obj.labeling = labeling;
        end
        
        function binsignal = step(obj, signal)
        % STEP maps the valuecontinuous Signal object "signal" to a binary 
        % Signal object "binsignal".
        % Be aware that the constellation points of signal has to be scaled
        % like the corresponding constellation of Mapper
        
            estimateSymbolsHard(obj, signal);
            map = Mapper(obj.nsymbols, obj.type, obj.labeling);
            binaryAsString = join(map.labels(obj.estIndex), ""); % gain the labels of the symbols from Mapper and concat them
            binvec = uint8(char(binaryAsString)) - uint8('0'); % convert to uint8 vector of zeros and ones
            binsignal = Signal(binvec(:), signal.fs * log2(obj.nsymbols), Signaltype.Bits, signal.details);
        end
        
        function estimatedSymbols = getEstimatedSymbols(obj, signal)
        % GETESTIMATEDSYMBOLS finds the nearest constellation symbol to the
        % symbols of the Signal object "signal" and outputs a 
        % valuecontinuous signal of estimated symbols
        
            estimateSymbolsHard(obj, signal);
            map = Mapper(obj.nsymbols, obj.type, obj.labeling);
            symbolvector = map.symbols(obj.estIndex);
            estimatedSymbols = Signal(symbolvector(:), signal.fs, Signaltype.Valuecontinuous, signal.details);
        end
    end
    
    methods (Access = private)
        % private method
        function estimateSymbolsHard(obj, signal)
            % Hard = hard decision
            obj.nsymbols = 2^(ceil(log2(obj.nsymbols))); % correct to next higher power of two
            if signal.signaltype == Signaltype.Valuecontinuous
                switch(obj.type)
                    case Mappingtype.QAM
                        % demapping for rectangular QAM
                        nsymbolsXAxis = 2^ceil(log2(obj.nsymbols) / 2);
                        nsymbolsYAxis = 2^floor(log2(obj.nsymbols) / 2);
%                         normX = 1 / (sqrt(2 * (nsymbolsXAxis^2 - 1) / 3)); % scaling factors to retrieve signal with energy = nsymbols
%                         normY = 1 / (sqrt(2 * (nsymbolsYAxis^2 - 1) / 3));
                        symbolsreal = real(signal.data);% / normX; % remove norm scaling
                        symbolsimag = imag(signal.data);% / normY;
                        symbolsreal = round((symbolsreal + nsymbolsXAxis - 1) / 2) + 1;
                        symbolsimag = round((symbolsimag + nsymbolsYAxis - 1) / 2) + 1;
                        symbolsreal = max(symbolsreal, 1); % clip values less than 1
                        symbolsimag = max(symbolsimag, 1);
                        symbolsreal = min(symbolsreal, nsymbolsXAxis); % clip values higher than nsymbols of axis
                        symbolsimag = min(symbolsimag, nsymbolsYAxis);
                        obj.estIndex = (symbolsreal - 1) * nsymbolsYAxis + symbolsimag;
                    case Mappingtype.PSK
                        angles = atan2(signal.imag.data, signal.real.data);
                        if obj.nsymbols == 4 % QPSK
                            obj.estIndex = mod(round(obj.nsymbols * angles / 2 / pi - 0.5), obj.nsymbols) + 1; % -0.5 because of the pi/4 offset
                        else % no QPSK
                            obj.estIndex = mod(round(obj.nsymbols * angles / 2 / pi), obj.nsymbols) + 1;
                        end
                    case Mappingtype.ASK
                        % demap equidistant ASK mapping
                        %thresholds = linspace(-(obj.nsymbols-2), obj.nsymbols-2, obj.nsymbols-1)% * norm;
                        
                        norm = 1/(sqrt((obj.nsymbols^2-1)/3)); % scaling factor to retrieve signal with energy = nsymbols
                        inputsymbols = signal.data / norm; % remove norm scaling
                        obj.estIndex = round((inputsymbols + obj.nsymbols - 1) / 2) + 1;
                        obj.estIndex = max(obj.estIndex, 1); % clip values less than 1
                        obj.estIndex = min(obj.estIndex, obj.nsymbols);    % clip values higher than nsymbols
                end
            end
        end
    end
end