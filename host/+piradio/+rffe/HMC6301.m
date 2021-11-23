%
% Company:	New York University
%			Pi-Radio
%
% Engineer: Panagiotis Skrimponis
%			Aditya Dhananjay
%
% Description:
%	HMC6301 is a 60 GHz millimeter wave receiver from Analog Devices. This
%	device operates in the 57-64 GHz band.
%
% Date: Last update on Nov 23, 2021
%
% Copyright @ 2021
%
classdef HMC6301 < matlab.System
    properties
        socket;		% TCP socket used to configure the HMC6301
    end
    
    methods
        function obj = HMC6301(varargin)
            % Constructor
            
            % Set parameters from constructor arguments.
            if nargin >= 1
                obj.set(varargin{:});
            end
        end
        
        function delete(obj)
            % Destructor
        end
        
        function powerDown(obj, rxIndex)
            if (rIndex == 10)
                for ihmc = '01234567' % Primary RX channels
                    write(obj.socket, sprintf('%s%s%s', '1', 'ff03c0', ihmc));
                    pause(0.1);
                end
            else
                write(obj.socket, sprintf('%s%s%s', '1', 'ff03c0', string(rxIndex)));
            end
        end
        
        function configure(obj, rxIndex, file)
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
                    %fprintf('HMC RX configuration: Line %d: \n', i);
                    fprintf('.');
                    c = a{1}{1};
                    
                    hmcRx = '01234567';
                    if (rxIndex == 10)
                        for ihmc = hmcRx
                            write(obj.socket, sprintf('%s%s%s', '1', c(1:6), ihmc));
                            pause (0.01);
                        end
                    else
                        write(obj.socket, sprintf('%s%s%s', '1', c(1:6), hmcRx(rxIndex)));
                        pause (0.01);
                    end
                end
            end
            fprintf('\n');
        end
        
        function attn(obj, bbAttn, ifAttn, rfAttn)
            switch ifAttn
                case 00
                    val = 'f0a3c0';
                case 05
                    val = 'f2a3c0';
                case 10
                    val = 'f1a3c0';
                case 15
                    val = 'f3a3c0';
                case 20
                    val = 'ffa3c0';
                otherwise
                    val = '000000';
            end
            
            for ihmc = '012345678' % Do this for all channels, incl Ref
                write(obj.socket, sprintf('%s%s%s', '1', val, ihmc));
                pause (0.01);
            end
            
            switch rfAttn
                case 00
                    val = '0113c0';
                case 06
                    val = '1113c0';
                case 12
                    val = '0913c0';
                case 18
                    val = '1913c0';
                otherwise
                    val = '000000';
            end
            
            for ihmc = '012345678' % Do this for all channels, incl Ref
                write(obj.socket, sprintf('%s%s%s', '1', val, ihmc));
                pause (0.01);
            end
            
            switch bbAttn
                case 0
                    r01 = '0883c0';
                    r02 = '0043c0';
                case 6
                    r01 = '0883c0';
                    r02 = '4043c0';
                case 12
                    r01 = '0883c0';
                    r02 = '8043c0';
                case 18
                    r01 = '0883c0';
                    r02 = 'c043c0';
                case 24
                    r01 = '1883c0';
                    r02 = 'c043c0';
                case 30
                    r01 = '2883c0';
                    r02 = 'c043c0';
                case 36
                    r01 = '3883c0';
                    r02 = 'c043c0';
                otherwise
                    r01 = '000000';
                    r02 = '000000';
            end
            
            for ihmc = '012345678' % Do this for all channels, incl Ref
                write(obj.socket, sprintf('%s%s%s', '1', r01, ihmc));
                write(obj.socket, sprintf('%s%s%s', '1', r02, ihmc));
                pause (0.01);
            end
        end
    end
end