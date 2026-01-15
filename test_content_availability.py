#!/usr/bin/env python3
"""
Test the content availability detection for soft paywalls.
"""

from bs4 import BeautifulSoup
from paywall_detection import check_content_availability, parse_paywall_status


def test_content_availability_checks():
    """Test various content availability scenarios"""
    print("=" * 70)
    print("TESTING CONTENT AVAILABILITY DETECTION")
    print("=" * 70)

    test_cases = []

    # Test 1: Article with sufficient content (should be FREE)
    html1 = '''
    <html>
    <body>
        <article>
            <h1>Full Article Title</h1>
            <div class="article-body">
                <p>This is a paragraph with substantial content. Lorem ipsum dolor sit amet,
                consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et
                dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation
                ullamco laboris nisi ut aliquip ex ea commodo consequat.</p>
                <p>Duis aute irure dolor in reprehenderit in voluptate velit esse cillum
                dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non
                proident, sunt in culpa qui officia deserunt mollit anim id est laborum.</p>
                <p>More substantial content here to make this a complete article that
                should not be flagged as paywalled based on content length.</p>
            </div>
        </article>
    </body>
    </html>
    '''
    test_cases.append({
        "name": "Full article with sufficient content",
        "html": html1,
        "expected": False,
        "description": "Should detect content is available"
    })

    # Test 2: Short preview with "continue reading" (should be PAYWALLED)
    html2 = '''
    <html>
    <body>
        <article>
            <h1>Article Title</h1>
            <div class="article-body">
                <p>This is just a short preview of the article content...</p>
                <div class="paywall-message">
                    <p>Continue reading with a subscription</p>
                </div>
            </div>
        </article>
    </body>
    </html>
    '''
    test_cases.append({
        "name": "Short preview with 'continue reading'",
        "html": html2,
        "expected": True,
        "description": "Should detect truncated content"
    })

    # Test 3: Very short snippet (should be PAYWALLED)
    html3 = '''
    <html>
    <body>
        <article class="article-content">
            <p>Just a tiny snippet of text here.</p>
        </article>
    </body>
    </html>
    '''
    test_cases.append({
        "name": "Very short snippet (< 400 chars)",
        "html": html3,
        "expected": True,
        "description": "Should detect insufficient content"
    })

    # Test 4: No article content at all (should be PAYWALLED)
    html4 = '''
    <html>
    <body>
        <div class="header">
            <h1>Page Title</h1>
        </div>
        <div class="sidebar">
            <p>Some sidebar content</p>
        </div>
    </body>
    </html>
    '''
    test_cases.append({
        "name": "No article content found",
        "html": html4,
        "expected": True,
        "description": "Should detect missing article content"
    })

    # Test 5: Content with "subscribe to" message (should be PAYWALLED)
    html5 = '''
    <html>
    <body>
        <article>
            <div class="story-body">
                <p>A short article introduction goes here. This is the opening paragraph.</p>
                <p>Another paragraph with some more details.</p>
                <div class="subscription-prompt">
                    <p>Subscribe to read the full story</p>
                </div>
            </div>
        </article>
    </body>
    </html>
    '''
    test_cases.append({
        "name": "Content with 'subscribe to' message",
        "html": html5,
        "expected": True,
        "description": "Should detect subscription prompt"
    })

    # Test 6: Medium-length content with subscription required (should be PAYWALLED)
    html6 = '''
    <html>
    <body>
        <article>
            <div class="entry-content">
                <p>This article has some content, but not the full story. Lorem ipsum dolor
                sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut
                labore et dolore magna aliqua.</p>
                <p>This article is for subscribers only. Sign in to read more.</p>
            </div>
        </article>
    </body>
    </html>
    '''
    test_cases.append({
        "name": "Medium content with 'this article is for subscribers'",
        "html": html6,
        "expected": True,
        "description": "Should detect subscriber-only message"
    })

    # Test 7: Long article with full content (should be FREE)
    html7 = '''
    <html>
    <body>
        <main>
            <article>
                <h1>Complete Article</h1>
                <div id="article-body">
                    <p>This is a complete article with plenty of content. Lorem ipsum dolor sit amet,
                    consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et
                    dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation
                    ullamco laboris nisi ut aliquip ex ea commodo consequat.</p>
                    <p>Duis aute irure dolor in reprehenderit in voluptate velit esse cillum
                    dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non
                    proident, sunt in culpa qui officia deserunt mollit anim id est laborum.</p>
                    <p>Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium
                    doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo inventore
                    veritatis et quasi architecto beatae vitae dicta sunt explicabo.</p>
                    <p>Nemo enim ipsam voluptatem quia voluptas sit aspernatur aut odit aut fugit,
                    sed quia consequuntur magni dolores eos qui ratione voluptatem sequi nesciunt.</p>
                </div>
            </article>
        </main>
    </body>
    </html>
    '''
    test_cases.append({
        "name": "Long article with full content",
        "html": html7,
        "expected": False,
        "description": "Should detect content is fully available"
    })

    # Test 8: Content with "become a member" (should be PAYWALLED)
    html8 = '''
    <html>
    <body>
        <article class="post-content">
            <p>Opening paragraph with some introduction to the topic.</p>
            <p>Second paragraph with a bit more detail about the subject matter.</p>
            <div class="membership-wall">
                <p>Become a member to continue reading</p>
            </div>
        </article>
    </body>
    </html>
    '''
    test_cases.append({
        "name": "Content with 'become a member'",
        "html": html8,
        "expected": True,
        "description": "Should detect membership requirement"
    })

    # Run tests
    passed = 0
    failed = 0

    for i, test in enumerate(test_cases, 1):
        print(f"\n{i}. {test['name']}")
        print(f"   Description: {test['description']}")
        print(f"   Expected: {'PAYWALLED' if test['expected'] else 'FREE'}")

        soup = BeautifulSoup(test['html'], 'html.parser')
        result = check_content_availability(soup)

        print(f"   Result: {'PAYWALLED' if result else 'FREE'}")

        if result == test['expected']:
            print("   ✅ PASS")
            passed += 1
        else:
            print(f"   ❌ FAIL - Expected {test['expected']}, got {result}")
            failed += 1

    # Summary
    print("\n" + "=" * 70)
    print("SUMMARY")
    print("=" * 70)
    print(f"Total: {len(test_cases)}")
    print(f"Passed: {passed} ✅")
    print(f"Failed: {failed} {'❌' if failed > 0 else ''}")
    print(f"Success rate: {(passed/len(test_cases)*100):.1f}%")

    return passed, failed


