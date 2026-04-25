function process_signal(input_file, output_file)
    % process_signal(input_file, output_file)
    % Entry point for the compiled MATLAB executable.
    
    try
        % Pass the input file variable to the script
        auto_input_file = input_file;
        
        % Suppress warnings that might clutter stdout
        warning('off', 'all');
        
        % Run the core logic script directly (not via evalin)
        % This helps the MATLAB compiler (mcc) detect the dependency.
        Mallbooks;
        
        % Extract the final values
        pr67 = Pressure_Report_67;
        
        % Map values for JSON response
        sysL = round(pr67(1, 17));
        sysH = sysL;
        
        diaL = round(pr67(1, 18));
        diaH = diaL;
        
        mapL = round(pr67(1, 19));
        mapH = mapL;
        
        ppL = round(pr67(1, 20));
        ppH = ppL;
        
        diagnosis = pr67(1, 33);
        
        % Create the results struct exactly as requested:
        % {"results":{"sysL":110,"sysH":120,"DiaL":70,"DiaH":80,"MAPH":95,"MAPL":85,"PPL":40,"PPH":50,"diagnosis":0}}
        
        results = struct();
        results.sysL = uint16(sysL);
        results.sysH = uint16(sysH);
        results.DiaL = uint16(diaL);
        results.DiaH = uint16(diaH);
        results.MAPL = uint16(mapL);
        results.MAPH = uint16(mapH);
        results.PPL = uint16(ppL);
        results.PPH = uint16(ppH);
        results.diagnosis = uint8(diagnosis);
        
        output_struct = struct('results', results);
        
        % Write to JSON file
        json_str = jsonencode(output_struct);
        fid = fopen(output_file, 'w');
        if fid == -1
            error('Cannot open output file %s', output_file);
        end
        fprintf(fid, '%s', json_str);
        fclose(fid);
        
        fprintf('Successfully processed %s\n', input_file);
        
    catch ME
        % In case of error, print it and exit with code 1 so Python knows
        fprintf(2, 'Error processing signal: %s\n', ME.message);
        for i=1:length(ME.stack)
            fprintf(2, '  In %s (line %d)\n', ME.stack(i).name, ME.stack(i).line);
        end
        exit(1);
    end
    
    % Exit successfully
    exit(0);
end
