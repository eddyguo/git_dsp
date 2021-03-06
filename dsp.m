function varargout = dsp(varargin)
% --- 数字音频分析与处理系统
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @dsp_OpeningFcn, ...
    'gui_OutputFcn',  @dsp_OutputFcn, ...
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


% --- Executes just before dsp is made visible.
function dsp_OpeningFcn(hObject, eventdata, handles, varargin)

% Choose default command line output for dsp
handles.output = hObject;

% 设置坐标轴
set(gcf,'defaultAxesXGrid','off', ...
    'defaultAxesYGrid','off', ...
    'defaultAxesZGrid','off');

% 初始化
movegui(gcf,'center'); % figure居中
handles.Sample=[]; % 初始化样本为空
handles.CSample=[]; % 初始化样本副本
handles.volume=0; % 初始化音量为0
handles.Fs=0; % 初始化采样率

if (exist('speech_database.mat','file')==2)
    load('speech_database.mat','-mat');
    handles.data=data;
    c=data2cell(handles.data);
else
    c=cell(0,0);
end
set(handles.data_uitable,'Data',c);

% Update handles structure
guidata(hObject, handles);

% --- Outputs from this function are returned to the command line.
function varargout = dsp_OutputFcn(hObject, eventdata, handles)

% Get default command line output from handles structure
varargout{1} = handles.output;


function record_radiobutton_Callback(hObject, eventdata, handles)

function file_radiobutton_Callback(hObject, eventdata, handles)

% --- 显示文件路径
function filepath_edit_Callback(hObject, eventdata, handles)

function filepath_edit_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function fs_popupmenu_Callback(hObject, eventdata, handles)

function fs_popupmenu_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- 文件输入音频
function file_choose_pushbutton_Callback(hObject, eventdata, handles)
[filename,pathname]=uigetfile({'*.wav;*.mp3;*.flac;*.m4a', ...
    '音频文件(*.wav,*.mp3,*.flac,*.m4a)'},'选择文件');%弹出选择文件窗口
% 判断文件为空
% 不能使用if isempty(filename)||isempty(pathname)
% 取消窗口时会报错，取消时uigetfile返回filename为0
if filename==0
    return
else
    handles.Filepath=[pathname,filename];
    set(handles.filepath_edit,'string',handles.Filepath);% 显示文件名
    [handles.Sample,handles.Fs]=audioread(handles.Filepath);% 读取音频文件
    % 若输入音频为双声道，则使用一个通道
    samplesize=size(handles.Sample);
    if samplesize(2)>1
        handles.Sample=handles.Sample(:,1);
    end
    handles.CSample=handles.Sample;% 创建副本
    handles.player=audioplayer(handles.CSample,handles.Fs);
    setplayer(handles);
    
    set(handles.play_pushbutton,'enable','on');
    set(handles.play_stop_pushbutton,'enable','on');
    set(handles.putfile_pushbutton,'enable','on');
    
    guidata(hObject,handles);
end


% --- 录音按钮
function record_start_pushbutton_Callback(hObject, eventdata, handles)
fs_list=get(handles.fs_popupmenu,'string');% 获取列表
fs_value=get(handles.fs_popupmenu,'value');% 获取参数序号
fs=str2double(fs_list{fs_value});% 获取选定采样率
% list类型为cell必须转换
handles.Fs=fs;

handles.recObj=audiorecorder(fs,16,1);% 创建一个录音器

set(handles.recObj,'StartFcn',{@recordstart_Callback,handles}, ...
    'StopFcn',{@recordstop_Callback,handles}); % 录音回调

record(handles.recObj);% 开始录音

guidata(hObject,handles);

% --- 停止录音按钮
function record_stop_pushbutton_Callback(hObject, eventdata, handles)
stop(handles.recObj);% 停止录音
handles.Sample=getaudiodata(handles.recObj);% 获取录音
handles.CSample=handles.Sample;% 创建副本
handles.player=audioplayer(handles.CSample,handles.Fs);
setplayer(handles);

guidata(hObject,handles);

