classdef AdvancedImageSerializer < handle
    %ADVANCEDIMAGESERIALIZER Summary of this class goes here
    %   Serializer to Transmit Images in Columns
    
    properties
        colorResolution % color Resolution of the Image
        img % the Image that needs to be Transmitted
        c_marker % column marker
        max_cols % number of columns
        done_serializing % done Marker
        x
    end
    
    methods
        function obj = AdvancedImageSerializer(pathToImage, colorResolutionInBits)
            %ADVANCEDIMAGESERIALIZER Construct an instance of this class
            %path to Image -> Path to Image
            %colorResolutionInBits -> color Resolution in Bits (4/8)
            
            %init Variabels
            obj.c_marker = 1;
            obj.colorResolution = colorResolutionInBits;
            obj.done_serializing = false;
            % Reads Image and converts to RGB
            [obj.x,obj.img] = imread(pathToImage);
            if isempty(obj.img)
               %image is already rgb
               obj.img = obj.x;
            else
                %image needs to be converted to RGB
               obj.img = ind2rgb(obj.x,obj.img);
            end
            
            obj.max_cols = size(obj.img,1);
            
            if colorResolutionInBits == 4
                obj.img = obj.downscaleImageTo4Bits();
            end
        end
        
        function [signal, done,obj] = getNextSignal(obj)
            done = false;
            if obj.c_marker >= obj.max_cols
                obj.done_serializing = true;
                done = true;
            end
            
            if obj.done_serializing ~= true
            
            for n = 1:3
                colorMat = obj.img(:,obj.c_marker,n);
                signal(n,:) = reshape(de2bi(colorMat(:,1),obj.colorResolution),1,[]); 
             end
             obj.c_marker = obj.c_marker +1;
            end
            if exist('signal','var') == 0
                signal = nan;
            end
        end
        
        function  downscaledImage = downscaleImageTo4Bits(obj)
            downscaledImage = obj.img / 17;
        end
    end
end

