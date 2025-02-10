# USERS

## Dyrektor

Dyrektor moze odraczac płatnosci oraz dodawac/usuwac nowe osoby.

create role director authorization dbo

grant delete, insert, select on dbo.Students to director

grant delete, insert, select on dbo.Studies to director

grant delete, insert, select on dbo.Teachers to director

grant delete, insert, select on dbo.Translators to director

grant delete, insert, select on dbo.YetToPayClassMeetings to director

grant delete, insert, select on dbo.YetToPayCourses to director

## Admin

Admin zarzadza całą baza danych, dodatkowo uzywa procedur do łatwego dodawania lub usuwania elementow bazy

create role admin authorization dbo;

grant alter, control on schema :: dbo to admin;

grant execute on dbo.AddNewCourse to admin;

grant execute on dbo.CanEnrollStudentToClassMeeting to admin;

grant execute on dbo.CanEnrollStudentToCourse to admin;

grant execute on dbo.CanEnrollStudentToStudy to admin;

grant execute on dbo.CanEnrollStudentToSubject to admin;

grant execute on dbo.CheckStudentEnrollmentForItem to admin;

grant execute on dbo.DeleteStudent to admin;

grant execute on dbo.EnrollStudentToCourse to admin;

grant execute on dbo.RegisterForInternship to admin;

grant execute on dbo.RegisterStudent to admin;

grant execute on dbo.RegisterStudentToClassMeeting to admin;

grant execute on dbo.RegisterStudentToStudies to admin;

grant execute on dbo.RegisterStudentToWebinar to admin;

grant execute on dbo.UnenrollStudentFromClassMeeting to admin;

grant execute on dbo.UnenrollStudentFromCourse to admin;

grant execute on dbo.UnregisterStudentFromStudies to admin;

grant execute on dbo.UnregisterStudentFromSubject to admin;

## Ksiegowy

Ksiegowy moze generowac liste historii zamowien, dodawac nowe waluty oraz generowac liste osob zalegajacych z wpłatą

create role ksiegowy authorization dbo;

grant insert, select on dbo.Currencies to ksiegowy;

grant select on dbo.Orders to ksiegowy;

grant select on dbo.YetToPayClassMeetings to ksiegowy;

grant select on dbo.YetToPayCourses to ksiegowy;

grant execute on dbo.ConvertPriceToCurrency to ksiegowy;

## Nauczyciel

Nauczyciel moze sprawdzac oraz wpisywac obecnosc na zajeciach i ustawiac nowe spotaknie.

create role nauczyciel authorization dbo;

grant delete, insert, select on dbo.ClassMeeting to nauczyciel;

grant select on dbo.Students to nauczyciel;

grant insert, select on dbo.ClassAttendenceDetails to nauczyciel;

grant execute on dbo.MarkClassAttendance to nauczyciel;

grant execute on dbo.MarkCourseAttendance to nauczyciel;

## Customer

Klient moze przegladac dostepna oferte oraz dodawac, sprawdzac jak i zatwierdzac produkty w koszyku

create role customer authorization dbo;

grant select on dbo.ClassMeeting to customer;

grant select on dbo.Courses to customer;

grant select on dbo.Studies to customer;

grant select on dbo.Webinars to customer;

grant execute on dbo.AddItemToCart to customer;

grant execute on dbo.CheckItemInCart to customer;

grant execute on dbo.CompleteOrder to customer;

## Studentt

Student moze sprawdzac swoja obecnosc na zajeciach, sprawdzac nastepne zajecia oraz kupowac nowe przedmioty

create role studentt authorization dbo;

grant select on dbo.ClassMeeting to studentt;

grant select on dbo.Courses to studentt;

grant select on dbo.Studies to studentt;

grant select on dbo.Webinars to studentt;

grant select on dbo.ClassAttendenceDetails to studentt;

grant execute on dbo.AddItemToCart to studentt;

grant execute on dbo.CheckItemInCart to studentt;
