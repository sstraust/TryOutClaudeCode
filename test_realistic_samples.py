#!/usr/bin/env python3
"""
Test paywall detection with realistic HTML samples that mimic real-world sites.
"""

from bs4 import BeautifulSoup
from paywall_detection import (
    check_schema_org_paywall,
    check_meta_paywall,
    check_paywall_elements,
    parse_paywall_status
)

# Realistic HTML samples based on actual paywalled sites

NYT_STYLE_HTML = '''
<!DOCTYPE html>
<html>
<head>
    <meta property="og:title" content="Test Article">
    <script type="application/ld+json">
    {
        "@context": "https://schema.org",
        "@type": "NewsArticle",
        "headline": "Test Article",
        "isAccessibleForFree": false,
        "hasPart": {
            "@type": "WebPageElement",
            "isAccessibleForFree": false,
            "cssSelector": ".article-body"
        }
    }
    </script>
</head>
<body>
    <div class="article">
        <div class="article-body">
            <p>Article content...</p>
        </div>
        <div id="gateway-content" class="css-1nz84br">
            <div class="css-1v2n6ql">Subscribe to continue reading.</div>
        </div>
    </div>
</body>
</html>
'''

WSJ_STYLE_HTML = '''
<!DOCTYPE html>
<html>
<head>
    <meta name="article.access" content="metered">
    <meta property="og:type" content="article">
    <script type="application/ld+json">
    {
        "@context": "https://schema.org",
        "@graph": [
            {
                "@type": "WebPage",
                "url": "https://example.com"
            },
            {
                "@type": "NewsArticle",
                "headline": "Test",
                "isAccessibleForFree": "false"
            }
        ]
    }
    </script>
</head>
<body>
    <article>
        <p>Some preview text...</p>
        <div class="snippet-promotion">
            <p>Continue reading your article with a WSJ membership</p>
        </div>
    </article>
</body>
</html>
'''

MEDIUM_STYLE_HTML = '''
<!DOCTYPE html>
<html>
<head>
    <meta property="og:site_name" content="Medium">
    <meta name="twitter:app:name:iphone" content="Medium">
</head>
<body>
    <div class="meteredContent">
        <article>
            <p>Article text...</p>
        </article>
        <div class="paywallBar">
            <button>Become a member</button>
        </div>
    </div>
</body>
</html>
'''

FT_STYLE_HTML = '''
<!DOCTYPE html>
<html>
<head>
    <meta name="ft-content-uuid" content="abc123">
    <meta name="ft-access" content="premium">
    <script type="application/ld+json">
    {
        "@context": "https://schema.org",
        "@type": "NewsArticle",
        "isAccessibleForFree": false
    }
    </script>
</head>
<body>
    <div class="article-body premium-content">
        <p>Premium article...</p>
        <div class="subscription-prompt">
            <p>Subscribe to read more</p>
        </div>
    </div>
</body>
</html>
'''

FREE_SITE_HTML = '''
<!DOCTYPE html>
<html>
<head>
    <meta property="og:type" content="article">
    <script type="application/ld+json">
    {
        "@context": "https://schema.org",
        "@type": "NewsArticle",
        "headline": "Free Article",
        "isAccessibleForFree": true
    }
    </script>
</head>
<body>
    <article class="article-content">
        <h1>Free Article</h1>
        <p>This is completely free content that anyone can read.</p>
        <p>No subscription required.</p>
    </article>
</body>
</html>
'''

BBC_STYLE_HTML = '''
<!DOCTYPE html>
<html>
<head>
    <meta property="og:site_name" content="BBC News">
    <meta name="article:author" content="BBC News">
    <script type="application/ld+json">
    {
        "@context": "https://schema.org",
        "@type": "NewsArticle",
        "headline": "News Article"
    }
    </script>
</head>
<body>
    <article>
        <h1>News Article</h1>
        <div class="article-body">
            <p>Full article content available to all.</p>
        </div>
    </article>
</body>
</html>
'''

