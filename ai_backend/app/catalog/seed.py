"""Seed list of fields and job titles a Job Seeker can choose from.

Titles use the names common in Malaysian and Singaporean job ads (JobStreet,
MyCareersFuture). International names are kept in `aka` so each role can be
matched in O*NET 31.0, ESCO v1.2.1 and the job-postings datasets.

Other sources considered: ResumeAtlas categories, MyCOL 2024/2025 (Malaysia
critical occupations), LinkedIn Jobs on the Rise 2026 and the WEF Future of
Jobs Report 2025 (emerging roles).

`emerging=True` marks roles that are new or fast-growing in 2025–2026.
`onet` / `esco` are manual matches, verified to exist in those databases,
used when automatic matching picked the wrong occupation.
"""

from dataclasses import dataclass, field


@dataclass(frozen=True)
class RoleSeed:
    title: str
    aka: tuple[str, ...] = ()
    emerging: bool = False
    onet: tuple[str, ...] = ()  # manual O*NET-SOC code(s) when automatic matching is wrong
    esco: str = ""              # manual ESCO preferred label when automatic matching is wrong
    ads: tuple[str, ...] = ()   # names used to find job ads, when the title means something else in US ads


@dataclass(frozen=True)
class FieldSeed:
    name: str
    roles: tuple[RoleSeed, ...] = field(default_factory=tuple)


def R(title: str, *aka: str, emerging: bool = False, onet: tuple[str, ...] = (), esco: str = "",
      ads: tuple[str, ...] = ()) -> RoleSeed:
    return RoleSeed(title, tuple(aka), emerging, onet, esco, ads)


