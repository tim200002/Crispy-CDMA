function checkOffsetWithScatterPlot(signal, symbolRate)
% CHECKOFFSETWITHSCATTERPLOT visualizes the phase or frequency offset of
% the Signal object "signal" in a scatter plot

sco = Scope();
% TODO: second plot with eye diagram, see:
% sco.plotEyeDiagramWithSlider(signal, 1/symbolRate);

% initital plot with zero as offset
offset = 0;
initialSymbolRate = symbolRate;
sampled = sample(signal, initialSymbolRate, offset);
sco.plotScatter(sampled);

% save axis, so that they will not change during sliding:
savedaxes = axis;

SliderOffset = uicontrol('style','slider','position',[0 0 500 20]);
SliderSymbolrate = uicontrol('style','slider','position',[0 20 500 40]);
addlistener(SliderOffset, 'Value', 'PostSet', @callbackfnoffset);
addlistener(SliderSymbolrate, 'Value', 'PostSet', @callbackfnsymbolrate);
TextOffset = uicontrol('style','text','position',[500 0 150 20]);
TextSymbolrate = uicontrol('style','text','position',[500 20 150 40]);

    function callbackfnoffset(source, eventdata)
        num          = get(eventdata.AffectedObject, 'Value');
        offset = num;
        TextOffset.String = "Offset factor " + num2str(offset);
        sampled = sample(signal, symbolRate, offset);
        sco.plotScatter(sampled);
%         axis manual;
%         axis(savedaxes);
    end

    function callbackfnsymbolrate(source, eventdata)
        num          = get(eventdata.AffectedObject, 'Value');
        symbolRate = initialSymbolRate + initialSymbolRate * (num - 0.5) * 1;
        TextSymbolrate.String = "Symbolrate in Baud " + num2str(symbolRate);
        sampled = sample(signal, symbolRate, offset);
        sco.plotScatter(sampled);
        axis manual;
        axis(savedaxes);
    end
end