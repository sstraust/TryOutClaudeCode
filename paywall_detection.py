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

        return {"is_paywalled": False}

    return {}