FIELDS: tuple[FieldSeed, ...] = (
    FieldSeed("Information & Communication Technology", (
        R("Software Engineer", "Software Developer", "Application Developer"),
        R("Web Developer"),
        R("Front-end Developer", "Frontend Developer", "React Developer", onet=("15-1254.00",), esco="web developer"),
        R("Back-end Developer", "Backend Developer", onet=("15-1252.00",), esco="software developer"),
        R("Full Stack Developer", "Full-stack Developer", onet=("15-1254.00", "15-1252.00"), esco="web developer"),
        R("Mobile App Developer", "Mobile Application Developer", "Android Developer", "iOS Developer", "Flutter Developer"),
        R("Game Developer", "Video Game Developer", esco="digital games developer"),
        R("Software QA Engineer", "QA Engineer", "Software Tester", "Quality Assurance Analyst", "Test Engineer"),
        R("DevOps Engineer", onet=("15-1244.00", "15-1252.00"), esco="cloud DevOps engineer"),
        R("Cloud Engineer", "Cloud Architect", onet=("15-1299.08",), esco="cloud engineer"),
        R("Site Reliability Engineer", "SRE", emerging=True, onet=("15-1244.00", "15-1252.00"), esco="cloud DevOps engineer"),
        R("System Administrator", "Systems Administrator", "System Engineer", onet=("15-1244.00",), esco="ICT system administrator"),
        R("Network Engineer", "Network Administrator", onet=("15-1241.00", "15-1244.00"), esco="ICT network engineer"),
        R("Cyber Security Analyst", "Cybersecurity Analyst", "Information Security Analyst", "Security Analyst", "SOC Analyst",
          onet=("15-1212.00",), esco="ICT security administrator"),
        R("Penetration Tester", "Ethical Hacker", onet=("15-1299.04",), esco="ethical hacker"),
        R("IT Support Executive", "IT Support Specialist", "Desktop Support", "Technical Support Engineer", "Help Desk Technician",
          onet=("15-1232.00",), esco="ICT help desk agent"),
        R("IT Executive", "IT Officer", "IT Administrator", onet=("15-1244.00", "15-1232.00"), esco="ICT system administrator"),
        R("Database Administrator", "SQL Developer"),
        R("Solution Architect", "Solutions Architect", "Software Architect", onet=("15-1299.08",), esco="ICT system architect"),
        R("UI/UX Designer", "UX Designer", "User Experience Designer", "UI Designer", onet=("15-1255.00",), esco="user interface designer"),
        R("Product Manager", "Technical Product Manager"),
        R("Blockchain Developer", emerging=True),
        R("SAP Consultant", "SAP Developer", onet=("15-1211.00",), esco="ICT business analyst"),
        R("Embedded Software Engineer", "Embedded Systems Engineer", "Firmware Engineer"),
        R("IoT Engineer", "Internet of Things Engineer", emerging=True, onet=("15-1299.08",)),
    )),
    FieldSeed("Data & Artificial Intelligence", (
        R("Data Analyst", onet=("15-2051.00", "15-2041.00"), esco="data analyst"),
        R("Business Intelligence (BI) Analyst", "Business Intelligence Analyst", "BI Analyst", "BI Developer"),
        R("Data Scientist", onet=("15-2051.00",), esco="data scientist"),
        R("Data Engineer", "ETL Developer", "Big Data Engineer"),
        R("Machine Learning Engineer", "ML Engineer", emerging=True, onet=("15-1221.00", "15-2051.00"), esco="artificial intelligence engineer"),
        R("AI Engineer", "Artificial Intelligence Engineer", emerging=True),
        R("MLOps Engineer", emerging=True, onet=("15-2051.00", "15-1252.00"), esco="cloud DevOps engineer"),
        R("Generative AI Engineer", "Prompt Engineer", "LLM Engineer", "GenAI Engineer", emerging=True,
          onet=("15-1221.00",), esco="artificial intelligence engineer"),
        R("Computer Vision Engineer", emerging=True, onet=("15-1221.00",), esco="computer vision engineer"),
        R("NLP Engineer", "Natural Language Processing Engineer", emerging=True, onet=("15-1221.00",), esco="artificial intelligence engineer"),
        R("Data Architect"),
        R("Statistician"),
    )),
    FieldSeed("Engineering", (
        R("Civil Engineer"),
        R("Site Engineer", "Civil Site Engineer", onet=("17-2051.00",), esco="civil engineer"),
        R("Structural Engineer", onet=("17-2051.00",), esco="civil engineer"),
        R("Mechanical Engineer"),
        R("Electrical Engineer"),
        R("Electronics Engineer", onet=("17-2072.00",), esco="electronics engineer"),
        R("Chemical Engineer"),
        R("Process Engineer", "Manufacturing Engineer", "Production Engineer", "Semiconductor Process Engineer"),
        R("Product Test Engineer", "Semiconductor Test Engineer", "Hardware Test Engineer", onet=("17-2072.00",), esco="electronics engineer"),
        R("Automation Engineer", "Mechatronics Engineer", "Robotics Engineer", "Controls Engineer"),
        R("Quality Engineer", "QA/QC Engineer", "Quality Control Engineer", "Quality Assurance Engineer"),
        R("Industrial Engineer"),
        R("Facilities Engineer", "Facility Engineer", onet=("17-2141.00",)),
        R("Maintenance Engineer"),
        R("Automotive Engineer"),
        R("Aerospace Engineer", onet=("17-2011.00",), esco="aerospace engineer"),
        R("Oil & Gas Engineer", "Petroleum Engineer", "Oil and Gas Engineer", "Drilling Engineer"),
        R("Renewable Energy Engineer", "Solar PV Engineer", "Solar Engineer", emerging=True),
        R("Environmental Engineer"),
        R("Safety & Health Officer", "Safety and Health Officer", "HSE Officer", "EHS Officer", "Safety Officer", "HSE Executive", onet=("19-5011.00",), esco="health and safety officer"),
    )),
    FieldSeed("Accounting & Finance", (
        R("Account Executive", "Accounts Executive", "Accounts Assistant", "Junior Accountant", onet=("13-2011.00",), esco="accountant",
          ads=("Accounts Executive", "Accounts Assistant", "Junior Accountant", "Staff Accountant", "Accounting Assistant")),
        R("Accountant", "Senior Accountant"),
        R("Audit Associate", "Auditor", "Internal Auditor", "External Auditor", "Audit Assistant"),
        R("Tax Associate", "Tax Consultant", "Tax Executive", "Tax Accountant"),
        R("Financial Analyst", "Finance Analyst"),
        R("Finance Manager"),
        R("Credit Executive", "Credit Analyst", "Credit Officer"),
        R("Risk Analyst", "Risk Executive", "Risk Manager"),
        R("Investment Analyst"),
        R("Actuarial Executive", "Actuary", "Actuarial Analyst"),
        R("Fintech Specialist", "Fintech Engineer", "Digital Payments Specialist", emerging=True),
    )),
    FieldSeed("Banking & Insurance", (
        R("Relationship Manager", onet=("13-2052.00",), esco="relationship banking manager"),
        R("Personal Banker", "Bank Officer", "Banking Officer", "Personal Financial Consultant"),
        R("Loan Officer", "Mortgage Officer", "Loan Executive"),
        R("Compliance Officer", "Compliance Executive", "Compliance Analyst"),
        R("Underwriter", "Insurance Underwriter"),
        R("Claims Executive", "Claims Adjuster", "Insurance Claims Executive"),
        R("Insurance Agent / Financial Planner", "Insurance Agent", "Financial Planner", "Unit Trust Consultant", "Financial Advisor"),
    )),
    FieldSeed("Business & Management", (
        R("Business Analyst"),
        R("Project Manager", onet=("13-1082.00",), esco="project manager"),
        R("Project Coordinator", "Project Management Officer", "PMO Analyst", "PMO Executive", onet=("13-1082.00",), esco="project support officer"),
        R("Operations Executive", "Operations Manager", "Operations Supervisor"),
        R("Management Consultant", "Business Consultant"),
        R("Business Development Executive", "Business Development Manager", onet=("11-2022.00",), esco="business developer"),
        R("Supply Chain Executive", "Supply Chain Analyst", "Supply Chain Planner"),
        R("Purchasing Executive", "Procurement Executive", "Buyer", "Purchaser", onet=("13-1023.00",), esco="purchaser"),
        R("ESG / Sustainability Executive", "Sustainability Specialist", "ESG Analyst", "Sustainability Executive", emerging=True),
    )),
    FieldSeed("Sales & Marketing", (
        R("Sales Executive", "Sales Representative", onet=("41-4012.00",), esco="commercial sales representative"),
        R("Key Account Manager", "Account Manager"),
        R("Marketing Executive", "Marketing Specialist", onet=("13-1161.00",), esco="marketing manager"),
        R("Digital Marketing Executive", "Digital Marketing Specialist"),
        R("SEO Specialist", "SEO Executive"),
        R("Social Media Executive", "Social Media Manager", "Social Media Specialist", onet=("27-3031.00",), esco="online community manager"),
        R("Content Writer", "Copywriter", "Content Creator"),
        R("Brand Executive", "Brand Manager"),
        R("Market Research Executive", "Market Research Analyst"),
        R("E-commerce Executive", "E-commerce Specialist", onet=("13-1161.00",), esco="online sales channel manager"),
        R("Property Negotiator", "Real Estate Negotiator", "Real Estate Agent", "Real Estate Sales Agent"),
    )),
    FieldSeed("Human Resources", (
        R("HR Executive", "Human Resources Executive", "Human Resources Specialist", "HR Generalist",
          onet=("13-1071.00",), esco="human resources officer"),
        R("Talent Acquisition Executive", "Talent Acquisition Specialist", "Recruiter", "Recruitment Executive"),
        R("HR Business Partner"),
        R("Payroll Executive", "Payroll Specialist", onet=("43-3051.00",), esco="payroll clerk"),
        R("Learning & Development Executive", "Learning and Development Specialist", "Training Executive", "Training Specialist",
          onet=("13-1151.00",), esco="corporate training manager"),
    )),
    FieldSeed("Design, Media & Communications", (
        R("Graphic Designer"),
        R("Multimedia Designer", "Motion Graphics Designer"),
        R("Video Editor"),
        R("Animator", "2D Animator", "3D Animator"),
        R("Photographer"),
        R("Interior Designer"),
        R("Fashion Designer", "Apparel Designer"),
        R("PR Executive", "Public Relations Executive", "Public Relations Specialist", "Corporate Communications Executive"),
        R("Journalist", "Reporter"),
        R("Illustrator", "Artist"),
    )),
    FieldSeed("Architecture & Construction", (
        R("Architect"),
        R("Quantity Surveyor"),
        R("Construction Project Manager", "Construction Manager"),
        R("Site Supervisor", "Construction Supervisor"),
        R("Draughtsman", "Drafter", "CAD Drafter"),
        R("M&E Engineer", "Building Services Engineer", "MEP Engineer"),
        R("Land Surveyor", "Surveyor"),
    )),
    FieldSeed("Healthcare & Wellness", (
        R("Medical Officer", "Doctor", "Physician", "General Practitioner", onet=("29-1215.00",), esco="general practitioner"),
        R("Staff Nurse", "Registered Nurse", "Nurse", onet=("29-1141.00",), esco="nurse responsible for general care"),
        R("Pharmacist", onet=("29-1051.00",), esco="pharmacist"),
        R("Medical Laboratory Technologist", "Medical Laboratory Scientist", "Medical Lab Technologist"),
        R("Physiotherapist", "Physical Therapist"),
        R("Dietitian", "Nutritionist"),
        R("Radiographer", "Radiologic Technologist"),
        R("Clinic Assistant", "Medical Assistant", "Healthcare Assistant"),
        R("Personal Trainer", "Fitness Trainer", "Fitness Coach"),
    )),
    FieldSeed("Education & Training", (
        R("Teacher", "School Teacher", onet=("25-2031.00",), esco="secondary school teacher"),
        R("Lecturer", "University Lecturer"),
        R("Tuition Teacher", "Tutor", "Private Tutor"),
        R("Instructional Designer"),
        R("Preschool Teacher", "Kindergarten Teacher", "Early Childhood Educator", onet=("25-2011.00",), esco="early years teacher"),
    )),
    FieldSeed("Legal", (
        R("Advocate & Solicitor", "Lawyer", "Legal Counsel", "Attorney", "Advocate"),
        R("Legal Executive", "Legal Assistant"),
        R("Paralegal", onet=("23-2011.00",), esco="legal assistant"),
        R("Company Secretary", "Corporate Secretarial Executive"),
    )),
    FieldSeed("Hospitality, Food & Tourism", (
        R("Chef", "Cook", "Commis Chef", "Sous Chef"),
        R("Outlet Manager", "Restaurant Manager", "F&B Manager"),
        R("Front Office Executive", "Hotel Front Office Executive", "Front Desk Agent", "Guest Service Agent"),
        R("Event Executive", "Event Planner", "Event Coordinator"),
        R("Travel Consultant", "Tour Guide", onet=("39-7011.00",), esco="tourist guide"),
        R("Food Technologist", "Food Scientist", "Food Safety Executive"),
    )),
    FieldSeed("Logistics, Transport & Aviation", (
        R("Logistics Executive", "Logistics Coordinator", onet=("13-1081.00",), esco="logistics and distribution manager"),
        R("Warehouse Supervisor", "Warehouse Manager", "Warehouse Executive"),
        R("Inventory Executive", "Store Executive", "Storekeeper", "Inventory Controller"),
        R("Shipping Executive", "Freight Forwarder", "Freight Forwarding Executive", onet=("43-5011.01",), esco="freight transport dispatcher"),
        R("Pilot", "Airline Pilot"),
        R("Aircraft Maintenance Engineer", "Aircraft Technician", "Licensed Aircraft Engineer"),
        R("Cabin Crew", "Flight Attendant", "Flight Steward"),
    )),
    FieldSeed("Science & Agriculture", (
        R("Plantation Executive", "Agricultural Officer", "Agronomist", "Estate Executive"),
        R("Chemist", "QC Chemist", "Analytical Chemist"),
        R("Biotechnologist", "Biotechnology Executive", onet=("19-1029.01", "19-4021.00"), esco="biotechnical technician"),
        R("Environmental Executive", "Environmental Officer", "Environmental Scientist"),
        R("Lab Analyst", "Laboratory Analyst", "Lab Technician", "Laboratory Technician",
          onet=("19-4099.01",), esco="scientific laboratory technician"),
    )),
    FieldSeed("Administration & Customer Service", (
        R("Admin Executive", "Administrative Executive", "Administrative Assistant", "Admin Assistant"),
        R("Office Manager"),
        R("Customer Service Executive", "Customer Service Representative", "Customer Service Officer"),
        R("Call Centre Agent", "Contact Centre Agent", "Customer Care Agent", "BPO Agent", onet=("43-4051.00",), esco="call centre agent"),
        R("Personal Assistant", "Executive Assistant", "Secretary"),
    )),
)
