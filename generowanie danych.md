# Generowanie danych

Do generowania danych używaliśmy głównie skryptów pisanych w Pythonie przy użyciu
biblioteki Faker (gwarantuje pseudolosowe dane), a także generowaliśmy je przy pomocy
użycia Chata GPT. Poniżej przykładowy skrypt generujący część danych z tabeli:
(skrypty z reguły na bieżąco modyfikowaliśmy, w zależności od aktualnych potrzeb
generowania do bazy)

import random
from datetime import datetime, timedelta
from faker import Faker
fake = Faker()

Students

for i in range (101, 1101):
    student_id = i
    first_name = fake.first_name()
    last_name = fake.last_name()
    address = fake.address()
    email = first_name[:3].lower() + last_name.lower() + str(random.randint(1, 100000)) + "@example.org"
    pesel = str(random.randint(30, 99)) + str(random.randint(10, 13)) + str(random.randint(10, 29)) + str(random.randint(10000, 99999))
    print(f"INSERT INTO Students (StudentID, FirstName, LastName, Address, Email, PESEL) VALUES ({i}, '{first_name}', '{last_name}', '{address}', '{email}', {pesel});")
    print(f"({i}, '{first_name}', '{last_name}', '{address}', '{email}', '{pesel}')")
    
Teachers

for i in range (21, 41):
    teacher_id = i
    first_name = fake.first_name()
    last_name = fake.last_name()
    phone = (str(random.randint(1,9)) + str(random.randint(1,9)) + str(random.randint(1,9)) + str(random.randint(1,9)) + str(random.randint(1,9)) + str(random.randint(1,9)) + str(random.randint(1,9)) + str(random.randint(1,9)) + str(random.randint(1,9)))
    email = first_name[:3].lower() + last_name.lower() + str(random.randint(1, 100000)) + ".teacher@example.org"
    print(f"INSERT INTO Teachers (TeacherID, FirstName, LastName, Phone, Email) VALUES ({i}, '{first_name}', '{last_name}', '{phone}', '{email}');")

 Studies

for i in range (1, 21):
    studies_id = i
    studies_name = fake.random_letter()
    studies_desc = fake.random_letter()
    studies_price = fake.pricetag()
    studies_limit = random.randint(10, 201)
    print(f"INSERT INTO Studies (StudiesID, Name, Description, Price, SpaceLimit) VALUES ({i}, '{studies_name}', '{studies_desc}', {studies_price}, {studies_limit});")

Translators

for i in range (1, 11):
    translator_id = i
    translator_first_name = fake.first_name()
    translator_last_name = fake.last_name()
    translator_phone = (str(random.randint(1,9)) + str(random.randint(1,9)) + str(random.randint(1,9)) + str(random.randint(1,9)) + str(random.randint(1,9)) + str(random.randint(1,9)) + str(random.randint(1,9)) + str(random.randint(1,9)) + str(random.randint(1,9)))
    translator_email = translator_first_name[:3].lower() + translator_last_name.lower() + str(random.randint(1, 100000)) + ".translator@example.org"
    print(f"INSERT INTO Translators (TranslatorID, FirstName, LastName, Phone, Email) VALUES ({i}, '{translator_first_name}', '{translator_last_name}', '{translator_phone}', '{translator_email}');")

Languages 

for i in range (11, 21):
    language_id = i
    language_name = fake.language_name()
    print(f"INSERT INTO Languages (LanguageID, LanguageName) VALUES ({i}, '{language_name}');")

for i in range (1, 21):
    order_id = i
    order_paymentlink = fake.random_letter()
    order_date = fake.date_this_decade()
    order_studentid = random.randint(1, 10)
    print(f"INSERT INTO Orders (OrderID, PaymentLink, OrderDate, StudentID) VALUES ({order_id}, '{order_paymentlink}', '{order_date}', {order_studentid});")

for i in range (3, 23):
    subjects_id = i
    subjects_studiesid = random.randint(1, 20)
    subjects_languageid = random.randint(1, 20)
    subjects_translatorid = random.randint(1, 10)
    subjects_teacherid = random.randint(1, 20)
    subjects_spacelimit = random.randint(10, 40)
    print(f"INSERT INTO Subjects (SubjectID, StudiesID, Name, Language, Description, TranslatorID, TeacherID, SpaceLimit) VALUES ({subjects_id}, {subjects_studiesid}, '', {subjects_languageid}, '', {subjects_translatorid}, {subjects_teacherid}, {subjects_spacelimit});")

CourseMeeting

for i in range (1, 101):
    c_id = i
    c_trans = random.randint(1, 10)
    c_teacher = random.randint(1, 40)
    c_data = fake.date_this_year()
    c_duration = random.randint(60, 180)
    c_courseid = random.randint(1, 50)
    print(f"INSERT INTO CourseMeeting (CourseMeetingID, CourseID, TranslatorID, TeacherID, Duration, Data) VALUES ({c_id}, {c_trans}, {c_teacher}, '{c_data}', {c_duration}, {c_courseid});")

Update CourseMeeting

for i in range (1, 101):
    c_id = i
    # c_trans = random.randint(1, 10)
    c_teacher = random.randint(1, 40)
    c_data = fake.date_between_dates(date_start=datetime(2025,1,1), date_end=datetime(2025,4,30))
    c_duration = '0' + str(random.randint(1,5)) + ':00:00'
    c_courseid = random.randint(1, 50)
    print(f"UPDATE CourseMeeting SET TeacherID = {c_teacher}, Data = '{c_data}', Duration = '{c_duration}', CourseID = {c_courseid} WHERE CourseMeetingID = {c_id};")

from numpy.random import choice
CourseMeetingAttendence
n = 1
m = 16
for i in range (1, 101):
    if i%10 == 0: m += 1
    students = set()
    for _ in range (m):
        att_id = i
        n += 1
        att_student = random.randint(1, 100)
        while att_student in students:
            att_student = random.randint(1, 100)
        students.add(att_student)
        possibilities = [0, 1]
        att_att = choice(possibilities, 1, p=[0.1, 0.9])
        print(f'INSERT INTO CourseMeetingAttendence (CourseMeetingID, StudentID, Presence) VALUES ({att_id}, {att_student}, {att_att[0]});')
