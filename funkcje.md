--1. Funkcja, która sprawdza, czy student może być zapisany na spotkanie klasowe. Funkcja przyjmuje dwa parametry: ID studenta oraz ID spotkania klasowego.
-- Funkcja zwraca 1, jeśli student może być zapisany na spotkanie, 0 w przeciwnym wypadku.
--Funkcja powinna sprawdzać, czy student nie jest już zapisany na to spotkanie oraz czy są dostępne miejsca, jeśli spotkanie jest stacjonarne.
CREATE FUNCTION [dbo].[CanEnrollStudentToClassMeeting] (
@StudentID INT, -- ID studenta
@ClassMeetingID INT -- ID spotkania klasowego
)
RETURNS INT
AS
BEGIN
DECLARE @CanEnroll INT = 1; -- Domyślnie zakładając, że student może być zapisany

    -- Sprawdzamy, czy student już jest zapisany na to spotkanie
    IF EXISTS (SELECT 1 FROM StudyMeetingAttendence WHERE StudentID = @StudentID AND ClassMeetingID = @ClassMeetingID)
    BEGIN
        SET @CanEnroll = 0;  -- Jeśli student jest już zapisany, zwracamy 0
        RETURN @CanEnroll;
    END

    -- Sprawdzanie, czy spotkanie jest stacjonarne
    DECLARE @IsStationary BIT;
    SET @IsStationary = CASE
                            WHEN EXISTS (SELECT 1 FROM StationaryMeeting sm WHERE sm.ClassMeetingID = @ClassMeetingID)
                            THEN 1
                            ELSE 0
                        END;

    -- Jeśli spotkanie jest stacjonarne, sprawdzamy dostępność miejsc
    IF @IsStationary = 1
    BEGIN
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
            SET @CanEnroll = 0;  -- Brak dostępnych miejsc
        END
    END

    -- Zwracamy wynik (0 = nie można zapisać, 1 = można zapisać)
    RETURN @CanEnroll;

END;
GO

--2. Funkcja, która sprawdza, czy student może być zapisany na kurs. Funkcja przyjmuje dwa parametry: ID studenta oraz ID kursu.

CREATE FUNCTION [dbo].[CanEnrollStudentToCourse]
(
@StudentID INT, -- ID studenta
@CourseID INT -- ID kursu
)
RETURNS INT
AS
BEGIN
DECLARE @CanEnroll INT = 1; -- Zakładamy, że student może się zapisać na kurs
DECLARE @CourseMeetingID INT;
DECLARE @IsStationary BIT;
DECLARE @PeopleLimit INT;
DECLARE @CurrentRegistrations INT;

    -- Sprawdzanie dostępności miejsc na wszystkich spotkaniach związanych z kursem
    DECLARE course_meeting_cursor CURSOR FOR
    SELECT CourseMeetingID
    FROM CourseMeeting
    WHERE CourseID = @CourseID;

    OPEN course_meeting_cursor;
    FETCH NEXT FROM course_meeting_cursor INTO @CourseMeetingID;

    -- Iteracja po spotkaniach kursu
    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Sprawdzamy, czy spotkanie jest stacjonarne
        SELECT @IsStationary = CASE WHEN sm.CourseMeetingID IS NOT NULL THEN 1 ELSE 0 END
        FROM StationaryCourseMeeting sm
        WHERE sm.CourseMeetingID = @CourseMeetingID;

        -- Pobieramy limit osób oraz liczbę zapisanych studentów
        SELECT @PeopleLimit = sm.PeopleLimit
        FROM StationaryCourseMeeting sm
        WHERE sm.CourseMeetingID = @CourseMeetingID;

        -- Liczymy obecnych studentów na spotkaniu
        SELECT @CurrentRegistrations = COUNT(*)
        FROM CourseMeetingAttendence cma
        WHERE cma.CourseMeetingID = @CourseMeetingID;

        -- Sprawdzamy, czy są dostępne miejsca
        IF @CurrentRegistrations >= @PeopleLimit
        BEGIN
            SET @CanEnroll = 0;  -- Brak miejsc na spotkaniu
            CLOSE course_meeting_cursor;
            DEALLOCATE course_meeting_cursor;
            RETURN @CanEnroll;
        END

        FETCH NEXT FROM course_meeting_cursor INTO @CourseMeetingID;
    END

    CLOSE course_meeting_cursor;
    DEALLOCATE course_meeting_cursor;

    -- Jeśli wszystkie spotkania przeszły pomyślnie, zwróć 1 (można zapisać studenta na kurs)
    RETURN @CanEnroll;