% --- 播放器设置
function setplayer(handles)
% 创建player回调函数
set(handles.player,'StartFcn',{@playstart_Callback,handles}, ...
    'StopFcn',{@playstop_Callback,handles});

% 音频信息
sample_length=length(handles.Sample); % 音频时长
t=sample_length/handles.Fs;
set(handles.timeinfo_text,'String',['时长：',num2str(t),'s']); % 显示时长
set(handles.fsinfo_text,'String',['采样率：',num2str(handles.Fs),'Hz']); % 显示采样率

% plot wave
audio_analyze(handles.Sample,handles.Fs,handles.axes1,handles); % 绘制初始样本
audio_analyze(handles.CSample,handles.Fs,handles.axes2,handles);% 绘制样本副本

nvar=std(handles.Sample).^2; % 初始方差
set(handles.nvar_edit,'String',round(nvar,3,'significant'));
nmean=mean(handles.Sample); % 初始均值
set(handles.nmean_edit,'String',round(nmean,3,'significant'));
dvar=std(handles.CSample).^2; % 样本方差
set(handles.dvar_edit,'String',round(dvar,3,'significant'));
dmean=mean(handles.CSample); % 样本均值
set(handles.dmean_edit,'String',round(dmean,3,'significant'));


% --- 播放按钮
function play_pushbutton_Callback(hObject, eventdata, handles)
play(handles.player);% 开始播放

% --- 停止播放按钮
function play_stop_pushbutton_Callback(hObject, eventdata, handles)
stop(handles.player);% 停止播放

% --- 输入方式按钮组
function uibuttongroup1_SelectionChangedFcn(hObject, eventdata, handles)
switch get(hObject,'tag')
    case 'record_radiobutton'
        set(handles.fs_popupmenu,'enable','on');
        set(handles.record_start_pushbutton,'enable','on');
        set(handles.record_stop_pushbutton,'enable','off');
        set(handles.filepath_edit,'enable','off');
        set(handles.file_choose_pushbutton,'enable','off');
        set(handles.play_pushbutton,'enable','off');
        set(handles.play_stop_pushbutton,'enable','off');
    case 'file_radiobutton'
        set(handles.fs_popupmenu,'enable','off');
        set(handles.record_start_pushbutton,'enable','off');
        set(handles.record_stop_pushbutton,'enable','off');
        set(handles.filepath_edit,'enable','on');
        set(handles.file_choose_pushbutton,'enable','on');
        set(handles.play_pushbutton,'enable','off');
        set(handles.play_stop_pushbutton,'enable','off');
end

% --- 波形选择栏
function wave_select_listbox_Callback(hObject, eventdata, handles)
audio_analyze(handles.Sample,handles.Fs,handles.axes1,handles);
audio_analyze(handles.CSample,handles.Fs,handles.axes2,handles);

function wave_select_listbox_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- 播放开始
function playstart_Callback(hObject,eventdata,handles)
set(handles.play_pushbutton,'enable','off');
set(handles.play_stop_pushbutton,'enable','on');
set(handles.playstate_text,'String','状态栏> 正在播放...');

% --- 播放结束
function playstop_Callback(hObject,eventdata,handles)
set(handles.play_pushbutton,'enable','on');
set(handles.play_stop_pushbutton,'enable','off');
set(handles.playstate_text,'String','状态栏>');

% --- 录音开始
function recordstart_Callback(hObject,eventdata,handles)
set(handles.record_start_pushbutton,'enable','off');
set(handles.record_stop_pushbutton,'enable','on');
set(handles.playstate_text,'String','状态栏> 正在录音...');

% --- 录音结束
function recordstop_Callback(hObject,eventdata,handles)
set(handles.play_pushbutton,'enable','on');
set(handles.play_stop_pushbutton,'enable','on');
set(handles.record_start_pushbutton,'enable','on');
set(handles.record_stop_pushbutton,'enable','off');
set(handles.putfile_pushbutton,'enable','on');
set(handles.playstate_text,'String','状态栏>');

% --- 输出音频
function putfile_pushbutton_Callback(hObject, eventdata, handles)
putfile(handles.CSample,handles.Fs); % 输出音频

