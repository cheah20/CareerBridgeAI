from app.services.layout import Box, order_boxes, to_text


def column(x: float, lines: list[str], top: float = 100, step: float = 14) -> list[Box]:
    return [Box(x, top + i * step, x + 150, top + i * step + 12, t) for i, t in enumerate(lines)]


def test_three_columns_are_read_one_after_another():
    boxes = (column(20, ["Machine Learning Engineer", "January 2018 - Present", "Design ML systems"])
             + column(200, ["Machine Learning Developer", "July 2016 - January 2018", "Built models"])
             + column(380, ["Education", "Bachelor of Science", "2012 - 2016"]))
    text = to_text(order_boxes(boxes))

    assert text.index("January 2018 - Present") < text.index("Machine Learning Developer")
    assert text.index("July 2016 - January 2018") < text.index("Education")


def test_header_above_columns_comes_first():
    boxes = [Box(20, 10, 300, 30, "Elena Covenant")] + column(20, ["Skills", "Python"], top=80) + column(220, ["Languages", "English"], top=80)
    lines = to_text(order_boxes(boxes)).split("\n")

    assert lines[0] == "Elena Covenant"
    assert lines.index("Python") < lines.index("Languages")


def test_tightly_spaced_lines_stay_in_order():
    # OCR boxes of neighbouring lines overlap a little when the line spacing is tight.
    boxes = [Box(20, 100 + i * 10, 300 - i * 30, 112 + i * 10, f"line {i}") for i in range(5)]

    assert to_text(order_boxes(boxes)).split("\n") == [f"line {i}" for i in range(5)]


def test_title_and_date_on_one_row_stay_together():
    boxes = [Box(20, 100, 200, 112, "Senior Clerk"), Box(400, 100, 480, 112, "Mar 2013 - Present"),
             Box(20, 116, 300, 128, "Malaysia Institute of Management")]

    assert to_text(order_boxes(boxes)).split("\n")[:2] == ["Senior Clerk", "Mar 2013 - Present"]
