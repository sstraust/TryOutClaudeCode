#!/usr/bin/env python3
"""
Test script for paywall detection functionality.
Tests against real-world websites to verify detection accuracy.
"""

import requests
from bs4 import BeautifulSoup
from paywall_detection import (
    check_schema_org_paywall,
    check_meta_paywall,
    check_paywall_elements,
    parse_paywall_status
)

# Test URLs - mix of paywalled and free sites
TEST_CASES = [
    # Known paywalled sites
    {
        "url": "https://www.nytimes.com/2024/01/01/world/americas/argentina-milei.html",
        "expected": True,
        "name": "New York Times (paywalled)"
    },
    {
        "url": "https://www.wsj.com/tech/ai/openai-chatgpt-losses-funding-197ddd13",
        "expected": True,
        "name": "Wall Street Journal (paywalled)"
    },
    {
        "url": "https://www.ft.com/content/1234",
        "expected": True,
        "name": "Financial Times (paywalled)"
    },
    # Free sites
    {
        "url": "https://www.bbc.com/news",
        "expected": False,
        "name": "BBC News (free)"
    },
    {
        "url": "https://www.reuters.com/",
        "expected": False,
        "name": "Reuters (free)"
    },
]

def fetch_page(url, timeout=10):
    """Fetch a webpage and return BeautifulSoup object"""
    try:
        headers = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
        }
        response = requests.get(url, headers=headers, timeout=timeout)
        response.raise_for_status()
        return BeautifulSoup(response.text, 'html.parser')
    except Exception as e:
        print(f"Error fetching {url}: {e}")
        return None

def test_individual_checks(soup, url):
    """Test each detection method individually"""
    print(f"\n--- Testing: {url} ---")

    results = {
        "schema_org": check_schema_org_paywall(soup),
        "meta_tag": check_meta_paywall(soup),
        "css_class": check_paywall_elements(soup)
    }

    print(f"Schema.org detection: {results['schema_org']}")
    print(f"Meta tag detection: {results['meta_tag']}")
    print(f"CSS class detection: {results['css_class']}")

    return results

def test_parse_paywall_status(soup):
    """Test the main parse_paywall_status function"""
    page_data = {"soup": soup}
    result = parse_paywall_status(
        basic_info={},
        page_data=page_data,
        existing_article=None,
        feed_article_obj=None
    )
    return result

def run_tests():
    """Run all tests"""
    print("=" * 60)
    print("PAYWALL DETECTION TEST SUITE")
    print("=" * 60)

    results_summary = []

    for test_case in TEST_CASES:
        url = test_case["url"]
        expected = test_case["expected"]
        name = test_case["name"]

        print(f"\n\nTesting: {name}")
        print(f"URL: {url}")
        print(f"Expected paywall: {expected}")

        soup = fetch_page(url)
        if not soup:
            print("⚠️  Could not fetch page, skipping...")
            results_summary.append({
                "name": name,
                "status": "SKIPPED",
                "reason": "Could not fetch"
            })
            continue

        # Test individual detection methods
        individual_results = test_individual_checks(soup, url)

        # Test main function
        paywall_status = test_parse_paywall_status(soup)
        detected_paywall = paywall_status.get("is_paywalled", False)
        detection_method = paywall_status.get("detection_method", "none")

        print(f"\nFinal result: is_paywalled={detected_paywall}, method={detection_method}")

        # Check if result matches expectation
        if detected_paywall == expected:
            print("✅ PASS")
            results_summary.append({
                "name": name,
                "status": "PASS",
                "detected": detected_paywall,
                "method": detection_method
            })
        else:
            print(f"❌ FAIL - Expected {expected}, got {detected_paywall}")
            results_summary.append({
                "name": name,
                "status": "FAIL",
                "expected": expected,
                "detected": detected_paywall,
                "method": detection_method
            })

    # Print summary
    print("\n" + "=" * 60)
    print("TEST SUMMARY")
    print("=" * 60)

    passed = sum(1 for r in results_summary if r["status"] == "PASS")
    failed = sum(1 for r in results_summary if r["status"] == "FAIL")
    skipped = sum(1 for r in results_summary if r["status"] == "SKIPPED")

    for result in results_summary:
        status_symbol = "✅" if result["status"] == "PASS" else "❌" if result["status"] == "FAIL" else "⚠️"
        print(f"{status_symbol} {result['name']}: {result['status']}")
        if result["status"] == "PASS":
            print(f"   Detected: {result['detected']}, Method: {result['method']}")
        elif result["status"] == "FAIL":
            print(f"   Expected: {result['expected']}, Got: {result['detected']}")

    print(f"\nTotal: {len(results_summary)} | Passed: {passed} | Failed: {failed} | Skipped: {skipped}")

    return passed, failed, skipped

