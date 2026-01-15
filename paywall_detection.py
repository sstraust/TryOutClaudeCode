import json

def check_schema_org_paywall(soup):
    """Check JSON-LD for isAccessibleForFree: false"""
    try:
        scripts = soup.find_all('script', type='application/ld+json')
        for script in scripts:
            if not script.string:
                continue
            data = json.loads(script.string)
            to_check = data if isinstance(data, list) else [data]

            while to_check:
                item = to_check.pop(0)
                if not isinstance(item, dict):
                    continue
                # Handle @graph structure
                graph = item.get('@graph')
                if graph:
                    if isinstance(graph, list):
                        to_check.extend(graph)
                    elif isinstance(graph, dict):
                        to_check.append(graph)
                    continue
                accessible = item.get('isAccessibleForFree')
                if accessible in [False, 'False', 'false']:
                    return True
    except Exception:
        pass
    return False

def check_meta_paywall(soup):
    """Check meta tags for paywall indicators"""
    paywall_keywords = ['paywall', 'premium', 'locked', 'metered']
    try:
        for meta in soup.find_all('meta'):
            content = meta.get('content', '') or ''
            name = meta.get('name', '') or ''
            prop = meta.get('property', '') or ''
            combined = f"{content} {name} {prop}".lower()
            if any(kw in combined for kw in paywall_keywords):
                return True
    except Exception:
        pass
    return False

def check_paywall_elements(soup):
    """Check for common paywall CSS classes/IDs"""
    paywall_patterns = ['paywall', 'subscriber-only', 'premium-content', 'locked-content', 'metered']
    try:
        for el in soup.find_all(class_=True):
            classes = el.get('class', [])
            if isinstance(classes, list):
                classes = ' '.join(classes)
            if any(p in classes.lower() for p in paywall_patterns):
                return True
        for el in soup.find_all(id=True):
            el_id = el.get('id')
            if el_id and any(p in el_id.lower() for p in paywall_patterns):
                return True
    except Exception:
        pass
    return False

def check_feed_paywall(feed_article_obj):
    """Check feedparser entry for paywall indicators"""
    if not feed_article_obj:
        return False
    try:
        # Check access field
        access = getattr(feed_article_obj, 'access', None)
        if access and 'registration' in str(access).lower():
            return True

        # Check rights field
        rights = getattr(feed_article_obj, 'rights', None)
        if rights and any(kw in str(rights).lower() for kw in ['subscriber', 'member', 'premium']):
            return True

        # Check for payment links in Atom feeds
        links = getattr(feed_article_obj, 'links', []) or []
        for link in links:
            rel = link.get('rel') if isinstance(link, dict) else getattr(link, 'rel', None)
            if rel == 'payment':
                return True
    except Exception:
        pass
    return False

def check_content_availability(soup, min_content_length=400):
    """
    Check if article content is actually present on the page.

    Detects "soft" paywalls where content is missing or truncated.
    Returns True if content appears to be missing/limited (likely paywalled).

    Args:
        soup: BeautifulSoup object
        min_content_length: Minimum character count for article content (default 400)
    """
    try:
        # Common article content selectors
        article_selectors = [
            'article',
            '[class*="article-body"]',
            '[class*="article-content"]',
            '[class*="story-body"]',
            '[class*="entry-content"]',
            '[id*="article-body"]',
            '[id*="article-content"]',
            '[class*="post-content"]',
            'main article',
            '.article p',
            'article p'
        ]

        max_text_length = 0
        found_content = False

        # Try each selector
        for selector in article_selectors:
            try:
                elements = soup.select(selector)
                for element in elements:
                    # Clone the element to avoid modifying the original
                    element_copy = BeautifulSoup(str(element), 'html.parser')

                    # Get text content, excluding script/style tags
                    for script in element_copy.find_all(['script', 'style']):
                        script.decompose()

                    text = element_copy.get_text(separator=' ', strip=True)
                    text_length = len(text)

                    if text_length > max_text_length:
                        max_text_length = text_length
                        found_content = True
            except Exception:
                continue

        # If no article content found, it might be missing
        # But only flag if the page has subscription-related language
        if not found_content:
            full_text = soup.get_text().lower()

            # Check for negative subscription language first (indicating FREE)
            negative_phrases = ['no subscription', 'free to read', 'free article']
            if any(phrase in full_text for phrase in negative_phrases):
                return False

            # Check for positive subscription hints
            subscription_hints = [
                'subscribe to', 'subscription required', 'sign in to read',
                'login to read', 'member only', 'premium content'
            ]
            # If page has subscription language but no article content, likely paywalled
            if any(hint in full_text for hint in subscription_hints):
                return True
            # Otherwise fail open (assume content is available)
            return False

        # Get full page text for truncation phrase checks
        full_text = soup.get_text().lower()

        # Look for strong truncation indicators (subscription prompts)
        strong_indicators = [
            'subscribe to read',
            'sign in to read',
            'login to read',
            'subscription required',
            'this article is for subscribers',
            'become a member to',
            'subscribe for full access'
        ]

        # If we have strong indicators AND short content, it's likely paywalled
        has_strong_indicator = any(phrase in full_text for phrase in strong_indicators)

        if has_strong_indicator and max_text_length < 600:
            return True

        # Content is very short AND has weaker subscription hints
        if max_text_length < min_content_length:
            weak_indicators = [
                'continue reading',
                'subscribe to',
                'become a member'
            ]
            has_weak_indicator = any(phrase in full_text for phrase in weak_indicators)

            # Only flag as paywalled if we have both short content AND subscription language
            if has_weak_indicator:
                return True

        # Content appears to be available
        return False

    except Exception:
        # If check fails, assume content is available (fail open)
        return False

def parse_paywall_status(basic_info, page_data, existing_article, feed_article_obj):
    """
    Detect if article is paywalled.
    Returns dict with paywall info or empty dict.
    """
    # Check existing article first
    if existing_article:
        try:
            is_paywalled = existing_article.get('is_paywalled') if isinstance(existing_article, dict) else getattr(existing_article, 'is_paywalled', None)
            if is_paywalled:
                return {"is_paywalled": True, "detection_method": "existing_article"}
        except Exception:
            pass

    # Check feedparser entry
    if check_feed_paywall(feed_article_obj):
        return {"is_paywalled": True, "detection_method": "feed"}

    # Check page content
    if page_data and page_data.get("soup"):
        soup = page_data["soup"]

        if check_schema_org_paywall(soup):
            return {"is_paywalled": True, "detection_method": "schema_org"}

        if check_meta_paywall(soup):
            return {"is_paywalled": True, "detection_method": "meta_tag"}

        if check_paywall_elements(soup):
            return {"is_paywalled": True, "detection_method": "css_class"}

        # Check if article content is actually available
        if check_content_availability(soup):
            return {"is_paywalled": True, "detection_method": "content_unavailable"}

        return {"is_paywalled": False}

    return {}
