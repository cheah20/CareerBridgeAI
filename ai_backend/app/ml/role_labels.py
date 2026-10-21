"""CareerBridge catalogue roles -> the 45 dataset categories the classifier is trained on."""

import argparse
import json

from app.ml.catalog import DATA_DIR

IT, DS = "Information Technology", "Data Science"
ROLE_TO_LABEL: dict[str, str | None] = {
    # Information & Communication Technology
    "software-engineer": IT, "web-developer": "Web Designing", "front-end-developer": "React Developer",
    "back-end-developer": IT, "full-stack-developer": IT, "mobile-app-developer": IT, "game-developer": IT,
    "software-qa-engineer": "Testing", "devops-engineer": "DevOps", "cloud-engineer": "DevOps",
    "site-reliability-engineer": "DevOps", "system-administrator": IT, "network-engineer": "Network Security Engineer",
    "cyber-security-analyst": "Network Security Engineer", "penetration-tester": "Network Security Engineer",
    "it-support-executive": IT, "it-executive": IT, "database-administrator": "Database", "solution-architect": IT,
    "ui-ux-designer": "Web Designing", "product-manager": None, "blockchain-developer": "Blockchain",
    "sap-consultant": "SAP Developer", "embedded-software-engineer": None, "iot-engineer": None,
    # Data & Artificial Intelligence
    "data-analyst": DS, "business-intelligence-bi-analyst": DS, "data-scientist": DS, "data-engineer": "ETL Developer",
    "machine-learning-engineer": DS, "ai-engineer": DS, "mlops-engineer": DS, "generative-ai-engineer": DS,
    "computer-vision-engineer": DS, "nlp-engineer": DS, "data-architect": "Database", "statistician": DS,
    # Engineering
    "civil-engineer": "Civil Engineer", "site-engineer": "Civil Engineer", "structural-engineer": "Civil Engineer",
    "mechanical-engineer": "Mechanical Engineer", "electrical-engineer": "Electrical Engineering",
    "electronics-engineer": "Electrical Engineering", "chemical-engineer": None, "process-engineer": None,
    "product-test-engineer": None, "automation-engineer": "Electrical Engineering", "quality-engineer": None,
    "industrial-engineer": None, "facilities-engineer": "Mechanical Engineer", "maintenance-engineer": "Mechanical Engineer",
    "automotive-engineer": "Automobile", "aerospace-engineer": "Aviation", "oil-and-gas-engineer": None,
    "renewable-energy-engineer": "Electrical Engineering", "environmental-engineer": None, "safety-and-health-officer": None,
    # Accounting & Finance
    "account-executive": "Accountant", "accountant": "Accountant", "audit-associate": "Accountant",
    "tax-associate": "Accountant", "financial-analyst": "Finance", "finance-manager": "Finance",
    "credit-executive": "Banking", "risk-analyst": "Finance", "investment-analyst": "Finance",
    "actuarial-executive": "Finance", "fintech-specialist": "Finance",
    # Banking & Insurance
    "relationship-manager": "Banking", "personal-banker": "Banking", "loan-officer": "Banking",
    "compliance-officer": None, "underwriter": "Banking", "claims-executive": None,
    "insurance-agent-financial-planner": "Banking",
    # Business & Management
    "business-analyst": "Business Analyst", "project-manager": "PMO", "project-coordinator": "PMO",
    "operations-executive": "Operations Manager", "management-consultant": "Consultant",
    "business-development-executive": "Business Development", "supply-chain-executive": None,
    "purchasing-executive": None, "esg-sustainability-executive": None,
    # Sales & Marketing
    "sales-executive": "Sales", "key-account-manager": "Sales", "marketing-executive": "Sales",
    "digital-marketing-executive": "Digital Media", "seo-specialist": "Digital Media",
    "social-media-executive": "Digital Media", "content-writer": "Digital Media", "brand-executive": "Sales",
    "market-research-executive": None, "e-commerce-executive": "Digital Media", "property-negotiator": "Sales",
    # Human Resources
    "hr-executive": "Human Resources", "talent-acquisition-executive": "Human Resources",
    "hr-business-partner": "Human Resources", "payroll-executive": "Human Resources",
    "learning-and-development-executive": "Human Resources",
    # Design, Media & Communications
    "graphic-designer": "Designing", "multimedia-designer": "Designing", "video-editor": "Digital Media",
    "animator": "Arts", "photographer": "Arts", "interior-designer": "Designing", "fashion-designer": "Apparel",
    "pr-executive": "Public Relations", "journalist": "Digital Media", "illustrator": "Arts",
    # Architecture & Construction
    "architect": "Architecture", "quantity-surveyor": "Building and Construction",
    "construction-project-manager": "Building and Construction", "site-supervisor": "Building and Construction",
    "draughtsman": "Architecture", "mande-engineer": "Building and Construction",
    "land-surveyor": "Building and Construction",
    # Healthcare & Wellness
    "medical-officer": "Healthcare", "staff-nurse": "Healthcare", "pharmacist": "Healthcare",
    "medical-laboratory-technologist": "Healthcare", "physiotherapist": "Healthcare", "dietitian": "Health and Fitness",
    "radiographer": "Healthcare", "clinic-assistant": "Healthcare", "personal-trainer": "Health and Fitness",
    # Education & Training
    "teacher": "Education", "lecturer": "Education", "tuition-teacher": "Education",
    "instructional-designer": "Education", "preschool-teacher": "Education",
    # Legal
    "advocate-and-solicitor": "Advocate", "legal-executive": "Advocate", "paralegal": "Advocate",
    "company-secretary": None,
    # Hospitality, Food & Tourism
    "chef": "Food and Beverages", "outlet-manager": "Food and Beverages", "front-office-executive": None,
    "event-executive": None, "travel-consultant": None, "food-technologist": None,
    # Logistics, Transport & Aviation
    "logistics-executive": None, "warehouse-supervisor": None, "inventory-executive": None,
    "shipping-executive": None, "pilot": "Aviation", "aircraft-maintenance-engineer": "Aviation", "cabin-crew": "Aviation",
    # Science & Agriculture
    "plantation-executive": "Agriculture", "chemist": None, "biotechnologist": None,
    "environmental-executive": None, "lab-analyst": None,
    # Administration & Customer Service
    "admin-executive": None, "office-manager": "Management", "customer-service-executive": "BPO",
    "call-centre-agent": "BPO", "personal-assistant": None,
}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--batch", required=True)
    args = parser.parse_args()
    folder = DATA_DIR / "synthetic" / args.batch
    rows = [json.loads(line) for line in (folder / "rendered.jsonl").read_text(encoding="utf-8").splitlines() if line]
    missing = sorted({r["profile"]["role_id"] for r in rows} - set(ROLE_TO_LABEL))
    if missing:
        raise SystemExit(f"Roles without a mapping entry: {missing}")
    kept = [{"label": ROLE_TO_LABEL[r["profile"]["role_id"]], "text": r["extracted_text"],
             "role_id": r["profile"]["role_id"], "file": r["file"]} for r in rows if ROLE_TO_LABEL[r["profile"]["role_id"]]]
    (folder / "train_45.jsonl").write_text("\n".join(json.dumps(k, ensure_ascii=False) for k in kept) + "\n", encoding="utf-8")
    skipped = sorted(r["profile"]["role_id"] for r in rows if not ROLE_TO_LABEL[r["profile"]["role_id"]])
    print(f"{len(kept)} of {len(rows)} resumes map to a dataset category; {len(skipped)} skipped:")
    print("  " + ", ".join(skipped))
    print(f"categories covered: {len({k['label'] for k in kept})} of 45")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