def test_schema_org_parsing():
    """Test specific JSON-LD parsing scenarios"""
    print("\n" + "=" * 60)
    print("TESTING JSON-LD PARSING LOGIC")
    print("=" * 60)

    # Test case 1: Simple isAccessibleForFree: false
    html1 = '''
    <script type="application/ld+json">
    {
        "@context": "https://schema.org",
        "@type": "NewsArticle",
        "isAccessibleForFree": false
    }
    </script>
    '''
    soup1 = BeautifulSoup(html1, 'html.parser')
    result1 = check_schema_org_paywall(soup1)
    print(f"Test 1 - Simple false: {result1} (expected: True) {'✅' if result1 else '❌'}")

    # Test case 2: String 'false'
    html2 = '''
    <script type="application/ld+json">
    {
        "@context": "https://schema.org",
        "@type": "NewsArticle",
        "isAccessibleForFree": "false"
    }
    </script>
    '''
    soup2 = BeautifulSoup(html2, 'html.parser')
    result2 = check_schema_org_paywall(soup2)
    print(f"Test 2 - String 'false': {result2} (expected: True) {'✅' if result2 else '❌'}")

    # Test case 3: @graph structure
    html3 = '''
    <script type="application/ld+json">
    {
        "@context": "https://schema.org",
        "@graph": [
            {
                "@type": "WebPage"
            },
            {
                "@type": "NewsArticle",
                "isAccessibleForFree": false
            }
        ]
    }
    </script>
    '''
    soup3 = BeautifulSoup(html3, 'html.parser')
    result3 = check_schema_org_paywall(soup3)
    print(f"Test 3 - @graph array: {result3} (expected: True) {'✅' if result3 else '❌'}")

    # Test case 4: isAccessibleForFree: true (no paywall)
    html4 = '''
    <script type="application/ld+json">
    {
        "@context": "https://schema.org",
        "@type": "NewsArticle",
        "isAccessibleForFree": true
    }
    </script>
    '''
    soup4 = BeautifulSoup(html4, 'html.parser')
    result4 = check_schema_org_paywall(soup4)
    print(f"Test 4 - isAccessibleForFree true: {result4} (expected: False) {'✅' if not result4 else '❌'}")

    # Test case 5: No isAccessibleForFree field
    html5 = '''
    <script type="application/ld+json">
    {
        "@context": "https://schema.org",
        "@type": "NewsArticle",
        "headline": "Some article"
    }
    </script>
    '''
    soup5 = BeautifulSoup(html5, 'html.parser')
    result5 = check_schema_org_paywall(soup5)
    print(f"Test 5 - No field: {result5} (expected: False) {'✅' if not result5 else '❌'}")

def test_meta_tag_detection():
    """Test meta tag detection"""
    print("\n" + "=" * 60)
    print("TESTING META TAG DETECTION")
    print("=" * 60)

    # Test case 1: Paywall in content
    html1 = '<meta name="description" content="This is a paywall article">'
    soup1 = BeautifulSoup(html1, 'html.parser')
    result1 = check_meta_paywall(soup1)
    print(f"Test 1 - 'paywall' in content: {result1} (expected: True) {'✅' if result1 else '❌'}")

    # Test case 2: Premium in name
    html2 = '<meta name="premium-content" content="true">'
    soup2 = BeautifulSoup(html2, 'html.parser')
    result2 = check_meta_paywall(soup2)
    print(f"Test 2 - 'premium' in name: {result2} (expected: True) {'✅' if result2 else '❌'}")

    # Test case 3: No paywall indicators
    html3 = '<meta name="description" content="Free article">'
    soup3 = BeautifulSoup(html3, 'html.parser')
    result3 = check_meta_paywall(soup3)
    print(f"Test 3 - No indicators: {result3} (expected: False) {'✅' if not result3 else '❌'}")

def test_css_class_detection():
    """Test CSS class/ID detection"""
    print("\n" + "=" * 60)
    print("TESTING CSS CLASS/ID DETECTION")
    print("=" * 60)

    # Test case 1: Paywall class
    html1 = '<div class="paywall-container">Content</div>'
    soup1 = BeautifulSoup(html1, 'html.parser')
    result1 = check_paywall_elements(soup1)
    print(f"Test 1 - paywall class: {result1} (expected: True) {'✅' if result1 else '❌'}")

    # Test case 2: Multiple classes with paywall
    html2 = '<div class="article-content subscriber-only premium">Content</div>'
    soup2 = BeautifulSoup(html2, 'html.parser')
    result2 = check_paywall_elements(soup2)
    print(f"Test 2 - subscriber-only class: {result2} (expected: True) {'✅' if result2 else '❌'}")

    # Test case 3: Paywall ID
    html3 = '<div id="paywall-message">Subscribe now</div>'
    soup3 = BeautifulSoup(html3, 'html.parser')
    result3 = check_paywall_elements(soup3)
    print(f"Test 3 - paywall ID: {result3} (expected: True) {'✅' if result3 else '❌'}")

    # Test case 4: No paywall indicators
    html4 = '<div class="article-content">Free content</div>'
    soup4 = BeautifulSoup(html4, 'html.parser')
    result4 = check_paywall_elements(soup4)
    print(f"Test 4 - No indicators: {result4} (expected: False) {'✅' if not result4 else '❌'}")

if __name__ == "__main__":
    # Run unit tests first
    test_schema_org_parsing()
    test_meta_tag_detection()
    test_css_class_detection()

    # Then run real-world tests
    print("\n\n")
    passed, failed, skipped = run_tests()

    # Exit code based on results
    exit(0 if failed == 0 else 1)