# Edge cases

NESTED_GRAPH_HTML = '''
<!DOCTYPE html>
<html>
<head>
    <script type="application/ld+json">
    {
        "@context": "https://schema.org",
        "@graph": {
            "@type": "NewsArticle",
            "isAccessibleForFree": false
        }
    }
    </script>
</head>
<body><p>Content</p></body>
</html>
'''

MULTIPLE_SCRIPTS_HTML = '''
<!DOCTYPE html>
<html>
<head>
    <script type="application/ld+json">
    {
        "@context": "https://schema.org",
        "@type": "WebSite",
        "name": "Example"
    }
    </script>
    <script type="application/ld+json">
    {
        "@context": "https://schema.org",
        "@type": "NewsArticle",
        "headline": "Test",
        "isAccessibleForFree": false
    }
    </script>
</head>
<body><p>Content</p></body>
</html>
'''

SUBSCRIBER_ONLY_CLASS = '''
<!DOCTYPE html>
<html>
<body>
    <div class="article subscriber-only">
        <p>Premium content for subscribers</p>
    </div>
</body>
</html>
'''

LOCKED_CONTENT_ID = '''
<!DOCTYPE html>
<html>
<body>
    <div id="locked-content-overlay">
        <p>This content is locked</p>
    </div>
</body>
</html>
'''

TEST_CASES = [
    ("New York Times style", NYT_STYLE_HTML, True, "NYT uses isAccessibleForFree: false in JSON-LD"),
    ("Wall Street Journal style", WSJ_STYLE_HTML, True, "WSJ uses @graph with isAccessibleForFree"),
    ("Medium style", MEDIUM_STYLE_HTML, True, "Medium uses metered/paywall classes"),
    ("Financial Times style", FT_STYLE_HTML, True, "FT uses premium meta tag and schema.org"),
    ("Free site with schema", FREE_SITE_HTML, False, "Explicitly marked as free"),
    ("BBC News style", BBC_STYLE_HTML, False, "BBC has no paywall indicators"),
    ("Nested @graph (dict not list)", NESTED_GRAPH_HTML, True, "Tests @graph as dict"),
    ("Multiple JSON-LD scripts", MULTIPLE_SCRIPTS_HTML, True, "Tests multiple script tags"),
    ("Subscriber-only class", SUBSCRIBER_ONLY_CLASS, True, "Tests CSS class detection"),
    ("Locked content ID", LOCKED_CONTENT_ID, True, "Tests ID-based detection"),
]

def test_realistic_samples():
    """Test with realistic HTML samples"""
    print("=" * 70)
    print("TESTING WITH REALISTIC HTML SAMPLES")
    print("=" * 70)

    passed = 0
    failed = 0

    for i, (name, html, expected_paywall, description) in enumerate(TEST_CASES, 1):
        print(f"\n{i}. {name}")
        print(f"   Description: {description}")
        print(f"   Expected: {'PAYWALLED' if expected_paywall else 'FREE'}")

        soup = BeautifulSoup(html, 'html.parser')

        # Test individual methods
        schema_result = check_schema_org_paywall(soup)
        meta_result = check_meta_paywall(soup)
        css_result = check_paywall_elements(soup)

        print(f"   Detection methods:")
        print(f"     - Schema.org: {schema_result}")
        print(f"     - Meta tags: {meta_result}")
        print(f"     - CSS/ID: {css_result}")

        # Test main function
        page_data = {"soup": soup}
        result = parse_paywall_status(
            basic_info={},
            page_data=page_data,
            existing_article=None,
            feed_article_obj=None
        )

        detected_paywall = result.get("is_paywalled", False)
        detection_method = result.get("detection_method", "none")

        print(f"   Result: is_paywalled={detected_paywall}, method={detection_method}")

        if detected_paywall == expected_paywall:
            print(f"   ✅ PASS")
            passed += 1
        else:
            print(f"   ❌ FAIL - Expected {expected_paywall}, got {detected_paywall}")
            failed += 1

    print("\n" + "=" * 70)
    print("SUMMARY")
    print("=" * 70)
    print(f"Total tests: {len(TEST_CASES)}")
    print(f"Passed: {passed} ✅")
    print(f"Failed: {failed} {'❌' if failed > 0 else ''}")
    print(f"Success rate: {(passed/len(TEST_CASES)*100):.1f}%")

    return passed, failed

