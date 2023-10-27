%
% Company:	New York University
%			Pi-Radio
%
% Engineer: Panagiotis Skrimponis
%			Aditya Dhananjay
%
% Description:
%	LMX2595 is a 20 GHz wideband RF Synthesizer with phase synchronization
%	from Texas Instruments.
%
% Date: Last update on Mar. 3, 2021
%
% Copyright @ 2021
%
classdef LMX2595 < matlab.System
    properties
        socket;
        name;
    end
    
    methods
        function obj = LMX2595(varargin)
            % Set parameters from constructor arguments.
            if nargin >= 1
                obj.set(varargin{:});
            end
        end
        
        function delete(obj)
            % Destructor
        end
        
        function configure(obj, file)
            filestr = fileread(file);
            filebyline = regexp(filestr, '\n', 'split');
            filebyline( cellfun(@isempty,filebyline) ) = [];
            filebyfield = regexp(filebyline, '\t', 'split');
            
            for i=1:numel(filebyfield)
                pause(0.01)
                a = filebyfield(i);
                b = a{1}{1};
                if (strcmp(b(1:1), '%') == 1)
                    % Ignore the comment line in the commands file
                else
                    %fprintf('LMX configuration: Line %d: ', i);
                    %fprintf('.');
                    c = a{1}{2};
                    s = sprintf('%s%s%s', '2', c(3:8), '0');
                    %fprintf('%s\n', s);
                    write(obj.socket, s)
                end
            end
            fprintf('\n');
        end % function configure
        
        function configureUnique(obj, freq)
            file = ['../../config/unique/' obj.name '/lmx_registers_' freq '.txt'];
            filestr = fileread(file);
            filebyline = regexp(filestr, '\n', 'split');
            filebyline( cellfun(@isempty,filebyline) ) = [];
            filebyfield = regexp(filebyline, '\t', 'split');
            
            for i=1:numel(filebyfield)
                pause(0.01)
                a = filebyfield(i);
                b = a{1}{1};
                if (strcmp(b(1:1), '%') == 1)
                    % Ignore the comment line in the commands file
                else
                    %fprintf('LMX configuration: Line %d: ', i);
                    %fprintf('.');
                    c = a{1}{2};
                    s = sprintf('%s%s%s', '2', c(3:8), '0');
                    fprintf('%s\n', s);
                    write(obj.socket, s)
                end
            end
            fprintf('\n');
        end % function configureUnique
        
    end % methods
end % classdef