function nmean_edit_Callback(hObject, eventdata, handles)

function nmean_edit_CreateFcn(hObject, eventdata, handles)

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function dmean_edit_Callback(hObject, eventdata, handles)

function dmean_edit_CreateFcn(hObject, eventdata, handles)

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function dvar_edit_Callback(hObject, eventdata, handles)

function dvar_edit_CreateFcn(hObject, eventdata, handles)

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function nvar_edit_Callback(hObject, eventdata, handles)

function nvar_edit_CreateFcn(hObject, eventdata, handles)

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- 谱减法去噪
function sub_denoise_pushbutton_Callback(hObject, eventdata, handles)
if(~isempty(handles.CSample))
    handles.CSample=specsub(handles.CSample,handles.Fs); % 谱减法去噪
    handles.player=audioplayer(handles.CSample,handles.Fs);
    setplayer(handles);
    
    guidata(hObject,handles);
else
    warndlg('请录入声音','警告');
end


% --- 音量调节
% --- 这里用音量的改变（差值）增加/减小音量
function volume_slider_Callback(hObject, eventdata, handles)
val=round(get(hObject,'Value'),2);
dval=val-handles.volume; %求音量相对值
handles.volume=val; %保存数值
volume=10^(dval/20); % 获取相对音量
set(handles.volume_edit,'String',['+',num2str(val),' dB']);
if isempty(handles.Sample)==0
    handles.CSample=handles.CSample.*volume; % 音量调节
    handles.player=audioplayer(handles.CSample,handles.Fs);
    setplayer(handles);
end

guidata(hObject,handles);

function volume_slider_CreateFcn(hObject, eventdata, handles)

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

% --- 显示音量
function volume_edit_Callback(hObject, eventdata, handles)
str=get(hObject,'String');
val=str(isstrprop(str,'digit'));% 读取数字
val=str2double(val);
if val<0
    val=0;
end
if val>20
    val=20;
end
% 矫正输入
dval=val-handles.volume; %求音量相对值
handles.volume=val; %保存数值
volume=10^(dval/20); % 获取相对音量
set(handles.volume_edit,'String',['+',num2str(val),' dB']);
if isempty(handles.Sample)==0
    handles.CSample=handles.CSample.*volume; % 音量调节
    handles.player=audioplayer(handles.CSample,handles.Fs);
    setplayer(handles);
end
set(handles.volume_slider,'Value',val);
guidata(hObject,handles);

function volume_edit_CreateFcn(hObject, eventdata, handles)

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- 重置
function reset_pushbutton_Callback(hObject, eventdata, handles)
if(~isempty(handles.CSample))
    handles.CSample=handles.Sample; % 重置样本
    handles.player=audioplayer(handles.CSample,handles.Fs);
    setplayer(handles);
    set(handles.volume_slider,'Value',0); % 重置音量
    set(handles.volume_edit,'String','+0 dB');
    guidata(hObject,handles);
else
    warndlg('请录入声音','警告');
end

% --- 录入声纹
function insert_prt_pushbutton_Callback(hObject, eventdata, handles)
if(~isempty(handles.CSample))
    [handles.data]=insertvoice(handles.CSample,handles.Fs); % 录入声纹
    c=data2cell(handles.data);
    set(handles.data_uitable,'Data',c);
    guidata(hObject,handles);
else
    warndlg('请录入声音','警告');
end

% --- 识别声纹
function select_speech_pushbutton_Callback(hObject, eventdata, handles)
if(~isempty(handles.CSample))
    if (exist('speech_database.mat','file')==2)
        recogvoice(handles.CSample,handles.Fs,handles.data); % 识别声纹
        guidata(hObject,handles);
    else
        warndlg('未录入声纹，请录入！','警告');
    end
else
    warndlg('请录入声音','警告');
end

% --- 删除数据
function delete_data_pushbutton_Callback(hObject, eventdata, handles)
if (exist('speech_database.mat','file')==2)
    c=deletedata(handles.data); % 删除声纹
    set(handles.data_uitable,'Data',c);
    guidata(hObject,handles)
else
    warndlg('数据库为空','警告');
end
