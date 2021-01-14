classdef Signal < handle
% SIGNAL is a class to universally store signals regardless of their type
% and include side information like samplerate.

    properties
        data(:,1) % stored as given in signaltype, column vector
        fs {mustBePositive} % samplingrate in Hz | bitrate in bit/s | symbolrate in Baud
        signaltype Signaltype % enumeration member of Signaltype
        details % struct with fields:
        %            sourcetype = enumeration of Sourcetype
        %            seed = nonnegative integer (necessary, if type == 'random')
        %            filename = path to file + filename, from which the data is
        %                        extracted of (necessary, if type == 'file')
    end
    methods
        function sig = Signal(dataIn, sampleRate, varargin)
            % variable number of arguments:
            % no arguments
            % (1) dataIn as column vector; (2) sampleRate as positive integer
            % (1) dataIn as column vector; (2) sampleRate as positive integer; (3) signalType as enumeration member of Signaltype
            % (1) dataIn as column vector; (2) sampleRate as positive integer; (3) signalType as enumeration member of Signaltype; (4) dataDetails as struct
            
            if nargin == 0 % default case
                sig.data = [];
                sig.fs = 1;
                sig.signaltype = Signaltype.Valuecontinuous;
                sig.details.sourcetype = Sourcetype.Undefined;
            else
                if ~isnumeric(dataIn) && ~islogical(dataIn)
                    error("constructor of Signal: signal input is not a numeric or logical signal");
                end
                if sampleRate <= 0
                    error("constructor of Signal: bad sample rate");
                end
                if nargin == 2
                    % determine signal type:
                    if isreal(dataIn)
                        if all(dataIn == 0) % if data is a zero vector
                            sig.signaltype = Signaltype.Valuecontinuous;
                        else
                            if all(double(logical(dataIn(:))) == dataIn(:)) % check first for bitarray
                                sig.signaltype = Signaltype.Bits;
                            elseif all(uint8(dataIn(:)) == dataIn(:)) % then check for bytearray
                                sig.signaltype = Signaltype.Bytes;
                            else
                                sig.signaltype = Signaltype.Valuecontinuous;
                            end
                        end
                    else
                        sig.signaltype = Signaltype.Valuecontinuous;
                    end
                    sig.details.sourcetype = Sourcetype.Undefined;
                elseif nargin == 3
                    sig.signaltype = varargin{1};
                    sig.details.sourcetype = Sourcetype.Undefined;
                elseif nargin == 4
                    sig.signaltype =  varargin{1};
                    sig.details = varargin{2};
                else
                    error("constructor of Signal: invalid arguments");
                end
%                 if sig.signaltype == Signaltype.Bits && mod(length(dataIn), 8) == 0 % if bitsignal containing multiple of 8 bits
%                     % bitarray is converted to bytearray
%                     bytevec = bitvector2bytevector(dataIn);
%                     sig.data = uint8(bytevec(:)); % convert to uint8 column vector
%                     sig.fs = sampleRate; % interprete sampleRate as bitrate
%                     sig.signaltype = Signaltype.Bytes;
%                 else
                    sig.data = dataIn(:); % to column vector
                    sig.fs = sampleRate;
