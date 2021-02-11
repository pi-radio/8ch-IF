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
classdef RFSoC < matlab.System
    %RFSOC Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
		ip;				% IP address
		mem;			% mem type: 'bram' or 'dram'
		sockData;		% data TCP connection
		sockCtrl;		% ctrl TCP connection
		isDebug;		% print debug messages.
    end
    
    methods
        function obj = RFSoC(varargin)
			% Constructor
			
            % Set parameters from constructor arguments.
			if nargin >= 1
				obj.set(varargin{:});
			end
			
			% Establish TCP connections.
			obj.connect();
			
			obj.sendCmd("TermMode 1");
		end
		
		function delete(obj)
			% Destructor.
			
			% Close TCP connections.
			obj.disconnect();
		end
		
		function data = recv(obj, nsamp)
			obj.sendCmd(sprintf("SetLocalMemSample 0 0 0 %d", nsamp));
			obj.sendCmd("LocalMemInfo 0");
			obj.sendCmd(sprintf("LocalMemTrigger 0 4 %d 0x00FF", nsamp));
			write(obj.sockData, sprintf("ReadDataFromMemory 0 0 %d 0\r\n", 2*nsamp));
			pause(0.1);
			data = read(obj.sockData, nsamp, 'int16');
			pause(0.1);
			rsp = read(obj.sockData);
			if (obj.isDebug)
				fprintf(1, "%s", rsp);
			end
			data = reshape(data,[],1); % return a column vector
		end
		
		function send(obj, data)
			nsamp = length(data);
			obj.sendCmd("LocalMemInfo 1");
			obj.sendCmd(sprintf("LocalMemTrigger 1 0 0 0x0000"));
			
			write(obj.sockData, sprintf("WriteDataToMemory 0 0 %d 0\r\n", 2*nsamp));
			write(obj.sockData, data, 'int16');
			pause(0.1);
			rsp = read(obj.sockData);
			if (obj.isDebug)
				fprintf(1, "%s", rsp);
			end
			
			obj.sendCmd(sprintf("SetLocalMemSample 1 0 0 %d", nsamp));
			
			obj.sendCmd("LocalMemTrigger 1 2 0 0x0001");
			obj.sendCmd("LocalMemInfo 1");
		end
		
		function configure(obj, file)
			% Parse the output file from the RFDC.
			fid = fopen(file,'r');
			while ~feof(fid)
				tline = fgetl(fid);
				% The following lines parse a file generated from the 
				% Windows RFDC application
				% tmp = regexp(tline, '\t', 'split');
				% fprintf(1, '%s\n',tmp{4})
				% obj.sendCmd(tmp{4});
				if (tline(1) ~= '%')
					fprintf(1, '%s\n', tline);
					obj.sendCmd(tline)
				end
			end
			fclose(fid);
			
			% Configure memory
			obj.sendCmd("GetMemType");
			if (obj.mem == "bram")
				obj.sendCmd("SetMemType 1");
			else
				obj.sendCmd("SetMemType 0");
			end
			
			obj.sendCmd("GetBitstream");
			obj.sendCmd("GetMemType");
		end
	end
	
	methods (Access = 'protected')
		function connect(obj)
			
			if (isempty(obj.sockData))
				obj.sockData = tcpclient(obj.ip, 8082, "Timeout", 5);
			end
            
			if (isempty(obj.sockCtrl)) 
				obj.sockCtrl = tcpclient(obj.ip, 8081, "Timeout", 5);
			end
			
		end
		
		function disconnect(obj)
			if (~isempty(obj.sockData))
				flush(obj.sockData);
				clear obj.sockData;
			end
			
			if (~isempty(obj.sockCtrl)) 
				flush(obj.sockCtrl);
				clear obj.sockCtrl;
			end			
		end
		
		function sendCmd(obj, cmd)
			
            % Flush the input/output buffer
			flush(obj.sockCtrl);
			
			% Send a command to the FPGA
            write(obj.sockCtrl, sprintf("%s\r\n",cmd));
			
			% Wait for the FPGA
			pause(0.1);
			
			% Read response and print in debug mode
			rsp = read(obj.sockCtrl);
			if (obj.isDebug)
				fprintf(1, "%s", rsp);
			end
		end
	end
end