def test_edge_cases():
    """Test edge cases and error handling"""
    print("\n" + "=" * 70)
    print("TESTING EDGE CASES")
    print("=" * 70)

    # Test 1: Empty soup
    print("\n1. Empty HTML")
    empty_soup = BeautifulSoup("", 'html.parser')
    result = parse_paywall_status({}, {"soup": empty_soup}, None, None)
    print(f"   Result: {result}")
    print(f"   ✅ PASS - Should return {{'is_paywalled': False}}" if result == {"is_paywalled": False} else "   ❌ FAIL")

    # Test 2: Malformed JSON-LD
    print("\n2. Malformed JSON-LD")
    malformed_html = '''
    <script type="application/ld+json">
    { invalid json here }
    </script>
    '''
    soup = BeautifulSoup(malformed_html, 'html.parser')
    result = check_schema_org_paywall(soup)
    print(f"   Result: {result}")
    print(f"   ✅ PASS - Should return False (graceful failure)" if not result else "   ❌ FAIL")

    # Test 3: None values in meta tags
    print("\n3. None values in meta tags")
    none_meta_html = '<meta name="" content="">'
    soup = BeautifulSoup(none_meta_html, 'html.parser')
    result = check_meta_paywall(soup)
    print(f"   Result: {result}")
    print(f"   ✅ PASS - Should handle None gracefully" if not result else "   ❌ FAIL")

    # Test 4: Classes as string (edge case)
    print("\n4. Class attribute as string")
    class_string_html = '<div class="paywall-content">text</div>'
    soup = BeautifulSoup(class_string_html, 'html.parser')
    result = check_paywall_elements(soup)
    print(f"   Result: {result}")
    print(f"   ✅ PASS - Should detect paywall" if result else "   ❌ FAIL")

    # Test 5: Array of JSON-LD objects
    print("\n5. JSON-LD as array")
    array_html = '''
    <script type="application/ld+json">
    [
        {"@type": "WebPage"},
        {"@type": "NewsArticle", "isAccessibleForFree": false}
    ]
    </script>
    '''
    soup = BeautifulSoup(array_html, 'html.parser')
    result = check_schema_org_paywall(soup)
    print(f"   Result: {result}")
    print(f"   ✅ PASS - Should detect paywall in array" if result else "   ❌ FAIL")

def test_existing_article_priority():
    """Test that existing article data takes priority"""
    print("\n" + "=" * 70)
    print("TESTING EXISTING ARTICLE PRIORITY")
    print("=" * 70)

    # Create HTML that would normally be detected as free
    free_html = '<html><body><p>Free content</p></body></html>'
    soup = BeautifulSoup(free_html, 'html.parser')
    page_data = {"soup": soup}

    # But existing article says it's paywalled
    existing_article = {"is_paywalled": True}

    result = parse_paywall_status({}, page_data, existing_article, None)

    print(f"HTML indicates: FREE")
    print(f"Existing article indicates: PAYWALLED")
    print(f"Result: {result}")

    if result.get("is_paywalled") and result.get("detection_method") == "existing_article":
        print("✅ PASS - Existing article data takes priority")
    else:
        print("❌ FAIL - Should prioritize existing article data")

if __name__ == "__main__":
    passed, failed = test_realistic_samples()
    test_edge_cases()
    test_existing_article_priority()

    print("\n" + "=" * 70)
    print("ALL TESTS COMPLETE")
    print("=" * 70)

    exit(0 if failed == 0 else 1)
