const targetJob = document.getElementById("targetJob");

const coveragePercent = document.getElementById("coveragePercent");
const coverageDescription = document.getElementById("coverageDescription");
const coverageBar = document.getElementById("coverageBar");

const matchedSkills = document.getElementById("matchedSkills");
const missingSkills = document.getElementById("missingSkills");

const roadmap = document.getElementById("roadmap");

const recommendationTitle = document.getElementById("recommendationTitle");
const recommendationText = document.getElementById("recommendationText");


const careerData = {

    ai: {
        title: "Junior AI Engineer",
        totalSkills: 10,
        matched: [
            "Python",
            "SQL",
            "Machine Learning",
            "Data Analysis",
            "Problem Solving",
            "Communication"
        ],
        missing: [
            "Deep Learning",
            "TensorFlow",
            "Model Deployment",
            "Computer Vision"
        ],
        roadmap: [
            {
                title: "Week 1 – Strengthen Python Skills",
                description: "Practise Python programming, functions, data structures, and working with libraries."
            },
            {
                title: "Week 2 – Learn Deep Learning Fundamentals",
                description: "Study neural networks, activation functions, and basic deep learning concepts."
            },
            {
                title: "Week 3 – Build an AI Project",
                description: "Create a small AI project using a dataset and apply machine learning techniques."
            },
            {
                title: "Week 4 – Prepare for Job Applications",
                description: "Improve your portfolio, practise technical questions, and prepare your resume."
            }
        ],
        recommendation:
            "You already have a foundation in Python, SQL, machine learning, and problem-solving. Focus on deep learning, AI tools, and practical project development to improve your readiness for a Junior AI Engineer role."
    },

    data: {
        title: "Data Analyst",
        totalSkills: 8,
        matched: [
            "SQL",
            "Data Analysis",
            "Python",
            "Problem Solving",
            "Communication"
        ],
        missing: [
            "Power BI",
            "Data Visualization",
            "Advanced Excel"
        ],
        roadmap: [
            {
                title: "Week 1 – Improve SQL Skills",
                description: "Practise joins, subqueries, grouping, and data manipulation."
            },
            {
                title: "Week 2 – Learn Data Visualization",
                description: "Create charts and dashboards to communicate data insights."
            },
            {
                title: "Week 3 – Practise Power BI",
                description: "Build an interactive dashboard using a sample dataset."
            },
            {
                title: "Week 4 – Build a Data Analysis Portfolio",
                description: "Complete a data analysis project and present your findings."
            }
        ],
        recommendation:
            "Your knowledge of SQL, Python, and data analysis gives you a good starting point. Improve your data visualization and dashboard skills to become more prepared for a Data Analyst position."
    },

    software: {
        title: "Software Developer",
        totalSkills: 8,
        matched: [
            "Python",
            "Problem Solving",
            "SQL",
            "Communication"
        ],
        missing: [
            "Java",
            "Object-Oriented Programming",
            "Git",
            "Software Testing"
        ],
        roadmap: [
            {
                title: "Week 1 – Learn Object-Oriented Programming",
                description: "Practise classes, objects, inheritance, and encapsulation."
            },
            {
                title: "Week 2 – Improve Programming Skills",
                description: "Build small programs using Java or Python."
            },
            {
                title: "Week 3 – Learn Git and Software Testing",
                description: "Practise version control and basic software testing."
            },
            {
                title: "Week 4 – Develop a Software Project",
                description: "Create a small application and upload it to your portfolio."
            }
        ],
        recommendation:
            "You have useful programming and problem-solving foundations. Focus on Java, object-oriented programming, Git, and software testing to strengthen your preparation for a Software Developer role."
    },

    web: {
        title: "Junior Web Developer",
        totalSkills: 8,
        matched: [
            "HTML",
            "CSS",
            "Problem Solving",
            "Communication"
        ],
        missing: [
            "JavaScript",
            "Responsive Design",
            "Git",
            "Web APIs"
        ],
        roadmap: [
            {
                title: "Week 1 – Improve HTML and CSS",
                description: "Practise creating structured and responsive web pages."
            },
            {
                title: "Week 2 – Learn JavaScript",
                description: "Understand variables, functions, events, and DOM manipulation."
            },
            {
                title: "Week 3 – Build an Interactive Website",
                description: "Create a website with interactive features and responsive layouts."
            },
            {
                title: "Week 4 – Portfolio and Deployment",
                description: "Prepare a web development portfolio and practise deployment."
            }
        ],
        recommendation:
            "You have a foundation in HTML, CSS, and problem-solving. Develop JavaScript, responsive design, and API integration skills to improve your readiness for a Junior Web Developer role."
    }

};


function displaySkills(skills, type) {

    return skills.map(skill => {

        return `<span class="skill-tag ${type}">${skill}</span>`;

    }).join("");

}


function displayRoadmap(items) {

    return items.map(item => {

        return `
            <div class="roadmap-item">

                <h3>${item.title}</h3>

                <p>${item.description}</p>

            </div>
        `;

    }).join("");

}


function updateDigitalTwin() {

    const selectedJob = targetJob.value;

    const data = careerData[selectedJob];

    const percentage = Math.round(
        (data.matched.length / data.totalSkills) * 100
    );

    // Update coverage
    coveragePercent.textContent = percentage + "%";

    coverageDescription.textContent =
        data.matched.length + " out of " +
        data.totalSkills + " required skills";

    coverageBar.style.width = percentage + "%";


    // Update matched skills
    matchedSkills.innerHTML =
        displaySkills(data.matched, "matched");


    // Update missing skills
    missingSkills.innerHTML =
        displaySkills(data.missing, "missing");


    // Update roadmap
    roadmap.innerHTML =
        displayRoadmap(data.roadmap);


    // Update recommendation
    recommendationTitle.textContent = data.title;

    recommendationText.textContent =
        data.recommendation;

}


// Update the page when the target job changes
targetJob.addEventListener("change", updateDigitalTwin);


// Display initial information
updateDigitalTwin();