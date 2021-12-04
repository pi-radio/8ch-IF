%
% Company:	New York University
%			Pi-Radio
%
% Engineer: Panagiotis Skrimponis
%			Aditya Dhananjay
%
% Description:
%	HMC6300 is a 60 GHz millimeter wave transmitter from Analog Devices.
%	This device operates in the 57-64 GHz band.
%
% Date: Last update on Nov 23, 2021
%
% Copyright @ 2021
%
classdef HMC6300 < matlab.System
    properties
        socket;
    end
    
    methods
        function obj = HMC6300(varargin)
            % Constructor
            
            % Set parameters from constructor arguments.
            if nargin >= 1
                obj.set(varargin{:});
            end
        end
        
        function delete(obj)
            % Destructor
        end
        function configure(obj, txIndex, file)
            % This function configures the RFFE.
            % * txIndex: Takes a value in [0,8] to select which upconverter 
            %           to configure. To configure all upconverters enter
            %           10.
            % * file: Input file with the configuration commands. This file
            %         has been exported from the ADI software.
            %
            filestr = fileread(file);
            filebyline = regexp(filestr, '\n', 'split');
            filebyline( cellfun(@isempty,filebyline) ) = [];
            filebyfield = regexp(filebyline, '\t', 'split');
            
            for i = 1:numel(filebyfield)
                pause(0.01)
                a = filebyfield(i);
                b = a{1}{1};
                if (strcmp(b(1:1), '%') == 1)
                    % Ignore the comment line in the commands file
                else
                    % fprintf('HMC TX configuration: Line %d: \n', i);
                    fprintf('.');
                    c = a{1}{1};
                    
                    hmcTx = '01234567'; % Primary TX channels only
                    if (txIndex == 10)
                        for ihmc = hmcTx
                            write(obj.socket, sprintf('%s%s%s', '0', c(1:6), ihmc));
                            pause (0.01);
                        end
                    else
                        write(obj.socket, sprintf('%s%s%s', '0', c(1:6), string(txIndex-1)));
                        pause (0.01);
                    end
                end
            end
            fprintf('\n');
        end
        
        function powerDown(obj, txIndex)
            if (txIndex == 10)
                for ihmc = '01234567' % Primary TX channels only
                    write(obj.socket, sprintf('%s%s%s', '0', 'ff22c0', ihmc));
                    pause(0.1);
                end
            else
                write(obj.socket, sprintf('%s%s%s', '0', 'ff22c0', string(txIndex-1)));
            end
        end
        
        function attn(obj, ifAttn, rfAttn)
            % This function control the RF and IF attenuation.
            switch ifAttn
                case 00
                    val = 'f0e2c0';
                case 05
                    val = 'f2e2c0';
                case 10
                    val = 'f1e2c0';
                case 15
                    val = 'f3e2c0';
                case 20
                    val = 'ffe2c0';
                otherwise
                    val = '000000';
            end
            
            for idx = '012345678' % Do this for all channels, incl Ref
                write(obj.socket, sprintf('%s%s%s', '0', val, idx));
                pause(0.01);
            end
            
            switch rfAttn
                case 00
                    val = 'c0d2c0';
                case 04
                    val = 'c2d2c0';
                case 08
                    val = 'c1d2c0';
                case 12
                    val = 'c3d2c0';
                case 15
                    val = 'cfd2c0';
                otherwise
                    val = '000000';
            end
            
            for idx = '012345678' % Do this for all channels, incl Ref
                write(obj.socket, sprintf('%s%s%s', '0', val, idx));
                pause(0.01);
            end
        end
    end
end