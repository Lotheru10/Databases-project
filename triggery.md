--1.Trigger, który po dodaniu nowego kursu do bazy danych, dodaje do tabeli HistoryOfPriceCourses rekord z ceną kursu i datą dodania kursu.

CREATE TRIGGER [dbo].[trg_AddInitialCoursePrice]
ON [dbo].[Courses]
AFTER INSERT
AS
BEGIN
-- Dodajemy początkową cenę do tabeli HistoryOfPriceCourses
INSERT INTO HistoryOfPriceCourses (CourseID, Price, ChangeDate)
SELECT
CourseID, -- ID kursu
Price, -- Aktualna cena kursu
GETDATE() -- Data zmiany
FROM inserted;
END;
GO

ALTER TABLE [dbo].[Courses] ENABLE TRIGGER [trg_AddInitialCoursePrice]
GO

--2.Trigger, który po zmianie ceny kursu w tabeli Courses, dodaje do tabeli HistoryOfPriceCourses rekord z nową ceną kursu i datą zmiany.

CREATE TRIGGER [dbo].[trg_UpdateCoursePrice]
ON [dbo].[Courses]
AFTER UPDATE
AS
BEGIN
IF UPDATE(Price)
BEGIN
INSERT INTO HistoryOfPriceCourses (ChangeDate, Price, CourseID)
SELECT GETDATE(), Price, CourseID
FROM inserted
WHERE Price <> (SELECT Price FROM deleted WHERE deleted.CourseID = inserted.CourseID)
END
END;
GO

ALTER TABLE [dbo].[Courses] ENABLE TRIGGER [trg_UpdateCoursePrice]
GO

--3.Trigger, który po dodaniu nowych studiów do bazy danych, dodaje do tabeli HistoryOfPriceStudies rekord z ceną studiów i datą dodania studiów.

CREATE TRIGGER [dbo].[trg_InsertStudiesPriceHistory]
ON [dbo].[Studies]
AFTER INSERT
AS
BEGIN
-- Dodajemy początkową cenę do tabeli HistoryOfPriceStudies
INSERT INTO HistoryOfPriceStudies (ChangeDate, StudiesID, Price)
SELECT
GETDATE(), -- Data zmiany
StudiesID, -- ID studiów
Price -- Początkowa cena
FROM inserted;
END;
GO

ALTER TABLE [dbo].[Studies] ENABLE TRIGGER [trg_InsertStudiesPriceHistory]
GO

--4.Trigger, który po zmianie ceny studiów w tabeli Studies, dodaje do tabeli HistoryOfPriceStudies rekord z nową ceną studiów i datą zmiany.

CREATE TRIGGER [dbo].[trg_UpdateStudiesPriceHistory]
ON [dbo].[Studies]
AFTER UPDATE
AS
BEGIN
-- Sprawdzamy, czy zmieniono cenę
IF (UPDATE(Price))
BEGIN
INSERT INTO HistoryOfPriceStudies (ChangeDate, StudiesID, Price)
SELECT
GETDATE(), -- Data zmiany
StudiesID, -- ID studiów
Price -- Nowa cena
FROM inserted;
END;
END;
GO

ALTER TABLE [dbo].[Studies] ENABLE TRIGGER [trg_UpdateStudiesPriceHistory]
GO

--5.Trigger, który po dodaniu nowego webinaru do bazy danych, dodaje do tabeli HistoryOfPriceWebinars rekord z ceną webinaru i datą dodania webinaru.
--Zakładamy, że początkowa cena webinaru wynosi 0.

CREATE TRIGGER [dbo].[trg_InsertWebinarPriceHistory]
ON [dbo].[Webinars]
AFTER INSERT
AS
BEGIN
-- Dodajemy początkową cenę 0 do tabeli HistoryOfPriceWebinars
INSERT INTO HistoryOfPriceWebinars (ChangeDate, WebinarID, Price)
SELECT
GETDATE(), -- Data zmiany
WebinarID, -- ID webinaru
0.00 -- Początkowa cena
FROM inserted;
END;
GO

ALTER TABLE [dbo].[Webinars] ENABLE TRIGGER [trg_InsertWebinarPriceHistory]
GO

--6.Trigger, który przy próbie dodania nowego przedmiotu do bazy danych sprawdza, czy limit osób na tym przedmiocie
--jest większy lub równy limitowi osób na studiach, do których ten przedmiot jest przypisany.

CREATE TRIGGER [dbo].[trg_CheckSubjectCapacity]
ON [dbo].[Subjects]
AFTER INSERT
AS
BEGIN
DECLARE @SubjectID INT, @SubjectSpaceLimit INT, @StudiesID INT;
DECLARE @StudiesSpaceLimit INT;

    -- Pobranie wartości z wstawionego przedmiotu
    SELECT @SubjectID = SubjectID, @SubjectSpaceLimit = SpaceLimit, @StudiesID = StudiesID FROM inserted;

    -- Pobranie limitu osób na całych studiach
    SELECT @StudiesSpaceLimit = SpaceLimit
    FROM Studies
    WHERE StudiesID = @StudiesID;

    -- Sprawdzenie, czy limit osób przedmiotu jest większy lub równy limitowi studiów
    IF @SubjectSpaceLimit < @StudiesSpaceLimit
    BEGIN
        -- Zgłoszenie błędu, jeśli limit osób przedmiotu jest mniejszy niż limit osób na studiach
        RAISERROR('Limit osób przedmiotu musi być większy lub równy limitowi osób na studiach.', 16, 1);
        ROLLBACK;  -- Anulowanie wstawienia rekordu
    END

