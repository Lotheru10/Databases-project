# WIDOKI

-- translators_with_languages
--zwraca tabelę z danymi tłumaczy i z przypisanymi do nich językami z tabeli Languages
-- kod:
CREATE VIEW translators_with_languages AS
SELECT TOP (100) PERCENT dbo.Translators.TranslatorID, dbo.Translators.FirstName,
dbo.Translators.LastName, dbo.Languages.LanguageName
FROM dbo.Translators 
INNER JOIN dbo.TranslatorsxLanguage ON dbo.TranslatorsxLanguage.TranslatorID = dbo.Translators.TranslatorID INNER JOIN dbo.Languages ON dbo.Languages.LanguageID = dbo.TranslatorsxLanguage.LanguageID
ORDER BY dbo.Translators.TranslatorID;


-- upcoming_webinars
-- Zwraca tabelę z id, nazwami i datami webinarów, które mają odbyć się w dowolnym momencie w przyszłości
-- kod:
CREATE VIEW upcoming_webinars AS
SELECT WebinarID, Name, Date
FROM   dbo.Webinars
WHERE (Date > GETDATE());


-- studies_list
-- Zwraca tabelę ze wszystkimi dostępnymi studiami wraz z ich opisem, ceną, ilością miejsc, itp.
-- kod:
CREATE VIEW studies_list AS
SELECT StudiesID, Name, Description, Price, SpaceLimit
FROM   dbo.Studies;


-- affordable_studies
-- Widok polega na tym samym co widok wyżej, tyle że studia w tej tabeli
-- kosztują nie więcej niż 1000 
-- kod:
CREATE VIEW affordable_studies AS
SELECT StudiesID, Name, Description, Price, SpaceLimit
FROM   dbo.Studies
WHERE (Price <= 1000);


-- spanish_translators
-- Zwraca tabelę z danymi wszystkich tłumaczy posługujących się językiem hiszpańskim 
-- kod:
CREATE VIEW spanish_translators AS
SELECT t.TranslatorID, t.FirstName, t.LastName, t.Email, t.Phone, txl.LanguageID
FROM   dbo.Translators AS t INNER JOIN
dbo.TranslatorsxLanguage AS txl ON txl.TranslatorID = t.TranslatorID
WHERE (txl.LanguageID = 4);


-- courses_info
--Zwraca tabelę z informacjami o kursach wraz z ich językiem
-- kod:
CREATE VIEW CourseDetails AS
SELECT c.CourseID, c.Name AS CourseName, l.LanguageName AS Language, c.Price,
c.Description, c.Data AS CourseStartDate
FROM Courses c
JOIN Languages l ON c.Language = l.LanguageID;


-- class_attendance_details
--Tworzy tabelę pokazującą zajęcia wraz z uczniami uczęszczającymi na nie i z informacją, 
-- czy byli obecni na danych zajęciach
-- kod:
CREATE VIEW ClassAttendenceDetails AS
SELECT sm.ClassMeetingID, s.StudentID,
CONCAT(s.FirstName, ' ', s.LastName) AS StudentName, sm.Presence
FROM StudyMeetingAttendence sm
JOIN Students s ON sm.StudentID = s.StudentID;


-- generating_invoices
-- Tworzy tablicę z zamówieniami, do których klienci zażyczyli sobie faktury
-- kod:
CREATE VIEW generating_invoices AS
SELECT O.OrderID, O.OrderDate, O.StudentID
FROM dbo.Orders AS O 
INNER JOIN dbo.OrderDetails AS OD ON OD.OrderID = O.OrderID
WHERE (OD.Invoice = 1);


-- course_price_history
-- Pozwala śledzić historię cen kursów
-- kod:
CREATE VIEW CoursePriceHistory AS
SELECT hpc.ChangeDate, c.Name AS CourseName, hpc.Price 
FROM HistoryOfPriceCourses hpc 
JOIN Courses c ON hpc.CourseID = c.CourseID;


