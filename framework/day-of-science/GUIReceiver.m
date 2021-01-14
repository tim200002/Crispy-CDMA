function varargout = GUIReceiver(varargin)
% GUIReceiver MATLAB code for GuiReceiver.fig
%      GUIReceiver, by itself, creates a new GUIReceiver or raises the existing
%      singleton*.
%
%      H = GUIReceiver returns the handle to a new GUIReceiver or the handle to
%      the existing singleton*.
%
%      GUIReceiver('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in GUIReceiver.M with the given input arguments.
%
%      GUIReceiver('Property','Value',...) creates a new GUIReceiver or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before GuiReceiver_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to GuiReceiver_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help GuiReceiver

% Last Modified by GUIDE v2.5 22-May-2019 14:56:19

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @GUIReceiver_OpeningFcn, ...
                   'gui_OutputFcn',  @GUIReceiver_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before GuiReceiver is made visible.
function GUIReceiver_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to GuiReceiver (see VARARGIN)

% Choose default command line output for GuiReceiver
handles.output = hObject;

handles.settings = ReceiverSettings();
handles.popMnInputDevice.set('String', handles.settings.getInputDevices());
handles.popMnModulation.set('String', handles.settings.modulationsList);
handles.popMnOutputDevice.set('String', handles.settings.getOutputDevices());
handles.popMnOutputChannel.set('String', handles.settings.channelList);

% Update handles structure
guidata(hObject, handles);

updateChannelEntries(handles, 1);
updateSettings(handles);

% UIWAIT makes GuiReceiver wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = GUIReceiver_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: delete(hObject) closes the figure
btRxStop_Callback(hObject, eventdata, handles);
delete(hObject);



% --- Executes on button press in btRxStart.
function btRxStart_Callback(hObject, eventdata, handles)
% hObject    handle to btRxStart (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.btRxStop,'Enable','on'); % change button 'pressability'
set(handles.btRxStart,'Enable','off');
handles.runloop = 1;
guidata(hObject,handles);
drawnow();
receiving(handles);


% --- Executes on button press in btRxStop.
function btRxStop_Callback(hObject, eventdata, handles)
% hObject    handle to btRxStop (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.btRxStop,'Enable','off'); % change button 'pressability'
set(handles.btRxStart,'Enable','on');
handles.runloop = 0;
guidata(hObject,handles);
drawnow();


function txtSampleRate_Callback(hObject, eventdata, handles)
% hObject    handle to txtSampleRate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txtSampleRate as text
%        str2double(get(hObject,'String')) returns contents of txtSampleRate as a double
handles.settings.sampleRate = str2double(hObject.get('String'));


function txtSamplesPerFrame_Callback(hObject, eventdata, handles)
% hObject    handle to txtSamplesPerFrame (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txtSamplesPerFrame as text
%        str2double(get(hObject,'String')) returns contents of txtSamplesPerFrame as a double
handles.settings.samplesPerFrame = str2double(hObject.get('String'));


% --- Executes on selection change in popMnInputDevice.
function popMnInputDevice_Callback(hObject, eventdata, handles)
% hObject    handle to popMnInputDevice (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popMnInputDevice contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popMnInputDevice
handles.settings.inputDeviceIndex = hObject.get('Value');


function txtNumberOfChannels_Callback(hObject, eventdata, handles)
% hObject    handle to txtNumberOfChannels (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txtNumberOfChannels as text
%        str2double(get(hObject,'String')) returns contents of txtNumberOfChannels as a double
handles.settings.setNChannels(str2double(hObject.get('String')));
handles.listboxConfig.set('Value', 1);
updateChannelEntries(handles);


function txtFc_Callback(hObject, eventdata, handles)
% hObject    handle to txtFc (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txtFc as text
%        str2double(get(hObject,'String')) returns contents of txtFc as a double
selectedChannel = handles.listboxConfig.get('Value');
handles.settings.carrierFrequencies(selectedChannel) = str2double(hObject.get('String'));
updateChannelEntries(handles);


function txtBandwidth_Callback(hObject, eventdata, handles)
% hObject    handle to txtBandwidth (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txtBandwidth as text
%        str2double(get(hObject,'String')) returns contents of txtBandwidth as a double
selectedChannel = handles.listboxConfig.get('Value');
handles.settings.bandwidth(selectedChannel) = str2double(hObject.get('String'));
updateChannelEntries(handles);


% --- Executes on selection change in popMnOutputDevice.
function popMnOutputDevice_Callback(hObject, eventdata, handles)
% hObject    handle to popMnOutputDevice (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popMnOutputDevice contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popMnOutputDevice
selectedChannel = handles.listboxConfig.get('Value');
handles.settings.outputDevicesIndices(selectedChannel) = hObject.get('Value');
updateChannelEntries(handles);


% --- Executes on selection change in popMnOutputChannel.
function popMnOutputChannel_Callback(hObject, eventdata, handles)
% hObject    handle to popMnOutputChannel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popMnOutputChannel contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popMnOutputChannel
selectedChannel = handles.listboxConfig.get('Value');
handles.settings.channelIndices(selectedChannel) = hObject.get('Value');
updateChannelEntries(handles);


% --- Executes on selection change in popMnModulation.
function popMnModulation_Callback(hObject, eventdata, handles)
% hObject    handle to popMnModulation (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popMnModulation contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popMnModulation
selectedChannel = handles.listboxConfig.get('Value');
handles.settings.modulationIndices(selectedChannel) = hObject.get('Value');
updateChannelEntries(handles);


% --- Executes on selection change in listboxConfig.
function listboxConfig_Callback(hObject, eventdata, handles)
% hObject    handle to listboxConfig (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns listboxConfig contents as cell array
%        contents{get(hObject,'Value')} returns selected item from listboxConfig
updateChannelEntries(handles);


% --- Executes on button press in btSave.
function btSave_Callback(hObject, eventdata, handles)
% hObject    handle to btSave (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[filename, path] = uigetfile;
fullPath = strcat(path, filename);
if length(filename) > 0
    se = handles.settings;
    save(fullPath, 'se');
end

% --- Executes on button press in btLoad.
function btLoad_Callback(hObject, eventdata, handles)
% hObject    handle to btLoad (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[filename, path] = uigetfile;
fullPath = strcat(path, filename);
if length(filename) > 0
    load(fullPath); % settings are stored with variable name 'se'
    handles.settings = se;
    %guidata(hObject, handles); % update handles
    updateSettings(handles);
    updateChannelEntries(handles, 1);
end


function updateSettings(handles)
guidata(handles.txtSampleRate, handles); % update handles

handles.txtSampleRate.set('String', string(handles.settings.sampleRate));
handles.txtSamplesPerFrame.set('String', string(handles.settings.samplesPerFrame));
handles.txtNumberOfChannels.set('String', string(handles.settings.nChannels));
handles.popMnInputDevice.set('Value', handles.settings.inputDeviceIndex);

guidata(handles.txtSampleRate, handles); % update handles


function updateChannelEntries(handles, varargin)
if nargin == 1 % if selected channel number must be determined
    selectedChannel = handles.listboxConfig.get('Value');
elseif nargin == 2 % if selected channel number is given
    selectedChannel = varargin{1};
    handles.listboxConfig.set('Value', selectedChannel);
end
handles.txtFc.set('String', handles.settings.carrierFrequencies(selectedChannel));
handles.txtBandwidth.set('String', handles.settings.bandwidth(selectedChannel));
handles.popMnOutputDevice.set('Value', handles.settings.outputDevicesIndices(selectedChannel));
handles.popMnOutputChannel.set('Value', handles.settings.channelIndices(selectedChannel));
handles.popMnModulation.set('Value', handles.settings.modulationIndices(selectedChannel));
handles.listboxConfig.set('String', handles.settings.getConfigurationAsStringCells());
