%======================================================================
%                    L O A D A N T S . M 
%                    doc: Thu Jul 21 22:53:21 2011
%                    dlm: Thu Aug  4 10:54:24 2011
%                    (c) 2011 A.M. Thurnherr
%                    uE-Info: 18 71 NIL 0 0 72 2 2 4 NIL ofnI
%======================================================================

% NOTES:
%   - very restrictive subset of ANTS standard:
%       - no empty lines
%       - no in-record comments

% HISTORY:
%   Jul 21, 2011: - began working on it
%	Jul 23, 2011: - made it work
%	Aug  4, 2011: - replaced "creator" by "Matlab_import"
%				  - BUG: %PARAM names with . were not handled correctly

function dta_struct = loadANTS(file_name)

fid = fopen(file_name);                                     % open file
if fid < 0
    error(sprintf('%s: not such file',file_name));
end

dta_struct = struct('Matlab_import',sprintf('loadANTS(''%s'')',file_name));

l = fgetl(fid);                                             % handle metadata
while ischar(l) & regexp(l,'^#')
    if regexp(l,'^#ANTS#ERROR#')
        error(l);
    elseif regexp(l,'^#ANTS#PARAMS#')
        [tmp,tmp,ptk] = regexp(l,'([\w\.]+){([^}]*)}');
        for i=1:length(ptk)
        	pname = matlabotomize(token1(i,l,ptk));
			if sum(size(ptk{i})) < 4	% empty def
				if isfield(dta_struct,pname)
					dta_struct = rmfield(dta_struct,pname);
				end
			else
				numval = str2double(token2(i,l,ptk));
				if isfinite(numval) | strcmpi(token2(i,l,ptk),'nan')
					dta_struct = setfield(dta_struct,pname,numval);
				else
					dta_struct = setfield(dta_struct,pname,token2(i,l,ptk));
				end
			end
        end
		
    elseif regexp(l,'^#ANTS#FIELDS#')
        [tmp,tmp,ftk] = regexp(l,'{([^}]*)}');
        fields = cell(1,length(ftk));
        for i=1:length(ftk)
             fields{i} = matlabotomize(token(i,l,ftk));
        end
    end % elseif
    l = fgetl(fid);
end % while

if ischar(l)												% not empty file
	isnumeric = zeros(1,length(fields));					% determine data types
    [tmp,tmp,tk] = regexp(l,'([^ \t]+)');					% split into tokens
	for i=1:length(fields)
		numval = str2double(token(i,l,tk));
		if isfinite(numval) | strcmpi(token(i,l,tk),'nan')
			isnumeric(i) = 1;
		end
	end
end

dta = cell(length(fields),1);								% init data cell array

while ischar(l)                                             % loop through records
    [tmp,tmp,tk] = regexp(l,'([^ \t]+)');					% split into tokens
    for i=1:length(tk)
    	if isnumeric(i)
    		dta{i} = [dta{i} str2double(token(i,l,tk))];
    	else
    		dta{i} = [dta{i} {token(i,l,tk)}];
    	end
    end
    l = fgetl(fid);
end

for i=1:length(fields)                                       % copy to structure
	dta_struct = setfield(dta_struct,fields{i},dta{i});
end

fclose(fid);

return

%----------------------------------------------------------------------

function tk = token(i,str,tki)
	tk = str(tki{i}(1):tki{i}(2));
	return;

function tk = token1(i,str,tki)
	tk = str(tki{i}(1,1):tki{i}(1,2));
	return;

function tk = token2(i,str,tki)
	tk = str(tki{i}(2,1):tki{i}(2,2));
	return

function s = matlabotomize(s)
	s = strrep(s,'.','_');
	s = strrep(s,'3','three');

