#!/usr/bin/env python3
"""Simulate the Emacs Lisp formatter logic to test it."""

def cider_format_map(s, prefix_length):
    """Format map string by adding newlines and indentation after commas."""
    if not (isinstance(s, str) and s.startswith('{') and s.endswith('}')):
        return s

    result = []
    i = 0
    depth = 0
    base_indent = prefix_length

    while i < len(s):
        char = s[i]

        # Skip strings
        if char == '"':
            result.append(char)
            i += 1
            # Find closing quote
            while i < len(s) and s[i] != '"':
                result.append(s[i])
                i += 1
            if i < len(s):
                result.append(s[i])  # Add closing quote
                i += 1
            continue

        # Opening brace
        if char == '{':
            result.append(char)
            depth += 1
            i += 1
            continue

        # Closing brace
        if char == '}':
            depth = max(0, depth - 1)
            result.append(char)
            i += 1
            continue

        # Comma
        if char == ',':
            result.append(char)
            i += 1
            # Skip spaces after comma
            while i < len(s) and s[i] == ' ':
                i += 1
            # Add newline and indent unless next is }
            if i < len(s) and s[i] != '}':
                indent_spaces = base_indent + 2 * depth
                result.append('\n' + ' ' * indent_spaces)
            continue

        # Regular character
        result.append(char)
        i += 1

    return ''.join(result)


def test_formatter():
    """Run tests on the formatter."""
    tests = [
        {
            'name': 'Simple map',
            'input': '{:a 1, :b 2}',
            'expected': '{:a 1,\n     :b 2}'
        },
        {
            'name': 'Nested map',
            'input': '{:a {:b 1, :c 2}, :d 3}',
            'expected': '{:a {:b 1,\n       :c 2},\n     :d 3}'
        },
        {
            'name': 'Empty map',
            'input': '{}',
            'expected': '{}'
        },
        {
            'name': 'String with comma',
            'input': '{:a "hello, world", :b 2}',
            'expected': '{:a "hello, world",\n     :b 2}'
        },
        {
            'name': 'Original complex example',
            'input': '{:deft.deft-test/side1 1, :deft.deft-test/side2 3, :deft.deft-test/pos {:deft.deft-test/x 1, :deft.deft-test/y 2, :type :deft.deft-test/Position}, :type :deft.deft-test/Rectangle}',
            'expected': None  # We'll just print this to see what we get
        },
        {
            'name': 'Vector (non-map)',
            'input': '[:a 1 :b 2]',
            'expected': '[:a 1 :b 2]'
        },
        {
            'name': 'Multiple strings with commas',
            'input': '{:a "hello", :b "world, foo", :c 3}',
            'expected': '{:a "hello",\n     :b "world, foo",\n     :c 3}'
        }
    ]

    passed = 0
    failed = 0

    for test in tests:
        result = cider_format_map(test['input'], 3)

        print(f"\n{'='*60}")
        print(f"TEST: {test['name']}")
        print(f"INPUT:")
        print(f"  {test['input']}")
        print(f"\nOUTPUT:")
        for line in result.split('\n'):
            print(f"  {repr(line)}")

        if test['expected'] is not None:
            if result == test['expected']:
                print(f"\n✓ PASS")
                passed += 1
            else:
                print(f"\n✗ FAIL")
                print(f"EXPECTED:")
                for line in test['expected'].split('\n'):
                    print(f"  {repr(line)}")
                failed += 1
        else:
            print(f"\n(No expected output - visual inspection)")

    print(f"\n{'='*60}")
    print(f"SUMMARY: {passed} passed, {failed} failed")
    print(f"{'='*60}")

    return failed == 0


if __name__ == '__main__':
    import sys
    success = test_formatter()
    sys.exit(0 if success else 1)
