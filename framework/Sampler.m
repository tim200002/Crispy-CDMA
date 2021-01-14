classdef Sampler < handle
% SAMPLER is a class to up- and downsample Signal objects

    properties
        upsampleFactor   {mustBePositive} = 3
        downsampleFactor {mustBePositive} = 2
    end
    methods
        function obj = Sampler(upsampleFactor, downsampleFactor)
            obj.upsampleFactor = upsampleFactor;
            obj.downsampleFactor = downsampleFactor;
        end
        
        function resampled = step(obj, signal)
        % STEP resamples "signal" with factors given by
        % obj.upsampleFactor and obj.downsampleFactor
        % thus, newFs = oldFs * obj.upsampleFactor / obj.downsampleFactor
        
            res = resample(signal.data, obj.upsampleFactor, obj.downsampleFactor);
            resampled = Signal(res, signal.fs * obj.upsampleFactor / obj.downsampleFactor, signal.signaltype, signal.details);
        end
        
        function [sampled, selectedIndices] = downsample(obj, signal, varargin)
        % DOWNSAMPLE downsamples the signal with integer ratio
        % use optional third argument to specify offset:
        % 0 <= offset < 1 determines, which part of the first samples shall be ignored
        % output argument selectedIndices is optional
        
            if nargin == 3
                offset = varargin{1};
            else
                offset = 0;
            end
            if round(obj.downsampleFactor) ~= obj.downsampleFactor
                error("Sampler.downsample needs integer downsample factor");
            end
            selectedIndices = 1 + round(offset * obj.downsampleFactor) : obj.downsampleFactor : signal.length;
            selection = signal.data(selectedIndices);
            sampled = Signal(selection, signal.fs / obj.downsampleFactor, signal.signaltype, signal.details);
        end
        
        function sampled = downsampleWithPlot(obj, signal, varargin)            
        % DOWNSAMPLEWITHPLOT has the same functionality as DOWNSAMPLE, but 
        % with visualization
        % use optional third argument to specify offset
        
            if nargin == 3
                [sampled, selectedIndices] = obj.downsample(signal, varargin{1});
            else
                [sampled, selectedIndices] = obj.downsample(signal);
            end
            
            title("Visualisation of sampling; sampled values in red");
            %subplot(1, 2, 1);
            hold on;
            plot(signal.real.data);
            stem(selectedIndices, real(signal.data(selectedIndices)));
            xlabel("sample index");
            ylabel("amplitude, real");
            hold off;
            % %     for imag part
            %     subplot(1, 2, 2);
            %     hold on;
            %     plot(signal.imag.data);
            %     stem(selectedIndices, imag(selection));
            %     xlabel("sample index");
            %     ylabel("amplitude, imaginary");
            %     hold off;
        end
        
        function upsampled = upsampleZeroPadding(obj, signal)
        % UPSAMPLEZEROPADDING upsamples "signal" to a whole number multiple
        % of its sample rate using zero padding
        
            ratio = obj.upsampleFactor; % is shorter, better readable
            newData = zeros(length(signal.data) * ratio, 1);
            newData((1:length(signal.data)) * ratio - ratio + 1) = signal.data;
            upsampled = Signal(newData, signal.fs * ratio, signal.signaltype, signal.details);
        end
    end
end