END;
GO

ALTER TABLE [dbo].[Subjects] ENABLE TRIGGER [trg_CheckSubjectCapacity]
GO

--7.Trigger, który po dodaniu nowego spotkania związane z przedmiotem do bazy danych, sprawdza, czy student, który właśnie uczestniczył w tym spotkaniu,
--ma wystarczającą obecność (80% wszystkich spotkań), aby zaliczyć ten przedmiot. Jeśli tak, to ustawia odpowiednią flagę w tabeli SubjectStatus.

CREATE TRIGGER [dbo].[trg_CheckPassingStatus]
ON [dbo].[StudyMeetingAttendence]
AFTER INSERT, UPDATE
AS
BEGIN
-- Deklaracje zmiennych
DECLARE @StudentID INT, @ClassMeetingID INT, @SubjectID INT, @TotalMeetings INT, @AttendedMeetings INT, @AttendanceRate DECIMAL(5,2);

    -- Pobieranie danych z wstawionych lub zaktualizowanych wierszy
    SELECT @StudentID = StudentID, @ClassMeetingID = ClassMeetingID
    FROM inserted;

    -- Pobranie SubjectID na podstawie ClassMeetingID
    SELECT @SubjectID = SubjectID
    FROM ClassMeeting
    WHERE ClassMeetingID = @ClassMeetingID;

    -- Liczba wszystkich spotkań związanych z danym przedmiotem
    SELECT @TotalMeetings = COUNT(*)
    FROM ClassMeeting
    WHERE SubjectID = @SubjectID;

    -- Liczba spotkań, na których student był obecny
    SELECT @AttendedMeetings = COUNT(*)
    FROM StudyMeetingAttendence sma
    JOIN ClassMeeting cm ON sma.ClassMeetingID = cm.ClassMeetingID
    WHERE sma.StudentID = @StudentID AND sma.Presence = 1 AND cm.SubjectID = @SubjectID;

    -- Obliczenie procentu obecności
    SET @AttendanceRate = (@AttendedMeetings * 100.0) / @TotalMeetings;

    -- Aktualizacja PassingStatus w tabeli SubjectStatus
    IF @AttendanceRate >= 80
    BEGIN
        UPDATE SubjectStatus
        SET PassingStatus = 1
        WHERE StudentID = @StudentID AND SubjectID = @SubjectID;
    END

END;
GO

ALTER TABLE [dbo].[StudyMeetingAttendence] ENABLE TRIGGER [trg_CheckPassingStatus]
GO

--8.Trigger, który po dodaniu nowego spotkania stacjonarnego do bazy danych, sprawdza, czy limit osób na tym spotkaniu
--jest większy lub równy limitowi osób na przedmiocie,

CREATE TRIGGER [dbo].[trg_CheckStationaryMeetingCapacity]
ON [dbo].[StationaryMeeting]
AFTER INSERT
AS
BEGIN
DECLARE @PeopleLimit INT, @SubjectID INT, @SubjectSpaceLimit INT;

    -- Pobranie danych z nowo dodanego spotkania stacjonarnego
    SELECT @PeopleLimit = PeopleLimit, @SubjectID = cm.SubjectID
    FROM inserted i
    JOIN ClassMeeting cm ON cm.ClassMeetingID = i.ClassMeetingID;

    -- Pobranie limitu osób na przedmiocie
    SELECT @SubjectSpaceLimit = SpaceLimit
    FROM Subjects
    WHERE SubjectID = @SubjectID;

    -- Sprawdzenie, czy limit osób na spotkaniu stacjonarnym jest większy lub równy limitowi na przedmiocie
    IF @PeopleLimit < @SubjectSpaceLimit
    BEGIN
        -- Zgłoszenie błędu, jeśli limit na spotkaniu stacjonarnym jest mniejszy niż limit na przedmiocie
        RAISERROR('Limit osób na spotkaniu stacjonarnym musi być większy lub równy limitowi osób na przedmiocie.', 16, 1);
        ROLLBACK;  -- Anulowanie dodania spotkania stacjonarnego
    END

END;
GO

ALTER TABLE [dbo].[StationaryMeeting] ENABLE TRIGGER [trg_CheckStationaryMeetingCapacity]
GO

--9.Trigger, który po zmienie statusu płatności w zamówieniu, ustawia status zamówienia na aktywne (wykonane) po zapłaceniu.

CREATE TRIGGER [dbo].[trg_UpdateOrderPaymentStatus]
ON [dbo].[OrderDetails]
AFTER UPDATE
AS
BEGIN
-- Sprawdzenie, czy status płatności został zaktualizowany na zapłacony
IF EXISTS (SELECT 1 FROM inserted WHERE PaymentStatus = 1)
BEGIN
-- Ustawienie statusu zamówienia na aktywne po zapłaceniu
UPDATE OrderStatus
SET IsActive = 1
FROM OrderStatus os
JOIN inserted i ON os.OrderID = i.OrderID
WHERE i.PaymentStatus = 1;
END
END;
GO

ALTER TABLE [dbo].[OrderDetails] ENABLE TRIGGER [trg_UpdateOrderPaymentStatus]
GO
