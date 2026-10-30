from faker import Faker
import csv
import random

# Initialize Faker
fake = Faker()

roles = ['Job Seeker', 'Recruiter', 'Admin']
statuses = ['Active', 'Disabled']

def generate_user(i):
    name = fake.name()
    email = fake.email()
    role = random.choice(roles)
    status = 'Active' if role == 'Admin' else random.choice(statuses)
    return {
        'id': i,
        'name': name,
        'email': email,
        'role': role,
        'status': status
    }

def main():
    filename = 'users.csv'
    with open(filename, 'w', newline='', encoding='utf-8') as f:
        writer = csv.DictWriter(f, fieldnames=['id', 'name', 'email', 'role', 'status'])
        writer.writeheader()
        for i in range(1, 1001):
            user = generate_user(i)
            writer.writerow(user)
    print(f"{filename} generated with 1000 records.")

if __name__ == "__main__":
    main()