-- teacher_list
-- Zwraca listę nauczycieli wraz z ich danymi oraz nauczanymi przez nich przedmiotami
-- kod:
CREATE VIEW teacher_list AS
SELECT dbo.Teachers.TeacherID, dbo.Teachers.FirstName, dbo.Teachers.LastName,
dbo.Teachers.Phone, dbo.Teachers.Email, dbo.Subjects.Name
FROM dbo.Teachers 
LEFT OUTER JOIN dbo.Subjects ON dbo.Subjects.TeacherID = dbo.Teachers.TeacherID;


-- rodo_not_approved
-- Zwraca listę osób (studenci, nauczyciele, tłumacze), 
-- którzy nie akceptowali RODO lub ich przekazanie danych się przedawniło
-- kod:
CREATE VIEW rodo_not_approved AS
SELECT S.StudentID, S.FirstName as StudentFName, S.LastName AS StudentLName,
T.TeacherID, T.FirstName as TeacherFName, T.LastName  AS TeacherLName,
TR.TranslatorID, TR.FirstName as TranslatorFName, TR.LastName  AS TranslatorLName 
FROM RODO R
JOIN Students S ON S.StudentID = R.StudentID
JOIN Teachers T ON T.TeacherID = R.TeacherID
JOIN Translators TR ON TR.TranslatorID = R.TranslatorID
WHERE Approved = 0;


-- diploma_check
-- Zwraca tabelę ze studentami i ich danymi, którym należy wysłać dyplomy za zakończone studia
-- kod:
CREATE VIEW diploma_check AS
SELECT SD.StudentID, SD.Address, S.FirstName, S.LastName, SD.StudiesID 
FROM SendingDiploma SD
JOIN Students S ON S.StudentID = SD.StudentID
WHERE SD.PassingStatus = 1;


-- student_list
-- pokazuje listę studentów wraz z ich danymi osobowymi oraz ich ordersami
-- kod:
CREATE VIEW student_list AS
SELECT S.StudentID, S.FirstName, S.LastName, S.Address, S.PESEL, S.Email, O.OrderID 
FROM Students S
JOIN Orders O on O.StudentID = S.StudentID;


-- not_passed_internships
-- Zwraca tablicę studentów, którzy mają zaległy lub oblany staż
-- kod:
CREATE VIEW not_passed_internships AS
SELECT S.StudentID, S.FirstName, S.LastName, I.IntershipID FROM Students S
JOIN IntershipxStudents I ON I.StudentID = S.StudentID
WHERE I.Passed = 0;


-- whole_price_history
-- W porównaniu z jednym z poprzednich widoków (course_price_history), 
-- ten pokazuje zmiany cen w czasie 
-- kursów, studiów i webinarów jednocześnie
-- kod:
CREATE VIEW whole_price_history AS
SELECT 'Course' AS Type, c.Name AS Name,
h.ChangeDate, h.Price
FROM HistoryOfPriceCourses h
JOIN Courses c ON h.CourseID = c.CourseID
UNION ALL
SELECT 'Studies' AS Type, s.Name AS Name,
h.ChangeDate, h.Price
FROM HistoryOfPriceStudies h
JOIN Studies s ON h.StudiesID = s.StudiesID

UNION ALL

SELECT 'Webinar' AS Type, w.Name AS Name,
h.ChangeDate, h.Price
FROM HistoryOfPriceWebinars h
JOIN Webinars w ON h.WebinarID = w.WebinarID;


-- perfect_frequency_students
-- Wyświetla listę uczniów, którzy zachowali stuprocentową frekwencję na wszystkich swoich zajęciach
-- kod:
CREATE VIEW perfect_frequency_students AS
SELECT S.StudentID, S.FirstName, S.LastName FROM Students S
JOIN CourseMeetingAttendence C ON C.StudentID = S.StudentID
GROUP BY S.StudentID, S.FirstName, S.LastName
HAVING MIN(CASE WHEN C.Presence = 1 THEN 1 ELSE 0 END) = 1;


