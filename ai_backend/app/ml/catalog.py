"""Where datasets and models live, plus friendly names for career categories."""

from pathlib import Path

from app.core.config import BACKEND_DIR

DATA_DIR = BACKEND_DIR / "data"
MODELS_DIR = BACKEND_DIR / "models"
REGISTRY_FILE = MODELS_DIR / "registry.json"

KAGGLE_V1 = {
    "name": "kaggle-resume-dataset-v1",
    "csv": DATA_DIR / "raw" / "kaggle-resume-dataset-v1" / "Resume" / "Resume.csv",
    "licence": "CC0: Public Domain",
    "sha256_prefix": "b12c4ab34df707ad",
}

RESUME_ATLAS_V1 = {
    "name": "resume-atlas-v1",
    "parquet": DATA_DIR / "raw" / "resume-atlas-v1" / "train.parquet",
    "licence": "MIT",
    "sha256_prefix": "d8061929a1905ad0",
}

# Kaggle categories -> ResumeAtlas names, so both datasets share one label set.
# ENGINEERING is left out: it overlaps ResumeAtlas' specific engineering classes.
KAGGLE_TO_ATLAS = {
    "ACCOUNTANT": "Accountant", "ADVOCATE": "Advocate", "AGRICULTURE": "Agriculture", "APPAREL": "Apparel",
    "ARTS": "Arts", "AUTOMOBILE": "Automobile", "AVIATION": "Aviation", "BANKING": "Banking", "BPO": "BPO",
    "BUSINESS-DEVELOPMENT": "Business Development", "CHEF": "Food and Beverages",
    "CONSTRUCTION": "Building and Construction", "CONSULTANT": "Consultant", "DESIGNER": "Designing",
    "DIGITAL-MEDIA": "Digital Media", "FINANCE": "Finance", "FITNESS": "Health and Fitness",
    "HEALTHCARE": "Healthcare", "HR": "Human Resources", "INFORMATION-TECHNOLOGY": "Information Technology",
    "PUBLIC-RELATIONS": "Public Relations", "SALES": "Sales", "TEACHER": "Education",
}

# Dataset labels -> names shown to users.
CAREER_LABELS = {
    "ACCOUNTANT": "Accountant",
    "ADVOCATE": "Advocate / Legal",
    "AGRICULTURE": "Agriculture",
    "APPAREL": "Apparel & Fashion",
    "ARTS": "Arts",
    "AUTOMOBILE": "Automotive",
    "AVIATION": "Aviation",
    "BANKING": "Banking",
    "BPO": "Business Process Outsourcing",
    "BUSINESS-DEVELOPMENT": "Business Development",
    "CHEF": "Chef / Culinary",
    "CONSTRUCTION": "Construction",
    "CONSULTANT": "Consulting",
    "DESIGNER": "Design",
    "DIGITAL-MEDIA": "Digital Media",
    "ENGINEERING": "Engineering",
    "FINANCE": "Finance",
    "FITNESS": "Fitness",
    "HEALTHCARE": "Healthcare",
    "HR": "Human Resources",
    "INFORMATION-TECHNOLOGY": "Information Technology",
    "PUBLIC-RELATIONS": "Public Relations",
    "SALES": "Sales",
    "TEACHER": "Teaching / Education",
}


CAREER_LABELS.update({  # ResumeAtlas labels that need a clearer name
    "Advocate": "Advocate / Legal", "Apparel": "Apparel & Fashion", "Automobile": "Automotive",
    "BPO": "Business Process Outsourcing", "Designing": "Design", "Food and Beverages": "Chef / Food & Beverage",
    "DotNet Developer": ".NET Developer", "PMO": "Project Management Office", "Web Designing": "Web Design",
    "Testing": "Software Testing / QA", "Database": "Database Administration",
})


# Model labels (ResumeAtlas names) -> CareerBridge fields (app/catalog/seed.py), for field-level results.
LABEL_TO_FIELD = {
    "Java Developer": "Information & Communication Technology", "Python Developer": "Information & Communication Technology",
    "DotNet Developer": "Information & Communication Technology", "React Developer": "Information & Communication Technology",
    "SAP Developer": "Information & Communication Technology", "Web Designing": "Information & Communication Technology",
    "Testing": "Information & Communication Technology", "DevOps": "Information & Communication Technology",
    "Network Security Engineer": "Information & Communication Technology", "Information Technology": "Information & Communication Technology",
    "Blockchain": "Information & Communication Technology", "Database": "Information & Communication Technology",
    "SQL Developer": "Information & Communication Technology",
    "Data Science": "Data & Artificial Intelligence", "ETL Developer": "Data & Artificial Intelligence",
    "Civil Engineer": "Engineering", "Mechanical Engineer": "Engineering", "Electrical Engineering": "Engineering",
    "Automobile": "Engineering",
    "Accountant": "Accounting & Finance", "Finance": "Accounting & Finance",
    "Banking": "Banking & Insurance",
    "Business Analyst": "Business & Management", "Management": "Business & Management", "Operations Manager": "Business & Management",
    "Consultant": "Business & Management", "PMO": "Business & Management", "Business Development": "Business & Management",
    "Sales": "Sales & Marketing",
    "Human Resources": "Human Resources",
    "Designing": "Design, Media & Communications", "Digital Media": "Design, Media & Communications",
    "Arts": "Design, Media & Communications", "Apparel": "Design, Media & Communications",
    "Public Relations": "Design, Media & Communications",
    "Architecture": "Architecture & Construction", "Building and Construction": "Architecture & Construction",
    "Health and Fitness": "Healthcare & Wellness", "Healthcare": "Healthcare & Wellness",
    "Education": "Education & Training",
    "Advocate": "Legal",
    "Food and Beverages": "Hospitality, Food & Tourism",
    "Aviation": "Logistics, Transport & Aviation",
    "Agriculture": "Science & Agriculture",
    "BPO": "Administration & Customer Service",
}


def friendly(label: str) -> str:
    if label in CAREER_LABELS:
        return CAREER_LABELS[label]
    # Kaggle labels are UPPER-CASE; ResumeAtlas labels are already readable ("SQL Developer").
    return label.replace("-", " ").title() if label.isupper() else label


def model_dir(version: str) -> Path:
    return MODELS_DIR / version
