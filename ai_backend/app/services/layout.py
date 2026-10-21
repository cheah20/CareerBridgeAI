"""Reading order for multi-column resumes (recursive XY-cut)."""

from dataclasses import dataclass
from statistics import median


@dataclass(frozen=True)
class Box:
    x0: float
    y0: float
    x1: float
    y1: float
    text: str


def _gaps(intervals: list[tuple[float, float]]) -> list[tuple[float, float]]:
    """Empty stretches between merged intervals, as (start, end)."""
    merged: list[list[float]] = []
    for a, b in sorted(intervals):
        if merged and a <= merged[-1][1]:
            merged[-1][1] = max(merged[-1][1], b)
        else:
            merged.append([a, b])
    return [(merged[i][1], merged[i + 1][0]) for i in range(len(merged) - 1)]


def _split(boxes: list[Box], axis: str, cuts: list[float]) -> list[list[Box]]:
    groups: list[list[Box]] = [[] for _ in range(len(cuts) + 1)]
    for b in boxes:
        centre = (b.y0 + b.y1) / 2 if axis == "y" else (b.x0 + b.x1) / 2
        groups[sum(centre > c for c in cuts)].append(b)
    return [g for g in groups if g]


def _rows(boxes: list[Box], h: float) -> list[Box]:
    """Top to bottom by line centre; boxes on the same row left to right."""
    rows: list[list[Box]] = []
    for b in sorted(boxes, key=lambda b: (b.y0 + b.y1) / 2):
        centre = (b.y0 + b.y1) / 2
        if rows and abs(centre - (rows[-1][0].y0 + rows[-1][0].y1) / 2) < 0.5 * h:
            rows[-1].append(b)
        else:
            rows.append([b])
    return [b for row in rows for b in sorted(row, key=lambda b: b.x0)]


def _row_layout(groups: list[list[Box]], h: float) -> bool:
    """True when the gap splits items on the same rows, not real columns."""
    if len(groups) != 2:
        return False
    small, big = sorted(groups, key=len)
    if len(small) > 0.7 * len(big):  # real columns hold similar amounts of text
        return False
    centre = lambda b: (b.y0 + b.y1) / 2  # noqa: E731
    return all(any(abs(centre(a) - centre(b)) < 0.5 * h for b in big) for a in small)


def order_boxes(boxes: list[Box], line_height: float | None = None) -> list[list[Box]]:
    """Boxes in reading order, grouped into blocks (blocks become paragraphs in Markdown)."""
    if len(boxes) <= 1:
        return [boxes] if boxes else []
    h = line_height or median(b.y1 - b.y0 for b in boxes) or 1.0
    y_gaps = _gaps([(b.y0, b.y1) for b in boxes])
    x_gaps = _gaps([(b.x0, b.x1) for b in boxes])
    big_y = [g for g in y_gaps if g[1] - g[0] >= 1.5 * h]       # a break between sections
    gutters = [g for g in x_gaps if g[1] - g[0] >= 0.5 * h]     # a gap between columns (empty from top to bottom)
    small_y = [g for g in y_gaps if g[1] - g[0] >= 0.2 * h]     # the gap between two lines

    if gutters and _row_layout(_split(boxes, "x", [(a + b) / 2 for a, b in gutters]), h):
        gutters = []  # e.g. job title on the left, dates on the right of the same rows: read row by row

    if big_y:
        axis, gaps = "y", big_y
    elif gutters:
        axis, gaps = "x", gutters
    elif small_y:
        axis, gaps = "y", small_y
    else:  # lines touch each other (tight spacing): group them into rows by their centres
        return [_rows(boxes, h)]

    groups = _split(boxes, axis, [(a + b) / 2 for a, b in gaps])
    if len(groups) < 2:  # the cut did not separate anything
        return [_rows(boxes, h)]
    if gaps is small_y:
        # Lines of one paragraph: keep them together in one block, top to bottom.
        return [[box for g in groups for block in order_boxes(g, h) for box in block]]
    # Sections or columns: each becomes its own block(s), read one after another.
    return [block for g in groups for block in order_boxes(g, h)]


def to_text(blocks: list[list[Box]]) -> str:
    """Lines of each block, blocks separated by a blank line."""
    return "\n\n".join("\n".join(b.text for b in block) for block in blocks)
