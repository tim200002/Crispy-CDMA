classdef CDMAEncoder
    properties
        walshMatrix %matrix of wals code
        codeLength
    end
    methods
         function obj = CDMAEncoder(codeLength)
             obj.codeLength = codeLength;
             obj.walshMatrix = hadamard(codeLength);
         end
         
         function retSignal = step(obj, signalToBeEncoded, walshIndex)
             walshSequence = obj.walshMatrix(:,walshIndex); %This is the Code for the current index (row)
             bipolarSignal = obj.makeBipolar(signalToBeEncoded);
             
             encodedData = [];
             %Create new data row
             for i =1:bipolarSignal.length
                 encodedData = [encodedData, bipolarSignal.data(i).*walshSequence];
             end
             
             retSignal = Signal(encodedData, bipolarSignal.fs*obj.codeLength);
             retSignal.signaltype = Signaltype.Valuecontinuous;
                          
         end
         
         function retSig = makeBipolar(obj, signal)
             retSig =Signal( 2*signal.data-1,signal.fs);
             retSig.signaltype = Signaltype.Valuecontinuous;
         end
         
         function matrix = getWalshMatrix(obj)
             matrix=obj.walshMatrix;
         end
    end

end