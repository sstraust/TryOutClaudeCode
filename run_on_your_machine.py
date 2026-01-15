#!/usr/bin/env python3
"""
Run this script on YOUR machine (with internet access) to test against real sites.

Usage:
    pip install requests beautifulsoup4
    python3 run_on_your_machine.py
"""

import requests
from bs4 import BeautifulSoup
from paywall_detection import parse_paywall_status

# Real-world test cases with actual URLs
REAL_WORLD_TESTS = [
    # Paywalled sites
    {
        "url": "https://www.nytimes.com/2024/01/15/technology/openai-chatgpt.html",
        "name": "New York Times article",
        "expected": True,
        "notes": "NYT uses Schema.org isAccessibleForFree"
    },
    {
        "url": "https://www.wsj.com/articles/something",
        "name": "Wall Street Journal article",
        "expected": True,
        "notes": "WSJ uses metered paywall with meta tags"
    },
    {
        "url": "https://www.ft.com/content/something",
        "name": "Financial Times article",
        "expected": True,
        "notes": "FT uses premium content markers"
    },
    {
        "url": "https://www.economist.com/something",
        "name": "The Economist article",
        "expected": True,
        "notes": "Economist has subscription paywall"
    },

    # Free sites
    {
        "url": "https://www.bbc.com/news/world",
        "name": "BBC News",
        "expected": False,
        "notes": "BBC is publicly funded, no paywall"
    },
    {
        "url": "https://www.reuters.com/world/",
        "name": "Reuters",
        "expected": False,
        "notes": "Reuters is generally free"
    },
    {
        "url": "https://www.theguardian.com/international",
        "name": "The Guardian",
        "expected": False,
        "notes": "Guardian is free with donation prompts (not paywalls)"
    },
    {
        "url": "https://www.npr.org/",
        "name": "NPR",
        "expected": False,
        "notes": "NPR is public radio, free content"
    },
]

def fetch_page(url):
    """Fetch a webpage"""
    headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        'Accept-Language': 'en-US,en;q=0.9',
    }

    try:
        response = requests.get(url, headers=headers, timeout=15)
        response.raise_for_status()
        return BeautifulSoup(response.text, 'html.parser')
    except Exception as e:
        print(f"    ❌ Error fetching: {e}")
        return None

def test_real_world():
    """Test against real websites"""
    print("=" * 80)
    print("REAL-WORLD PAYWALL DETECTION TEST")
    print("=" * 80)
    print("\nNote: Some URLs may have changed. The test will show the detection results.")
    print()

    results = {
        "passed": 0,
        "failed": 0,
        "error": 0,
        "details": []
    }

    for i, test in enumerate(REAL_WORLD_TESTS, 1):
        print(f"\n{i}. {test['name']}")
        print(f"   URL: {test['url']}")
        print(f"   Expected: {'PAYWALLED' if test['expected'] else 'FREE'}")
        print(f"   Notes: {test['notes']}")

        soup = fetch_page(test['url'])

        if not soup:
            results['error'] += 1
            results['details'].append({
                "name": test['name'],
                "status": "ERROR",
                "reason": "Could not fetch page"
            })
            continue

        # Run detection
        page_data = {"soup": soup}
        result = parse_paywall_status({}, page_data, None, None)

        detected = result.get("is_paywalled", False)
        method = result.get("detection_method", "none")

        print(f"   Result: {'PAYWALLED' if detected else 'FREE'} (method: {method})")

        # Check if correct
        if detected == test['expected']:
            print(f"   ✅ PASS")
            results['passed'] += 1
            results['details'].append({
                "name": test['name'],
                "status": "PASS",
                "method": method
            })
        else:
            print(f"   ❌ FAIL - Expected {test['expected']}, got {detected}")
            results['failed'] += 1
            results['details'].append({
                "name": test['name'],
                "status": "FAIL",
                "expected": test['expected'],
                "detected": detected,
                "method": method
            })

            # Debug info
            print(f"   Debug: Showing first 500 chars of page:")
            print(f"   {str(soup)[:500]}")

    # Print summary
    print("\n" + "=" * 80)
    print("SUMMARY")
    print("=" * 80)

    total = len(REAL_WORLD_TESTS)
    print(f"\nTotal tests: {total}")
    print(f"Passed: {results['passed']} ✅")
    print(f"Failed: {results['failed']} ❌")
    print(f"Errors: {results['error']} ⚠️")

    if results['passed'] > 0:
        accuracy = (results['passed'] / (results['passed'] + results['failed'])) * 100 if (results['passed'] + results['failed']) > 0 else 0
        print(f"\nAccuracy: {accuracy:.1f}%")

    print("\nDetailed results:")
    for detail in results['details']:
        status_icon = {"PASS": "✅", "FAIL": "❌", "ERROR": "⚠️"}[detail['status']]
        print(f"{status_icon} {detail['name']}: {detail['status']}")
        if detail['status'] == "PASS":
            print(f"   Detection method: {detail['method']}")
        elif detail['status'] == "FAIL":
            print(f"   Expected: {detail['expected']}, Got: {detail['detected']}")

    return results

def test_specific_url():
    """Test a specific URL provided by user"""
    print("\n" + "=" * 80)
    print("TEST YOUR OWN URL")
    print("=" * 80)

    url = input("\nEnter a URL to test (or press Enter to skip): ").strip()

    if not url:
        print("Skipped.")
        return

    print(f"\nTesting: {url}")
    soup = fetch_page(url)

    if not soup:
        print("Could not fetch page.")
        return

    page_data = {"soup": soup}
    result = parse_paywall_status({}, page_data, None, None)

    detected = result.get("is_paywalled", False)
    method = result.get("detection_method", "none")

    print(f"\nResult: {'PAYWALLED' if detected else 'FREE'}")
    print(f"Detection method: {method}")

    # Show some debug info
    print("\nDebug information:")
    print(f"- Found {len(soup.find_all('script', type='application/ld+json'))} JSON-LD scripts")
    print(f"- Found {len(soup.find_all('meta'))} meta tags")
    print(f"- Page title: {soup.title.string if soup.title else 'N/A'}")

if __name__ == "__main__":
    print("Paywall Detection - Real World Test")
    print("=" * 80)
    print("\nThis script will test the paywall detection code against real websites.")
    print("Make sure you have internet access and the required packages installed:")
    print("  pip install requests beautifulsoup4")
    print()

    input("Press Enter to start testing...")

    # Run tests
    results = test_real_world()

    # Offer to test custom URL
    test_specific_url()

    print("\n" + "=" * 80)
    print("Testing complete!")
    print("=" * 80)
