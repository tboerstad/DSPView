function varargout = DSPView(varargin)
% DSPVIEW Framework for ultrasound processsing.
%      DSPView MATLAB framework for ultrasound B-mode, velocity, 
%      strain and elastographic processing. 
%
%      DSPView() will open up the GUI, see the YouTube video for a simple
%      demonstration: http://youtu.be/Y7wjaqBPt9o
%
%      
%
% See also: ImagingSystem, strainEstimatorLSQ, velocityEstimator

% Edit the above text to modify the response to help DSPView

% Last Modified by GUIDE v2.5 11-Oct-2013 15:54:36

% Begin initialization code - DO NOT EDIT
gui_Singleton = 0;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @DSPView_OpeningFcn, ...
    'gui_OutputFcn',  @DSPView_OutputFcn, ...
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
end
% End initialization code - DO NOT EDIT

function DSPView_OpeningFcn(hObject, ~, handles, varargin)
    % Add all folders to search path
    addpath(genpath(pwd))

    handles.output = hObject;
    handles.imagingSystem = [];
    handles.frameNo = 1;
    handles.displays = [];
    guidata(hObject, handles);

    % Enable the slider to notify other function when moved
    if verLessThan('matlab','7.12')
        addlistener(handles.slider, 'Action', ...
            @(src,evnt)sliderMoved(src, evnt, hObject));
    else
        addlistener(handles.slider, 'ContinuousValueChange', ...
            @(src,evnt)sliderMoved(src, evnt, hObject));
    end
end
function varargout = DSPView_OutputFcn(~, ~, handles)
varargout{1} = handles.output;
end



% ==================================================
% ------ Fig creation and deletion functions  ------
% ==================================================

function newFig(hObject, handles, displayType)

    % create the new display struct, which holds the figure handle
    currDisplay.fig = figure('DeleteFcn', ...
        @(src,evnt)figDeleteFnc(src, evnt, hObject, displayType));
    currDisplay.axes = axes('Parent',currDisplay.fig);
    set(currDisplay.axes,'FontSize', 14);
    currDisplay.modality = displayType;
    currDisplay.medFiltEn = 0;
    currDisplay.medFiltDim = [3,3];

    % Check to see if other displays exist, if so use their size
    if ~isempty(handles.displays)
        pos=get(handles.displays(end).fig,'position');
        set(currDisplay.fig, 'position', pos+[pos(3), 0,0,0]);
    end

    if strcmp(displayType,'rfLine') || strcmp(displayType, 'rfLineFreq')
        currDisplay = createPlotHandles(handles, currDisplay, displayType);
    else
        currDisplay = createPriAndSecHandle(handles, ...
            currDisplay, displayType);
    end

addDisplay(hObject, handles, currDisplay)
updateDisplay(handles, currDisplay);
end
function figDeleteFnc(~, ~, hObject, displayType)
    handles=guidata(hObject);
    removeDisplay(hObject, handles, displayType);
end

% A display represents a data set that will be visualized to the user,
% such as a b-mode image, velocity data or strain data. 
function addDisplay(hObject, handles, display)
    if isempty(handles.displays)
        handles.displays=display;
        enableColorPanel(handles);
        set(handles.figSelect,'String',{display.modality});
    else
        handles.displays(end+1)=display;
        figList=get(handles.figSelect,'String');
        figList=[figList; display.modality];
        set(handles.figSelect,'String', figList);
    end
    setActiveDisplay(handles, display);
    guidata(hObject, handles)
end
function removeDisplay(hObject, handles, displayType)
idx=idxOfDisplay(handles, displayType);
if idx
    handles.displays(idx)=[];
    guidata(hObject, handles);
    
    set(handles.(displayType), 'Value',0)
    noDisplays=length(handles.displays);
    if  noDisplays == 0 % All figures closed, disable figSelector
        set(handles.figSelect,'Enable','off');
    else % Still figures enabled, switch active figure
        figList = get(handles.figSelect, 'String');
        figList(idx)=[];
        set(handles.figSelect, 'String', figList);
        n=mod(idx-2,noDisplays)+1;
        setActiveDisplay(handles, handles.displays(n));
    end
