function checkOffsetWithScatterPlot2(signal, symbolRate, carrierFreq, lpf)% lpf = psh.filterimpulseresponse; % for matched filter
% CHECKOFFSETWITHSCATTERPLOT2 visualizes the phase or frequency offset of
% the Signal object "signal" in a scatter plot.
% In comparison to CHECKOFFSETWITHSCATTERPLOT the signal is mixed before
% scatter plot generation.

sco = Scope();
% TODO: second plot with eye diagram, see:
% sco.plotEyeDiagramWithSlider(signal, 1/symbolRate);

% initital plot with zero as offset
offset = 0;
initialSampleRate = signal.fs;
phaseoffset = 0;


mix2 = Mixer(Mixertype.ComplexConjugate, carrierFreq);
mixedrecsignal = mix2.step(signal);
demodrecsignal = lpf.step(mixedrecsignal);
sampled = sample(demodrecsignal, symbolRate, offset);
sco.plotScatter(sampled);



% save axis, so that they will not change during sliding:
savedaxes = axis;

SliderOffset      = uicontrol('style','slider','position',[0 0  500 20]);
SliderSamplerate  = uicontrol('style','slider','position',[0 20 1200 20]);
SliderPhaseoffset = uicontrol('style','slider','position',[0 40 500 20]);
addlistener(SliderOffset,      'Value', 'PostSet', @callbackfnoffset);
addlistener(SliderSamplerate,  'Value', 'PostSet', @callbackfnsamplerate);
addlistener(SliderPhaseoffset, 'Value', 'PostSet', @callbackfnphaseoffset);
TextOffset      = uicontrol('style','text','position',[500 0  200 20], 'HorizontalAlignment', 'left');
TextSymbolrate  = uicontrol('style','text','position',[1200 20 200 20], 'HorizontalAlignment', 'left');
TextPhaseoffset = uicontrol('style','text','position',[500 40 200 20], 'HorizontalAlignment', 'left');

    function callbackfnoffset(source, eventdata)
        num          = get(eventdata.AffectedObject, 'Value');
        offset = num;
        TextOffset.String = num2str(offset) + " sampling offset factor";
        
        sampled = sample(demodrecsignal, symbolRate, offset);
        sco.plotScatter(sampled);
        axis manual;
        axis(savedaxes);
    end

    function callbackfnsamplerate(source, eventdata)
        num          = get(eventdata.AffectedObject, 'Value');
        sampleRate = initialSampleRate + 2*(num - 0.5);%initialSampleRate * (num - 0.5) * 0.01;
        TextSymbolrate.String = num2str(sampleRate) + " Samplerate in Hz";
        
        signal.fs = sampleRate;
        mixedrecsignal = mix2.step(signal);
        demodrecsignal = lpf.step(mixedrecsignal);
        sampled = sample(demodrecsignal, symbolRate, offset);
        sco.plotScatter(sampled);
%         axis manual;
%         axis(savedaxes);
    end

    function callbackfnphaseoffset(source, eventdata)
        num          = get(eventdata.AffectedObject, 'Value');
        phaseoffset = 2*pi*num;
        TextPhaseoffset.String = num2str(num) + "* 2pi Phaseoffset (rad)";
        
        mix2.memoryPhase = phaseoffset;
        mixedrecsignal = mix2.step(signal);
        demodrecsignal = lpf.step(mixedrecsignal);
        sampled = sample(demodrecsignal, symbolRate, offset);
        sco.plotScatter(sampled);
        axis manual;
        axis(savedaxes);
    end
end