classdef Scope < handle
% SCOPE can do
% - time domain plots
% - frequency domain plots
% - scatter plots
% - eye diagram plots
% - waterfall plots
% Axes can be preserved e.g. for animations using preserveAxes.

	properties
        tLimits(1, 2) {mustBeNumeric}                   % lower and upper bound for plot in array indices OR seconds (according to obj.xAxis) as 2 element vector
        fLimits(1, 2) {mustBeNumeric}                   % lower and upper bound for spectrum plot in FFT indices OR Hertz (according to obj.xAxis) as 2 element vector
        yLimits(1, 2) {mustBeNumeric}                   % lower and upper bound for y Axis (independent of obj.yAxis) as 2 element vector
        xAxis ScopeXAxis                                % element of enumeration ScopeXAxis
        yAxis = ScopeYAxis.Magnitude                    % element of enumeration ScopeYAxis
        axesHandle                                      % optional: axesHandle: an axes object vector (e.g. out of GUI handle struct), which shall be used to display the plot
        nDisplayedSamples(1, 1) {mustBeNonnegative}     % optional: number of samples to display for animated plots; if > 0, axes are preserved
        animationFrameNumber(1, 1) {mustBeNonnegative}  % optional: how many animation frames have been displayed yet
        memory                                          % optional: storage for animated plots
        window                                          % optional: window for waterfall plots as double vector, e.g. hann(256)
        plotSpec                                        % optional: specification for plot line style and color
    end
    methods
        function obj = Scope(varargin)
        % arguments:
        % (1) (optional): ScopeXAxis-enum member or string; e.g.
        % ScopeXAxis.Hertz or "Hertz"
        % (2) (optional): ScopeYAxis-enum member or string; e.g.
        % ScopeYAxis.dB or "dB"
        
            obj.plotSpec = '';
            if nargin == 1
                assignToCorrectAxisProperty(obj, varargin{1});
            elseif nargin == 2
                assignToCorrectAxisProperty(obj, varargin{1}); % decision for first argument
                assignToCorrectAxisProperty(obj, varargin{2}); % decision for second argument
            else
                obj.xAxis = ScopeXAxis.Seconds; % default settings
                obj.yAxis = ScopeYAxis.Real;
            end
        end
        
        function preserveAxes(obj, varargin)
        % PRESERVEAXES sets the option to preserve axes rescaling.
        % arguments:
        % (1) obj: Scope object
        % (2) (optional) axes handle
        
            if nargin == 2
                if ishandle(varargin{1})
                    obj.axesHandle = varargin{1};
                end
            end
            if obj.nDisplayedSamples == 0 % if not specified otherwise
                obj.nDisplayedSamples = 1;
            end
        end
        
        function plotTimeDomain(obj, signal, varargin)
        % PLOTTIMEDOMAIN plots the Signal object "signal" with optional x
        % axis limits and line style specification.
        % arguments:
        % (1) obj: Scope object
        % (2) signal: signal to plot
        % (3) (optional): limits for time domain plots in seconds or in
        % samples (according to obj.xAxis) as two element vector
        % (4) (optional): specification for plot line style and color;
        % e.g. 'green' or 'b--o' or 'c*'
                        
            if ~isa(signal, 'Signal')
                error('Input needs to be an instance of Signal');
            end
            
            if nargin == 3
                obj.tLimits = varargin{1};
            elseif nargin == 4
                obj.tLimits = varargin{1};
                obj.plotSpec = varargin{2};
            end
            
            if signal.signaltype == Signaltype.Fouriertransformed
                % perform a inverse Fourier transformation of whole signal
                % probably does not work with 'fftshift'ed signals
                YValues = ifft(signal.data);
            else
                YValues = signal.data;
            end
            
            if obj.nDisplayedSamples == 0                                  % no animation
                checkTLimits(obj, signal);                
                if obj.xAxis == ScopeXAxis.Index
                    tLabel = 'Time [samples]';
                    rangeInSamples = obj.tLimits(1) : obj.tLimits(2);
                else
                    tLabel = 'Time [s]';
                    if signal.signaltype == Signaltype.Bytes % exception for bytes
                        rangeInSamples = floor(obj.tLimits * signal.fs / 8);
                    else
                        rangeInSamples = floor(obj.tLimits * signal.fs);
                    end
                    rangeInSamples = (rangeInSamples(1) + 1) : rangeInSamples(2);
                end                
                if isempty(rangeInSamples)
                    error("Scope: bad range input");
                end                
                XValues = linspace(obj.tLimits(1), obj.tLimits(2), length(rangeInSamples));
                YValues = YValues(rangeInSamples);                                              
                obj.plotSingleFrame(XValues, YValues, signal.signaltype);
                title('Time domain plot');
                xlabel(tLabel);
            else                                                           % if animation mode
                % don't care about obj.tLimits, display nDisplayedSamples
                % everytime
                
                XValues = (1 : obj.nDisplayedSamples) / signal.fs * ((obj.xAxis == ScopeXAxis.Index) * (signal.fs - 1) + 1); % :-)
                if signal.signaltype == Signaltype.Bytes % exception for bytes
                    XValues = XValues * 8;
                end
                
                if obj.animationFrameNumber == 0                           % first frame
                    dataToPlot = [YValues(1 : min(signal.length, obj.nDisplayedSamples)); zeros(obj.nDisplayedSamples - signal.length, 1)]; % zero padding, so that length(dataToPlot)=nDisplayedSamples
                    obj.plotSingleFrame(XValues, dataToPlot, signal.signaltype);                    
                    title('Time domain plot');
                    if obj.xAxis == ScopeXAxis.Index
                        xlabel('Time [samples]');
                    else
                        xlabel('Time [s]');
                    end
                else                                                       % not the first frame                    
                    dataToPlot = [signal.data; obj.memory];                % concat new to old data
                    dataToPlot = dataToPlot(1 : obj.nDisplayedSamples);
                    obj.plotFollowingFrame(XValues, dataToPlot);
                end
                obj.memory = dataToPlot;                                   % save currently plotted data
            end
        end
        
        function plotFrequencyDomain(obj, signal, varargin)
        % PLOTFREQUENCYDOMAIN plots the Signal object "signal" with optional x
        % axis limits and line style specification.
        % arguments:
        % (1) obj: Scope object
        % (2) signal: signal to plot
        % (3) (optional): limits for frequency domain plots in Hertz or in
        % samples (according to obj.xAxis) as two element vector
        % (4) (optional): specification for plot line style and color;
        % e.g. 'green' or 'b--o' or 'c*'
                        
            if ~isa(signal, 'Signal')
                error('Input needs to be an instance of Signal');
            end
            
            if nargin == 3
                obj.fLimits = varargin{1};
            elseif nargin == 4
                obj.fLimits = varargin{1};
                obj.plotSpec = varargin{2};
            end
            
            checkFLimits(obj, signal);
            
            if obj.xAxis == ScopeXAxis.Index
                fLabel = 'Frequency [samples]';
                rangeInSamples = obj.fLimits(1) : obj.fLimits(2);
                XValues = rangeInSamples;
            else
                %  Hertz --> Samples
                lowerBoundInSamples = round((obj.fLimits(1) + signal.fs/2) / signal.fs * signal.length + 1);
                upperBoundInSamples = round((obj.fLimits(2) + signal.fs/2) / signal.fs * signal.length);
                rangeInSamples = lowerBoundInSamples : upperBoundInSamples;
                
                if any(obj.fLimits > 2000)
                    fLabel = 'Frequency [kHz]'; % f axis in kHz
                    XValues = linspace(obj.fLimits(1), obj.fLimits(2), length(rangeInSamples)) / 1000;
                else
                    fLabel = 'Frequency [Hz]'; % f axis in Hz
                    XValues = linspace(obj.fLimits(1), obj.fLimits(2), length(rangeInSamples));
                end
            end
            
            if isempty(rangeInSamples)
               	error("Scope: bad plot range input");
            end
            
            nFFT = signal.length; % fixed FFT length here
            
            if signal.signaltype == Signaltype.Fouriertransformed
                % probably missing fftshift
                YValues = signal.data(rangeInSamples);
            else
                % perform a Fourier transformation of whole signal
                YValues = fftshift(fft(signal.data, nFFT)) / nFFT; % division according to Parseval's theorem
                YValues = YValues(rangeInSamples);
            end
            
            if obj.nDisplayedSamples == 0                                  % no animation
                obj.plotSingleFrame(XValues, YValues, Signaltype.Fouriertransformed);
                title('Frequency domain plot');
                xlabel(fLabel);
            else                                                           % animated plot
                % dont care about old values in obj.memory, do not concat
                
                if  obj.animationFrameNumber == 0                          % display first frame
                    obj.plotSingleFrame(XValues, YValues, Signaltype.Fouriertransformed);
                    title('Frequency domain plot');
                    xlabel(fLabel);
                else
                    obj.plotFollowingFrame(XValues, YValues);
                end
                
                obj.memory = 1; % dummy: to mark, that the first frame was displayed
            end
        end
        
        function plotEyeDiagram(obj, signal, symbolTime, offset)
        % PLOTEYEDIAGRAM shows an eye diagram of the Signal object "signal"
        % with symbolTime in seconds
        % 0 <= offset < 1
        
            if signal.signaltype ~= Signaltype.Valuecontinuous
                error("Scope.plotEyeDiagram: invalid signal type");
            end
            symbolTimeInSamples = round(symbolTime * signal.fs);
            offsetInSamples = round(offset * symbolTimeInSamples);
            
            if obj.xAxis == ScopeXAxis.Index % X values depending on scope x axis setting
                XValues = 1 : 2 * symbolTimeInSamples;
                tLabel = 'Time [samples]';
            else
                XValues = linspace(0, 2 * symbolTime, 2 * symbolTimeInSamples);
                tLabel = 'Time [s]';
            end
            if obj.nDisplayedSamples == 0                                  % no animation
                selection = signal.data(offsetInSamples + 1 : end); % simply ignore first offsetInSamples samples
                nSymbolPairs = floor(length(selection) / symbolTimeInSamples / 2);
                selection = selection(1 : nSymbolPairs * 2 * symbolTimeInSamples); % so that it fits in the rehaped matrix
                selection = reshape(selection, [2 * symbolTimeInSamples, nSymbolPairs]);
                selection = selection.'; % .' to transpose the matrix without conjugate
                
                obj.plotSingleFrame(XValues, selection, Signaltype.Valuecontinuous); % selection is matrix
                title("Eye Diagram");
                xlabel(tLabel);
            else                                                           % animated plot
                comb = [signal; obj.memory]; % concat new to old data
                comb = comb.selectFromTo(1, min(comb.length, obj.nDisplayedSamples + offsetInSamples)); % select desired amount of samples
                
                selection = comb.data(offsetInSamples + 1 : end); % simply ignore first offsetInSamples samples
                nSymbolPairs = floor(length(selection) / symbolTimeInSamples / 2);
                selection = selection(1 : nSymbolPairs * 2 * symbolTimeInSamples); % so that it fits in the rehaped matrix
                selection = reshape(selection, [2 * symbolTimeInSamples, nSymbolPairs]);
                selection = selection.'; % .' to transpose the matrix without conjugate
                
                if  obj.animationFrameNumber == 0                          % display first frame
                    obj.plotSingleFrame(XValues, selection, Signaltype.Valuecontinuous);
                    title("Eye Diagram");
                    xlabel(tLabel);
                else                                                       % display following frames
                    axes(obj.axesHandle(1));
                    axis manual;
                    switch obj.yAxis
                        case ScopeYAxis.Magnitude
                            calcYValues = abs(selection);
                        case ScopeYAxis.dB
                            calcYValues = round(mag2db(abs((selection).^2), 4));
                        case ScopeYAxis.Imaginary
                            calcYValues = imag(selection);
                        case ScopeYAxis.RealAndImag
                            calcYValues1 = real(selection);
                            calcYValues2 = imag(selection);
                        case ScopeYAxis.MagAndPhase
                            calcYValues1 = round(mag2db(abs(selection)), 4);
                            calcYValues2 = angle(selection);
                        otherwise % ScopeYAxis.Real is default case
                            calcYValues = real(selection);
                    end
                    if isscalar(obj.axesHandle)
                        for idx = 1:min(numel(obj.axesHandle.Children), size(selection, 1))
                            set(obj.axesHandle.Children(idx), 'XData', XValues, 'YData', calcYValues(idx, :));
                        end
                    else
                        for idx = 1:min(numel(obj.axesHandle(1).Children), size(selection, 1))
                            set(obj.axesHandle(1).Children(idx), 'XData', XValues, 'YData', calcYValues1(idx, :));
                            set(obj.axesHandle(2).Children(idx), 'XData', XValues, 'YData', calcYValues2(idx, :));
                        end
                    end
                    drawnow();
                    obj.animationFrameNumber = obj.animationFrameNumber + 1; % increment animationFrameNumber
                end
                
                obj.memory = signal; % save current signal
            end
        end
        
        function plotEyeDiagramWithSlider(obj, signal, symbolTime)
        % PLOTEYEDIAGRAMWITHSLIDER shows an eye diagram of the Signal
        % object "signal" and lets control the offset with a slider.
        % symbolTime in seconds.
        
            obj.plotEyeDiagram(signal, symbolTime, 0);
            
            SliderH = uicontrol('style','slider','position',[0 0 500 20]);
            addlistener(SliderH, 'Value', 'PostSet', @callbackfn);
            TextH = uicontrol('style','text','position',[500 0 40 15]);
            
            function callbackfn(~, eventdata)
                num          = get(eventdata.AffectedObject, 'Value');
                TextH.String = num2str(num);
                obj.plotEyeDiagram(signal, symbolTime, num);
            end
        end
        
        function plotScatter(obj, signal)
        % PLOTSCATTER shows a scatter plot in the Re-Im plane of the Signal
        % object "signal"
        
            if signal.signaltype ~= Signaltype.Valuecontinuous
                error("Scope.plotScatter: invalid signal type");
            end
            
            if ~isempty(obj.axesHandle) && ishandle(obj.axesHandle) % if obj.axesHandle is specified, use it
                axes(obj.axesHandle);
            end
            
            if obj.nDisplayedSamples == 0 % no animation
                if signal.isReal
                    plot(signal.data, zeros(signal.length, 1), '.');
                else % complex symbols
                    plot(signal.data, '.');
                end
                title('Scatter plot');
                xlabel('Amplitude, real');
                ylabel('Amplitude, imaginary');
                if ~all(obj.yLimits == 0)
                    ylim(obj.yLimits); % set ylimits, if defined
                    xlim(obj.yLimits); % set xlimits to ylimits to get quadratic limits
                end
            else % animated plot                
                comp = [signal; obj.memory]; % concat memory
                comp = comp.selectFromTo(1, min(obj.nDisplayedSamples, comp.length));
                
                if  obj.animationFrameNumber == 0                          % display first frame
                    if comp.isReal
                        lineHandle = plot(comp.data, zeros(comp.length, 1), '.');
                    else % complex symbols
                        lineHandle = plot(comp.data, '.');
                    end
                    obj.axesHandle = lineHandle.Parent;
                    drawnow();
                    title('Scatter plot');
                    xlabel('Amplitude, real');
                    ylabel('Amplitude, imaginary');
                    if ~all(obj.yLimits == 0)
                        ylim(obj.yLimits); % set ylimits, if defined
                        xlim(obj.yLimits); % set xlimits to ylimits to get quadratic limits
                    end
                    obj.animationFrameNumber = 1; % first frame displayed
                else % display following frames
                    if comp.isReal
                        set(obj.axesHandle.Children, 'XData', comp.real.data, 'YData', zeros(comp.length, 1)); % only set new data, no recalculation of axis,...
                    else % complex symbols
                        set(obj.axesHandle.Children, 'XData', comp.real.data, 'YData', comp.imag.data); % only set new data, no recalculation of axis,...
                    end
                    drawnow();
                    obj.animationFrameNumber = obj.animationFrameNumber + 1; % increment animationFrameNumber
                end
                obj.memory = comp;
            end
        end
        
        function plotWaterfall(obj, signal, varargin)
        % PLOTWATERFALL displays a spectrogram of the Signal object
        % "signal".
        % optional 3rd argument: overlap ratio in [0;1) determines the 
        % overlapping of blocks, of which the fft is calculated
        
            if signal.signaltype ~= Signaltype.Valuecontinuous
                error("wrong signaltype");
            end
            if isempty(obj.window)
                warning("no window specified; setting waterfall plot window to default hann window with 256 samples");
                obj.window = hann(256); % default window
            end
            if nargin == 3
                overlapRatio = varargin{1};
            else
                overlapRatio = 0.1; % hard coded default
            end
            winLength = length(obj.window);
            
            spec = obj.calcSpectrogram(signal.data, overlapRatio);
            
            obj.checkFLimits(Signal(signal.data(1 : winLength), signal.fs)); % TODO do not construct dummy signal: bad style
            
            if obj.xAxis == ScopeXAxis.Index % obj.fLimits interpreted as indices in dft
                if obj.nDisplayedSamples == 0 % no animated plot
                    timeLimits = [0 1] * signal.length;
                else % animated plot
                    timeLimits = [0 1] * (obj.nDisplayedSamples - 1);
                end
                lowerBoundInSamples = obj.fLimits(1);
                upperBoundInSamples = obj.fLimits(2);
                fLabel = 'Frequency [samples]';
                tLabel = 'Time [samples]';
            else % obj.fLimits interpreted as Hertz
                % Hertz --> Samples
                lowerBoundInSamples = round((obj.fLimits(1) + signal.fs/2) / signal.fs * winLength + 1);
                upperBoundInSamples = round((obj.fLimits(2) + signal.fs/2) / signal.fs * winLength);
                if obj.nDisplayedSamples == 0
                    timeLimits = [0 1] * signal.lengthInSeconds;
                else
                    timeLimits = [0 1] * (obj.nDisplayedSamples - 1) / signal.fs;
                end
                fLabel = 'Frequency [Hz]';
                tLabel = 'Time [s]';
            end
            
            if ~isempty(obj.axesHandle) && ishandle(obj.axesHandle)
                axes(obj.axesHandle);
            end
            
            if obj.nDisplayedSamples == 0 % no animated plot
                imagesc(obj.fLimits, timeLimits, mag2db(abs(spec(:, lowerBoundInSamples : upperBoundInSamples))));
                colorbar;
                caxis([-100 0]);
                title('Waterfall diagram [dB]');
                xlabel(fLabel);
                ylabel(tLabel);
            else % animated plot
                if size(spec, 2) == size(obj.memory, 2)
                    % concat new to old memory data
                    segmentsOfSpec = min(size(spec, 1), ceil((obj.nDisplayedSamples - winLength) / (winLength - floor(winLength * overlapRatio))));
                    segmentsOfMemory = min(size(obj.memory, 1), ceil((obj.nDisplayedSamples - winLength) / (winLength - floor(winLength * overlapRatio)) - segmentsOfSpec));
                    spec = [spec(1 : segmentsOfSpec, :); obj.memory(1 : segmentsOfMemory, :)];
                end
                
                if  obj.animationFrameNumber == 0 % display first frame
                    imageHandle = imagesc(obj.fLimits, timeLimits, mag2db(abs(spec(:, lowerBoundInSamples : upperBoundInSamples))));
                    obj.axesHandle = imageHandle.Parent;
                    drawnow();
                    colorbar;
                    caxis([-100 0]);
                    title('Waterfall diagram [dB]');
                    xlabel(fLabel);
                    ylabel(tLabel);
                    obj.animationFrameNumber = 1;
                else % display following frames
                    set(obj.axesHandle.Children, 'CData', mag2db(abs(spec(:, lowerBoundInSamples : upperBoundInSamples)))); % only set new color data, no recalculation of axis,...
                    drawnow();
                    obj.animationFrameNumber = obj.animationFrameNumber + 1; % increment animationFrameNumber
                end
                obj.memory = spec; % save current spectrogram
            end
        end
        
    end % end of methods
    
    methods (Access = private)
        
        function plotSingleFrame(obj, XValues, YValues, signalType) % if a non-animation single plot or the first frame of an animation
            if ~isempty(obj.axesHandle) && all(ishandle(obj.axesHandle)) % if a handle is specified, use this; if not, plot() will generate one
                axes(obj.axesHandle);
            end
            switch signalType
                case Signaltype.Bits
                    lineHandle = stairs(XValues, YValues, 'green');
                    lineHandle.Parent.Color = 'black'; % background color
                    ylim([-0.2 1.2]);
                    yticks([0 1]);
                    ylabel('bit value');
                case Signaltype.Bytes
                    lineHandle = stairs(XValues, YValues, 'green');
                    lineHandle.Parent.Color = 'black'; % background color
                    ylim([0 255]);
                    yticks([0 15 31 47 63 79 95 111 127 143 159 175 191 207 223 239 255]);
                    yticklabels({'00_{16}', '0F_{16}', '1F_{16}', '2F_{16}', '3F_{16}', '4F_{16}', '5F_{16}', '6F_{16}', '7F_{16}', '8F_{16}', '9F_{16}', 'AF_{16}', 'BF_{16}', 'CF_{16}', 'DF_{16}', 'EF_{16}', 'FF_{16}'});
                    ylabel('hex value');
                otherwise
                    switch obj.yAxis
                        case ScopeYAxis.Magnitude
                            lineHandle = plot(XValues, abs(YValues), obj.plotSpec);
                            ylabel('Magnitude (linear)');
                        case ScopeYAxis.dB
                            lineHandle = plot(XValues, round(mag2db(abs(YValues)+eps), 4), obj.plotSpec);
                            ylabel('Signal power (dB)');
                        case ScopeYAxis.RealAndImag
                            subplot(2, 1, 1);
                            lineHandle(:, 1) = plot(XValues, real(YValues), 'red');
                            ylabel('Amplitude (linear), real part');
                            subplot(2, 1, 2);
                            lineHandle(:, 2) = plot(XValues, imag(YValues), 'blue');
                            ylabel('Amplitude (linear), imaginary part');
                        case ScopeYAxis.Imaginary
                            lineHandle = plot(XValues, imag(YValues),  obj.plotSpec);
                            ylabel('Amplitude (linear), imag');
                        case ScopeYAxis.MagAndPhase
                            subplot(2, 1, 1);
                            lineHandle(:, 1) = plot(XValues, round(mag2db(abs(YValues)), 6), obj.plotSpec);
                            ylabel('Magnitude (dB)');
                            subplot(2, 1, 2);
                            lineHandle(:, 2) = plot(XValues, unwrap(angle(YValues)), obj.plotSpec);
                            ylabel('Phase (rad)');
                        otherwise % ScopeYAxis.Real is default case
                            lineHandle = plot(XValues, real(YValues), obj.plotSpec);
                            ylabel('Amplitude (linear), real');
                    end
                    if ~all(obj.yLimits == 0) % if y limits were set
                        ylim(obj.yLimits); % set these y limits
                    end
            end
            
            if obj.nDisplayedSamples > 0 % if animation mode
                if size(lineHandle, 2) == 2 % for subplots
                    obj.axesHandle = lineHandle(1, 1).Parent; % !!! not: obj.axesHandle(1) =
                    obj.axesHandle(2) = lineHandle(1, 2).Parent;
                else % for single line plots in one figure or for multi line plots (as for Eye diagrams)
                    obj.axesHandle = lineHandle(1).Parent;
                end
                obj.animationFrameNumber = 1; % first frame of an animation displayed herewith
                drawnow();
            end
        end
        
        function plotFollowingFrame(obj, XValues, YValues) % if first frame of an animation is displayed yet and axis, labels, ... are set; use set() to not change them
            axes(obj.axesHandle);
            axis manual;
            switch obj.yAxis
                case ScopeYAxis.Magnitude
                    set(obj.axesHandle.Children, 'XData', XValues, 'YData', abs(YValues));
                case ScopeYAxis.dB
                    set(obj.axesHandle.Children, 'XData', XValues, 'YData', round(mag2db(abs(YValues)), 4));
                case ScopeYAxis.RealAndImag
                    set(obj.axesHandle(1).Children, 'XData', XValues, 'YData', real(YValues));
                    set(obj.axesHandle(2).Children, 'XData', XValues, 'YData', imag(YValues));
                case ScopeYAxis.Imaginary
                    set(obj.axesHandle.Children, 'XData', XValues, 'YData', imag(YValues));
                case ScopeYAxis.MagAndPhase
                    set(obj.axesHandle(1).Children, 'XData', XValues, 'YData', round(mag2db(abs(YValues)), 4));
                    set(obj.axesHandle(2).Children, 'XData', XValues, 'YData', (angle(YValues)));
                otherwise % ScopeYAxis.Real is default case
                    set(obj.axesHandle.Children, 'XData', XValues, 'YData', real(YValues));
            end
            drawnow();
            obj.animationFrameNumber = obj.animationFrameNumber + 1; % increment animationFrameNumber
        end
        
        function spec = calcSpectrogram(obj, data, overlapRatio)
            % (1) obj: Scope object
            % (2) data: double vector
            % (3) overlapRatio: range is 0 <= overlapRatio < 1
            winLength = length(obj.window); % for best fft performance, use powers of 2
            winShift = winLength - floor(winLength * overlapRatio);
            nSegments = ceil((length(data) - winLength) / winShift);
            
            selMat = repmat((1:winLength)', 1, nSegments) + repmat(winShift*(0:(nSegments-1)), winLength, 1);
            % selMat dimensions: winLength x nSegments
            selMat(:, nSegments) = (length(data)-winLength+1):length(data); % for end values
            
            windowed = (data(selMat) .* obj.window(:)); % transpose, because subsequent fft is columnwise operation
            
            spec = fftshift(fft(windowed), 1)' / sqrt(winLength);
            % imagesc(mag2db(abs(spec))) % to display spectrogram
        end
        
        function assignToCorrectAxisProperty(obj, unknownAxisDescriptor)
            % ASSIGNTOCORRECTAXISPROPERTY tries to cast unknownAxisDescriptor to a
            % valid ScopeXAxis or ScopeYAxis object.
            % unknownAxisDescriptor can be string or member of enumeration
            % ScopeXAxis or ScopeYAxis
            if isenum(unknownAxisDescriptor)
                if isa(unknownAxisDescriptor, 'ScopeXAxis')
                    obj.xAxis = unknownAxisDescriptor;
                elseif isa(unknownAxisDescriptor, 'ScopeYAxis')
                    obj.yAxis = unknownAxisDescriptor;
                end
            else % not a enum, so probably a string
                try
                    obj.xAxis = ScopeXAxis(unknownAxisDescriptor);
                catch
                    try
                        obj.yAxis = ScopeYAxis(unknownAxisDescriptor);
                    catch
                        error("class Scope: invalid Scope axis descriptor; use enumerations ScopeXAxis | ScopeYAxis instead");
                    end
                end
            end
        end
        
        function checkTLimits(obj, signal)
            % check t Limits according to signal
            % arguments:
            % (1) obj: Scope object
            % (2) signal: signal to plot
            obj.tLimits = [min(obj.tLimits) max(obj.tLimits)]; % sort
            if obj.xAxis == ScopeXAxis.Index  % interpret arguments as range of SAMPLES
                if all(obj.tLimits == 0) % no bounds specified
                    obj.tLimits = [1 signal.length]; % default range
                else % use range specified in obj.tLimits
                    newLimits = round(max(1, min(signal.length, obj.tLimits))); % check and correct bounds
                    if any(newLimits ~= obj.tLimits) % reject non-integer and non-positive numbers for indices
                        warning("Scope: indices must be positive integer; correcting tLimits "+join(string(obj.tLimits))+" to nearest reasonable values "+join(string(newLimits)));
                        obj.tLimits = newLimits;
                    end
                end
            else % interpret arguments as range of SECONDS
                if all(obj.tLimits == 0) % no bounds specified
                    obj.tLimits = [0 signal.lengthInSeconds]; % default range
                else % use range specified in obj.tLimits
                    newLimits = max(0, min(signal.lengthInSeconds, obj.tLimits)); % check and correct bounds
                    if any(newLimits ~= obj.tLimits) % reject negative numbers for time values
                        warning("Scope: plot range in seconds must be positive; correcting tLimits "+join(string(obj.tLimits))+" to nearest reasonable values "+join(string(newLimits)));
                        obj.tLimits = newLimits;
                    end
                end
            end
        end
        
        function checkFLimits(obj, signal)
            % check f Limits according to signal
            % arguments:
            % (1) obj: Scope object
            % (2) signal: signal to plot
            obj.fLimits = [min(obj.fLimits) max(obj.fLimits)]; % sort
            if obj.xAxis == ScopeXAxis.Index % interpret arguments as range of INDICES in dft array
                if all(obj.fLimits == 0) % no bounds specified
                    obj.fLimits = [1 signal.length]; % default range; fft length = signal length
                else % use range specified in obj.fLimits
                    newLimits = round(max(1, min(signal.length, obj.fLimits))); % check and correct bounds
                    if any(newLimits ~= obj.fLimits) % reject non-integer and non-positive numbers for indices
                        warning("Scope: indices must be positive integer; correcting fLimits "+join(string(obj.fLimits))+" to nearest reasonable values "+join(string(newLimits)));
                        obj.fLimits = newLimits;
                    end
                end
            else % arguments interpreted as the desired bounds of the plot in HERTZ
                if all(obj.fLimits == 0) % no bounds specified
                    obj.fLimits = [-1 1] * signal.fs / 2; % default range
                else % use range specified in obj.fLimits
                    newLimits = max(-signal.fs/2, min(signal.fs/2, obj.fLimits)); % check and correct bounds
                    if any(newLimits ~= obj.fLimits)
                        warning("Scope: correcting fLimits "+join(string(obj.fLimits))+" to nearest reasonable values "+join(string(newLimits)));
                        obj.fLimits = newLimits;
                    end
                end
            end
        end
    end % end of private methods
end