end
end
function setActiveDisplay(handles, display)
    idx = idxOfDisplay(handles, display.modality);
    if idx
        set(handles.figSelect, 'Value', idx);
        cLim = get(display.axes, 'CLim');
        set(handles.cMin, 'string', num2str(cLim(1)));
        set(handles.cMax, 'string', num2str(cLim(2)));
        medFiltEn  = display.medFiltEn;
        medFiltDim = display.medFiltDim; 
        set(handles.medFiltEn, 'value', medFiltEn);
        set(handles.medFiltX, 'string', num2str(medFiltDim(1)));
        set(handles.medFiltY, 'string', num2str(medFiltDim(2)));
    end
end

% Image figures are contained in MATLAB handles. Since each image figure
% can potentially plot two images in the same view (background and 
% foreground), both a primary and a secondary handle is needed. 
% This function handles the creation of these handles, is responsible
% for aligning the two images, for setting the correct image labels, 
% aspect ratio and colormap. 
function currDisplay = createPriAndSecHandle(handles, currDisplay, displayType)
    % Get the primary image (foreground image) and associated axis
    im = handles.imagingSystem.getFrame(handles.frameNo, displayType);
    xAx  = handles.imagingSystem.getLateralAxis();
    yAx  = handles.imagingSystem.getDepthAxis();

    % Convert to uint8 image
    [cMin, cMax] = autoScale(im, displayType);
    im = uint8(thresholdAndScale(im, [cMin, cMax], 192))+64;

    % Need to know how to align the foreground (sub) image 
    % with the larger background image
    [xData, yData] = centerCoords(handles.imagingSystem.rfDim, size(im));

    % First display the background image
    backgroundImage = zeros(handles.imagingSystem.rfDim, 'uint8');
    currDisplay.secHandle = image([xAx(1), xAx(end)], [yAx(1), yAx(end)], ...
        backgroundImage, 'Parent', currDisplay.axes);
    hold(currDisplay.axes,'on');

    % Then the foreground image
    currDisplay.priHandle = image([xAx(xData(1)), xAx(xData(2))], ...
        [yAx(yData(1)), yAx(yData(2))], im, 'Parent', currDisplay.axes);

    % Update axis' labels 
    set(currDisplay.axes,'CLim',[cMin, cMax]);
    xlabel(currDisplay.axes, 'Lateral axis [mm]', 'FontSize', 14);
    ylabel(currDisplay.axes, 'Depth axis [mm]'  , 'FontSize', 14);


    % Fix the aspect ratio of the figure equal to that of the recording
    set(currDisplay.axes,'DataAspectRatio', ...
        [1, handles.imagingSystem.aspectRatio(), 1]);

    % Set the colormap;
    cMap = defaultCmap(displayType);
    if get(handles.mixEn,'Value') && isMixable(currDisplay.modality)   
        set(currDisplay.priHandle, 'alphadata', ...
                str2double(get(handles.alpha,'String')));
        set(currDisplay.secHandle, 'UserData' , bModeClim(handles));
    cMap = [gray(64); cMap];
    else
        cMap = [ones(64,3); cMap];
    end
    colormap(currDisplay.axes, cMap);
end

% createPlotHandles is responsible for creating new line plots of an RF
% data line, either in time or frequency domain. 
function currDisplay = createPlotHandles(handles, currDisplay, displayType)
    y=handles.imagingSystem.getLine(handles.frameNo, 36, displayType);
    if strcmp(displayType,'rfLine')
        x=handles.imagingSystem.getDepthAxis();
    else
        x=handles.imagingSystem.getFreqAxis();
    end
    currDisplay.secHandle=[];
    currDisplay.priHandle=plot(x,y);
    set(currDisplay.axes,'NextPlot','replacechildren');
    peak=max(abs(y));
    peak=peak+0.05*peak;
    if strcmp(displayType,'rfLine')
        xLab='Depth (mm)';
        yLab='Rf amplitude';
        set(currDisplay.axes, 'YLim',[-peak peak]);
    else
        xLab='Frequency (mHz)';
        yLab='Power spectrum estimate (dB)';
        set(currDisplay.axes, 'YLim',[peak-70 peak]);
    end
    set(get(currDisplay.axes,'XLabel'),'String',xLab);
    set(get(currDisplay.axes,'YLabel'),'String',yLab);
    set(currDisplay.axes, 'XLim',[x(1) x(end)]);
    grid(currDisplay.axes, 'on');
