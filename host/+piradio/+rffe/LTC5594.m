%
% Company:	New York University
%			Pi-Radio
%
% Engineer: Panagiotis Skrimponis
%			Aditya Dhananjay
%
% Description:
%	300MHz to 9GHz High Linearity I/Q Demodulator
%   with Wideband IF Amplifier
%
% Date: Last update on Mar. 23, 2023
%
% Copyright @ 2023
%
classdef LTC5594 < matlab.System
    properties
        socket;
        name;
    end
    
    methods
        function obj = LTC5594(varargin)
            % Set parameters from constructor arguments.
            if nargin >= 1
                obj.set(varargin{:});
            end
        end
        
        function delete(obj)
            % Destructor
        end
        
        function configure(obj, txIndex, file)
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
                    fprintf('LTC5594 configuration: Line %d: ', i);
                    %fprintf('.');
                    c = a{1}{2};
                    s = sprintf('%s%s%s%s', '3', c(3:6), '00', string(txIndex-1));
                    fprintf('%s\n', s);
                    write(obj.socket, s)
                end
            end
            fprintf('\n');
        end % function configure        
    
    end % methods
end % classdef