def test_integration_with_parse_paywall():
    """Test that content availability integrates properly with main function"""
    print("\n" + "=" * 70)
    print("TESTING INTEGRATION WITH MAIN FUNCTION")
    print("=" * 70)

    # Test case: Short content with no other paywall indicators
    html = '''
    <html>
    <head>
        <script type="application/ld+json">
        {
            "@context": "https://schema.org",
            "@type": "NewsArticle",
            "headline": "Test Article"
        }
        </script>
    </head>
    <body>
        <article>
            <p>Very short preview text.</p>
            <p>Subscribe to read more</p>
        </article>
    </body>
    </html>
    '''

    soup = BeautifulSoup(html, 'html.parser')
    page_data = {"soup": soup}
    result = parse_paywall_status({}, page_data, None, None)

    print("\nTest: Short content with 'subscribe to read more'")
    print(f"Expected: PAYWALLED (via content_unavailable)")
    print(f"Result: is_paywalled={result.get('is_paywalled')}, method={result.get('detection_method')}")

    if result.get("is_paywalled") and result.get("detection_method") == "content_unavailable":
        print("✅ PASS - Content availability check integrated correctly")
        return True
    else:
        print("❌ FAIL - Integration issue")
        return False


def test_custom_threshold():
    """Test content availability with custom threshold"""
    print("\n" + "=" * 70)
    print("TESTING CUSTOM CONTENT LENGTH THRESHOLD")
    print("=" * 70)

    html = '''
    <article>
        <p>This is a medium-length article with about 300 characters of text content.
        Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor
        incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud
        exercitation ullamco laboris nisi ut aliquip.</p>
    </article>
    '''

    soup = BeautifulSoup(html, 'html.parser')

    # Test with default threshold (400)
    result_default = check_content_availability(soup)
    print(f"\n1. Default threshold (400 chars)")
    print(f"   Result: {'PAYWALLED' if result_default else 'FREE'}")
    print(f"   Expected: PAYWALLED (content < 400)")
    if result_default:
        print("   ✅ PASS")
    else:
        print("   ❌ FAIL")

    # Test with lower threshold (200)
    result_low = check_content_availability(soup, min_content_length=200)
    print(f"\n2. Low threshold (200 chars)")
    print(f"   Result: {'PAYWALLED' if result_low else 'FREE'}")
    print(f"   Expected: FREE (content > 200)")
    if not result_low:
        print("   ✅ PASS")
    else:
        print("   ❌ FAIL")


if __name__ == "__main__":
    print("Content Availability Detection Tests")
    print("=" * 70)

    # Run all tests
    passed, failed = test_content_availability_checks()
    integration_pass = test_integration_with_parse_paywall()
    test_custom_threshold()

    print("\n" + "=" * 70)
    print("ALL TESTS COMPLETE")
    print("=" * 70)

    exit(0 if failed == 0 and integration_pass else 1)
