classdef ScopeYAxis
    enumeration
        Magnitude       % magnitude linear
        dB              % magnitude log
        Real            % only real part of amplitude
        Imaginary       % only imag part of amplitude
        RealAndImag     % both real and imag part of amplitude in one diagram
        MagAndPhase     % magnitude log and phase beneath each other
    end
end