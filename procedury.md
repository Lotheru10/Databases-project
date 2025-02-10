--1. Procedura dodająca przedmiot do koszyka, najpierw sprawdza czy student jest już zapisany na przedmiot, czy przedmiot jest już w koszyku,
--czy zamówienie już zostało zrealizowane, czy są dostępne miejsca, czy przedmiot jest aktywny, czy cena jest poprawna, czy data jest poprawna,
--a następnie dodaje przedmiot do koszyka i aktualizuje cenę w OrderDetails

CREATE PROCEDURE [dbo].[AddItemToCart]
(
@StudentID INT,
@OrderID INT,
@ItemType VARCHAR(50), -- Typ przedmiotu ('Webinar', 'Course', 'Studies', 'ClassMeeting')
@ItemID INT
)
AS
BEGIN
BEGIN TRY
BEGIN TRANSACTION;

        -- Sprawdzenie, czy przedmiot istnieje
        DECLARE @ItemExists BIT = 0;

        IF @ItemType = 'Webinar'
        BEGIN
            -- Sprawdzenie, czy webinar istnieje
            IF EXISTS (SELECT 1 FROM Webinars WHERE WebinarID = @ItemID)
                SET @ItemExists = 1;
        END
        ELSE IF @ItemType = 'ClassMeeting'
        BEGIN
            -- Sprawdzenie, czy spotkanie istnieje
            IF EXISTS (SELECT 1 FROM ClassMeeting WHERE ClassMeetingID = @ItemID)
                SET @ItemExists = 1;
        END
        ELSE IF @ItemType = 'Course'
        BEGIN
            -- Sprawdzenie, czy kurs istnieje
            IF EXISTS (SELECT 1 FROM Courses WHERE CourseID = @ItemID)
                SET @ItemExists = 1;
        END
        ELSE IF @ItemType = 'Studies'
        BEGIN
            -- Sprawdzenie, czy studia istnieją
            IF EXISTS (SELECT 1 FROM Studies WHERE StudiesID = @ItemID)
                SET @ItemExists = 1;
        END

        IF @ItemExists = 0
        BEGIN
            RAISERROR('The specified item does not exist.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Zmienna na sprawdzenie, czy student jest już zapisany na przedmiot
        DECLARE @IsEnrolled BIT = dbo.CheckStudentEnrollmentForItem(@StudentID, @ItemID, @ItemType);

        -- Zmienna na sprawdzenie, czy przedmiot jest już w koszyku
        DECLARE @IsInCart BIT = dbo.CheckItemInCart(@OrderID, @ItemID, @ItemType);

        -- Sprawdzenie, czy zamówienie już zostało zrealizowane (IsActive = 1)
        DECLARE @OrderStatus BIT;
        DECLARE @TargetCurrencyID INT;

        -- Sprawdzanie, czy zamówienie już istnieje
        IF NOT EXISTS (SELECT 1 FROM Orders WHERE OrderID = @OrderID)
        BEGIN
            -- Tworzenie nowego zamówienia
            INSERT INTO Orders (OrderID, OrderDate, StudentID, PaymentLink)
            VALUES (@OrderID, GETDATE(), @StudentID, 'link');

            -- Dodanie statusu zamówienia do tabeli OrderStatus z IsActive = 0 i CurrenciesID = 1
            INSERT INTO OrderStatus (OrderID, IsActive)
            VALUES (@OrderID, 0); -- 0 oznacza nieaktywny

            -- Tworzenie OrderDetails dla nowego zamówienia
            INSERT INTO OrderDetails (OrderID, PaymentStatus, Price, Invoice, VAT, CurrenciesID, ChangeDate)
            VALUES (@OrderID, 0, 0, 0, (SELECT TOP 1 VatChangeDate FROM VAT ORDER BY VatChangeDate DESC), 1, (SELECT TOP 1 ChangeDate FROM Currencies WHERE CurrenciesID = 1 ORDER BY ChangeDate DESC));
        END

        -- Pobranie statusu zamówienia (IsActive) z tabeli OrderStatus
        SELECT @OrderStatus = IsActive
        FROM OrderStatus
        WHERE OrderID = @OrderID;

        -- Pobranie CurrencyID z tabeli OrderDetails
        SELECT @TargetCurrencyID = CurrenciesID
        FROM OrderDetails
        WHERE OrderID = @OrderID;

        -- Jeśli zamówienie już zostało zrealizowane, wyświetl błąd
        IF @OrderStatus = 1
        BEGIN
            RAISERROR('The order has already been completed and cannot be modified.', 16, 1);
            RETURN;
        END

        -- Jeśli student jest już zapisany na ten przedmiot
        IF @IsEnrolled = 1
        BEGIN
            RAISERROR('Student is already enrolled for this item.', 16, 1);
            RETURN;
        END

        -- Jeśli przedmiot jest już w koszyku
        IF @IsInCart = 1
        BEGIN
            RAISERROR('Item is already in the cart.', 16, 1);
            RETURN;
        END

        -- Sprawdzanie dostępności miejsc w zależności od typu przedmiotu
        DECLARE @CanEnroll BIT;

        IF @ItemType = 'Webinar'
        BEGIN
            -- Sprawdzenie dostępności miejsc na webinarze
            SET @CanEnroll = dbo.CanEnrollStudentToWebinar(@StudentID, @ItemID);
        END
        ELSE IF @ItemType = 'ClassMeeting'
        BEGIN
            -- Sprawdzenie dostępności miejsc na spotkaniu
            SET @CanEnroll = dbo.CanEnrollStudentToClassMeeting(@StudentID, @ItemID);
        END
        ELSE IF @ItemType = 'Course'
        BEGIN
            -- Sprawdzenie dostępności miejsc na kursie
            SET @CanEnroll = dbo.CanEnrollStudentToCourse(@StudentID, @ItemID);
        END
        ELSE IF @ItemType = 'Studies'
        BEGIN
            -- Sprawdzenie dostępności miejsc na studiach
            SET @CanEnroll = dbo.CanEnrollStudentToStudies(@StudentID, @ItemID);
        END
        ELSE
        BEGIN
            RAISERROR('Invalid ItemType', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Jeśli nie ma dostępnych miejsc, wyświetl błąd
        IF @CanEnroll = 0
        BEGIN
            RAISERROR('No available spots for this item.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Pobranie ceny na podstawie ItemType
        DECLARE @Price DECIMAL(10, 2);
        IF @ItemType = 'Webinar'
        BEGIN
            SELECT @Price = dbo.GetCurrentWebinarPrice(@ItemID);
        END
        ELSE IF @ItemType = 'ClassMeeting'
        BEGIN
            SELECT @Price = Price
            FROM ClassMeeting
            WHERE ClassMeetingID = @ItemID;
        END
        ELSE IF @ItemType = 'Course'
        BEGIN
            SELECT @Price = DepositAmount -- początkowo dodaje tylko zaliczkę
            FROM CourseDeposits
            WHERE CourseID = @ItemID;
        END
        ELSE IF @ItemType = 'Studies'
        BEGIN
            SELECT @Price = PaymentAmount -- początkowo dodaje tylko zaliczkę
            FROM StudiesPayments
            WHERE StudiesID = @ItemID;
        END
        ELSE
        BEGIN
            RAISERROR('Invalid ItemType', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END;

SELECT @TargetCurrencyID = CurrenciesID
FROM OrderDetails
WHERE OrderID = @OrderID;

-- Przekonwertowanie ceny na walutę docelową
SET @Price = dbo.ConvertPriceToCurrency(@Price, 1, @TargetCurrencyID);

        -- Pobranie docelowego CurrencyID na podstawie OrderID
        -- Używamy już zaktualizowanego OrderDetails

        -- Dodanie przedmiotu do odpowiedniej tabeli w zależności od typu
        IF @ItemType = 'Webinar'
        BEGIN
            -- Sprawdzenie daty webinaru
            DECLARE @WebinarDate DATE;
            SELECT @WebinarDate = Date
            FROM Webinars
            WHERE WebinarID = @ItemID;

            IF GETDATE() >= @WebinarDate
            BEGIN
                RAISERROR('Cannot add this webinar to the cart because it has already started or is too close to the start date.', 16, 1);
                RETURN;
            END

            -- Dodanie do koszyka
            INSERT INTO WebinarOrder (OrderID, WebinarID)
            VALUES (@OrderID, @ItemID);
        END
        ELSE IF @ItemType = 'Course'
        BEGIN
            -- Sprawdzenie daty pierwszego spotkania kursu
            DECLARE @FirstCourseMeetingDate DATE;
            SELECT @FirstCourseMeetingDate = MIN(Data)
            FROM CourseMeeting
            WHERE CourseID = @ItemID;

            IF DATEADD(DAY, 3, GETDATE()) > @FirstCourseMeetingDate
            BEGIN
                RAISERROR('Cannot add this course to the cart because it is too close to the start date.', 16, 1);
                RETURN;
            END

            -- Dodanie do koszyka
            INSERT INTO CourseOrder (OrderID, CourseID)
            VALUES (@OrderID, @ItemID);
        END
        ELSE IF @ItemType = 'Studies'
        BEGIN
            -- Sprawdzenie daty pierwszego spotkania studiów
            DECLARE @FirstStudiesMeetingDate DATE;
            SELECT @FirstStudiesMeetingDate = MIN(Data)
            FROM ClassMeeting
            WHERE SubjectID IN(SELECT SubjectID FROM Subjects where StudiesID=@ItemID);

            IF DATEADD(DAY, 3, GETDATE()) > @FirstStudiesMeetingDate
            BEGIN
                RAISERROR('Cannot add these studies to the cart because it is too close to the start date.', 16, 1);
                RETURN;
            END

            -- Dodanie do koszyka
            INSERT INTO StudiesOrder (OrderID, StudiesID)
            VALUES (@OrderID, @ItemID);
        END
        ELSE IF @ItemType = 'ClassMeeting'
        BEGIN
            -- Sprawdzenie daty spotkania
            DECLARE @ClassMeetingDate DATE;
            SELECT @ClassMeetingDate = Data
            FROM ClassMeeting
    		 WHERE ClassMeetingID = @ItemID;

            IF DATEADD(DAY, 3, GETDATE()) > @ClassMeetingDate
            BEGIN
                RAISERROR('Cannot add this class meeting to the cart because it is too close to the start date.', 16, 1);
                RETURN;
            END

            -- Dodanie do koszyka
            INSERT INTO ClassMeetingOrder (OrderID, ClassMeetingID)
            VALUES (@OrderID, @ItemID);
        END

       IF EXISTS (SELECT 1 FROM OrderDetails WHERE OrderID = @OrderID)

BEGIN
-- Jeśli rekord istnieje, zaktualizuj wartości
UPDATE OrderDetails
SET
Price = Price + @Price -- Dodajemy nową cenę do istniejącej
WHERE OrderID = @OrderID;
END
ELSE
BEGIN
-- Jeśli rekord nie istnieje, dodaj nowy
INSERT INTO OrderDetails (OrderID, PaymentStatus, Price, Invoice, VAT, CurrenciesID, ChangeDate)
VALUES (@OrderID, 0, @Price, 0,
(SELECT TOP 1 VatChangeDate FROM VAT ORDER BY VatChangeDate DESC),
@TargetCurrencyID,
(SELECT TOP 1 ChangeDate FROM Currencies WHERE CurrenciesID = @TargetCurrencyID ORDER BY ChangeDate DESC));
END

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        DECLARE @ErrorMessage NVARCHAR(MAX), @ErrorSeverity INT, @ErrorState INT;
        SELECT @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH

END

GO

--2. Procedura dodająca nowy kurs do bazy danych

CREATE PROCEDURE [dbo].[AddNewCourse] (
@CourseID INT,
@Name NVARCHAR(100),
@Language INT,
@Price DECIMAL(19, 2),
@Description NVARCHAR(100),
@Data DATETIME
)
AS
BEGIN
INSERT INTO Courses (CourseID, Name, Language, Price, Description, Data)
VALUES (@CourseID, @Name, @Language, @Price, @Description, @Data);

    PRINT 'Kurs został pomyślnie dodany.';

END;
GO

--3. Procedura usuwająca studenta z bazy danych, najpierw sprawdza czy student istnieje w tabeli Students

CREATE PROCEDURE [dbo].[DeleteStudent](
@StudentID INT
)
AS
BEGIN
-- Sprawdź, czy student istnieje w tabeli Students
IF NOT EXISTS (SELECT 1 FROM Students WHERE StudentID = @StudentID)
BEGIN
PRINT 'Student o podanym ID nie istnieje.';
RETURN;
END

    -- Usuwanie studenta ze wszystkich przedmiotów (z tabeli StudyMeetingAttendence, SubjectStatus itd.)
    -- Najpierw usuń studenta ze spotkań
    DELETE FROM StudyMeetingAttendence
    WHERE StudentID = @StudentID;

    -- Usuń studenta z tabeli SubjectStatus
    DELETE FROM SubjectStatus
    WHERE StudentID = @StudentID;

    -- Usuń studenta z tabeli SendingDiploma (jeśli jest zapisany na studia)
    DELETE FROM SendingDiploma
    WHERE StudentID = @StudentID;

    -- Usuwanie danych studenta w tabeli RODO

DELETE FROM RODO WHERE StudentID = @StudentID;

-- Usuwanie danych studenta w tabeli CourseMeetingAttendence
DELETE FROM CourseMeetingAttendence WHERE StudentID = @StudentID;

-- Usuwanie danych studenta w tabeli IntershipxStudents
DELETE FROM IntershipxStudents WHERE StudentID = @StudentID;

-- Usuwanie danych studenta w tabeli Orders
DELETE FROM Orders WHERE StudentID = @StudentID;
-- Delete student from YetToPayClassMeetings
DELETE FROM YetToPayClassMeetings
WHERE StudentID = @StudentID;

-- Delete student from YetToPayCourses
DELETE FROM YetToPayCourses
WHERE StudentID = @StudentID;

    -- Usuwanie studenta z tabeli Students
    DELETE FROM Students
    WHERE StudentID = @StudentID;

    PRINT 'Student został usunięty z bazy danych.';

END;
GO

--4. Procedura dodająca studenta do kursu, najpierw sprawdza czy kurs istnieje, czy student jest już zapisany na spotkania związane z tym kursem

CREATE PROCEDURE [dbo].[EnrollStudentToCourse]
(
@StudentID INT, -- ID studenta
@CourseID INT -- ID kursu
)
AS
BEGIN
BEGIN TRY
BEGIN TRANSACTION;

        -- Sprawdzenie, czy kurs istnieje
        IF NOT EXISTS (SELECT 1 FROM Courses WHERE CourseID = @CourseID)
        BEGIN
            RAISERROR('CourseID does not exist.', 16, 1);
            RETURN;
        END

        -- Sprawdzenie, czy student już jest zapisany na spotkania związane z tym kursem
        DECLARE @IsEnrolled BIT;
        SET @IsEnrolled = dbo.CheckStudentEnrollmentForItem(@StudentID, @CourseID, 'Course');

        IF @IsEnrolled = 1
        BEGIN
            RAISERROR('Student is already enrolled in this course.', 16, 1);
            RETURN;
        END

        -- Sprawdzenie spotkań związanych z kursem i zapisanie studenta
        DECLARE @CourseMeetingID INT;
        DECLARE @IsStationary BIT;
        DECLARE @PeopleLimit INT;
        DECLARE @CurrentRegistrations INT;

        DECLARE course_cursor CURSOR FOR
        SELECT cm.CourseMeetingID
        FROM CourseMeeting cm
        WHERE cm.CourseID = @CourseID;

        OPEN course_cursor;
        FETCH NEXT FROM course_cursor INTO @CourseMeetingID;

        -- Iteracja po spotkaniach kursu
        WHILE @@FETCH_STATUS = 0
        BEGIN
            -- Sprawdzenie, czy spotkanie jest stacjonarne

SELECT
@IsStationary = CASE WHEN sm.CourseMeetingID IS NOT NULL THEN 1 ELSE 0 END
FROM StationaryCourseMeeting sm
WHERE sm.CourseMeetingID = @CourseMeetingID;

-- Pobranie limitu miejsc
SELECT
@PeopleLimit = sm.PeopleLimit
FROM StationaryCourseMeeting sm
WHERE sm.CourseMeetingID = @CourseMeetingID;

            -- Jeśli spotkanie jest stacjonarne, sprawdzamy, czy nie przekroczono limitu miejsc
            IF @IsStationary = 1
            BEGIN
                -- Liczymy obecnych studentów na spotkaniu
                SELECT @CurrentRegistrations = COUNT(*)
                FROM CourseMeetingAttendence cma
                WHERE cma.CourseMeetingID = @CourseMeetingID;

                -- Sprawdzamy, czy jest jeszcze miejsce
                IF @CurrentRegistrations >= @PeopleLimit
                BEGIN
                    RAISERROR('No available spots for this stationary course meeting.', 16, 1);
                    ROLLBACK TRANSACTION;
                    RETURN;
                END
            END

            -- Dodanie studenta na spotkanie kursu (jeśli nie ma błędów)
            INSERT INTO CourseMeetingAttendence (StudentID, CourseMeetingID, Presence)
            VALUES (@StudentID, @CourseMeetingID, 0);  -- 0 oznacza, że student jest zapisany, ale nie jest obecny

            FETCH NEXT FROM course_cursor INTO @CourseMeetingID;
        END

        CLOSE course_cursor;
        DEALLOCATE course_cursor;

        -- Komunikat informujący o sukcesie
        PRINT 'Student enrolled successfully for all course meetings.';

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        -- Obsługa błędów
        ROLLBACK TRANSACTION;
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH

END;
GO

USE [u_wkostka]
GO

--5.Procedura zmieniająca obecność studenta na spotkaniu, najpierw sprawdza czy student jest zapisany na spotkanie

CREATE PROCEDURE [dbo].[MarkClassAttendance](
@ClassMeetingID INT,
@StudentID INT,
@Presence BIT
)
AS
BEGIN
-- Może dać obecność tylko zapisanym osobom
IF EXISTS (
SELECT 1
FROM StudyMeetingAttendence
WHERE ClassMeetingID = @ClassMeetingID AND StudentID = @StudentID
)
BEGIN
-- Aktualizacja obecności
UPDATE StudyMeetingAttendence
SET Presence = @Presence
WHERE ClassMeetingID = @ClassMeetingID AND StudentID = @StudentID;
END;
END
GO

USE [u_wkostka]
GO

--6. Procedura zmieniająca obecność studenta na kursie, najpierw sprawdza czy student jest zapisany na kurs

CREATE PROCEDURE [dbo].[MarkCourseAttendance](
@CourseMeetingID INT,
@StudentID INT,
@Presence BIT
)
AS
BEGIN
-- Może dać obecność tylko zapisanym osobom
IF EXISTS (
SELECT 1
FROM CourseMeetingAttendence
WHERE CourseMeetingID = @CourseMeetingID AND StudentID = @StudentID
)
BEGIN
-- Aktualizacja obecności
UPDATE CourseMeetingAttendence
SET Presence = @Presence
WHERE CourseMeetingID = @CourseMeetingID AND StudentID = @StudentID;
END;
END
GO

--7. Procedura zapisująca studenta na staż, najpierw sprawdza czy student jest już zapisany na staż

CREATE PROCEDURE [dbo].[RegisterForInternship](
@IntershipID INT,
@StudentID INT
)
AS
BEGIN
IF EXISTS (
SELECT 1
FROM IntershipxStudents
WHERE IntershipID = @IntershipID AND StudentID = @StudentID
)
BEGIN
PRINT 'Student już jest zarejestrowany na ten staż.';
END
ELSE
BEGIN
INSERT INTO IntershipxStudents (IntershipID, Passed, StudentID)
VALUES (@IntershipID, 0, @StudentID); -- Zakładamy, że "Passed" ma początkową wartość 0
END;
END
GO

--8. Procedura dodająca nowego studenta do bazy danych, najpierw sprawdza czy student z takim samym PESEL lub e-mailem już istnieje

CREATE PROCEDURE [dbo].[RegisterStudent](
@FirstName NVARCHAR(50),
@LastName NVARCHAR(50),
@Address NVARCHAR(100),
@PESEL NVARCHAR(11),
@Email NVARCHAR(30)
)
AS
BEGIN
-- Sprawdzamy, czy istnieje student z takim samym PESEL
IF EXISTS (SELECT 1 FROM Students WHERE PESEL = @PESEL)
BEGIN
PRINT 'Student z takim PESEL już istnieje.';
RETURN; -- Zakończenie procedury, jeśli PESEL już istnieje
END

    -- Sprawdzamy, czy istnieje student z takim samym e-mailem
    IF EXISTS (SELECT 1 FROM Students WHERE Email = @Email)
    BEGIN
        PRINT 'Student z takim e-mailem już istnieje.';
        RETURN; -- Zakończenie procedury, jeśli e-mail już istnieje
    END

    -- Jeśli nie znaleziono duplikatów, wstawiamy nowego studenta
    INSERT INTO Students (FirstName, LastName, Address, PESEL, Email)
    VALUES (@FirstName, @LastName, @Address, @PESEL, @Email);

END;
GO

USE [u_wkostka]
GO

--9. Procedura zapisująca studenta na spotkanie studyjne, najpierw sprawdza czy student jest już zapisany na to spotkanie studyjne

CREATE PROCEDURE [dbo].[RegisterStudentToClassMeeting]
@StudentID INT,
@ClassMeetingID INT
AS
BEGIN
-- Sprawdzanie, czy student już jest zapisany na to spotkanie studyjne
IF EXISTS (SELECT 1 FROM StudyMeetingAttendence WHERE StudentID = @StudentID AND ClassMeetingID = @ClassMeetingID)
BEGIN
RAISERROR('Student is already registered for this class meeting.', 16, 1);
RETURN;
END

    -- Sprawdzanie, czy spotkanie jest stacjonarne

DECLARE @IsStationary BIT;
SET @IsStationary = CASE
WHEN EXISTS (SELECT 1 FROM StationaryMeeting sm WHERE sm.ClassMeetingID = @ClassMeetingID)
THEN 1
ELSE 0
END;

    IF @IsStationary = 1
    BEGIN
        -- Sprawdzanie dostępności miejsc w przypadku spotkania stacjonarnego
        DECLARE @PeopleLimit INT, @CurrentRegistrations INT;

        -- Pobieramy limit osób oraz aktualną liczbę zapisanych
    	SELECT @CurrentRegistrations = COUNT(*)

FROM StudyMeetingAttendence cma
WHERE cma.ClassMeetingID = @ClassMeetingID;
SELECT @PeopleLimit = sm.PeopleLimit
FROM StationaryMeeting sm
WHERE sm.ClassMeetingID = @ClassMeetingID;

        -- Sprawdzamy, czy są dostępne miejsca
        IF @CurrentRegistrations >= @PeopleLimit
        BEGIN
            RAISERROR('No more seats available for this class meeting.', 16, 1);
            RETURN;
        END
    END

    -- Dodanie zapisu studenta na spotkanie studyjne
    INSERT INTO StudyMeetingAttendence (StudentID, ClassMeetingID,Presence)
    VALUES (@StudentID, @ClassMeetingID,0);

END;
GO

--10. Procedura zapisująca studenta na studia, najpierw sprawdza czy student jest już zapisany na te studia

CREATE PROCEDURE [dbo].[RegisterStudentToStudies] (
@StudentID INT, -- ID studenta
@StudiesID INT -- ID programu studiów
)
AS
BEGIN
-- Rozpocznij transakcję
BEGIN TRY
BEGIN TRANSACTION;

        -- Sprawdź, czy student jest już zapisany na dany program studiów
        IF EXISTS (SELECT 1 FROM SendingDiploma WHERE StudentID = @StudentID AND StudiesID = @StudiesID)
        BEGIN
            PRINT 'Student jest już zapisany na ten program studiów.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Zapisz studenta na program studiów
        INSERT INTO SendingDiploma (StudentID, StudiesID)
        VALUES (@StudentID, @StudiesID);

        PRINT 'Student został zapisany na studia.';

        -- Pobierz wszystkie przedmioty związane z tym programem studiów
        DECLARE @SubjectID INT;

        DECLARE subject_cursor CURSOR FOR
        SELECT SubjectID
        FROM Subjects
        WHERE StudiesID = @StudiesID;

        OPEN subject_cursor;
        FETCH NEXT FROM subject_cursor INTO @SubjectID;

        -- Rejestracja studenta na każdym przedmiocie
        WHILE @@FETCH_STATUS = 0
        BEGIN
            -- Sprawdź, czy jest miejsce na przedmiocie przed zapisaniem
            DECLARE @CurrentCount INT;
            DECLARE @SpaceLimit INT;

            -- Pobierz liczbę zapisanych studentów na dany przedmiot
            SELECT @CurrentCount = COUNT(*)
            FROM SubjectStatus
            WHERE SubjectID = @SubjectID;

            -- Pobierz limit miejsc na przedmiocie
            SELECT @SpaceLimit = SpaceLimit
            FROM Subjects
            WHERE SubjectID = @SubjectID;

            -- Sprawdź, czy nie przekroczono limitu miejsc
            IF @CurrentCount >= @SpaceLimit
            BEGIN
                PRINT 'Brak miejsc na przedmiocie. Zapis studenta na studia zostanie wycofany.';
                ROLLBACK TRANSACTION;
                CLOSE subject_cursor;
                DEALLOCATE subject_cursor;
                RETURN;
            END

            -- Jeśli jest miejsce, zarejestruj studenta na przedmiocie
            EXEC RegisterStudentToSubject @StudentID, @SubjectID;

            FETCH NEXT FROM subject_cursor INTO @SubjectID;
        END

        CLOSE subject_cursor;
        DEALLOCATE subject_cursor;

        -- Zatwierdź transakcję, jeśli wszystkie operacje się powiodły
        COMMIT TRANSACTION;
        PRINT 'Student został zapisany na wszystkie przedmioty z programu studiów.';

    END TRY
    BEGIN CATCH
        -- W przypadku błędu wycofaj transakcję
        PRINT 'Wystąpił błąd, cofnięcie zmian.';
        ROLLBACK TRANSACTION;
    END CATCH

END;
GO

--11. Procedura zapisująca studenta na przedmiot, najpierw sprawdza czy student jest już zapisany na ten przedmiot, czy nie przekroczono limitu miejsc

CREATE PROCEDURE [dbo].[RegisterStudentToSubject] (
@StudentID INT,
@SubjectID INT
)
AS
BEGIN
DECLARE @CurrentCount INT;
DECLARE @SpaceLimit INT;
DECLARE @AlreadyRegistered INT;

    -- Rozpocznij transakcję
    BEGIN TRY
        BEGIN TRANSACTION;

        -- Sprawdź, czy student jest już zapisany na dany przedmiot
        SELECT @AlreadyRegistered = COUNT(*)
        FROM SubjectStatus
        WHERE StudentID = @StudentID AND SubjectID = @SubjectID;

        IF @AlreadyRegistered > 0
        BEGIN
            PRINT 'Student jest już zapisany na ten przedmiot.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Pobierz liczbę zapisanych studentów na dany przedmiot w tabeli SubjectStatus
        SELECT @CurrentCount = COUNT(*)
        FROM SubjectStatus
        WHERE SubjectID = @SubjectID;

        -- Pobierz limit miejsc na przedmiocie z tabeli Subjects
        SELECT @SpaceLimit = SpaceLimit
        FROM Subjects
        WHERE SubjectID = @SubjectID;

        -- Sprawdź, czy nie przekroczono limitu miejsc
        IF @CurrentCount < @SpaceLimit
        BEGIN
            -- Zapisywanie studenta na przedmiot
            INSERT INTO SubjectStatus (StudentID, PassingStatus, SubjectID, StudentGrade)
            VALUES (@StudentID, 0, @SubjectID, 1);
            PRINT 'Student został zapisany na przedmiot.';

            -- Zapisz studenta na wszystkie zajęcia związane z tym przedmiotem
            -- Dla spotkań zajęć (ClassMeeting)
            DECLARE @ClassMeetingID INT;
            DECLARE class_meeting_cursor CURSOR FOR
            SELECT ClassMeetingID
            FROM ClassMeeting
            WHERE SubjectID = @SubjectID;

            OPEN class_meeting_cursor;
            FETCH NEXT FROM class_meeting_cursor INTO @ClassMeetingID;

            WHILE @@FETCH_STATUS = 0
            BEGIN
                -- Wywołanie procedury zapisu studenta na ClassMeeting
                EXEC dbo.RegisterStudentToClassMeeting @StudentID, @ClassMeetingID;

                -- Jeśli zapisywanie na spotkanie się nie powiedzie, wycofaj transakcję
                IF @@ERROR <> 0
                BEGIN
                    PRINT 'Błąd podczas zapisywania na spotkanie. Cofam wszystkie zmiany.';
                    ROLLBACK TRANSACTION;
                    CLOSE class_meeting_cursor;
                    DEALLOCATE class_meeting_cursor;
                    RETURN;
                END
                FETCH NEXT FROM class_meeting_cursor INTO @ClassMeetingID;
            END

            CLOSE class_meeting_cursor;
            DEALLOCATE class_meeting_cursor;

            -- Zatwierdź transakcję, jeśli wszystko przebiegło pomyślnie
            COMMIT TRANSACTION;
        END
        ELSE
        BEGIN
            PRINT 'Brak miejsc na przedmiocie. Student nie może się zapisać.';
            ROLLBACK TRANSACTION;
        END
    END TRY
    BEGIN CATCH
        -- W przypadku błędu, wycofaj transakcję
        PRINT 'Wystąpił błąd, cofnięcie zmian.';
        ROLLBACK TRANSACTION;
    END CATCH

END;
GO

--12. Procedura zapisująca studenta na webinar, najpierw sprawdza czy student jest już zapisany na ten webinar

CREATE PROCEDURE [dbo].[RegisterStudentToWebinar]
@StudentID INT,
@WebinarID INT
AS
BEGIN
-- Sprawdzanie, czy student już jest zapisany na to webinarium
IF EXISTS (SELECT 1 FROM WebinarxStudents WHERE StudentID = @StudentID AND WebinarID = @WebinarID)
BEGIN
RAISERROR('Student is already registered for this webinar.', 16, 1);
RETURN;
END

    -- Dodanie zapisu do tabeli WebinarxStudents
    INSERT INTO WebinarxStudents (StudentID, WebinarID)
    VALUES (@StudentID, @WebinarID);

    -- Możesz dodać dodatkową logikę, np. generowanie powiadomienia o zapisaniu
    PRINT 'Student has been successfully registered for the webinar.';

END;
GO

--13.Procedura kupująca produkty w koszyku, jeśli transakcja się powiedzie, zapisuje studenta na kursy, webinary, studia, spotkania,
--ustawia status zamówienia na opłacone

CREATE PROCEDURE [dbo].[CompleteOrder]
@OrderID INT,
@StudentID INT,
@PayFull BIT -- 1 - płatność w całości, 0 - płatność zaliczkowa
AS
BEGIN
BEGIN TRY
BEGIN TRANSACTION;

        -- Sprawdzanie, czy koszyk jest pusty
        DECLARE @Price DECIMAL(10, 2);
        SELECT @Price = Price
        FROM OrderDetails
        WHERE OrderID = @OrderID;

        IF @Price = 0
        BEGIN
            -- Sprawdzamy, czy są darmowe webinary w koszyku
            IF NOT EXISTS (SELECT 1 FROM WebinarOrder WHERE OrderID = @OrderID)
            BEGIN
                RAISERROR('Koszyk jest pusty, brak przedmiotów do zakupu.', 16, 1);
                ROLLBACK TRANSACTION;
                RETURN;
            END
            ELSE
            BEGIN
                -- Zapisz studenta na darmowe webinary
                -- Sprawdzenie, czy student jest już zapisany na ten webinar

IF NOT EXISTS (SELECT 1 FROM WebinarxStudents WHERE StudentID = @StudentID AND WebinarID IN (SELECT WebinarID FROM WebinarOrder WHERE OrderID = @OrderID))
BEGIN
-- Zapisz studenta na webinary z koszyka
INSERT INTO WebinarxStudents (WebinarID, StudentID)
SELECT WebinarID, @StudentID
FROM WebinarOrder
WHERE OrderID = @OrderID;
END
ELSE
BEGIN
RAISERROR('Student jest już zapisany na ten webinar.', 16, 1);
ROLLBACK TRANSACTION;
RETURN;
END

                -- Ustaw status zamówienia na opłacone
                UPDATE OrderStatus
                SET IsActive = 0
                WHERE OrderID = @OrderID;

                COMMIT TRANSACTION;
                RETURN;
            END
        END

        -- Jeśli cena w OrderDetails nie jest 0, to kontynuujemy proces zapisywania
        DECLARE @ClassMeetingID INT;
        DECLARE @CourseID INT;
    	DECLARE @StudiesID INT;
        DECLARE @ClassCount INT;
        DECLARE @CoursePrice DECIMAL(10, 2);
        DECLARE @StudyPrice DECIMAL(10, 2);

        -- Sprawdź dostępność miejsc na przedmiotach (kursach, studiach, spotkaniach)
        IF EXISTS (SELECT 1 FROM CourseOrder WHERE OrderID = @OrderID)
        BEGIN
            -- Sprawdzenie dostępności miejsc na kursie
            SELECT @CourseID = CourseID
            FROM CourseOrder
            WHERE OrderID = @OrderID;

            -- Sprawdź, czy kurs ma wolne miejsca
            IF dbo.CanEnrollToCourse(@StudentID, @CourseID) = 0
            BEGIN
                RAISERROR('Brak miejsc na kursie.', 16, 1);
                ROLLBACK TRANSACTION;
                RETURN;
            END

            -- Zapisywanie studenta na kurs
            -- Sprawdzenie, czy student nie jest już zapisany na kurs

DECLARE @AlreadyEnrolled BIT;
-- Sprawdzenie, czy student jest zapisany na kurs
SET @AlreadyEnrolled = dbo.CheckStudentEnrollmentForItem(@StudentID, @CourseID, 'Course');

IF @AlreadyEnrolled = 1
BEGIN
RAISERROR('Student jest już zapisany na ten kurs.', 16, 1);
RETURN;
END

-- Wywołanie procedury zapisu studenta na kurs
EXEC dbo.EnrollStudentToCourse @StudentID, @CourseID;

            -- Jeśli zapłacono w całości, zwiększ cenę w OrderDetails
            IF @PayFull = 1
            BEGIN
                -- Pobierz pełną cenę kursu
                SELECT @CoursePrice = Price
                FROM Courses
                WHERE CourseID = @CourseID;

                -- Przewalutowanie ceny kursu przed jej dodaniem do OrderDetails

DECLARE @ConvertedCoursePrice DECIMAL(10, 2);

-- Przypisanie docelowej waluty na podstawie OrderID (można zmienić, jeśli masz inną logikę do tego)
DECLARE @TargetCurrencyID INT;
SELECT @TargetCurrencyID = CurrenciesID
FROM OrderDetails
WHERE OrderID = @OrderID;

-- Przewalutowanie ceny kursu z waluty źródłowej na docelową walutę
SET @ConvertedCoursePrice = dbo.ConvertPriceToCurrency(@CoursePrice, 1, @TargetCurrencyID);

-- Zwiększenie ceny w OrderDetails
UPDATE OrderDetails
SET Price = Price + @ConvertedCoursePrice
WHERE OrderID = @OrderID;
END
ELSE
BEGIN
-- Jeśli płatność tylko zaliczkowa, dodaj do dłużników
DECLARE @CourseStartDate DATE;
SELECT @CourseStartDate = MIN(Data)
FROM CourseMeeting
WHERE CourseID = @CourseID;

                -- Dodaj do dłużników
                INSERT INTO YetToPayCourses (StudentID, CourseID, Date, Amount)
                VALUES (@StudentID, @CourseID, DATEADD(DAY, -3, @CourseStartDate), @CoursePrice - (SELECT DepositAmount FROM CourseDeposits WHERE CourseID = @CourseID));
            END
        END

        IF EXISTS (SELECT 1 FROM StudiesOrder WHERE OrderID = @OrderID)
        BEGIN
    	SET @StudiesID=(SELECT StudiesID FROM StudiesOrder WHERE OrderID = @OrderID);
          -- Pobranie wszystkich przedmiotów związanych z danymi studiami

DECLARE @SubjectID INT;
DECLARE subject_cursor CURSOR FOR
SELECT SubjectID
FROM Subjects
WHERE StudiesID = @StudiesID

-- Rozpoczęcie kursora
OPEN subject_cursor;

-- Pętla przez wszystkie przedmioty
FETCH NEXT FROM subject_cursor INTO @SubjectID;

WHILE @@FETCH_STATUS = 0
BEGIN
-- Sprawdzamy, czy studia mają wolne miejsca na dany przedmiot
IF dbo.CanEnrollStudentToSubject(@StudentID, @SubjectID) = 0
BEGIN
RAISERROR('Brak miejsc na przedmiocie.', 16, 1);
ROLLBACK TRANSACTION;
CLOSE subject_cursor;
DEALLOCATE subject_cursor;
RETURN;
END

    -- Pobranie kolejnego przedmiotu
    FETCH NEXT FROM subject_cursor INTO @SubjectID;

END

-- Zamknięcie kursora
CLOSE subject_cursor;
DEALLOCATE subject_cursor;
-- Wywołanie procedury zapisywania studenta na studia
EXEC dbo.RegisterStudentToStudies @StudentID, @StudiesID;

            -- Jeśli zapłacono w całości, zwiększ cenę w OrderDetails
            IF @PayFull = 1
            BEGIN
                -- Pobierz pełną cenę studiów
                SELECT @StudyPrice = Price
                FROM Studies
                WHERE StudiesID = @StudiesID;
    			                -- Przewalutowanie ceny kursu przed jej dodaniem do OrderDetails

DECLARE @ConvertedStudiesPrice DECIMAL(10, 2);

-- Przewalutowanie ceny kursu z waluty źródłowej na docelową walutę
SET @ConvertedStudiesPrice = dbo.ConvertPriceToCurrency(@StudyPrice, 1, @TargetCurrencyID);

                -- Zwiększ cenę w OrderDetails
                UPDATE OrderDetails
                SET Price = Price + @ConvertedStudiesPrice
                WHERE OrderID = @OrderID;
            END
            ELSE
            BEGIN
                -- Jeśli płatność tylko zaliczkowa, dodaj do dłużników
                -- Pobranie liczby spotkań związanych z przedmiotami w programie studiów

DECLARE @ClassMeetingCount INT;
SELECT @ClassMeetingCount = COUNT(\*)
FROM ClassMeeting
WHERE SubjectID IN (SELECT SubjectID FROM Subjects WHERE StudiesID = @StudiesID);

-- Oblicz cenę za jedno spotkanie
DECLARE @PricePerClassMeeting DECIMAL(18, 2);
SET @PricePerClassMeeting = @StudyPrice / @ClassMeetingCount;

-- Dodaj do dłużników każde spotkanie
INSERT INTO YetToPayClassMeetings (StudentID, ClassMeetingID, Date, Amount)
SELECT @StudentID, cm.ClassMeetingID, DATEADD(DAY, -3, cm.Data), @PricePerClassMeeting
FROM ClassMeeting cm
WHERE cm.SubjectID IN (SELECT SubjectID FROM Subjects WHERE StudiesID = @StudiesID);
END
END
-- Zapisz studenta na webinar z koszyka (jeśli jest)
IF EXISTS (SELECT 1 FROM WebinarOrder WHERE OrderID = @OrderID)
BEGIN
-- Zapisz studenta na webinar z koszyka
IF NOT EXISTS (SELECT 1 FROM WebinarxStudents WHERE StudentID = @StudentID AND WebinarID IN (SELECT WebinarID FROM WebinarOrder WHERE OrderID = @OrderID))
BEGIN
INSERT INTO WebinarxStudents (WebinarID, StudentID)
SELECT WebinarID, @StudentID
FROM WebinarOrder
WHERE OrderID = @OrderID;
END
ELSE
BEGIN
RAISERROR('Student jest już zapisany na ten webinar.', 16, 1);
END
END

        -- Zapisz studenta na spotkanie z kursu z koszyka (jeśli jest)
        IF EXISTS (SELECT 1 FROM ClassMeetingOrder WHERE OrderID = @OrderID)
        BEGIN

            SELECT @ClassMeetingID = ClassMeetingID
            FROM ClassMeetingOrder
            WHERE OrderID = @OrderID;

            -- Sprawdź dostępność miejsc na spotkaniu
            IF dbo.CanEnrollToClassMeeting(@StudentID, @ClassMeetingID) = 0
            BEGIN
                RAISERROR('Brak miejsc na spotkaniu.', 16, 1);
                ROLLBACK TRANSACTION;
                RETURN;
            END
    		-- Sprawdź, czy student jest już zapisany na spotkanie
    IF EXISTS (SELECT 1 FROM StudyMeetingAttendence WHERE StudentID = @StudentID AND ClassMeetingID = @ClassMeetingID)
    BEGIN
        RAISERROR('Student jest już zapisany na to spotkanie.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END

            -- Zapisz studenta na spotkanie
            INSERT INTO StudyMeetingAttendence(ClassMeetingID, StudentID, Presence)
            VALUES (@ClassMeetingID, @StudentID,0);
        END

        -- Zaktualizuj status zamówienia na zakończony
        UPDATE OrderStatus
        SET IsActive = 0
        WHERE OrderID = @OrderID;

        -- Zakończ transakcję
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        -- Obsługa błędów
        ROLLBACK TRANSACTION;
        RAISERROR('Wystąpił błąd podczas przetwarzania zamówienia.', 16, 1);
    END CATCH

END;
GO

--14.Procedura usuwająca studenta ze spotkania studyjnego

CREATE PROCEDURE [dbo].[UnenrollStudentFromClassMeeting]
@StudentID INT,
@ClassMeetingID INT
AS
BEGIN
-- Sprawdzenie, czy student jest zapisany na dane zajęcia
DECLARE @IsRegistered INT;
SELECT @IsRegistered = COUNT(\*)
FROM StudyMeetingAttendence
WHERE StudentID = @StudentID AND ClassMeetingID = @ClassMeetingID;

    -- Jeśli student nie jest zapisany na te zajęcia, zwróć komunikat
    IF @IsRegistered = 0
    BEGIN
        PRINT 'Student nie jest zapisany na te zajęcia.';
        RETURN;
    END
    -- Usunięcie zapisu studenta z ClassMeetingAttendance
    DELETE FROM StudyMeetingAttendence
    WHERE StudentID = @StudentID AND ClassMeetingID = @ClassMeetingID;

END;
GO

USE [u_wkostka]
GO

--15.Procedura usuwająca studenta z kursu

CREATE PROCEDURE [dbo].[UnenrollStudentFromCourse]
(
@StudentID INT, -- ID studenta
@CourseID INT -- ID kursu
)
AS
BEGIN
BEGIN TRY
BEGIN TRANSACTION;

        -- Sprawdzenie, czy kurs istnieje
        IF NOT EXISTS (SELECT 1 FROM Courses WHERE CourseID = @CourseID)
        BEGIN
            RAISERROR('CourseID does not exist.', 16, 1);
            RETURN;
        END

        -- Sprawdzenie, czy student jest zapisany na spotkania związane z tym kursem
        DECLARE @IsEnrolled BIT;
        SET @IsEnrolled = dbo.CheckStudentEnrollmentForItem(@StudentID, @CourseID, 'Course');

        IF @IsEnrolled = 0
        BEGIN
            RAISERROR('Student is not enrolled in this course.', 16, 1);
            RETURN;
        END

        -- Usunięcie studenta z wszystkich spotkań związanych z tym kursem
        DELETE FROM CourseMeetingAttendence
        WHERE StudentID = @StudentID
        AND CourseMeetingID IN (
            SELECT CourseMeetingID
            FROM CourseMeeting
            WHERE CourseID = @CourseID
        );

        -- Komunikat informujący o sukcesie
        PRINT 'Student unenrolled successfully.';

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        -- Obsługa błędów
        ROLLBACK TRANSACTION;
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH

END;
GO

--16.Procedura usuwająca studenta z programu studiów

CREATE PROCEDURE [dbo].[UnregisterStudentFromStudies] (
@StudentID INT, -- ID studenta
@StudiesID INT -- ID studiów
)
AS
BEGIN
-- Rozpocznij transakcję
BEGIN TRY
BEGIN TRANSACTION;

        -- Sprawdź, czy student jest zapisany na dany program studiów
        IF NOT EXISTS (SELECT 1 FROM SendingDiploma WHERE StudentID = @StudentID AND StudiesID = @StudiesID)
        BEGIN
            PRINT 'Student nie jest zapisany na te studia.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Usuń studenta ze wszystkich przedmiotów związanych z tym programem studiów
        DECLARE @SubjectID INT;

        DECLARE subject_cursor CURSOR FOR
        SELECT SubjectID
        FROM Subjects
        WHERE StudiesID = @StudiesID;

        OPEN subject_cursor;
        FETCH NEXT FROM subject_cursor INTO @SubjectID;

        -- Usuwanie studenta z każdego przedmiotu
        WHILE @@FETCH_STATUS = 0
        BEGIN
            -- Wywołaj procedurę usuwającą studenta z przedmiotu
            EXEC UnregisterStudentFromSubject @SubjectID, @StudentID;

            FETCH NEXT FROM subject_cursor INTO @SubjectID;
        END

        CLOSE subject_cursor;
        DEALLOCATE subject_cursor;

        PRINT 'Student został usunięty ze wszystkich przedmiotów z programu studiów.';

        -- Usuń studenta z programu studiów w tabeli SendingDiploma
        DELETE FROM SendingDiploma
        WHERE StudentID = @StudentID AND StudiesID = @StudiesID;

        PRINT 'Student został usunięty z programu studiów.';

        -- Zatwierdź transakcję, jeśli wszystkie operacje się powiodły
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        -- W przypadku błędu wycofaj transakcję
        PRINT 'Wystąpił błąd, cofnięcie zmian.';
        ROLLBACK TRANSACTION;
    END CATCH

END;
GO

--17.Procedura usuwająca studenta z przedmiotu

CREATE PROCEDURE [dbo].[UnregisterStudentFromSubject] (
@StudentID INT,
@SubjectID INT
)
AS
BEGIN
-- Rozpocznij transakcję
BEGIN TRY
BEGIN TRANSACTION;

        -- Sprawdź, czy student jest już zapisany na ten przedmiot
        DECLARE @AlreadyRegistered INT;
        SELECT @AlreadyRegistered = COUNT(*)
        FROM SubjectStatus
        WHERE StudentID = @StudentID AND SubjectID = @SubjectID;

        IF @AlreadyRegistered = 0
        BEGIN
            PRINT 'Student nie jest zapisany na ten przedmiot.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Wypisanie studenta z przedmiotu
        DELETE FROM SubjectStatus
        WHERE StudentID = @StudentID AND SubjectID = @SubjectID;
        PRINT 'Student został wypisany z przedmiotu.';

        -- Wypisanie studenta ze wszystkich zajęć związanych z tym przedmiotem

        -- Dla spotkań klasowych (ClassMeeting)
        DECLARE @ClassMeetingID INT;
        DECLARE class_meeting_cursor CURSOR FOR
        SELECT ClassMeetingID
        FROM ClassMeeting
        WHERE SubjectID = @SubjectID;

        OPEN class_meeting_cursor;
        FETCH NEXT FROM class_meeting_cursor INTO @ClassMeetingID;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            -- Wywołanie procedury wypisywania studenta z ClassMeeting
            EXEC dbo.UnregisterStudentFromClassMeeting @StudentID, @ClassMeetingID;

            -- Jeśli wypisywanie z spotkania się nie powiedzie, wycofaj transakcję
            IF @@ERROR <> 0
            BEGIN
                PRINT 'Błąd podczas wypisywania ze spotkania. Cofam wszystkie zmiany.';
                ROLLBACK TRANSACTION;
                CLOSE class_meeting_cursor;
                DEALLOCATE class_meeting_cursor;
                RETURN;
            END
            FETCH NEXT FROM class_meeting_cursor INTO @ClassMeetingID;
        END

        CLOSE class_meeting_cursor;
        DEALLOCATE class_meeting_cursor;

        -- Zatwierdź transakcję, jeśli wszystko przebiegło pomyślnie
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        -- W przypadku błędu, wycofaj transakcję
        PRINT 'Wystąpił błąd, cofnięcie zmian.';
        ROLLBACK TRANSACTION;
    END CATCH

END;
GO

--18.Procedura zmieniająca status faktury dla zamówienia, czy student chce fakturę

CREATE PROCEDURE [dbo].[UpdateInvoiceStatus]
(
@OrderID INT, -- Identifikator zamówienia
@WantInvoice BIT -- 1 jeśli chce fakturę, 0 jeśli nie chce
)
AS
BEGIN
BEGIN TRY
BEGIN TRANSACTION;

        -- Sprawdzenie, czy zamówienie istnieje w tabeli OrderDetails
        IF EXISTS (SELECT 1 FROM OrderDetails WHERE OrderID = @OrderID)
        BEGIN
            -- Aktualizacja statusu faktury w tabeli OrderDetails
            UPDATE OrderDetails
            SET Invoice = @WantInvoice
            WHERE OrderID = @OrderID;

            -- Komunikat, że operacja zakończona sukcesem
            PRINT 'Invoice status updated successfully.';
        END
        ELSE
        BEGIN
            -- Błąd, jeśli zamówienie nie istnieje
            RAISERROR('OrderID does not exist.', 16, 1);
        END

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        -- Obsługa błędów
        ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH

END;
GO