END;
GO

--3. Funkcja, która sprawdza, czy student może być zapisany na studia. Funkcja przyjmuje dwa parametry: ID studenta oraz IDstudiów.

CREATE FUNCTION [dbo].[CanEnrollStudentToStudy]
(
@StudentID INT, -- ID studenta
@StudyID INT -- ID studiów (np. kierunku studiów)
)
RETURNS INT
AS
BEGIN
DECLARE @CanEnroll INT = 1; -- Zakładamy, że student może się zapisać na studia
DECLARE @SubjectID INT;

    -- Sprawdzanie dostępności miejsc na wszystkich przedmiotach powiązanych ze studiami
    DECLARE study_subject_cursor CURSOR FOR
    SELECT SubjectID
    FROM Subjects
    WHERE StudiesID = @StudyID;

    OPEN study_subject_cursor;
    FETCH NEXT FROM study_subject_cursor INTO @SubjectID;

    -- Iteracja po przedmiotach związanych ze studiami
    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Sprawdzamy, czy student może zapisać się na przedmiot związany ze studiami
        IF dbo.CanEnrollStudentToSubject(@StudentID, @SubjectID) = 0
        BEGIN
            SET @CanEnroll = 0;  -- Brak miejsc na przedmiocie lub spotkaniach
            CLOSE study_subject_cursor;
            DEALLOCATE study_subject_cursor;
            RETURN @CanEnroll;
        END

        FETCH NEXT FROM study_subject_cursor INTO @SubjectID;
    END

    CLOSE study_subject_cursor;
    DEALLOCATE study_subject_cursor;

    -- Jeśli wszystkie przedmioty przeszły pomyślnie, zwróć 1 (można zapisać studenta na studia)
    RETURN @CanEnroll;

END;
GO

--4. Funkcja, która sprawdza, czy student może być zapisany na przedmiot. Funkcja przyjmuje dwa parametry: ID studenta oraz ID przedmiotu.

CREATE FUNCTION [dbo].[CanEnrollStudentToSubject]
(
@StudentID INT, -- ID studenta
@SubjectID INT -- ID przedmiotu
)
RETURNS INT
AS
BEGIN
DECLARE @CanEnroll INT = 1; -- Zakładamy, że student może zostać zapisany
DECLARE @ClassMeetingID INT;
DECLARE @CurrentCount INT;
DECLARE @PeopleLimit INT;
DECLARE @SubjectLimit INT;
DECLARE @SubjectCurrentCount INT;

    -- Sprawdzanie dostępności miejsc na przedmiocie (limit miejsc na przedmiocie)
    SELECT @SubjectLimit = SpaceLimit
    FROM Subjects
    WHERE SubjectID = @SubjectID;

    -- Liczymy liczbę zapisanych studentów na dany przedmiot
    SELECT @SubjectCurrentCount = COUNT(*)
    FROM SubjectStatus
    WHERE SubjectID = @SubjectID;

    -- Sprawdzamy, czy nie przekroczono limitu miejsc na przedmiocie
    IF @SubjectCurrentCount >= @SubjectLimit
    BEGIN
        SET @CanEnroll = 0;  -- Brak miejsc na przedmiocie
        RETURN @CanEnroll;
    END

    -- Sprawdzanie dostępności miejsc na spotkaniach związanych z przedmiotem
    DECLARE class_meeting_cursor CURSOR FOR
    SELECT ClassMeetingID
    FROM ClassMeeting
    WHERE SubjectID = @SubjectID;

    OPEN class_meeting_cursor;
    FETCH NEXT FROM class_meeting_cursor INTO @ClassMeetingID;

    -- Iteracja po spotkaniach związanych z przedmiotem
    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Wywołujemy funkcję sprawdzającą, czy można zapisać studenta na dane spotkanie
        IF dbo.CanEnrollToClassMeeting(@StudentID, @ClassMeetingID) = 0
        BEGIN
            SET @CanEnroll = 0;  -- Brak miejsc na tym spotkaniu
            CLOSE class_meeting_cursor;
            DEALLOCATE class_meeting_cursor;
            RETURN @CanEnroll;
        END

        FETCH NEXT FROM class_meeting_cursor INTO @ClassMeetingID;
    END

    CLOSE class_meeting_cursor;
    DEALLOCATE class_meeting_cursor;

    -- Jeśli wszystkie sprawdzenia przeszły pomyślnie, zwróć 1 (można zapisać studenta)
    RETURN @CanEnroll;