-- studies_with_internships
-- Pokazuje staże powiązane z konkretnymi studiami
-- kod:
CREATE VIEW studies_with_internships AS
SELECT S.StudiesID, S.Name, P.IntershipID FROM Studies S
INNER JOIN PossibleInterships P ON P.StudiesID = S.StudiesID;


-- students_with_courses_and_status
Pokazuje tabelę z danymi studentów, wraz z ich kursami oraz statusem zaliczenia
-- kod:
CREATE VIEW students_with_courses_and_status AS
SELECT s.StudentID, s.FirstName, s.LastName, c.Name AS CourseName, 
ss.PassingStatus AS IsCoursePassed, ss.StudentGrade AS Grade
FROM dbo.Students AS s 
INNER JOIN dbo.SubjectStatus AS ss ON s.StudentID = ss.StudentID 
INNER JOIN dbo.Subjects AS sub ON ss.SubjectID = sub.SubjectID 
INNER JOIN dbo.Studies AS st ON sub.StudiesID = st.StudiesID 
INNER JOIN dbo.Courses AS c ON st.StudiesID = c.CourseID;


-- popular_subjects
-- Wyświetla listę najbardziej popularnych przedmiotów
-- kod:
CREATE VIEW popular_subjects AS
SELECT sub.SubjectID, sub.Name AS SubjectName, COUNT(ss.StudentID) AS Enrollments
FROM Subjects sub
LEFT JOIN SubjectStatus ss ON sub.SubjectID = ss.SubjectID
GROUP BY sub.SubjectID, sub.Name
ORDER BY Enrollments DESC;


-- list_of_debtors
-- Wyświetla tabelę z dłużnikami i ich danymi
-- kod:
CREATE VIEW list_of_debtors AS
SELECT Y.StudentID, S.FirstName, S.LastName, S.PESEL, Y.CourseID, C.Name, YC.ClassMeetingID, 
Y.Amount AS CoursesAmount, YC.Amount AS ClassMeetingAmount 
FROM YetToPayCourses Y
JOIN Students S ON S.StudentID = Y.StudentID
JOIN Courses C ON C.CourseID = Y.CourseID
LEFT JOIN YetToPayClassMeetings YC ON YC.StudentID = Y.StudentID;

-- future_meetings
-- Wyświetla tabelę z id spotkań kursowych, które mają się odbyć w przyszłości, 
-- wraz z ilością osób zapisanych na te spotkania
-- kod:
CREATE VIEW future_meetings AS
SELECT C.CourseMeetingID, COUNT(C.StudentID) AS AmountOfStudents 
FROM CourseMeetingAttendence C
JOIN CourseMeeting CM ON CM.CourseMeetingID = C.CourseMeetingID
WHERE CM.Data > GETDATE()
GROUP BY C.CourseMeetingID;


-- future_study_meetings
-- To co wyżej tylko dla studiów
-- kod:
CREATE VIEW future_study_meetings AS
SELECT S.ClassMeetingID, COUNT(S.StudentID) AS AmountOfStudents 
FROM StudyMeetingAttendence S
JOIN ClassMeeting CM ON CM.ClassMeetingID = S.ClassMeetingID
WHERE CM.Data > GETDATE()
GROUP BY S.ClassMeetingID;


-- financial_report
-- Zwraca tabelę zawierającą raporty finansowe dla wszystkich typów spotkań 
-- (kurs, webinar, studia) wraz z przychodem dla każdego konkretnego wydarzenia
-- kod:
CREATE VIEW financial_report AS
SELECT 'Webinar' AS ReportType, w.Name AS Name, SUM(od.Price) AS TotalIncome
FROM Webinars w
JOIN WebinarOrder wo ON w.WebinarID = wo.WebinarID
JOIN OrderDetails od ON wo.OrderID = od.OrderID
WHERE od.PaymentStatus = 1 -- Tylko opłacone zamówienia
GROUP BY w.Name

