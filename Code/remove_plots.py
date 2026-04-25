import re

def comment_out_plots(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    # Regex to match plotting-related MATLAB commands
    # e.g., plot(...), figure(...), saveas(...), title(...), xlabel(...), ylabel(...), hold on, hold off, legend(...)
    # We want to match these at the start of the line or after whitespace
    pattern = re.compile(r'^(\s*)(figure|plot|saveas|title|xlabel|ylabel|legend|hold on|hold off|xlim|ylim|scatter|area|fill)\b', re.IGNORECASE)

    modified = False
    for i in range(len(lines)):
        line = lines[i]
        # Skip already commented lines
        if line.lstrip().startswith('%'):
            continue
        
        if pattern.match(line):
            lines[i] = '%' + line
            modified = True
            
        # Also catch h_rmsratio = plot(...) style assignments
        if re.search(r'^\s*\w+\s*=\s*(plot|figure|scatter)\b', line, re.IGNORECASE):
            lines[i] = '%' + line
            modified = True

    if modified:
        with open(file_path, 'w', encoding='utf-8') as f:
            f.writelines(lines)
        print(f"Modified {file_path}")
    else:
        print(f"No changes made to {file_path}")

if __name__ == "__main__":
    comment_out_plots("Mallbooks.m")
