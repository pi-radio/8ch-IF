%
% Company:	New York University
%			Pi-Radio
%
% Engineer: Panagiotis Skrimponis
%			Aditya Dhananjay
%
% Description:
%	UltraCMOS® SPDT RF Switch, 9 kHz–60 GHz
%   Peregrine Semiconductor
%
% Date: Last update on Mar. 28, 2023
%
% Copyright @ 2023
%
classdef ObsCtrl < matlab.System
    properties
        socket;
        name;
    end
    
    methods
        function obj = ObsCtrl(varargin)
            % Set parameters from constructor arguments.
            if nargin >= 1
                obj.set(varargin{:});
            end
        end
        
        function delete(obj)
            % Destructor
        end
        
        function configure(obj, val)
            s = sprintf('%s%s%s', 'e', '000000', num2str(val));
            fprintf('%s\n', s);
            write(obj.socket, s);
            fprintf('\n');
        end % function configure
       
        
    end % methods
end % classdef