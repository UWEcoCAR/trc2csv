function [ sigRows ] = buildLog( log, msg_indicies, msg_list, end_time )
%buildLog builds a log array for all of the signals contained in the
%messages listed in the input msg_list
%     Input: log - the complete dbc and trace import
%            msg_cell - the list of all messages in order of occurence
%            msg_list - a list of the messages to display in the final output log
%     Output: sigRows - the complete matrix of all the data needed to format the output log

    tic
    max = ceil(end_time*100); % max iterations based off total trace time and fastest occuring message (10 ms)
    %% Preallocate
%   need to add preallocation....predetermine  log dimensions
%    sigCell = cell(max+1,length(msg_list));
%    sigRows = cell(max,8*length(msg_list));

   row = 1;

    %% Build log array
    while(row < max) 
        for i = 1:length(msg_list) % locate message instance 
            clear val  
            if msg_indicies(i,row + 1) == 0     % found all instances of this message, so record empty cells
                list = fieldnames(log(1,msg_indicies(i,1)).Signals([]))'; 
                val(1,1) = {[]};            % omit timestamp
                for j = 1:(length(list))      % omit signal values    
                    val(1,j+1) = {[]};
                end
                sigCell{row+1, i} = val;      % append values
            else
                list = fieldnames(log(1,msg_indicies(i,row)).Signals([]))';   % get signal field names for header            
                val(1,1) = {log(1,msg_indicies(i,row)).Timestamp};            % get timestamp
                for j = 1:(length(list))                        % get signal values    
                    val(1,j+1) = {log(1,msg_indicies(i,row)).Signals.(list{j})};
                end

                if row == 1                       % add header
                   header = horzcat({'Time'}, list);
                   sigCell{1,i} = header;  
                end
               sigCell{row+1, i} = val;      % append values
            end
        end 
        sigRows(row,:) = [sigCell{row,1:end}];   % write and append row
        row = row + 1;        
    end
    disp('Output log complete')
    toc
end