END;

GO

--5.Funkcja, która sprawdza czy dany produkt jest w koszyku. Funkcja przyjmuje trzy parametry: ID zamówienia,
--ID produktu oraz typ produktu (Webinar, Course, Studies, ClassMeeting).

CREATE FUNCTION [dbo].[CheckItemInCart] (
@OrderID INT,
@ItemID INT,
@ItemType VARCHAR(50)
)
RETURNS BIT
AS
BEGIN
DECLARE @IsItemInCart BIT;

    -- Domyślnie zakłada się, że przedmiot nie jest w koszyku
    SET @IsItemInCart = 0;

    -- Sprawdzamy odpowiednią tabelę w zależności od typu przedmiotu
    IF @ItemType = 'Webinar'
    BEGIN
        -- Sprawdzamy, czy przedmiot (webinar) jest w koszyku
        IF EXISTS (SELECT 1 FROM WebinarOrder WHERE OrderID = @OrderID AND WebinarID = @ItemID)
        BEGIN
            SET @IsItemInCart = 1; -- Przedmiot znajduje się w koszyku
        END
    END
    ELSE IF @ItemType = 'Course'
    BEGIN
        -- Sprawdzamy, czy przedmiot (kurs) jest w koszyku
        IF EXISTS (SELECT 1 FROM CourseOrder WHERE OrderID = @OrderID AND CourseID = @ItemID)
        BEGIN
            SET @IsItemInCart = 1; -- Przedmiot znajduje się w koszyku
        END
    END
    ELSE IF @ItemType = 'Studies'
    BEGIN
        -- Sprawdzamy, czy przedmiot (studia) jest w koszyku
        IF EXISTS (SELECT 1 FROM StudiesOrder WHERE OrderID = @OrderID AND StudiesID = @ItemID)
        BEGIN
            SET @IsItemInCart = 1; -- Przedmiot znajduje się w koszyku
        END
    END
    ELSE IF @ItemType = 'ClassMeeting'
    BEGIN
        -- Sprawdzamy, czy przedmiot (spotkanie) jest w koszyku
        IF EXISTS (SELECT 1 FROM ClassMeetingOrder WHERE OrderID = @OrderID AND ClassMeetingID = @ItemID)
        BEGIN
            SET @IsItemInCart = 1; -- Przedmiot znajduje się w koszyku
        END
    END
    -- Zwracamy wynik: 1 - przedmiot w koszyku, 0 - przedmiot nie w koszyku
    RETURN @IsItemInCart;

END;
GO

--6.Funkcja, która sprawdza, czy student jest zapisany na dany produkt.
-- Funkcja przyjmuje trzy parametry: ID studenta, ID przedmiotu oraz typ przedmiotu (Webinar, Course, Studies, ClassMeeting).

