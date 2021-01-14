function image = JPEGDecompressImage(signal)
% JPEGDECOMPRESSIMAGE returns (length x width x 3) uint8 matrix, that e.g. 
% can be displayed with image().
% This is the inverse function to JPEGCOMPRESSIMAGE.
% arguments:
% (1) signal: Signal object containing an uint8 vector, that represents a JPEG file

filename = ['tempFile' date '.jpg'];
fileSaver = Sink();
fileSaver.step(signal);
fileSaver.saveBytesToFile(filename);
try
    image = imread(filename);
catch
    warning("JPEG file corrupted, could not decompress");
    image = zeros(1, 1, 3);
end
delete(filename);

end