%
% Company:	New York University
%			Pi-Radio
%
% Engineer: Aditya Dhananjay
%			Panagiotis Skrimponis
%
% Description:
%
%
% Date: Last update on Feb. 11, 2021
%
% Copyright @ 2021
%
classdef FullyDigital < matlab.System
	properties
		ip;				% IP address
		mem;			% mem type: 'bram' or 'dram'
		socket;			% TCP socket to control the Pi-Radio platform
		fpga;			% 
		rfferx;			% 
		rffetx;			% 
		isDebug;		% print debug messages.
	end
	
	methods
		function obj = FullyDigital(varargin)
			% Constructor
			
            % Set parameters from constructor arguments.
			if nargin >= 1
				obj.set(varargin{:});
			end
			
			% Establish TCP connections.
			obj.connect();
			
			obj.fpga = piradio.fpga.RFSoC('ip', obj.ip, 'mem', obj.mem, ...
				'isDebug', obj.isDebug);
		end
		
		function delete(obj)
			% Destructor.
			
			clear obj.fpga obj.rffrx obj.rfftx;
			
			% Close TCP connection.
			obj.disconnect();
		end
		
		function data = recv(obj, nsamp)
			data = obj.fpga.recv(nsamp);
			
		end
		
		function send(obj, data)
			obj.fpga.send(data);
		end
		
		function setSchedule(obj, readMax, skipMax)
			write(obj.socket, sprintf("+%d%d",readMax,skipMax));
		end
	end
	
	methods (Access = 'protected')
		function connect(obj)
			if (isempty(obj.socket))
				obj.socket = tcpclient(obj.ip, 8083, "Timeout", 5);
			end
		end
		
		function disconnect(obj)
			if (~isempty(obj.socket)) 
				write(obj.socket, 'disconnect');
				pause(0.1);
				clear obj.socket;
			end	
		end
	end
end

