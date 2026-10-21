from app.services.resume_markdown import is_heading, to_markdown, without_personal_details

RESUME = """MICHELLE YI
Professional Clerk
+60 12 3456 7890 • mich.yi@email.com • linkedin.com/in/michelle
No. 12, Jalan Merdeka, 75000 Melaka

EXECUTIVE SUMMARY
• Professional Clerk with 10 years of experience

PROFESSIONAL EXPERIENCE
PERSONAL ASSISTANT
Feb 2007 - Aug 2010
• Supported the Sales Director

Personal Details
Date of Birth: 1 January 1990
Religion: Islam

REFERENCES
Dr. Tan, 012-111 2222
"""


def test_headings_and_bullets_become_markdown():
    md = to_markdown(RESUME)
    assert "## Executive Summary" in md and "## Professional Experience" in md
    assert "- Professional Clerk with 10 years of experience" in md


def test_sentences_and_job_titles_are_not_headings():
    assert not is_heading("Experienced machine learning")
    assert not is_heading("business objectives.")
    assert not is_heading("PERSONAL ASSISTANT")
    assert is_heading("WORK EXPERIENCE") and is_heading("Key Skills")


def test_personal_details_are_removed_but_work_stays():
    clean = without_personal_details(to_markdown(RESUME))
    for private in ("MICHELLE YI", "3456 7890", "mich.yi@email.com", "linkedin", "Jalan Merdeka", "1990", "Islam", "Dr. Tan"):
        assert private not in clean
    assert "PERSONAL ASSISTANT" in clean and "Feb 2007 - Aug 2010" in clean
    assert "Professional Clerk" in clean


def test_names_with_qualifications_and_year_ranges():
    clean = without_personal_details(to_markdown("JOHN SIM, CA\nSenior Accountant\n\nEDUCATION\nBachelor of Accounting\n2012 - 2016"))
    assert "JOHN SIM" not in clean
    assert "2012 - 2016" in clean  # a year range is not a phone number


def test_ocr_slips_are_cleaned():
    md = to_markdown("。SKILLS。\nAl / ML Technology\nNatural Language Processing\n(NLP)\no\nAl-Azhar University")
    assert "## Skills" in md
    assert "AI / ML Technology" in md and "Natural Language Processing (NLP)" in md
    assert "\no\n" not in md and "Al-Azhar" in md  # a name starting with "Al-" is left alone


def test_details_section_and_home_city_are_removed():
    text = "JAKE WYATT\nAthens, GA\n\n。DETAILS。\nAthens, GA\n\nPROFILE\nAI engineer.\n\nEXPERIENCE\nEngineer at Siemens, Alpharetta, GA"
    clean = without_personal_details(to_markdown(text))
    assert "Athens" not in clean
    assert "Siemens, Alpharetta, GA" in clean  # where someone worked is not personal


def test_invisible_characters_do_not_hide_the_name():
    clean = without_personal_details(to_markdown("Tay Jun Cheng​\nProduct Engineer\n​\nㅡ​\n\nSKILLS\nHTML"))
    assert "Tay" not in clean and "​" not in clean and "ㅡ" not in clean
    assert "Product Engineer" in clean and "HTML" in clean
