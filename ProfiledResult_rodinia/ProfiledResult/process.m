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
			    freqs = glob([path '*/']);
			    for f = 1:length(freqs)
				    fname = ls([freqs{f} '*.txt']);
				    tmp = parseFile([fname]);
					fname
					if ~isempty(tmp)					    
					fstruct(end+1) = parseFile([fname]);
					names(end+1) = {fname};
					else 
					sprintf('file %s did not work\n')
					end
    			end
			end
		end
    
    
    
    
    end
	fstruct(1) = [];
	cfi_array = printCFI(fstruct, names);    
    
    
    
    
    
end


function fstruct = parseFile(fname);
	sprintf('Parsing file %s', fname);
	fstruct = struct();
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
						if (term(end) == '%')
							term(end) = [];
							term = str2num(term)
							term = term / 100;
						else 
							term = str2num(term);
						end
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
	fhout = fopen('process_data.out', 'w');
	for i = 1:length(str)
		name = names{i}
		f = str(i);
		metrics = f.MetricName;
	
		cf_iss = find(strcmp(metrics, '"cf_issued"'));
		ins_exec = find(strcmp(metrics, '"inst_executed"'));
		srover = find(strcmp(metrics, '"shared_replay_overhead"'));
		lrover = find(strcmp(metrics, '"local_replay_overhead"'));
		gcrover = find(strcmp(metrics, '"global_cache_replay_overhead"'));
		arover = find(strcmp(metrics, '"atomic_replay_overhead"'));
		branch_ef = find(strcmp(metrics, '"branch_efficiency"'));
		%if (length(cf_exec) != length(branch_ef) || length(branch_ef) != length(ins_exec))
		if (length(cf_iss) != length(ins_exec))
				sprintf('File: %s, %s\n', name)
				sprintf('Do not have all metrics\n')
				continue;
		end
		if (length([f.Avg]) != length(f.MetricName) ) 
			sprintf('metric len %d avg len %d', length(f.MetricName), length(f.Avg))	
			f.MetricName
			f.Avg
			continue
		end
		fprintf(fhout, 'File: %s\n', name);
		for j = 1:length(cf_iss);
						
			kernel = f.Kernel{cf_iss(j)}
%			cf_e = f.Avg(cf_exec(j));
			if (strfind(name, '780'))
				b_e = 0;
			else
				b_e = f.Avg(branch_ef(j));
			end
			cf_i = f.Avg(cf_iss(j))
			i_e = f.Avg(ins_exec(j))
			sro = f.Avg(srover(j));
			lro = f.Avg(lrover(j));
			gcro =f.Avg(gcrover(j));
			aro = f.Avg(arover(j));		
			if (i_e == 0) 
				fprintf(fhout, 'CFI undetermined - instructions executed = 0\n');
	
			else
				cfi_val =  cf_i / i_e;
				mai_val = sro + lro + gcro + aro;
				cfi_array(i, j) = (cf_i/i_e)
				mai_array(i, j) = mai_val;
				if (strfind(name, '780'))
					fprintf(fhout,'CFI: %4.3f    Total Ins: %8.0f      MAI: %4.3f Kernel: %s\n', cfi_val, i_e, mai_val, kernel);
				else 
					fprintf(fhout,'CFI: %4.3f    Branch Efficiency: %4.3f      Total Ins: %8.0f      MAI: %4.3f Kernel: %s\n', cfi_val, b_e, i_e, mai_val, kernel);
				end
				%fprintf(fhout,'CFI: %4.3f  Kernel: %s\n', cfi_val, kernel);
			end 
		end
		
	end
	fclose(fhout);


end
