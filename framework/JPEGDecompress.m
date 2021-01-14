function decomp = JPEGDecompress(signal)
% JPEGDECOMPRESS returns a Signal object with an uint8 vector containing 
% bytes of the uncompressed JPEG file.
% This is the inverse function to JPEGCompress.
% It's universally usable; e.g. for audio signals.
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
vectorized = permute(image, [3 1 2]); % stack RGB values one after each other
vectorized = vectorized(:);
decomp = Signal(vectorized, signal.fs, Signaltype.Bytes, signal.details);
delete(filename);

end