CREATE FUNCTION [dbo].[CheckStudentEnrollmentForItem] (
@StudentID INT,
@ItemID INT,
@ItemType VARCHAR(50) -- Typ przedmiotu ('Webinar', 'Course', 'Studies', 'ClassMeeting')
)
RETURNS BIT
AS
BEGIN
DECLARE @IsEnrolled BIT;
SET @IsEnrolled = 0; -- Domyślnie ustawiamy, że student nie jest zapisany na dany przedmiot

    -- Sprawdzenie, czy student jest zapisany na webinar
    IF @ItemType = 'Webinar'
    BEGIN
        IF EXISTS (SELECT 1 FROM WebinarxStudents WHERE StudentID = @StudentID AND WebinarID = @ItemID)
        BEGIN
            SET @IsEnrolled = 1;  -- Student jest zapisany na webinar o danym WebinarID
        END
    END

     -- Sprawdzenie, czy student jest zapisany na kurs
    ELSE IF @ItemType = 'Course'
    BEGIN
        -- Sprawdzamy, czy student jest zapisany na wszystkie spotkania kursu
        IF NOT EXISTS (
            SELECT 1
            FROM CourseMeeting cm
            WHERE cm.CourseID = @ItemID
            AND NOT EXISTS (
                SELECT 1
                FROM CourseMeetingAttendence cma
                WHERE cma.CourseMeetingID = cm.CourseMeetingID
                AND cma.StudentID = @StudentID
            )
        )
        BEGIN
            SET @IsEnrolled = 1;  -- Student jest zapisany na wszystkie spotkania kursu
        END
    END

    -- Sprawdzenie, czy student jest zapisany na studia
    ELSE IF @ItemType = 'Studies'
    BEGIN
        IF EXISTS (SELECT 1 FROM SendingDiploma WHERE StudentID = @StudentID AND StudiesID = @ItemID)
        BEGIN
            SET @IsEnrolled = 1;  -- Student jest zapisany na studia o danym StudiesID
        END
    END

    -- Sprawdzenie, czy student jest zapisany na spotkanie studyjne
    ELSE IF @ItemType = 'ClassMeeting'
    BEGIN
        IF EXISTS (SELECT 1 FROM StudyMeetingAttendence WHERE StudentID = @StudentID AND ClassMeetingID = @ItemID)
        BEGIN
            SET @IsEnrolled = 1;  -- Student jest zapisany na spotkanie studyjne o danym ClassMeetingID
        END
    END

    -- Zwracamy wynik: 1 – student jest zapisany, 0 – student nie jest zapisany
    RETURN @IsEnrolled;

END;

GO

--7. Funkcja, która przelicza cenę produktu na inną walutę. Funkcja przyjmuje trzy parametry: cenę produktu, ID oryginalnej waluty
-- oraz ID waluty, na którą chcemy przeliczyć cenę.

CREATE FUNCTION [dbo].[ConvertPriceToCurrency] (
@Price DECIMAL(10, 2), -- Cena w oryginalnej walucie (CurrencyID1)
@CurrencyID1 INT, -- ID oryginalnej waluty (Currency 1)
@CurrencyID2 INT -- ID waluty, na którą chcemy przeliczyć (Currency 2)
)
RETURNS DECIMAL(10, 2)
AS
BEGIN
DECLARE @ExchangeRate1 DECIMAL(10, 4); -- Kurs wymiany dla CurrencyID1
DECLARE @ExchangeRate2 DECIMAL(10, 4); -- Kurs wymiany dla CurrencyID2
DECLARE @ConvertedPrice DECIMAL(10, 2); -- Obliczona cena w nowej walucie

    -- Pobranie najnowszego kursu wymiany dla CurrencyID1
    SELECT @ExchangeRate1 = ExchangeRate
    FROM Currencies
    WHERE CurrenciesID = @CurrencyID1
    AND ChangeDate = (SELECT MAX(ChangeDate) FROM Currencies WHERE CurrenciesID = @CurrencyID1);

    -- Pobranie najnowszego kursu wymiany dla CurrencyID2
    SELECT @ExchangeRate2 = ExchangeRate
    FROM Currencies
    WHERE CurrenciesID = @CurrencyID2
    AND ChangeDate = (SELECT MAX(ChangeDate) FROM Currencies WHERE CurrenciesID = @CurrencyID2);

    -- Sprawdzenie, czy kursy wymiany są dostępne
    IF @ExchangeRate1 IS NULL OR @ExchangeRate2 IS NULL
    BEGIN
        RETURN -1;
    END

    -- Obliczenie ceny w nowej walucie
    SET @ConvertedPrice = @Price * (@ExchangeRate2 / @ExchangeRate1);

    RETURN @ConvertedPrice;

END;
GO

--8. Funkcja, która zwraca aktualną cenę webinaru. Funkcja przyjmuje jeden parametr: ID webinaru.

CREATE FUNCTION [dbo].[GetCurrentWebinarPrice] (@WebinarID INT)
RETURNS DECIMAL(10, 2)
AS
BEGIN
DECLARE @CurrentPrice DECIMAL(10, 2);

    -- Pobieramy najnowszą cenę dla danego webinaru
    SELECT TOP 1 @CurrentPrice = Price
    FROM HistoryOfPriceWebinars
    WHERE WebinarID = @WebinarID
    ORDER BY ChangeDate DESC; -- Najnowsza cena (po dacie)

    RETURN @CurrentPrice;

END;
GO
