function [output_file, delete_log] = convertTrace(input_file)
%convertTrace Converts a p-can '.trc' log to a vector 'asc' log so it can
%be used with the Matlab Vehicle Network Tools
%   input must be *.trc output must be *.asc

tic
    %% Check input trace file extension
    [path,name,ext] = fileparts(input_file);
    if (~strcmp('.trc',ext))
        error('Input file must be .trc p-can log file');
    end
    output_file = strcat(path, '\Converted_', name, '.asc');
    
    %% Check if output exists
    if (exist(output_file, 'file') == 2)
        disp('Converted trc file exists, no need to convert') 
        delete_log = 1; % dont delete 
    else
        disp('Converting trc file to asc...')  
        clear log
        %% Find log start index
        fileID = fopen(input_file,'r');
        startRow = 1;
        line = fgetl(fileID);
        % skip lines starting with ';'
        while line(1) == ';'
           startRow = startRow + 1;
           line = fgetl(fileID);
        end
        fclose(fileID); % not sure if necessary to have seperate fid

        %% Read columns of data according to format string.
        fileID = fopen(input_file,'r');
        delimiter = {'  ',' ',';','-',')'};
        %formatSpec = '%*7s%14f%2s%4s%12s%*2s%3s%6s%3s%3s%3s%3s%3s%3s%3s%[^\n\r]';
        %formatSpec = '%*9s%12f%2s%6s%10s%*2s%3s%*3s%4s%3s%3s%3s%3s%3s%3s%4s%[^\n\r]';
        formatSpec = '%*s%f%s%s%s%s%s%s%s%s%s%s%s%s%[^\n\r]';
        %dataArray = textscan(fileID, formatSpec, 'Delimiter', '', 'WhiteSpace', '', 'HeaderLines' ,startRow-1, 'ReturnOnError', false);
        dataArray = textscan(fileID, formatSpec, 'Delimiter', delimiter, 'MultipleDelimsAsOne', true, 'HeaderLines', startRow-1, 'ReturnOnError', false);

        fclose(fileID);

        %% Create output variable
        dataArray(1) = cellfun(@mtimes, dataArray(1), {10^-3}, 'UniformOutput', false); % convert ms to s
        dataArray(1) = cellfun(@(x) num2cell(x), dataArray(1), 'UniformOutput', false); % convert num to cell
        data = [dataArray{1:end-1}];

        %% Format to match vector trace
%         data(:,[3 4]) = data(:,[4 3]);

        %% Write to '.asc' output
        fid = fopen(output_file,'w');
        fmt = ['   %f %s  %s             %s   d ' repmat('%s ',1,9) '\n'];
        for i = 1:size(data,1)
            fprintf(fid,fmt,data{i,1:size(data,2)});
        end
        fclose(fid);
        delete_log = 0; %delete
        toc
    end

end
