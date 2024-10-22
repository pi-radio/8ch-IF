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
% Last update on Mar 23, 2023
%
% Copyright @ 2023
%
classdef FullyDigital < matlab.System
    properties
        ip;				% IP address
        socket;			% TCP socket to control the Pi-Radio platform
        fpga;			% FPGA object
        lo;             % LO object (TI LMX 2595)
        ltc;            % ADI LTC5594 chips
        rffeTx;         % ADI HMC6300 chips
        rffeRx;         % ADI HMC6301 chips
        obsCtrl;        % Self observation pathway
        isDebug;		% if 'true' print debug messages
        
        nch = 8;		% number of channels
        figNum;         % Figure number to plot waveforms for this SDR
        fc = 60e9;     % carrier frequency of the SDR in Hz
        name;           % Unique name for this transceiver board

        % Cal Factors
        calTxDelay;
        calRxDelay;
        calTxPhase;
        calRxPhase;
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
            obj.obsCtrl = piradio.rffe.ObsCtrl('socket', obj.socket, 'name', obj.name);
            obj.ltc = piradio.rffe.LTC5594('socket', obj.socket, 'name', obj.name);
            obj.rffeTx = piradio.rffe.HMC6300('socket', obj.socket);
            obj.rffeRx = piradio.rffe.HMC6301('socket', obj.socket);
            
            figure(obj.figNum);
            clf;

            obj.calTxDelay = zeros(1, obj.nch);
            obj.calRxDelay = zeros(1, obj.nch);
            obj.calTxPhase = zeros(1, obj.nch);
            obj.calRxPhase = zeros(1, obj.nch);
        end
        
        function delete(obj)
            % Destructor.
            clear obj.fpga obj.lo obj.rffeTx obj.rffeRx;
            clear obj.ltc;
            
            % Close TCP connection.
            obj.disconnect();
        end
        
        function data = recv(obj, nread, nskip, nbatch, toPlot)
            % Calculate the total number of samples to read:
            % (# of batch) * (samples per batch) * (# of channel) * (I/Q)
            nsamp = nbatch * nread * obj.nch * 2;
            
            write(obj.socket, sprintf("+ %d %d %d",  nread/2, nskip/2, nsamp*2));
            
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
            
            if (toPlot == 1)
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
                    ylim([40 160]);
                    grid on;
                end
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
            write(obj.socket, sprintf("f00000%s", led_string));
        end

        function opBlob = fracDelay(obj, ipBlob,fracDelayVal,N)
            taps = zeros(0,0);
            for index=-100:100
                delay = index - fracDelayVal;
                taps = [taps sinc(delay)];
            end
            x = [ipBlob; ipBlob];
            x = x';
            y = conv(taps, x);
            opBlob = y(N/2 : N/2 + N - 1);
            opBlob = opBlob';
        end % fracDelay

        function blob = applyCalRxArray(obj, rxtd)
            blob = zeros(size(rxtd));
            for rxIndex=1:obj.nch
                for itimes=1:size(rxtd, 2)
                    td = rxtd(:, itimes, rxIndex);
                    td = obj.fracDelay(td, obj.calRxDelay(rxIndex), size(td, 1));
                    td = td * exp(1j * obj.calRxPhase(rxIndex));
                    blob(:, itimes, rxIndex) = td;
                end % itimes
            end % rxIndex
        end % function applyCalRxArray
        
        function blob = applyCalTxArray(obj, txtd)
            blob = zeros(size(txtd));
            for txIndex=1:obj.nch
                td = txtd(:, txIndex);
                td = obj.fracDelay(td, obj.calTxDelay(txIndex), size(td, 1));
                td = td * exp(1j * obj.calTxPhase(txIndex));
                blob(:, txIndex) = td;
            end % txIndex
        end % function applyCalTxArray
        
        function set_switches(obj, switch_string)
            if switch_string == "on"
                write(obj.socket, "e0000001");
            elseif switch_string == "off"
                write(obj.socket, "e0000000");
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

