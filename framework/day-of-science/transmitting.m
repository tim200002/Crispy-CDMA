function transmitting(GUIhandles)
    settings = GUIhandles.settings;
    
%     outputDevice = audioDeviceWriter(settings.sampleRate, 'BitDepth','16-bit integer');
%     outputDevice.Device = settings.outputDevicesList(settings.outputDeviceIndex);
    
    outputDevice = Sink(settings.outputDeviceIndex, settings.sampleRate, '16-bit integer');
    
    usedChannels = find(settings.inputsIndices ~= 1);
    usedInputs = unique(settings.inputsIndices(settings.inputsIndices ~= 1), 'stable'); % indices in input drop down list, which do not point at value 1=no input
    
    for idx = 1:length(usedInputs) % instantiate sources
        if usedInputs(idx) <= (length(settings.inputsList) - 6) % if it's a device
            sources(idx) = Source(Sourcetype.Audiodevice, usedInputs(idx) - 1, settings.sampleRate, '16-bit integer', settings.samplesPerFrame);
        else % if it's a file
            fileName = settings.inputsList(usedInputs(idx));
            sources(idx) = Source(Sourcetype.Audiofile, fileName{1});
        end
        % create empty Signal array 'inputSignals', which is as long as the input
        % drop down list:
        inputSignals(usedInputs(idx)) = Signal([], settings.sampleRate, Signaltype.Valuecontinuous);
    end
    
    % create modulator array
    for idx = 1:length(usedChannels)
        if     settings.modulationIndices(usedChannels(idx)) == 1
            modulator{idx} = DSBModulator(settings.carrierFrequencies(usedChannels(idx)));
        elseif settings.modulationIndices(usedChannels(idx)) == 2
            modulator{idx} = SSBModulator(settings.carrierFrequencies(usedChannels(idx)), 'LSB');
        elseif settings.modulationIndices(usedChannels(idx)) == 3
            modulator{idx} = SSBModulator(settings.carrierFrequencies(usedChannels(idx)), 'USB');
        end
        lpf{idx} = Filter.generateLowPass(settings.sampleRate, settings.bandwidth(idx) / 2 * 0.9, settings.bandwidth(idx) / 2); % 0.9 hard coded
        lpf{idx}.setPersistentMemory(true);
    end
    
    outputsig = Signal([], settings.sampleRate, Signaltype.Valuecontinuous);
    
    runloop = 1;
    while runloop
        outputsig.clear;
        % SIGNAL INPUT
        for idx = 1:length(sources)
            inputSignals(usedInputs(idx)) = sources(idx).step(settings.samplesPerFrame);
        end
        
        for idx = 1:length(usedChannels)
            % LOW PASS FILTER: BAND LIMITATION
            bandlimitedsignal = lpf{idx}.step(inputSignals(settings.inputsIndices(usedChannels(idx))));
            % MODULATION
            modulated = modulator{idx}.step(bandlimitedsignal);
            % ADDITION
            outputsig = outputsig + modulated;
        end
        
        % SIGNAL OUTPUT
        outputDevice.step(outputsig.normByMax); % or outputsig.normByMax
        
        pause(0.01); % time to react to the 'Stop' Button
        guih = guidata(GUIhandles.txtSampleRate); % guidata fetches the actual GUI handles; txtSampleRate is arbitrary chosen
        runloop = guih.runloop;
    end
    
    outputDevice.releaseDevice();
    for idx = 1:length(usedInputs)
        sources(idx).releaseDevice();
    end
end