end

% =====================================
% ---- Visualization/Presentation -----
% =====================================
function drawAllModalities(handles)
    %tic
        for i=1:size(handles.displays,2)
            updateDisplay(handles, handles.displays(i));
        end
    %toc
end

% Refreshes a display when a new image data is available 
function updateDisplay(handles, display)
    if ~isImage(display.modality)
        updateRfLine(handles, display);
    else
        cLim = get(display.axes,'CLim');
        
        % If image pixel masking is enabled
        % we need to create an image mask. 
        if get(handles.qualityEn,'Value') && isMixable(display.modality)
            [im, alphaMat] = handles.imagingSystem.getFrame( ...
                handles.frameNo, display.modality);
            thr = str2double(get(handles.qualityThr, 'string'));
            alphaMat(alphaMat < thr)=0;
            alphaMat(alphaMat >= thr)=1; 
            alphaMat=bwareaopen(alphaMat, 300, 4);
            alphaMat=alphaMat*str2double(get(handles.alpha,'string'));
        else
            im = handles.imagingSystem.getFrame(handles.frameNo, ...
                display.modality);
            alphaMat = str2double(get(handles.alpha,'string'));
        end
    
        % Handles median filtering 
        if (display.medFiltEn)
            im = medfilt2(im, display.medFiltDim);
        end
    
        % Handles image scaling to the colormap, hardcoded to 192 colors
        scaledIm = uint8(thresholdAndScale(im,cLim,192))+64;
        set(display.priHandle, 'CData', scaledIm);
        
        % If we have to post process the image, (image masking or 
        % image mixing is enabled). 
        if  ( get(handles.mixEn,'Value') || get(handles.qualityEn,'value') ) ...
                && isMixable(display.modality)
            bMode=handles.imagingSystem.getFrame(handles.frameNo, 'bMode');
            bModeClim=get(display.secHandle,'UserData');
            if numel(bModeClim) == 0
                [mini, maxi] = autoScale(bMode,'bMode');
                bModeClim = [mini,maxi];
            end
            set(display.secHandle, 'CData', ...
                uint8(thresholdAndScale(bMode, bModeClim, 64)));
            set(display.priHandle, 'alphadata', alphaMat);
        end
    end
    title(display.axes, [display.modality, ', frame: ', ...
        num2str(handles.frameNo), '/', ...
        num2str(get(handles.slider,'Max'))]);
end
function updateRfLine(handles, display)
    [x]=handles.imagingSystem.getLine(handles.frameNo, 36, display.modality);
    set(display.priHandle,'YData',x);
end

% =====================================
% ----------- UI Callbacks ------------
% =====================================
function strainParamUpdate(hObject, ~, handles)
    dx=str2double(get(handles.dx,'String'));
    algList = get(handles.strainAlg,'String');
    strainAlg    = char(algList(get(handles.strainAlg,'Value')));
    handles.imagingSystem.strainEstParam(dx, strainAlg);
    strainDisps={'strain','absStrain','elasto'};
    for i=1:length(strainDisps)
        displayType=char(strainDisps(i));
        idx=idxOfDisplay(handles, displayType);
        if idx
            currDisplay=handles.displays(idx);
            cLim = get(currDisplay.axes,'CLim');
            currDisplay=createPriAndSecHandle(handles, currDisplay, displayType);
            set(currDisplay.axes,'CLim',cLim);
            handles.displays(idx)=currDisplay;
            updateDisplay(handles, currDisplay);
        end
    end
    guidata(hObject, handles);
