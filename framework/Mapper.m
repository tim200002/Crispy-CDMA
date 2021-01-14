classdef Mapper < handle
% MAPPER performs different types of mapping (such as QAM, PSK, ASK) with
% specified numbers of symbols. MAPPER is further able to assign the
% generated symbols with labels in natural or gray labeling. Symbols can be
% visualized in a constellation diagram.

    properties
        nsymbols {mustBePositive} % number of symbols
        symbols % real vector for ASK, complex vector for PSK, complex matrix for QAM
        type Mappingtype % enumeration of Mappingtype
        labeling Labeling % enumeration of Labeling
        labels % string vector / matrix; is a matrix, if type==QAM
    end
    
    methods
        function obj = Mapper(numberOfSymbols, mappingType, labeling)
            obj.nsymbols = 2^(ceil(log2(numberOfSymbols))); % correct to next higher power of 2
            if obj.nsymbols ~= numberOfSymbols
                disp("changed number of symbols to next higher power of two: "+obj.nsymbols);
            end
            obj.type = mappingType;
            obj.labeling = labeling;
            obj.calcSymbols;
            obj.labelSymbols;
        end
        
        function mapped = step(obj, signal)
        % STEP maps the bits/bytes given in the Signal object "signal"
        % to a Signal object "mapped" according to the chosen mapping.
        % Remaining bits are ignored.
            
            bitDepth = ceil(log2(obj.nsymbols));
            decimalSymbols = signal.divideInBitBlocks(bitDepth, 'int', false);
            if obj.labeling == Labeling.Natural
                symbolsout = obj.symbols(decimalSymbols + 1);
            elseif obj.labeling == Labeling.Gray
                % converts the obj.labels string matrix (not char arrays) of binary numbers to a matrix of decimal numbers with same dimensions
                stringvec = obj.labels(:);
                decimalLabels = reshape(binaryVector2DecimalNumber(char(stringvec) - '0'), size(obj.symbols, 1), size(obj.symbols, 2));
                [~, invGrayDecimal] = sort(decimalLabels(:));
                symbolsout = obj.symbols(invGrayDecimal(decimalSymbols + 1));
            end
            symbolrate = signal.fs / bitDepth; % symbolrate is smaller than bitrate
            mapped = Signal(symbolsout, symbolrate, Signaltype.Valuecontinuous, signal.details);
        end
        
        function plotConstellation(obj)
        % PLOTCONSTELLATION shows a plot of the constellation of the
        % specified mapping scheme.
        
            title("Constellation diagram of "+obj.nsymbols+"-"+string(obj.type));
            if isreal(obj.symbols) % real symbols (occuring in ASK, 2-PSK, 2-QAM)
                plot(obj.symbols, zeros(1, numel(obj.symbols)), 'o');
                xlabel('real');
                ylabel('imag');
                if ~isempty(obj.labels)
                    text(obj.symbols(1:2:end), zeros(1, numel(obj.symbols(1:2:end))), obj.labels(1:2:end), 'VerticalAlignment', 'bottom');
                    text(obj.symbols(2:2:end), zeros(1, numel(obj.symbols(2:2:end))), obj.labels(2:2:end), 'VerticalAlignment', 'top');
                end
            else % complex symbols (occuring in QAM and PSK)
                plot(obj.symbols, 'o');
                xlabel('real');
                ylabel('imag');
                if ~isempty(obj.labels)
                    text(real(obj.symbols(:)), imag(obj.symbols(:)), obj.labels(:));
                end
            end
        end
        
        function energy = getConstellationEnergy(obj)
        % GETCONSTELLATIONENERGY returns the energy of the constellation
        % symbols.
        
            energy = mean((abs(obj.symbols(:))) .^ 2);
        end
        
        function demap = getDemapper(obj)
        % GETDEMAPPER returns the corresponding Demapper object
        
            demap = Demapper(obj.nsymbols, obj.type, obj.labeling);
        end
    end
    
    methods (Access = private)
        function calcSymbols(obj)
            % generates obj.symbols matrix
            obj.nsymbols = 2^(ceil(log2(obj.nsymbols))); % correct to next higher power of two
            switch(obj.type)
                case Mappingtype.QAM
                    % rectangular QAM mapping
                    nsymbolsXAxis = 2^ceil(log2(obj.nsymbols) / 2);
                    nsymbolsYAxis = 2^floor(log2(obj.nsymbols) / 2);
                    %normX = 1 / (sqrt(2 * (nsymbolsXAxis^2 - 1) / 3)); % scaling factors to retrieve signal with energy = nsymbols
                    %normY = 1 / (sqrt(2 * (nsymbolsYAxis^2 - 1) / 3));
                    XSpacing = linspace(-(nsymbolsXAxis-1), nsymbolsXAxis-1, nsymbolsXAxis);% * normX;
                    YSpacing = linspace(-(nsymbolsYAxis-1), nsymbolsYAxis-1, nsymbolsYAxis);% * normY;
                    obj.symbols = repmat(XSpacing, nsymbolsYAxis, 1) + j * repmat(YSpacing', 1, nsymbolsXAxis);
                    % sum(abs(obj.symbols(:)).^2) %for testing signal energy
                case Mappingtype.PSK
                    angleSpacing = (0:obj.nsymbols-1) * (2 * pi / obj.nsymbols);
                    if obj.nsymbols == 4
                    % QPSK, the symbols shall not lay on real/imag axes
                        obj.symbols = round(exp(j * (angleSpacing + pi/4)), 5); % round() because of numerical inaccuracy
                    else
                        % the first symbol shall lay on real axis
                        obj.symbols = round(exp(j * angleSpacing), 5);
                    end
                case Mappingtype.ASK
                    % equidistant ASK mapping
                    norm = 1/(sqrt((obj.nsymbols^2-1)/3)); % scaling factor to retrieve signal with energy = nsymbols
                    obj.symbols = linspace(-(obj.nsymbols-1), obj.nsymbols-1, obj.nsymbols) * norm;
                    % sum(abs(obj.symbols(:)).^2) %for testing signal energy
            end
        end
        
        function labelSymbols(obj)
            % generates the obj.labeling matrix depending on obj.symbols
            switch(obj.labeling)
                case Labeling.Natural
                    matr = zeros(size(obj.symbols, 1), size(obj.symbols, 2));
                    matr(:) = 0:numel(obj.symbols)-1;
                    obj.labels = string(dec2bin(matr));
                    obj.labels = obj.labels(matr+1);
                case Labeling.Gray
                    grayVectorX = binaryVector2DecimalNumber(getGrayCodeSeries(log2(size(obj.symbols, 2))));
                    grayVectorY = binaryVector2DecimalNumber(getGrayCodeSeries(log2(size(obj.symbols, 1))));
                    grayMatr = repmat(size(obj.symbols, 1) * grayVectorX', size(obj.symbols, 1), 1) + repmat(grayVectorY, 1, size(obj.symbols, 2));
                    
                    obj.labels = string(dec2bin(grayMatr));
                    matr = zeros(size(obj.symbols, 1), size(obj.symbols, 2));
                    matr(:) = 0:numel(obj.symbols)-1;
                    obj.labels = obj.labels(matr+1);
            end
        end
    end
end