# INDEKSY



## Przy tworzeniu tabel klucze główne automatycznie się dla nich utworzyły, dodaliśmy ręcznie indeksy w kluczach obcych tabel




CREATE INDEX ClassMeeting_SubjectID ON ClassMeeting (SubjectID);

CREATE INDEX ClassMeeting_TranslatorID ON ClassMeeting (TranslatorID);

CREATE INDEX ClassMeetingOrder_OrderID ON ClassMeetingOrder (OrderID);

CREATE INDEX CourseMeeting_CourseID ON CourseMeeting (CourseID);

CREATE INDEX CourseMeeting_TranslatorID ON CourseMeeting (TranslatorID);

CREATE INDEX CourseMeeting_TeacherID ON CourseMeeting (TeacherID);

CREATE INDEX CourseOrder_CourseID ON CourseOrder (CourseID);

CREATE INDEX Courses_Language ON Courses (Language);

CREATE INDEX OrderDetails_Vat ON OrderDetails (Vat);

CREATE INDEX OrderDetails_CurrenciesID ON OrderDetails (CurrenciesID);

CREATE INDEX OrderDetails_ChangeDate ON OrderDetails (ChangeDate);

CREATE INDEX Orders_StudentID ON Orders (StudentID);

CREATE INDEX PossibleInterships_StudiesID ON PossibleInterships (StudiesID);

CREATE INDEX RODO_StudentID ON RODO (StudentID);

CREATE INDEX RODO_TeacherID ON RODO (TeacherID);

CREATE INDEX RODO_TranslatorID ON RODO (TranslatorID);

CREATE INDEX SendingDiploma_StudiesID ON SendingDiploma (StudiesID);

CREATE INDEX StudiesOrder_StudiesID ON StudiesOrder (StudiesID);

CREATE INDEX Subjects_StudiesID ON Subjects (StudiesID);

CREATE INDEX Subjects_Language ON Subjects (Language);

CREATE INDEX Subjects_TranslatorID ON Subjects (TranslatorID);

CREATE INDEX Subjects_TeacherID ON Subjects (TeacherID);

CREATE INDEX TeacherChanges_TeacherID ON TeacherChanges (TeacherID);

CREATE INDEX WebinarOrder_WebinarID ON WebinarOrder (WebinarID);

CREATE INDEX Webinars_Language ON Webinars (Language);

CREATE INDEX Webinars_TranslatorID ON Webinars (TranslatorID);

CREATE INDEX Webinars_TeacherID ON Webinars (TeacherID);