end
function sliderMoved(sliderObj, ~, hObject)
    handles=guidata(hObject);
    sliderVal=floor(get(sliderObj,'Value')+0.49);
    if sliderVal ~=  handles.frameNo
        handles.frameNo=sliderVal;
        drawAllModalities(handles)
        guidata(hObject, handles);
    end
end
function cMapChanged(hObject, ~, handles)
    figList=get(handles.figSelect,'String');
    displayType=figList(get(handles.figSelect,'Value'));
    idx=idxOfDisplay(handles, displayType);
    if idx
        currDisplay=handles.displays(idx);
        cMin=str2double(get(handles.cMin,'string'));
        cMax=str2double(get(handles.cMax,'string'));
        set(currDisplay.axes,'Clim',[cMin, cMax]);
        updateDisplay(handles, currDisplay)
    end
    guidata(hObject, handles);
end

% Called when median filter settings are updated
function medFiltChanged(hObject, ~, handles)
    figList=get(handles.figSelect,'String');
    displayType=figList(get(handles.figSelect,'Value'));
    idx=idxOfDisplay(handles, displayType);
    if idx
        medFiltEn   = get(handles.medFiltEn, 'value');
        medFiltX    = str2double(get(handles.medFiltX, 'string'));
        medFiltY    = str2double(get(handles.medFiltY, 'string'));
        medFiltDim  = [medFiltX, medFiltY];
        handles.displays(idx).medFiltEn  = medFiltEn;
        handles.displays(idx).medFiltDim = medFiltDim;
        guidata(hObject, handles);
        updateDisplay(handles, handles.displays(idx));
    end
end
% Called when play button is pressed
function play(hObject, ~, handles)
    for i=handles.frameNo+1:get(handles.slider,'Max')
        handles.frameNo=handles.frameNo+1;
        drawAllModalities(handles)
        drawnow
        set(handles.slider,'Value',handles.frameNo);
    end
    guidata(hObject, handles);

end
% Called when the figure selection drop-down menu changes
function figSelect_Callback(~, ~, handles)
    figList=get(handles.figSelect,'String');
    displayType=figList(get(handles.figSelect,'Value'));    
    idx=idxOfDisplay(handles, displayType);
    if idx
        newDisplay=handles.displays(idx);
        setActiveDisplay(handles, newDisplay);
    end
end
% Called when the different modality checkboxes change
function modality_Callback(hObject, ~, handles)
    if get(hObject,'Value')
        newFig(hObject, handles, get(hObject,'Tag'));
    else
        idx=idxOfDisplay(handles, get(hObject, 'Tag'));
        if idx
            delete(handles.displays(idx).fig);
        end
    end
end
% Called when the color map settings are updated
function autoCmap_Callback(hObject, ~, handles)
    idx=get(handles.figSelect, 'Value');
    if isstruct(handles.displays)
        display=handles.displays(idx);
        im=handles.imagingSystem.getFrame(handles.frameNo, display.modality);
        [cMin,cMax]=autoScale(im, display.modality);
        set(handles.cMin, 'string', num2str(cMin));
        set(handles.cMax, 'string', num2str(cMax));
        cMapChanged(hObject, 0, handles);
    end
end
% Called when the color bar button is pushed
function cBar_Callback(~, ~, handles)
    idx=get(handles.figSelect, 'Value');
    if isstruct(handles.displays)
        display=handles.displays(idx);
        cMin = str2double(get(handles.cMin, 'string'));
        cMax = str2double(get(handles.cMax, 'string'));
        cLim = [cMin, cMax];
        cMap = colormap(display.axes);
        cMap=cMap(65:end,:);
    
        switch(display.modality)
            case 'vel'
                cLim=cLim*1e03;
                unit='mm/s';
            case {'strain', 'absStrain'}
                cLim=cLim*1e03;
                unit='10^{-3}';
            otherwise
                unit='';
        end      
        createColorbar(cLim, cMap, unit);
    end
