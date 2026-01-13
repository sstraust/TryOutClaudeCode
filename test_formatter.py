#!/usr/bin/env python3
"""Test the formatter - only :type should be reordered."""

def parse_map(s):
    """Parse a map string into list of (key, value) tuples."""
    if not s.startswith('{') or not s.endswith('}'):
        return None

    entries = []
    i = 1  # Skip opening {

    while i < len(s) - 1:
        # Skip whitespace
        while i < len(s) and s[i] in ' \t\n':
            i += 1

        if i >= len(s) - 1:
            break

        # Read key
        key_start = i
        while i < len(s) and s[i] not in ' \t\n,{}':
            i += 1
        key = s[key_start:i]

        if not key:
            break

        # Skip whitespace
        while i < len(s) and s[i] in ' \t\n':
            i += 1

        # Read value
        val_start = i
        if i >= len(s):
            break

        if s[i] == '"':
            # String value
            i += 1
            while i < len(s) and s[i] != '"':
                i += 1
            i += 1
            val = s[val_start:i]
        elif s[i] == '{':
            # Nested map
            depth = 1
            i += 1
            while i < len(s) and depth > 0:
                if s[i] == '"':
                    i += 1
                    while i < len(s) and s[i] != '"':
                        i += 1
                    i += 1
                elif s[i] == '{':
                    depth += 1
                    i += 1
                elif s[i] == '}':
                    depth -= 1
                    i += 1
                else:
                    i += 1
            val = s[val_start:i]
        else:
            # Simple value
            while i < len(s) and s[i] not in ' \t\n,{}':
                i += 1
            val = s[val_start:i]

        if val:
            entries.append((key, val))

        # Skip whitespace and comma
        while i < len(s) and s[i] in ' \t\n,':
            i += 1

    return entries


def format_map(s, indent=0):
    """Format a map with :type first, preserving order of other keys."""
    entries = parse_map(s)
    if not entries:
        return s

    # Separate :type entries from others, preserving original order
    type_entries = [e for e in entries if e[0].startswith(':type')]
    other_entries = [e for e in entries if not e[0].startswith(':type')]
    entries = type_entries + other_entries

    # Calculate column position (after opening brace)
    col = indent + 1

    # Format entries
    result = ['{']
    for i, (key, val) in enumerate(entries):
        if i > 0:
            result.append(',\n' + ' ' * col)

        # Recursively format nested maps
        if val.startswith('{'):
            formatted_val = format_map(val, col + len(key) + 1)
        else:
            formatted_val = val

        result.append(f'{key} {formatted_val}')

    result.append('}')
    return ''.join(result)


def cider_format_map(s, prefix_length):
    """Format map with prefix alignment."""
    if not (isinstance(s, str) and s.startswith('{') and s.endswith('}')):
        return s
    return format_map(s, prefix_length)


def test_formatter():
    """Test the formatter."""
    tests = [
        {
            'name': 'Simple map',
            'input': '{:a 1, :b 2}',
            'note': 'No :type, order should be preserved'
        },
        {
            'name': 'Map with :type at end',
            'input': '{:a 1, :b 2, :type :Foo}',
            'note': ':type should move to front, :a and :b stay in order'
        },
        {
            'name': 'Map with :type in middle',
            'input': '{:a 1, :type :Foo, :b 2, :c 3}',
            'note': ':type first, then :a, :b, :c in original order'
        },
        {
            'name': 'Original complex example',
            'input': '{:deft.deft-test/side1 1, :deft.deft-test/side2 3, :deft.deft-test/pos {:deft.deft-test/x 1, :deft.deft-test/y 2, :type :deft.deft-test/Position}, :type :deft.deft-test/Rectangle}',
            'note': 'Check order preservation and nested formatting'
        },
        {
            'name': 'Empty map',
            'input': '{}',
            'note': 'Should stay empty'
        },
        {
            'name': 'String with comma',
            'input': '{:a "hello, world", :b 2}',
            'note': 'String should not be broken'
        },
        {
            'name': 'Multiple nested maps',
            'input': '{:x {:a 1, :type :A}, :y {:b 2, :type :B}, :type :Root}',
            'note': 'Each level should have :type first'
        },
    ]

    for test in tests:
        result = cider_format_map(test['input'], 3)

        print(f"\n{'='*70}")
        print(f"TEST: {test['name']}")
        print(f"NOTE: {test['note']}")
        print(f"\nINPUT:")
        print(f"  {test['input']}")
        print(f"\nOUTPUT:")
        for line in result.split('\n'):
            print(f"=> {line}")


if __name__ == '__main__':
    test_formatter()