%                 end
            end
        end
        
        function sig = vertcat(obj1, obj2)
        % VERTCAT for vertical concatenation of Signal objects.
        % MATLAB operator overloading of [x;y]
        
            if isempty(obj1)
                sig = Signal(obj2.data, obj2.fs, obj2.signaltype, obj2.details);
                return;
            end
            if isempty(obj2)
                sig = Signal(obj1.data, obj1.fs, obj1.signaltype, obj1.details);
                return;
            end
            if obj1.fs ~= obj2.fs % accept only equal sample rates
                error("Signal.vertcat: samplerate mismatch");
            end
            if obj1.signaltype == obj2.signaltype
                if obj1.signaltype == Signaltype.Valuecontinuous % Valuecontinuous signals are concatenated
                    sig = Signal([obj1.data(:); obj2.data(:)], obj1.fs, Signaltype.Valuecontinuous, obj1.details);
                elseif obj1.signaltype == Signaltype.Bits || obj1.signaltype == Signaltype.Bytes
                    % accept random data with different seed and accept file data of different files; obj1.details is used
                    sig = Signal([obj1.data(:); obj2.data(:)], obj1.fs, obj1.signaltype, obj1.details);
                end
            else % not same signaltype
                if     (obj1.signaltype == Signaltype.Bits  && obj2.signaltype == Signaltype.Bytes) ...
                    || (obj1.signaltype == Signaltype.Bytes && obj2.signaltype == Signaltype.Bits)
                    bitarr1 = obj1.selectFromBitToBitAsBitvector(1, obj1.lengthInBits);
                    bitarr2 = obj2.selectFromBitToBitAsBitvector(1, obj2.lengthInBits);
                    % accept random data with different seed and accept file data of different files; obj1.details is used
                    sig = Signal([bitarr1(:); bitarr2(:)], obj1.fs, Signaltype.Bits, obj1.details);
                else
                    error("signaltype mismatch");
                end
            end
        end
        
        function signal = plus(si1, si2)
        % PLUS adds two valuecontinuous signals.
        % The shorter signal is zero padded.
        % The output is as long as the longer signal.
        % MATLAB operator overloading of +
    
            if ~(si1.signaltype == Signaltype.Valuecontinuous && si2.signaltype == Signaltype.Valuecontinuous && si1.fs == si2.fs)
                error("Signal.plus: signals are not valuecontinuous or sample rate / bit rate doesn't match");
            end
            commonLength = max(si1.length, si2.length);
            data1 = [si1.data(:); zeros(commonLength - si1.length, 1)];
            data2 = [si2.data(:); zeros(commonLength - si2.length, 1)];
            signal = Signal(data1 + data2, si1.fs, si1.signaltype, si1.details);
        end
        
        function signal = minus(si1, si2)
        % MINUS subtracts two valuecontinuous Signal objects.
        % The shorter signal is zero padded.
        % Output is as long as the longer signal.
        % MATLAB operator overloading of -
        
            if ~(si1.signaltype == Signaltype.Valuecontinuous && si2.signaltype == Signaltype.Valuecontinuous && si1.fs == si2.fs)
                error("Signal.minus: signals are not valuecontinuous or sample rate / bit rate doesn't match");
            end
            commonLength = max(si1.length, si2.length);
            data1 = [si1.data(:); zeros(commonLength - si1.length, 1)];
            data2 = [si2.data(:); zeros(commonLength - si2.length, 1)];
            signal = Signal(data1 - data2, si1.fs, si1.signaltype, si1.details);
        end
        
        function sig = mtimes(fac1, fac2)
        % MTIMES multiplies a scalar with a Signal object.
        % MATLAB operator overloading of *
        % only allow multiplications with scalar numbers
        
            if ~isa(fac1, 'Signal') && isscalar(fac1)
                scalar = fac1;
                if isa(fac2, 'Signal')
                    signal = fac2;
                end
            elseif ~isa(fac2, 'Signal') && isscalar(fac2)
                scalar = fac2;
                if isa(fac1, 'Signal')
                    signal = fac1;
                end
            else
                error("Signal.mtimes: no matrix multiplication for signals");
            end
            
            if signal.signaltype == Signaltype.Valuecontinuous
                sig = Signal(scalar * signal.data(:), signal.fs, signal.signaltype, signal.details);
            else
                error("Signal.mtimes: signal is not valuecontinuous");
            end
        end
        
        function selection = selectFromBitToBit(obj, fromBit, toBit)
        % SELECTFROMBITTOBIT returns a selection of the input signal obj
        % from the given bit position to the given bit position
        % as Signal object.
        % Only working for bitsignals or bytesignals.
            
            if fromBit < 1 || toBit > obj.lengthInBits
                error("Signal.selectFromBitToBit: selection bounds out of range");
            end
            
            if obj.signaltype == Signaltype.Bits
                % trivial case
                selection = obj.selectFromTo(fromBit, toBit);
            elseif obj.signaltype == Signaltype.Bytes
                % don't convert the whole bytearray
                % convert only the used bytes and select the bits therein
                nBits = toBit - fromBit + 1;
                beginByte = floor((fromBit - 1) / 8) + 1;
                endByte = floor((nBits - 1 + fromBit - 1) / 8) + 1;
                bitvec = bytevector2bitvector(obj.data(beginByte:endByte));
                firstBit = mod(fromBit - 1, 8) + 1; % mapping fromBit->firstBit: 1->1|...|8->8|9->1|...|16->8|17->1
                bitvec = bitvec(firstBit : firstBit + nBits - 1); % select nBits
                selection = Signal(uint8(bitvec(:)), obj.fs, Signaltype.Bits, obj.details);
            else
                error("signaltype must be bit or byte");
            end
        end
        
        function signalSelection = selectFromBitToBitAsBitvector(obj, fromBit, toBit)
        % SELECTFROMBITTOBITASBITVECTOR returns a selection of the input 
        % signal obj from the given bit position to the given bit position
        % as uint8 Bitvector (not Signal object).
        % Only working for bitsignals or bytesignals.
            
            if fromBit >= 1 && toBit <= obj.lengthInBits
                if obj.signaltype == Signaltype.Bits
                    signalSelection = uint8(obj.data(fromBit:toBit)); % trivial case                    
                elseif obj.signaltype == Signaltype.Bytes
                    % don't convert the whole bytearray
                    % convert only the used bytes and select the bits therein
                    nBits = toBit - fromBit + 1;
                    beginByte = floor((fromBit - 1) / 8) + 1;
                    endByte = floor((nBits - 1 + fromBit - 1) / 8) + 1;
                    bitvec = bytevector2bitvector(obj.data(beginByte:endByte));
                    bitvec = bitvec(mod(fromBit - 1, 8) + 1 : mod(fromBit - 1, 8) + 1 + nBits - 1);
                    signalSelection = uint8(bitvec);
                else
                    error("signaltype must be bit or byte");
                end
                signalSelection = signalSelection(:);
            else
                error("Signal.selectFromBitToBitAsBitvector: tried to access bit out of vector range");
            end
        end
        
        function blocks = divideInBitBlocks(obj, nBits, outputType, ignoreOrPad)
        % DIVIDEINBITBLOCKS divides bit / byte Signal objects in blocks of
        % nBits.
        % arguments:
        % (1) obj: Signal object
        % (2) nBits: number of bits of a block
        % (3) outputType: 'matrix': return a nLines x nBits double/uint8-matrix of reordered bits, default
        %                 'int': return a vector of integers containing the blocks converted to unsigned decimal
        %                 'string': return a vector of strings representing binary numbers
        % (4) ignoreOrPad: logical: false: ignore last bits, that might not fit into a block
        %                           true: zero padding, until it fits into a block
        
            if obj.signaltype ~= Signaltype.Bits && obj.signaltype ~= Signaltype.Bytes
                error("signaltype must be bit or byte");
            end
            if ignoreOrPad
                nLines = ceil(obj.lengthInBits / nBits);
                bitvec = [obj.selectFromBitToBitAsBitvector(1, obj.lengthInBits); zeros(nLines * nBits - obj.lengthInBits, 1)];
            else
                nLines = floor(obj.lengthInBits / nBits);
                bitvec = obj.selectFromBitToBitAsBitvector(1, nLines * nBits);
            end
            blocks = reshape(bitvec, nBits, nLines)';
            if strcmpi(outputType, 'int')
                blocks = binaryVector2DecimalNumber(blocks);
            elseif strcmpi(outputType, 'string')
                blocks = join(string(blocks), "");
            end
        end
        
        function byteSignal = convertBitToByteSignal(obj, varargin)
        % CONVERTBITTOBYTESIGNAL converts a signal with signaltype 'Bits' to signal with
        % signaltype 'Bytes'.
        % If not defined with ignoreOrPad, it ignores last bits, that
        % might not fit into a block.
        % argument:
        % (1) ignoreOrPad (optional): logical: false: ignore last bits, that might not fit into a block
        %                                      true: zero padding, until it fits into a block
        
            if obj.signaltype == Signaltype.Bits
                if nargin == 2
                    if ignoreOrPad
                        % zero pad last bit
                        byteSignal = Signal(bitvector2bytevector(obj.data), obj.fs, Signaltype.Bytes, obj.details);
                    else
                        % ignore last bits
                        nConvertedBits = floor(obj.length / 8) * 8;
                        byteSignal = Signal(bitvector2bytevector(obj.data(1:nConvertedBits)), obj.fs, Signaltype.Bytes, obj.details);
                    end
                else
                    % ignore last bits
                    nConvertedBits = floor(obj.length / 8) * 8;
                    byteSignal = Signal(bitvector2bytevector(obj.data(1:nConvertedBits)), obj.fs, Signaltype.Bytes, obj.details);
                end
            else
                error("signal must be a bit signal");
            end
        end
        
        function asText = getDataAsText(obj)
        % GETDATAASTEXT interpretes bytes as ASCII characters and returns
        % it.
        
            if obj.signaltype == Signaltype.Bits
                asText = char(obj.selectFromBitToBit(1, obj.lengthInBits - mod(obj.lengthInBits, 8)).data(:)');
            elseif obj.signaltype == Signaltype.Bytes || obj.signaltype == Signaltype.Valuecontinuous
                asText = char(obj.data(:)');
            else
                error("expected bits or bytes");
            end
        end
        
        function printDataAsText(obj)
        % PRINTDATAASTEXT interpretes bytes as ASCII characters and prints
        % on console.
        
            if obj.signaltype == Signaltype.Bits
                disp(char(obj.selectFromBitToBit(1, obj.lengthInBits - mod(obj.lengthInBits, 8)).data(:)'));
            elseif obj.signaltype == Signaltype.Bytes || obj.signaltype == Signaltype.Valuecontinuous
                disp(char(obj.data(:)'));
            else
                error("expected bits or bytes");
            end
        end
        
        function result = signalenergy(obj)
        % SIGNALENERGY returns the signal energy of the Signal object.
            result = mean(abs(obj.data).^2);
        end
        
        function PAPRatio = PAPR(obj)
        % PAPRATIO returns the peak to average power ratio.
        % NOT in dB; use pow2db(PAPRatio) to calculate it in dB
            PAPRatio = max(abs(obj.data).^2) / obj.signalenergy;
        end
        
        function normed = normByMax(obj)
        % NORMBYMAX ensures that the magnitude of the whole signal is <= 1.
            if obj.signaltype == Signaltype.Valuecontinuous
                normed = Signal(obj.data / max(abs(obj.data)), obj.fs, obj.signaltype, obj.details);
            else
                error("expected valuecontinuous signal");
            end
        end
        
        function normed = normByAvg(obj)
        % NORMBYAVG sets the average magnitude to 1.
            if obj.signaltype == Signaltype.Valuecontinuous
                normed = Signal(obj.data / mean(abs(obj.data)), obj.fs, obj.signaltype, obj.details);
            else
                error("expected valuecontinuous signal");
            end
        end
        
        function meanfree = removeDCOffset(obj)
        % REMOVEDCOFFSET returns the mean-free Signal object.
            if obj.signaltype == Signaltype.Valuecontinuous
                meanfree = Signal(obj.data - mean(obj.data), obj.fs, obj.signaltype, obj.details);
            else
                error("expected valuecontinuous signal");
            end
        end
        
        function isRealLogical = isReal(obj)
        % ISREAL determines if signal is real.
            isRealLogical = isreal(round(obj.data, 6)); % round because e.g. round(exp(j*pi), 5) = -1 ~= exp(j*pi), which is complex due to numerical inaccuracies
        end
        
        function realpartSignal = real(obj)
        % REAL returns the real part of the Signal object.
            realpartSignal = Signal(real(obj.data), obj.fs, obj.signaltype, obj.details);
        end
        
        function imagpartSignal = imag(obj)
        % IMAG returns the imaginary part of the Signal object.
            imagpartSignal = Signal(imag(obj.data), obj.fs, obj.signaltype, obj.details);
        end
        
        function lengthOfData = length(obj)
        % LENGTH returns the number of samples / bits / bytes of the Signal
        % object.
            lengthOfData = length(obj.data);
        end
        
        function clear(obj)
        % CLEAR empties the Signal object's data vector.
            obj.data = [];
        end
        
        function result = isempty(obj)
        % ISEMPTY returns whether the Signal object is empty.
            result = isempty(obj.data);
        end
        
        function selection = selectFromTo(obj, from, to)
        % SELECTFROMTO returns the samples from "from" to "to" of the
        % Signal data vector.
            if from >= 1 && to <= obj.length
                selection = Signal(obj.data(from : to), obj.fs, obj.signaltype, obj.details);
            else
                error("Signal.selectFromTo: selection bounds out of range");
            end
        end
        
        function bitlength = lengthInBits(obj)
        % LENGTHINBITS returns the length of the stored data in bits.
            if obj.signaltype == Signaltype.Bits
                bitlength = obj.length;
            elseif obj.signaltype == Signaltype.Bytes
                bitlength = 8 * obj.length;
            else % error case for other signals
                error("Signal.LengthInBits: cannot determine bitlength");
            end
        end
        
        function secondsLength = lengthInSeconds(obj)
        % LENGTHINSECONDS returns the length of the Signal object in
        % seconds.
            if obj.signaltype == Signaltype.Bits || obj.signaltype == Signaltype.Bytes
                secondsLength = obj.lengthInBits / obj.fs;
            else
                secondsLength = obj.length / obj.fs;
            end
        end
        
        function disp(obj)
        % DISP prints a short description of the Signal object on the
        % console.
            fprintf('Instance of class Signal:\n');
            if isempty(obj)
                fprintf('This is an empty instance.\n');
            else
                fprintf("Length: " + obj.length + "\n");
                switch obj.signaltype
                    case Signaltype.Bits
                        fprintf("Bits\nBitrate: " + obj.fs + " bit/s");
                    case Signaltype.Bytes
                        fprintf("Bytes\nBitrate: " + obj.fs + " bit/s");
                    case Signaltype.Fouriertransformed
                        fprintf("dft samples\nSamplerate: " + obj.fs + " Hz");
                    case Signaltype.Valuecontinuous
                        fprintf("Valuecontinuous values\nSamplerate: " + obj.fs + " Hz");
                end
                fprintf("\nThe first " + min(obj.length, 20) + " values are " + join(string(obj.data(1:min(obj.length, 20)))) + "\n");
                fprintf("The source of this signal is " + string(obj.details.sourcetype) + ".\n");
            end
        end
    end
end