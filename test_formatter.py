#!/usr/bin/env python3
"""Test the new formatter with :type sorting and column alignment."""

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

        # Skip whitespace
        while i < len(s) and s[i] in ' \t\n':
            i += 1

        # Read value
        val_start = i
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

        entries.append((key, val))

        # Skip whitespace and comma
        while i < len(s) and s[i] in ' \t\n,':
            i += 1

    return entries


def format_map(s, indent=0):
    """Format a map with :type first and column alignment."""
    entries = parse_map(s)
    if not entries:
        return s

    # Sort: :type first
    entries = sorted(entries, key=lambda e: (not e[0].startswith(':type'), e[0]))

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
            'expected': '{:a 1,\n    :b 2}'
        },
        {
            'name': 'Map with :type (should move to front)',
            'input': '{:a 1, :type :Foo, :b 2}',
            'expected': '{:type :Foo,\n    :a 1,\n    :b 2}'
        },
        {
            'name': 'Original complex example',
            'input': '{:deft.deft-test/side1 1, :deft.deft-test/side2 3, :deft.deft-test/pos {:deft.deft-test/x 1, :deft.deft-test/y 2, :type :deft.deft-test/Position}, :type :deft.deft-test/Rectangle}',
            'expected': None  # Just show output
        },
        {
            'name': 'Nested with :type in both levels',
            'input': '{:a 1, :b {:c 2, :type :Inner}, :type :Outer}',
            'expected': None
        },
    ]

    for test in tests:
        result = cider_format_map(test['input'], 3)

        print(f"\n{'='*70}")
        print(f"TEST: {test['name']}")
        print(f"\nINPUT:")
        print(f"  {test['input']}")
        print(f"\nOUTPUT:")
        # Add "=> " prefix for display
        for line in result.split('\n'):
            print(f"=> {line}")

        if test['expected']:
            expected_with_prefix = '\n'.join(f"=> {line}" for line in test['expected'].split('\n'))
            actual_with_prefix = '\n'.join(f"=> {line}" for line in result.split('\n'))

            print(f"\nEXPECTED:")
            print(expected_with_prefix)

            if result == test['expected']:
                print("\n✓ PASS")
            else:
                print("\n✗ FAIL")


if __name__ == '__main__':
    test_formatter()