end
% Called when the velocity estimator settings are updated
function velParamUpdate(hObject, ~, handles)
    rngGate      = str2double(get(handles.rngGate,'String'));
    latGate      = str2double(get(handles.latGate,'String'));
    ensLength    = str2double(get(handles.ensLength,'String'));
    velFiltOrder = str2double(get(handles.velFiltOrder,'String'));
    velFiltCutOff= str2double(get(handles.velFiltCutOff,'String'));
    twoDimCorrEn = get(handles.twoDimCorrEn,'Value');
    fDem         = str2double(get(handles.fDem,'String'));
    unwrapEn     = get(handles.unwrapEn,'Value');


    handles.imagingSystem.velEstParam(rngGate, latGate, twoDimCorrEn, ...
        fDem, unwrapEn, ensLength, velFiltOrder, velFiltCutOff);
    displayType='vel';
    idx=idxOfDisplay(handles, displayType);
    if idx
        currDisplay=handles.displays(idx);
        cLim = get(currDisplay.axes,'CLim');
        currDisplay=createPriAndSecHandle(handles, currDisplay, displayType);
        set(currDisplay.axes,'CLim',cLim);
        handles.displays(idx)=currDisplay;
        updateDisplay(handles, currDisplay);
    end
    strainParamUpdate(hObject, 0, handles);
end
% Called when the RF filter settings are updated
function rfFiltUpdate(~, ~, handles)
    enable=get(handles.filtEn,'Value');
    order=str2double(get(handles.filtOrder, 'String'));
    fMin=str2double(get(handles.filtLow, 'String'));
    fMax=str2double(get(handles.filtHigh, 'String'));
    handles.imagingSystem.rfFilt(enable, order, [fMin, fMax]);
    drawAllModalities(handles);
end
% Called when the visualization settings are updated
function visualizationUpdate(~, ~, handles)
if get(handles.mixEn, 'Value')
    cLim = bModeClim(handles);
    for i=1:size(handles.displays,2)
        currDisplay=handles.displays(i);
        if isMixable(currDisplay.modality)
            cMap=colormap(currDisplay.axes);
            cMap(1:64,:)=gray(64);
            colormap(currDisplay.axes, cMap);
            set(currDisplay.priHandle,'alphadata', str2double(get(handles.alpha,'String')));
            set(currDisplay.secHandle,'UserData', cLim);
            updateDisplay(handles, currDisplay);
        end
    end
else
    for i=1:size(handles.displays,2)
        currDisplay=handles.displays(i);
        if isMixable(currDisplay.modality)
            cMap=colormap(currDisplay.axes);
            cMap(1:64,:)=ones(64,3);
            colormap(currDisplay.axes, cMap);
            set(currDisplay.priHandle,'alphadata', 1.0);
            updateDisplay(handles, currDisplay);
        end
    end
end
end
% Called when the elastogram settings are updated
function elastoParamUpdate(~, ~, handles)
eFiltOrder = str2double(get(handles.eFiltOrder,'String'));
eThr       = str2double(get(handles.eThr,'String'));
handles.imagingSystem.elastoParam(eFiltOrder, eThr);
idx=idxOfDisplay(handles, 'elasto');
if idx
    updateDisplay(handles, handles.displays(idx));
end
end
% Called when File->Load is pressed
function Load_Callback(hObject, ~, handles)
[fileName, pathName, filterIndex]=uigetfile( ...
    {'*.mat;*.rf','RF data (*.mat, *.rf)'});
switch filterIndex
    case 0 % User pressed cancel
        set(handles.slider,'Enable','off');
        return
    case 1 % load RF-data file
        handles.imagingSystem=ImagingSystem([pathName, fileName]);
