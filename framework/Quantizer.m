classdef Quantizer < handle
% QUANTIZER converts valuecontinuous Signal objects to binary Signal
% objects

    properties
        nBits {mustBePositive}
        labels string % string vector
        qSteps % quantization steps [-1;1]; vector length: 2^obj.nBits
        symmetry % -1: negative range has one step more; 0: curve really symmetric, but idle noise; 1: positive range has one step more
        mu = 0 % µ-law parameter; mu=0 for no µ-law application; mu>0 for µ-law application
    end
    
    methods
        function obj = Quantizer(nBits, symmetry)
            obj.nBits = nBits;
            obj.symmetry = sign(symmetry);
            obj.calcQSteps();
            obj.labels = string(dec2bin(0:2^obj.nBits - 1));
        end
        
        function [quant, SQNR, indices] = step(obj, signal)
        % STEP returns a quantized version of the valuecontinuous Signal
        % object "signal". 
        % It expects values between -1 and 1.
        % output arguments:
        % (1) quant: quantized signal as binary Signal
        % (2) SQNR: signal to quantization noise ratio in dB
        % (3) indices: indices in vector obj.labels; range between 1 and 2^obj.nBits
        
            if signal.signaltype ~= Signaltype.Valuecontinuous
                error("expect valuecontinuous signal");
            end
            if obj.mu > 0
                inputsignal = sign(signal.data) .* log(1 + obj.mu .* abs(signal.data)) ./ log(1 + obj.mu);
            else
                inputsignal = signal.data;
            end
            scaled = inputsignal * (2^obj.nBits - 1 + abs(obj.symmetry)) / 2;
            shifted = scaled + (2^obj.nBits + 1 - obj.symmetry) / 2;
            indices = round(shifted);
            indices = max(indices, 1); % no nonpositive values
            indices = min(indices, 2^obj.nBits); % no values above 2^obj.nBits
            
            if nargout > 1
                SQNR = pow2db(sum(abs(inputsignal) .^ 2) / sum(abs(obj.qSteps(indices) - signal.data) .^ 2));
            end
            
            quant = obj.labels(indices);
            quant = join(quant, "");
            quant = uint8(char(quant) - '0');
            quant = Signal(quant, signal.fs * obj.nBits, Signaltype.Bits, signal.details);
        end
        
        function analog = invPCM(obj, signal)
        % INVPCM performs inverse PCM of binary Signal object "signal" to range [-1;1]. 
        % INVPCM is the inverse operation to STEP.
        
            decimal = signal.divideInBitBlocks(obj.nBits, 'int', true) + 1; % resulting range: [1;2^obj.nBits]
            analog = obj.qSteps(decimal);
            if obj.mu > 0
                analog = sign(analog) .* ((1 + obj.mu) .^ abs(analog) - 1) ./ obj.mu;
            end
            analog = Signal(analog, signal.fs / obj.nBits, Signaltype.Valuecontinuous, signal.details);
        end
        
        function plotCurve(obj)
        % PLOTCURVE shows the quantization curve of the Quantizer "obj".
        
            testsig = Signal(linspace(-1.5, 1.5, 2^obj.nBits * 100), 1, Signaltype.Valuecontinuous); %  * 100 hard coded
            [~, ~, indices] = obj.step(testsig);
            plot(testsig.data, indices - 1, 'LineWidth', 2);
            yticks(0:2^obj.nBits-1);
            yticklabels(obj.labels);
            grid('on');
            
            hold on;
            if obj.mu > 0
                inputsignal = sign(testsig.data) .* log(1 + obj.mu .* abs(testsig.data)) ./ log(1 + obj.mu);
            else
                inputsignal = testsig.data;
            end
            scaled = inputsignal * (2^obj.nBits - 1 + abs(obj.symmetry)) / 2;
            shifted = scaled + (2^obj.nBits + 1 - obj.symmetry) / 2;
            plot(linspace(-1.5, 1.5, length(shifted)), shifted);
            hold off;
        end
    end
    
    methods (Access = private)
        function calcQSteps(obj)
            obj.qSteps = (2 * (1:2^obj.nBits)' - 2^obj.nBits - 1 + obj.symmetry) / (2^obj.nBits - 1 + abs(obj.symmetry));
            if obj.mu > 0
                obj.qSteps = sign(obj.qSteps) .* ((1 + obj.mu) .^ abs(obj.qSteps) - 1) ./ obj.mu;
            end
        end
    end
end