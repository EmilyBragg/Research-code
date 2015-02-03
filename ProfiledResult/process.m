%/bin/octave
function [fstruct names cfi_array] = process()
    
    toplevel = glob('*/');
		fstruct = struct();
		names = {};
    
    for i = 1:length(toplevel)
	    path = toplevel{i};
	    midlevel = glob([path '*/']);
	    for j = 1:length(midlevel)
		    %path = [toplevel{i} midlevel{j}]
		    path = [midlevel{j}];
		    cards = glob([path '*/']);
		    for c = 1:length(cards)
			    %path = [toplevel{i} midlevel{j} cards{c}]
			    path = [cards{c}];
			    freqs = glob([path '*/'])
			    for f = 1:length(freqs)
				    fname = ls([freqs{f} '*.txt']);
									    
					fstruct(end+1) = parseFile([fname]);
					names(end+1) = {fname};
    			end
			end
		end
    
    
    
    
    end
	fstruct(1) = [];
	cfi_array = printCFI(fstruct, names);    
    
    
    
    
    
end


function fstruct = parseFile(fname);
	sprintf('Parsing file %s', fname);
	fh = fopen(fname, 'r');
	line = fgetl(fh);
	flag = false;
	fields = {};
	while (ischar(line))
		start = find(line == '(');
		fin = find(line == ')');
		for (i = length(start):-1:1) 
			line(start(i):fin(i)) = char(' ' .* ones(1,fin(i) - start(i) + 1));
		end
		start = find(line == '<');
		fin = find(line == '>');
		for (i = length(start):-1:1) 
			line(start(i):fin(i)) = char(' ' .* ones(1,fin(i) - start(i) + 1));
		end
		line(line == ' ') = [];

		if (strfind(line, 'Metricresult:'))
			flag = true;		
			line = fgetl(fh);
			line(line == '"') = [];
			while (~isempty(line))
				[term, line] = strtok(line, ',');
				if (term(2) =='"') 
					next_quote = find(line == '"');
					next_quote(2:end) = [];
					term = [term line(1:next_quote)];	
					line(1:next_quote) = [];
				end
				term = term(term >= 'A');
				fstruct.(term) = 0;
				fields(end+1) = {term};
			end
			line = fgetl(fh);
		    start = find(line == '(');
		    fin = find(line == ')');
		    for (i = length(start):-1:1) 
			    line(start(i):fin(i)) = char(' ' .* ones(1,fin(i) - start(i) + 1));
		    end
		    start = find(line == '<');
		    fin = find(line == '>');
		    for (i = length(start):-1:1) 
			    line(start(i):fin(i)) = char(' ' .* ones(1,fin(i) - start(i) + 1));
		    end
		    line(line == ' ') = [];
		end
		if (flag)
			i = 1; 
			while (~isempty(line))
				field = fields{i};
				[term, line] = strtok(line, ',');
				switch (field)
					case {'Min', 'Max', 'Avg'}
						term = str2num(term);
					otherwise 
						term = {term};
				end
				fstruct.(field) = [fstruct.(field) term];
				i = i + 1;
			end

		end
		line = fgetl(fh);
		

	end
	fclose(fh);

end;

function cfi_array = printCFI(str, names) 
	cfi_array = [];
	for i = 1:length(str)
		name = names{i};
		f = str(i);
		metrics = f.MetricName;
		cf_exec = find(strcmp(metrics, '"cf_executeda'));
		branch_ef = find(strcmp(metrics, '"branch_efficiency"'));
		ins_exec = find(strcmp(metrics, '"inst_executed"'));
		if (length(cf_exec) != length(branch_ef) || length(branch_ef) != length(ins_exec))
				sprintf('File: %s, %s\n', name);
				sprintf('Do not have all metrics\n')
				continue;
		end
			
		for j = 1:length(cf_exec);
						
			kernel = f.Kernel{cf_exec(j)}
			cf_e = f.Avg(cf_exec(j));
			b_e = f.Avg(branch_ef(j));
			i_e = f.Avg(ins_exec(j));
			if (i_e == 0) 
				sprintf('File, Kernel: %s, %s\n', name, kernel)
				sprintf('CFI undetermined - instructions executed = 0')
	
			else
				cfi_array(i, j) = ((1-b_e) * cf_e) / i_e;
				sprintf('File, Kernel: %s, %s\n', name, kernel);
				sprintf('CFI: %d\n', ((1-b_e) * cf_e) / i_e);
			end 
		end
		sprintf('-------------------------------\n')
		
	end


end