end
enableUi(handles);
newFig(hObject, handles, 'bMode');
end
% Called when "File->Save all as images" is pressed 
function saveAllToFile(~, ~, handles)
folder_name = uigetdir();
if folder_name
    ratio=handles.imagingSystem.aspectRatio;
    for j=1:size(handles.displays,2)
        currDisplay=handles.displays(j);
        if isImage(currDisplay.modality)
            mkdir([folder_name,'/',currDisplay.modality])
        end
    end
    h=waitbar(0,'Storing visible figures to disk');
    for i=1:get(handles.slider,'Max')
        for j=1:size(handles.displays,2)
            currDisplay=handles.displays(j);
            if isImage(currDisplay.modality)
                im=handles.imagingSystem.getFrame(i, currDisplay.modality);
                cLim=get(currDisplay.axes,'CLim');
                cMap=colormap(currDisplay.axes);
                cMap=cMap(65:end,:);
                im=imresize(im,[size(im,1),floor(size(im,1)*ratio)]);
                
                
                if strcmp(currDisplay.modality,'elasto')
                    im=medfilt2(uint8(thresholdAndScale(im,cLim, 256)));
                    im=histeq(im,64);
                    cMap=jet(256);
                else
                    im=uint8(thresholdAndScale(im,cLim, 192));
                end
                % extra stuff
                imwrite(im, cMap,strcat(sprintf('%s/%s/%.4d',folder_name,currDisplay.modality,i),'.png'));
            end
        end
        waitbar(i/get(handles.slider,'Max'));
    end
end
close(h);
end
% Called when "File->Export to workspace" is pressed 
function exportDataToWorkspace(~, ~, handles)
    assignin('base','imSystem', handles.imagingSystem);
end
% Called when "File->Preprocess all frames" is pressed.
function preprocessAll(~, ~, handles)
    N=handles.imagingSystem.noFrames();
    handles.imagingSystem.setBufLength(N);
    h=waitbar(1/N);
    for i = 1:N
    [~,~]=handles.imagingSystem.getFrame(i,'strain');
    waitbar(i/N);
    end
    delete(h);
end
function closeAll(~, ~, handles)
    try
        if isstruct(handles.displays)
            for i=1:size(handles.displays,2)
                delete(handles.displays(i).fig);
            end
        end
        % Attempt to close file.
        if ~isempty(handles.imagingSystem)
            handles.imagingSystem.close();
        end
    catch exc
        warning('GUI:failedToClose','Caught exception: ');
        disp(exc);
    end
    delete(gcf);
end

% =====================================
% -------- Misc functions --------
% =====================================
function b=isImage(modality)
    if strcmp(modality, 'rfLine') || ...
            strcmp(modality, 'rfLineFreq')
        b=0;
    else
        b=1;
    end
end
function b=isMixable(modality)
    if strcmp(modality, 'bMode') || ...
            strcmp(modality, 'rfLine') || ...
            strcmp(modality, 'rfLineFreq')
        b=0;
    else
        b=1;
    end
end
function cMap = defaultCmap(displayType)
    switch (displayType)
        case 'bMode'
         cMap = gray(192);
        case 'vel'
            cMap = velMap192;
        case 'absStrain'
            cMap = (hot(192));
        otherwise
            cMap = jet(192);
    end
end
function idx=idxOfDisplay(handles, displayType)
    idx=find(ismember({handles.displays.modality},displayType),1);
    if isempty(idx)
        idx=0;
    end
end
function enableUi(handles)
    N=handles.imagingSystem.noFrames;
    set(handles.slider,'Max',N);
    set(handles.slider,'SliderStep',[1/(N-1), 10/(N-1)]);
    set(handles.slider,'Value',1);
    set(handles.slider,'Enable','on');
    set(handles.bMode, 'Enable','on');
    set(handles.bMode, 'Value',1);
    set(handles.vel, 'Enable','on');
    set(handles.strain, 'Enable','on');
    set(handles.absStrain, 'Enable','on');
    set(handles.rfLine, 'Enable','on');
    set(handles.rfLineFreq, 'Enable','on');
end
function enableColorPanel(handles)
    set(handles.figSelect, 'Enable','on');
    set(handles.cMax,'Enable', 'on');
    set(handles.cMin,'Enable', 'on');
end
function cLim = bModeClim(handles)
    idx=idxOfDisplay(handles, 'bMode');
    if idx
        cLim=get(handles.displays(idx).axes,'CLim');
    else
        bModeFrame=handles.imagingSystem.getFrame(handles.frameNo, 'bMode');
        [cMin, cMax]=autoScale(bModeFrame, 'bMode');
        cLim = [cMin, cMax];
    end
end
