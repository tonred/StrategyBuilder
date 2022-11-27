PERCENT_DENOMINATOR = 100_000


def to_percent(percent: float) -> int:
    return int(percent * PERCENT_DENOMINATOR)


def to_seconds(days: float) -> int:
    return int(60 * 60 * 24 * days)
