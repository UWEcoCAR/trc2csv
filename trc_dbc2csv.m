%% Batch CAN TRC Log to CSV
%
%   By Jake Garrison
%  
% Info:
%     Given a path to traces, dbc and file containing messages of interest, this script
%     combines the dbc and trace into a log and parses it for information using
%     several functions. It creates an output .csv for each trace
%
% Functions (see Options)  
%     log_values: build an array of timestamped values based off the input msg_list
%     save_log: writes log to file


%% Setup Variables
%===========================================================================================================
clear all; close all; clc;   

% Folder full of traces
trc_path='traces\';  

% Database (dbc)
input_dbc = 'UW_HS_with_diesel.dbc';   % ONLY 1 DBC
% someone can make this an arrya containing dbc and bus for multiple dbcs

% Text file listing Messages to log
input_msgs_list = 'message_list.txt';

%% Options   
opt_log_values  = false;        % build an array of timestamped values based off the input msg_list
opt_save_log    = false;
        output_ext = '.csv';
        output_delimiter = ',';

%===========================================================================================================
%% Import Message List 
% Import messages of interest from text file.
if (exist(input_msgs_list, 'file') == 0) % check for file
    error('Message log file not found!');
end

delimiter = '\t';
startRow = 1;
formatSpec = '%s';
fileID = fopen(input_msgs_list,'r');
dataArray = textscan(fileID, formatSpec, 'Delimiter', delimiter, 'HeaderLines' ,startRow-1, 'ReturnOnError', false);
fclose(fileID);
msg_list = dataArray{:, 1}; % list of messages converted to cell
clearvars delimiter startRow formatSpec fileID dataArray ans;

%% Loop Through all trace files
clearvars file_num
% Search Path for trc files
fil=fullfile(trc_path,'*.trc');    % look of r .trc files
d=dir(fil);
disp(['Processing all trc files in : ', trc_path])

for file_num=1:numel(d)       % loop through path
  
    clearvars log log_values msg_cell msg_indicies msd_occurence 
    % Input P-Can .trc file
  input_file = fullfile(trc_path,d(file_num).name);
  disp(['(File ', num2str(file_num), ' of ' num2str(numel(d)) ')'])
  disp(['Input File : ', input_file])
  
    % Must be .asc (Vector) or .txt (Kvaser). Use 'convertTrac.m' to convert
    % .trc to .asc

    % Convert Trace
    [converted_trace, delete_log] = trc2asc(input_file);

    if delete_log == 0   % delete previous log if new trace is converted
        clear log
    end

    % Check workspace
    if (exist('log', 'var') == 1)
       disp('Skipping dbc and trace import since log var exists. To reimport, clear log var')

    else % import trc and dbc and create a list of messages
        disp('Importing dbc and trace...')
        tic
        log = canMessageImport(converted_trace, 'Vector', canDatabase(input_dbc));
        toc
        %% Build Cell of Message Names
        msg_cell = cell(length(log),1);
        for i = 1:length(log)
           msg_cell{i,1} = log(1,i).Name;
        end
    end   


    %% Get indicies for messages
    end_time = log(1,end).Timestamp; % last timestamp (total log time)
    msg_indicies= zeros(length(msg_list), ceil(end_time*100));
    for i = 1:length(msg_list)
        r = find(strcmp(msg_cell,msg_list(i)))'; % Find Index of specific message
        msg_indicies(i,1:length(r)) =  r;
    end
    

    %% Log Values
    % Builds an array of all signals, timestamps and values for messages of
    % intrest
    if opt_log_values
       disp('Building output log...')
       [log_values] = buildLog( log, msg_indicies, msg_list, end_time);
    end

    %% Write Log to Output
    %  MAKE FASTER
    if opt_save_log && opt_log_values
        disp('Writing log to file')
        tic
        % Build file name
        [path,name,ext] = fileparts(input_file);
        output_file = strcat(path, '\', name, '_log', output_ext);
        disp(['Output path : ', output_file])
        cell2file(output_file,log_values,output_delimiter);
        clearvars path name ext
        toc
    end

disp('-------------------------------------------------')  
end
