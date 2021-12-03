%
% Company:	New York University
%           Pi-Radio
%
% Engineer: Panagiotis Skrimponis
%           Aditya Dhananjay
%
% Description: This class creates a fully-digital SDR with 8-channels. This
% class establish a communication link between the host and the Pi-Radio
% TCP server running on the ARM. The server configures the RF front-end and
% the ADC flow control.
%
% Last update on Nov 23, 2021
%
% Copyright @ 2021
%
classdef FullyDigital < matlab.System
    properties
        ip;				% IP address
        socket;			% TCP socket to control the Pi-Radio platform
        fpga;			% FPGA object
        lo;             % LO object (TI LMX 2595)
        rffeTx;         % ADI HMC6300 chips
        rffeRx;         % ADI HMC6301 chips
        isDebug;		% if 'true' print debug messages
        
        nch = 8;		% number of channels
        figNum;         % Figure number to plot waveforms for this SDR
        fc = 135e9;     % carrier frequency of the SDR in Hz
        name;           % Unique name for this transceiver board
    end
    
    methods
        function obj = FullyDigital(varargin)
            % Constructor
            
            % Set parameters from constructor arguments.
            if nargin >= 1
                obj.set(varargin{:});
            end
            
            % Establish connection with the Pi-Radio TCP Server.
            obj.connect();
            
            % Create the RFSoC object
            obj.fpga = piradio.fpga.RFSoC('ip', obj.ip, 'isDebug', obj.isDebug);
            obj.lo = piradio.rffe.LMX2595('socket', obj.socket, 'name', obj.name);
            obj.rffeTx = piradio.rffe.HMC6300('socket', obj.socket);
            obj.rffeRx = piradio.rffe.HMC6301('socket', obj.socket);
            
            figure(obj.figNum);
            clf;
        end
        
        function delete(obj)
            % Destructor.
            clear obj.fpga obj.lo obj.rffeTx obj.rffeRx;
            
            % Close TCP connection.
            obj.disconnect();
        end
        
        function data = recv(obj, nread, nskip, nbatch)
            % Calculate the total number of samples to read:
            % (# of batch) * (samples per batch) * (# of channel) * (I/Q)
            nsamp = nbatch * nread * obj.nch * 2;
            
            write(obj.socket, sprintf("+ %d %d %d", nread/2, nskip/2, nsamp*2));
            
            % Read data from the FPGA
            data = obj.fpga.recv(nsamp);
            
            % Process the data (i.e., calibration, flow control)
            data = reshape(data, nread, nbatch, obj.nch);
            
             % Remove DC Offsets
            for ich = 1:obj.nch
                for ibatch = 1:nbatch
                    data(:,ibatch,ich) = data(:,ibatch,ich) - mean(data(:,ibatch,ich));
                end
            end
            
            % Plot the RX waveform for the first batch
            figure(obj.figNum);
            for rxIndex=1:obj.nch
                subplot(8, 4, rxIndex+16);
                plot(real(data(:,1,rxIndex)), 'r'); hold on;
                plot(imag(data(:,1,rxIndex)), 'b'); hold off;
                ylim([-35000 35000]);
                grid on;
                
                n = size(data,1);
                scs = linspace(-n/2, n/2-1, n);
                subplot(8,4,rxIndex+24);
                plot(scs, mag2db(abs(fftshift(fft(data(:,1,rxIndex))))));
                %ylim([60 140]);
                grid on;
            end
        end
        
        function send(obj, data)
            write(obj.socket, sprintf("- %d", size(data,1)));
            obj.fpga.send(data);
            
             % Plot the TX waveforms
            figure(obj.figNum);
            for txIndex=1:obj.nch
                subplot(8, 4, txIndex);
                plot(real(data(:,txIndex)), 'r'); hold on;
                plot(imag(data(:,txIndex)), 'b'); hold off;
                ylim([-35000 35000]);
                grid on;
                
                n = size(data,1);
                scs = linspace(-n/2, n/2-1, n);
                subplot(8,4,txIndex+8);
                plot(scs, abs(fftshift(fft(data(:,txIndex)))));
                grid on;
            end
        end
        
        function set_leds(obj, led_string)
            write(obj.socket, sprintf("400000%s", led_string));
        end
        
        function set_switches(obj, switch_string)
            if switch_string == "normal"
                write(obj.socket, "3000000c");
            elseif switch_string == "testTxArray"
                write(obj.socket, "30000006");
            elseif switch_string == "testRxArray"
                write(obj.socket, "30000009");
            else
                fprintf("Error. Unrecognized switch_string\n");
            end
        end
    end
    
    methods (Access = 'protected')
        function connect(obj)
            % Establish connection with the Pi-Radio TCP Server.
            if (isempty(obj.socket))
                obj.socket = tcpclient(obj.ip, 8083, "Timeout", 5);
            end
        end
        
        function disconnect(obj)
            % Close the Pi-Radio TCP socket
            if (~isempty(obj.socket))
                flush(obj.socket);
                write(obj.socket, 'disconnect');
                pause(0.1);
                clear obj.socket;
            end
        end
    end
end

