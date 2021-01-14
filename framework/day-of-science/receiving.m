function receiving(GUIhandles)
    settings = GUIhandles.settings;
    
    inputDevice = audioDeviceReader(settings.sampleRate, 'BitDepth','16-bit integer', 'SamplesPerFrame',settings.samplesPerFrame);
    inputDevice.Device = settings.inputDevicesList{settings.inputDeviceIndex};
    
    % list of possibilities for L or R 
    channelMat{1} = 1; % R
    channelMat{2} = 2; % L
    channelMat{3} = [1 2]; % R L
    
    deviceMapping = zeros(length(settings.outputDevicesList), 2); % for each listed device and channel (2, L and R)
    
    demodulatorMapping = find(settings.outputDevicesIndices(1:settings.nChannels) ~= 1); % contains number of valid (not 'No Output') channels
    
    for idx = 1:length(demodulatorMapping)
        if settings.modulationIndices(demodulatorMapping(idx)) == 1
            demodulator{idx} = DSBDemodulator(settings.carrierFrequencies(demodulatorMapping(idx)),        settings.sampleRate, settings.bandwidth(demodulatorMapping(idx)) / 2);
        elseif settings.modulationIndices(demodulatorMapping(idx)) == 2
            demodulator{idx} = SSBDemodulator(settings.carrierFrequencies(demodulatorMapping(idx)), 'LSB', settings.sampleRate, settings.bandwidth(demodulatorMapping(idx)) / 2);
        elseif settings.modulationIndices(demodulatorMapping(idx)) == 3
            demodulator{idx} = SSBDemodulator(settings.carrierFrequencies(demodulatorMapping(idx)), 'USB', settings.sampleRate, settings.bandwidth(demodulatorMapping(idx)) / 2);
        end
        % insert the number of demodulator in the corresponding device
        % and channel (L/R/LR):
        deviceMapping(settings.outputDevicesIndices(demodulatorMapping(idx)), channelMat{settings.channelIndices(demodulatorMapping(idx))}) = idx;
    end
    
    % determine all zeros rows in deviceMapping matrix:
    nonZeroRows = any(deviceMapping' ~= 0)';
    % set existing zeros to the number of demodulator + 1:
    deviceMapping(deviceMapping == 0) = 1 + length(demodulatorMapping);

    % determine relevant (used) devices; array contains the indices in settings.outputDevicesList
    deviceIndices = find(nonZeroRows);
    
    for idx = 1:length(deviceIndices)
        outputDevices{idx} = audioDeviceWriter(settings.sampleRate, 'BitDepth','8-bit integer');
        outputDevices{idx}.Device = settings.outputDevicesList{deviceIndices(idx)};
    end    

    SignalPlotter = Scope();
    SignalPlotter.preserveAxes(GUIhandles.diagram1); % enable animated plot
    SignalPlotter.nDisplayedSamples = 5 * settings.sampleRate; % hard coded 5 seconds
    SignalPlotter.yLimits = [-1 1];

    SpectrumPlotter = Scope(ScopeYAxis.Magnitude);
    SpectrumPlotter.preserveAxes(GUIhandles.diagram2); % enable animated plot
    SpectrumPlotter.fLimits = [0 settings.sampleRate / 2];
    %SpectrumPlotter.yLimits = [];
    
    WaterfallPlotter = Scope();
    WaterfallPlotter.preserveAxes(GUIhandles.diagram3); % enable animated plot
    WaterfallPlotter.nDisplayedSamples = 5 * 48000; % hard coded 5 seconds
    WaterfallPlotter.fLimits = [0 settings.sampleRate / 2];
    WaterfallPlotter.window = hann(128);
    
    receivedSignal = Signal([], settings.sampleRate, Signaltype.Valuecontinuous);
    % empty matrix for outputs of the demodulators plus a last row for a
    % zero frame, which can be used to output a zero signal at a device
    % channel:
    demodsig = zeros(settings.samplesPerFrame, 1 + length(demodulatorMapping));
    
    totalOverrun = 0;
    runloop = 1;
    while runloop
        tic;
        [SamplesReceived, Overrun] = inputDevice.step();
        receivedSignal.data = SamplesReceived;
        totalOverrun = totalOverrun + Overrun;
        
        SignalPlotter.plotTimeDomain(receivedSignal);
        SpectrumPlotter.plotFrequencyDomain(receivedSignal, [0 settings.sampleRate / 2]);
        WaterfallPlotter.plotWaterfall(receivedSignal);       

        for idx = 1:length(demodulatorMapping)
            demodsig(:, idx) = demodulator{idx}.step(receivedSignal).data(:);
        end
        
        pause((settings.samplesPerFrame / settings.sampleRate - toc) * 0.8);
        
        for idx = 1:length(deviceIndices)
            outputDevices{idx}.step(demodsig(:, deviceMapping(deviceIndices(idx), :)));
        end
        
        guih = guidata(GUIhandles.txtSampleRate); % guidata fetches the actual GUI handles
        runloop = guih.runloop;
    end
    disp("number of overruns: " + totalOverrun);
    
    inputDevice.release();
    for idx = 1:length(deviceIndices)
        outputDevices{idx}.release();% if assigned previously; in order to change settings
    end
end