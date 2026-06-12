import os
import re

def replace_with_opacity(file_path):
    with open(file_path, 'r') as f:
        content = f.read()
    
    # Regex to match .withOpacity(...)
    # It handles nested parentheses by finding the matching closing parenthesis
    def replacer(match):
        start_index = match.start()
        # Find the start of the arguments (after '.withOpacity(')
        args_start = start_index + len('.withOpacity(')
        
        # Balance parentheses to find the end of the .withOpacity call
        depth = 1
        i = args_start
        while depth > 0 and i < len(content):
            if content[i] == '(':
                depth += 1
            elif content[i] == ')':
                depth -= 1
            i += 1
        
        if depth == 0:
            args = content[args_start:i-1]
            return f'.withValues(alpha: {args})'
        else:
            return match.group(0) # Should not happen with valid code

    # We use a while loop or finditer to replace all occurrences because they can be nested or sequential
    new_content = content
    pattern = re.compile(r'\.withOpacity\(')
    
    # Process from the end to avoid index shifts
    matches = list(pattern.finditer(content))
    for match in reversed(matches):
        start_index = match.start()
        args_start = start_index + len('.withOpacity(')
        
        depth = 1
        i = args_start
        while depth > 0 and i < len(content):
            if content[i] == '(':
                depth += 1
            elif content[i] == ')':
                depth -= 1
            i += 1
        
        if depth == 0:
            args = content[args_start:i-1]
            new_content = new_content[:start_index] + f'.withValues(alpha: {args})' + new_content[i:]

    if new_content != content:
        with open(file_path, 'w') as f:
            f.write(new_content)
        return True
    return False

def main():
    for root, dirs, files in os.walk('.'):
        for file in files:
            if file.endswith('.dart'):
                file_path = os.path.join(root, file)
                if replace_with_opacity(file_path):
                    print(f'Updated {file_path}')

if __name__ == '__main__':
    main()
