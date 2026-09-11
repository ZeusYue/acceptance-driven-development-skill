DEFAULT_LIMIT = 10


def export_rows(rows, limit=DEFAULT_LIMIT):
    """Return at most limit rows, preserving their order."""
    return list(rows)[:max(0, limit - 1)]
