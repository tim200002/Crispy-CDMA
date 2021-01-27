classdef Analyzer
    methods
        function obj = Analyzer()
        end
        
        function [bitErrorRate, numbersOfErrors]= calculateBitErrorRate(obj, referenceSignal, receivedSignal)
            diffArray = abs(referenceSignal.data-receivedSignal.data);
            numbersOfErrors = sum(diffArray);
            bitErrorRate = numbersOfErrors/referenceSignal.length;
        end
        
        function plotConstellation(obj, signal, referenceValues)
            scatter(real(signal.data), imag(signal.data));
            xlabel('I') 
            ylabel('Q')
            axis([-1 1 -1 1]);
            hold on
            if exist('referenceValues','var')
            scatter(real(referenceValues), imag(referenceValues), 'red');
            end
            hold off
        end
        
        function plotBitErrorRateOverTime(obj, referenceSignal,receivedSignal , intervallLength)
            [startRef, endRef] = obj.splitIntoArraysToReshape(referenceSignal, intervallLength);
            [startRec, endRec] = obj.splitIntoArraysToReshape(receivedSignal, intervallLength);
            
            shapedRef = reshape(startRef, intervallLength ,[]);
            shapedRec = reshape(startRec, intervallLength,[]);
            
            bitRatesPerIntervall = sum(abs(shapedRef-shapedRec))/intervallLength;
            
            bitRatesPerIntervall = [bitRatesPerIntervall sum(abs(endRef-endRec))/length(endRef)];
            xValues = 0:intervallLength:intervallLength*(length(bitRatesPerIntervall)-1);
            plot(xValues,bitRatesPerIntervall);
            ylabel(sprintf('BER for intervalls of size %d', intervallLength));
            xlabel('Index');
        end
        
        function [largeArray, rest] = splitIntoArraysToReshape(obj, signal, intervallLength)
             signalData = signal.data;
            numberOfNotMatchingElements = mod(length(signalData), intervallLength);
            endArray = signalData(end-numberOfNotMatchingElements:end);
            signalData = signalData(1:end-numberOfNotMatchingElements);
            largeArray= signalData;
            rest = endArray;
        end
    end
end