UNION ALL

SELECT 'Course' AS ReportType, c.Name AS Name, SUM(od.Price) AS TotalIncome
FROM Courses c
JOIN CourseOrder co ON c.CourseID = co.CourseID
JOIN OrderDetails od ON co.OrderID = od.OrderID
WHERE od.PaymentStatus = 1
GROUP BY c.Name

UNION ALL

SELECT 'Study' AS ReportType, s.Name AS Name, SUM(od.Price) AS TotalIncome
FROM Studies s
JOIN StudiesOrder so ON s.StudiesID = so.StudiesID
JOIN OrderDetails od ON so.OrderID = od.OrderID
WHERE od.PaymentStatus = 1
GROUP BY s.Name;


-- course_presence
-- Prezentuje frekwencję na odbytych już spotkaniach kursowych: datę spotkania, 
-- liczbę osób obecnych i nieobecnych na konkretnym spotkaniu
-- kod:
CREATE VIEW course_presence AS
SELECT c.Name AS Kurs, cm.Data AS DataSpotkania, COUNT(CASE WHEN cma.Presence = 1 THEN 1 END) AS Obecni,
COUNT(CASE WHEN cma.Presence = 0 THEN 1 END) AS Nieobecni, COUNT(cma.StudentID) AS LiczbaZapisanych
FROM CourseMeeting cm
LEFT JOIN CourseMeetingAttendence cma ON cm.CourseMeetingID = cma.CourseMeetingID
LEFT JOIN Courses c ON cm.CourseID = c.CourseID
WHERE cm.Data < GETDATE()
GROUP BY c.Name, cm.Data;


-- study_presence
-- To samo co wyżej, ale dla studiów
-- kod:
CREATE VIEW study_presence AS
SELECT cm.Data AS DataSpotkania, COUNT(CASE WHEN sma.Presence = 1 THEN 1 END) AS Obecni,
COUNT(CASE WHEN sma.Presence = 0 THEN 1 END) AS Nieobecni, COUNT(sma.StudentID) AS LiczbaZapisanych
FROM ClassMeeting cm
LEFT JOIN StudyMeetingAttendence sma ON cm.ClassMeetingID = sma.ClassMeetingID
WHERE cm.Data < GETDATE()
GROUP BY cm.Data;


-- bilocation
-- Raport bilokacji: lista osób, które są zapisane na co najmniej dwa przyszłe szkolenia, 
-- które ze sobą kolidują czasowo.
-- kod:
CREATE VIEW bilocation AS
SELECT s.StudentID, s.FirstName, s.LastName, cm1.CourseMeetingID AS CourseMeetingID1,
cm1.Data AS Data1, cm1.Duration AS Duration1, cm2.CourseMeetingID AS CourseMeetingID2,
cm2.Data AS Data2, cm2.Duration AS Duration2
FROM CourseMeetingAttendence cma1
JOIN CourseMeeting cm1 ON cma1.CourseMeetingID = cm1.CourseMeetingID
JOIN CourseMeetingAttendence cma2 ON cma1.StudentID = cma2.StudentID
JOIN CourseMeeting cm2 ON cma2.CourseMeetingID = cm2.CourseMeetingID
JOIN Students s ON cma1.StudentID = s.StudentID
WHERE cm1.CourseMeetingID < cm2.CourseMeetingID
    AND DATEADD(MINUTE, DATEDIFF(MINUTE, 0, cm1.Duration), CAST(cm1.Data AS DATETIME)) > CAST(cm2.Data AS DATETIME)
    AND CAST(cm1.Data AS DATETIME) < DATEADD(MINUTE, DATEDIFF(MINUTE, 0, cm2.Duration), CAST(cm2.Data AS DATETIME))
    AND CAST(cm1.Data AS DATETIME) > GETDATE() 
    AND CAST(cm2.Data AS DATETIME) > GETDATE();



























