-- Created by Vertabelo (http://vertabelo.com)
-- Last modification date: 2024-12-10 14:31:25.354

-- tables
-- Table: ClassMeeting
CREATE TABLE ClassMeeting (
    ClassMeetingID varchar(15)  NOT NULL,
    SubjectID int  NOT NULL,
    Date date  NOT NULL,
    Duration time(0)  NOT NULL CHECK (Duration >0),
    TranslatorID int  NOT NULL,
    Price money  NOT NULL CHECK (Price >=0),
    CONSTRAINT  CHECK (),
    CONSTRAINT ClassMeeting_pk PRIMARY KEY  (ClassMeetingID)
);

-- Table: ClassMeetingOrder
CREATE TABLE ClassMeetingOrder (
    OrderID int  NOT NULL,
    ClassMeetingID varchar(15)  NOT NULL,
    CONSTRAINT ClassMeetingOrder_pk PRIMARY KEY  (OrderID)
);

-- Table: CourseMeeting
CREATE TABLE CourseMeeting (
    CourseMeetingID int  NOT NULL,
    CourseID int  NOT NULL,
    TeacherID int  NOT NULL,
    TranslatorID int  NOT NULL,
    Duration time(0)  NOT NULL,
    CONSTRAINT CourseMeeting_pk PRIMARY KEY  (CourseMeetingID)
);

-- Table: CourseMeetingAttendence
CREATE TABLE CourseMeetingAttendence (
    CourseMeetingID int  NOT NULL,
    StudentID int  NOT NULL,
    Presence binary(1)  NOT NULL,
    CONSTRAINT CourseMeetingAttendence_pk PRIMARY KEY  (CourseMeetingID)
);

-- Table: CourseOrder
CREATE TABLE CourseOrder (
    OrderID int  NOT NULL,
    CourseID int  NOT NULL,
    CONSTRAINT CourseOrder_pk PRIMARY KEY  (OrderID)
);

-- Table: Courses
CREATE TABLE Courses (
    CourseID int  NOT NULL,
    Name varchar(100)  NOT NULL,
    Language int  NOT NULL,
    Price int  NOT NULL,
    Description varchar(100)  NOT NULL,
    Date datetime  NOT NULL,
    CONSTRAINT Courses_pk PRIMARY KEY  (CourseID)
);

-- Table: Currencies
CREATE TABLE Currencies (
    CurrenciesID int  NOT NULL,
    CurrencyName int  NOT NULL,
    ExchangeRate float(4)  NOT NULL,
    ChangeDate date  NOT NULL,
    CONSTRAINT Currencies_pk PRIMARY KEY  (CurrenciesID)
);

-- Table: HistoryOfPriceCourses
CREATE TABLE HistoryOfPriceCourses (
    ChangeDate date  NOT NULL,
    CourseID int  NOT NULL,
    Price money  NOT NULL CHECK (Price >=0),
    CONSTRAINT HistoryOfPriceCourses_pk PRIMARY KEY  (ChangeDate)
);

-- Table: HistoryOfPriceStudies
CREATE TABLE HistoryOfPriceStudies (
    ChangeDate date  NOT NULL,
    StudiesID int  NOT NULL,
    Price money  NOT NULL CHECK (Price >=0),
    CONSTRAINT HistoryOfPriceStudies_pk PRIMARY KEY  (ChangeDate)
);

-- Table: HistoryOfPriceWebinars
CREATE TABLE HistoryOfPriceWebinars (
    ChangeDate date  NOT NULL,
    WebinarID int  NOT NULL,
    Price money  NOT NULL CHECK (Price >=0),
    CONSTRAINT HistoryOfPriceWebinars_pk PRIMARY KEY  (ChangeDate)
);

-- Table: IntershipxStudents
CREATE TABLE IntershipxStudents (
    IntershipID int  NOT NULL,
    StudentID int  NOT NULL,
    Passed bit  NOT NULL,
    CONSTRAINT IntershipxStudents_pk PRIMARY KEY  (IntershipID)
);

-- Table: Languages
CREATE TABLE Languages (
    LanguageID int  NOT NULL,
    LanguageName varchar(20)  NOT NULL,
    CONSTRAINT Languages_pk PRIMARY KEY  (LanguageID)
);

-- Table: OnlineAsyncMeeting
CREATE TABLE OnlineAsyncMeeting (
    ClassMeetingID int  NOT NULL,
    RecordingLink nvarchar  NOT NULL,
    CONSTRAINT OnlineAsyncMeeting_pk PRIMARY KEY  (ClassMeetingID)
);

-- Table: OnlineSyncMeeting
CREATE TABLE OnlineSyncMeeting (
    ClassMeetingID int  NOT NULL,
    OnlinePlatform nvarchar  NOT NULL,
    LiveMeetingLink nvarchar  NOT NULL,
    RecordingLink nvarchar  NOT NULL,
    CONSTRAINT OnlineSyncMeeting_pk PRIMARY KEY  (ClassMeetingID)
);

-- Table: OrderDetails
CREATE TABLE OrderDetails (
    OrderID int  NOT NULL,
    PaymentStatus binary(2)  NOT NULL,
    Price money  NOT NULL CHECK (Price >=0),
    CurrenciesID int  NOT NULL,
    Invoice binary(1)  NOT NULL,
    Vat date  NOT NULL,
    CONSTRAINT OrderDetails_pk PRIMARY KEY  (OrderID)
);

-- Table: OrderStatus
CREATE TABLE OrderStatus (
    OrderID int  NOT NULL,
    IsActive binary(2)  NOT NULL,
    CONSTRAINT OrderStatus_pk PRIMARY KEY  (OrderID)
);

-- Table: Orders
CREATE TABLE Orders (
    OrderID int  NOT NULL,
    StudentID int  NOT NULL,
    PaymentLink nvarchar  NOT NULL,
    OrderDate date  NOT NULL,
    CONSTRAINT Orders_pk PRIMARY KEY  (OrderID)
);

-- Table: PossibleInterships
CREATE TABLE PossibleInterships (
    IntershipID int  NOT NULL,
    StudiesID int  NOT NULL,
    CONSTRAINT PossibleInterships_pk PRIMARY KEY  (IntershipID)
);

-- Table: RODO
CREATE TABLE RODO (
    RODO_ID int  NOT NULL,
    StudentID int  NULL,
    TeacherID int  NULL,
    TranslatorID int  NULL,
    Approved binary(1)  NOT NULL,
    Date date  NOT NULL,
    CONSTRAINT RODO_pk PRIMARY KEY  (RODO_ID)
);

-- Table: SendingDiploma
CREATE TABLE SendingDiploma (
    StudiesID int  NOT NULL,
    StudentID int  NOT NULL,
    PassingStatus binary(2)  NOT NULL,
    Address varchar(100)  NOT NULL,
    CONSTRAINT SendingDiploma_pk PRIMARY KEY  (StudiesID)
);

-- Table: StationaryMeeting
CREATE TABLE StationaryMeeting (
    ClassMeetingID int  NOT NULL,
    Place nvarchar  NOT NULL,
    PeopleLimit int  NOT NULL,
    CONSTRAINT StationaryMeeting_pk PRIMARY KEY  (ClassMeetingID)
);

-- Table: Students
CREATE TABLE Students (
    StudentID int  NOT NULL,
    FirstName varchar(50)  NOT NULL,
    LastName varchar(50)  NOT NULL,
    Address varchar(100)  NOT NULL,
    PESEL int  NOT NULL,
    Email varchar(30)  NOT NULL,
    CONSTRAINT Students_pk PRIMARY KEY  (StudentID)
);

-- Table: Studies
CREATE TABLE Studies (
    StudiesID int  NOT NULL,
    Name varchar(100)  NOT NULL,
    Description varchar(100)  NOT NULL,
    Price money  NOT NULL CHECK (Price >=0),
    SpaceLimit int  NOT NULL CHECK (SpaceLimit >0),
    CONSTRAINT Studies_pk PRIMARY KEY  (StudiesID)
);

-- Table: StudiesOrder
CREATE TABLE StudiesOrder (
    StudiesID int  NOT NULL,
    OrderID int  NOT NULL,
    CONSTRAINT StudiesOrder_pk PRIMARY KEY  (OrderID)
);

-- Table: StudyMeetingAttendence
CREATE TABLE StudyMeetingAttendence (
    ClassMeetingID int  NOT NULL,
    StudentID int  NOT NULL,
    Presence binary(1)  NOT NULL,
    CONSTRAINT StudyMeetingAttendence_pk PRIMARY KEY  (ClassMeetingID)
);

-- Table: SubjectStatus
CREATE TABLE SubjectStatus (
    SubjectID int  NOT NULL,
    StudentID int  NOT NULL,
    PassingStatus binary(2)  NOT NULL,
    StudentGrade int  NOT NULL,
    CONSTRAINT SubjectStatus_pk PRIMARY KEY  (SubjectID)
);

-- Table: Subjects
CREATE TABLE Subjects (
    SubjectID int  NOT NULL,
    Name varchar(55)  NOT NULL,
    Studies int  NOT NULL,
    Language int  NOT NULL,
    Description varchar(100)  NOT NULL,
    Teacher int  NOT NULL,
    SpaceLimit int  NOT NULL CHECK (SpaceLimit >0),
    CONSTRAINT Subjects_pk PRIMARY KEY  (SubjectID)
);

-- Table: Teachers
CREATE TABLE Teachers (
    TeacherID int  NOT NULL,
    FirstName varchar(50)  NOT NULL,
    LastName varchar(50)  NOT NULL,
    Phone varchar(15)  NOT NULL,
    Email varchar(50)  NOT NULL,
    CONSTRAINT Teachers_pk PRIMARY KEY  (TeacherID)
);

-- Table: Translators
CREATE TABLE Translators (
    TranslatorID int  NOT NULL,
    FirstName varchar(20)  NOT NULL,
    LastName varchar(20)  NOT NULL,
    Phone varchar(15)  NOT NULL,
    Email varchar(50)  NOT NULL,
    CONSTRAINT Translators_pk PRIMARY KEY  (TranslatorID)
);

-- Table: TranslatorsxLanguage
CREATE TABLE TranslatorsxLanguage (
    LanguageID int  NOT NULL,
    TranslatorID int  NOT NULL,
    CONSTRAINT TranslatorsxLanguage_pk PRIMARY KEY  (LanguageID,TranslatorID)
);

-- Table: VAT
CREATE TABLE VAT (
    VatChangeDate date  NOT NULL,
    VatChange float(2)  NOT NULL,
    CONSTRAINT VAT_pk PRIMARY KEY  (VatChangeDate)
);

-- Table: WebinarOrder
CREATE TABLE WebinarOrder (
    OrderID int  NOT NULL,
    WebinarID int  NOT NULL,
    CONSTRAINT WebinarOrder_pk PRIMARY KEY  (OrderID)
);

-- Table: Webinars
CREATE TABLE Webinars (
    WebinarID int  NOT NULL,
    Name varchar(100)  NOT NULL,
    Date datetime  NOT NULL,
    Language int  NOT NULL,
    Description varchar(100)  NOT NULL,
    Teacher int  NOT NULL,
    TranslatorID int  NOT NULL,
    VideoLink varchar(100)  NOT NULL,
    CONSTRAINT Webinars_pk PRIMARY KEY  (WebinarID)
);

-- foreign keys
-- Reference: Attendence_Class (table: StudyMeetingAttendence)
ALTER TABLE StudyMeetingAttendence ADD CONSTRAINT Attendence_Class
    FOREIGN KEY (ClassMeetingID)
    REFERENCES ClassMeeting (ClassMeetingID);

-- Reference: Attendence_Students (table: StudyMeetingAttendence)
ALTER TABLE StudyMeetingAttendence ADD CONSTRAINT Attendence_Students
    FOREIGN KEY (StudentID)
    REFERENCES Students (StudentID);

-- Reference: ClassMeetingOrder_ClassMeeting (table: ClassMeetingOrder)
ALTER TABLE ClassMeetingOrder ADD CONSTRAINT ClassMeetingOrder_ClassMeeting
    FOREIGN KEY (ClassMeetingID)
    REFERENCES ClassMeeting (ClassMeetingID);

-- Reference: ClassMeeting_OnlineAsyncMeeting (table: ClassMeeting)
ALTER TABLE ClassMeeting ADD CONSTRAINT ClassMeeting_OnlineAsyncMeeting
    FOREIGN KEY (<EMPTY>)
    REFERENCES OnlineAsyncMeeting (ClassMeetingID);

-- Reference: ClassMeeting_OnlineSyncMeeting (table: ClassMeeting)
ALTER TABLE ClassMeeting ADD CONSTRAINT ClassMeeting_OnlineSyncMeeting
    FOREIGN KEY (<EMPTY>)
    REFERENCES OnlineSyncMeeting (ClassMeetingID);

-- Reference: ClassMeeting_StationaryMeeting (table: ClassMeeting)
ALTER TABLE ClassMeeting ADD CONSTRAINT ClassMeeting_StationaryMeeting
    FOREIGN KEY (<EMPTY>)
    REFERENCES StationaryMeeting (ClassMeetingID);

-- Reference: ClassMeeting_Subjects (table: ClassMeeting)
ALTER TABLE ClassMeeting ADD CONSTRAINT ClassMeeting_Subjects
    FOREIGN KEY (SubjectID)
    REFERENCES Subjects (SubjectID);

-- Reference: ClassMeeting_Translators (table: ClassMeeting)
ALTER TABLE ClassMeeting ADD CONSTRAINT ClassMeeting_Translators
    FOREIGN KEY (TranslatorID)
    REFERENCES Translators (TranslatorID);

-- Reference: CourseMeeting_CourseMeetingAttendence (table: CourseMeeting)
ALTER TABLE CourseMeeting ADD CONSTRAINT CourseMeeting_CourseMeetingAttendence
    FOREIGN KEY (CourseMeetingID)
    REFERENCES CourseMeetingAttendence (CourseMeetingID);

-- Reference: CourseMeeting_Teachers (table: CourseMeeting)
ALTER TABLE CourseMeeting ADD CONSTRAINT CourseMeeting_Teachers
    FOREIGN KEY (TeacherID)
    REFERENCES Teachers (TeacherID);

-- Reference: CourseMeeting_Translators (table: CourseMeeting)
ALTER TABLE CourseMeeting ADD CONSTRAINT CourseMeeting_Translators
    FOREIGN KEY (TranslatorID)
    REFERENCES Translators (TranslatorID);

-- Reference: Courses_CourseMeeting (table: Courses)
ALTER TABLE Courses ADD CONSTRAINT Courses_CourseMeeting
    FOREIGN KEY (CourseID)
    REFERENCES CourseMeeting (CourseID);

-- Reference: Courses_CourseOrder (table: Courses)
ALTER TABLE Courses ADD CONSTRAINT Courses_CourseOrder
    FOREIGN KEY ()
    REFERENCES CourseOrder ();

-- Reference: Courses_Languages (table: Courses)
ALTER TABLE Courses ADD CONSTRAINT Courses_Languages
    FOREIGN KEY (Language)
    REFERENCES Languages (LanguageID);

-- Reference: HistoryOfPriceCourses_Courses (table: HistoryOfPriceCourses)
ALTER TABLE HistoryOfPriceCourses ADD CONSTRAINT HistoryOfPriceCourses_Courses
    FOREIGN KEY (CourseID)
    REFERENCES Courses (CourseID);

-- Reference: HistoryOfPriceStudies_Studies (table: HistoryOfPriceStudies)
ALTER TABLE HistoryOfPriceStudies ADD CONSTRAINT HistoryOfPriceStudies_Studies
    FOREIGN KEY (StudiesID)
    REFERENCES Studies (StudiesID);

-- Reference: HistoryOfPriceWebinars_Webinars (table: HistoryOfPriceWebinars)
ALTER TABLE HistoryOfPriceWebinars ADD CONSTRAINT HistoryOfPriceWebinars_Webinars
    FOREIGN KEY (WebinarID)
    REFERENCES Webinars (WebinarID);

-- Reference: Intership_Studies (table: PossibleInterships)
ALTER TABLE PossibleInterships ADD CONSTRAINT Intership_Studies
    FOREIGN KEY (StudiesID)
    REFERENCES Studies (StudiesID);

-- Reference: IntershipxStudents_PossibleInterships (table: IntershipxStudents)
ALTER TABLE IntershipxStudents ADD CONSTRAINT IntershipxStudents_PossibleInterships
    FOREIGN KEY (IntershipID)
    REFERENCES PossibleInterships (IntershipID);

-- Reference: IntershipxStudents_Students (table: IntershipxStudents)
ALTER TABLE IntershipxStudents ADD CONSTRAINT IntershipxStudents_Students
    FOREIGN KEY (StudentID)
    REFERENCES Students (StudentID);

-- Reference: OrderDetails_ClassMeetingOrder (table: OrderDetails)
ALTER TABLE OrderDetails ADD CONSTRAINT OrderDetails_ClassMeetingOrder
    FOREIGN KEY (OrderID)
    REFERENCES ClassMeetingOrder (OrderID);

-- Reference: OrderDetails_CourseOrder (table: OrderDetails)
ALTER TABLE OrderDetails ADD CONSTRAINT OrderDetails_CourseOrder
    FOREIGN KEY (OrderID)
    REFERENCES CourseOrder (OrderID);

-- Reference: OrderDetails_Currencies (table: OrderDetails)
ALTER TABLE OrderDetails ADD CONSTRAINT OrderDetails_Currencies
    FOREIGN KEY (CurrenciesID)
    REFERENCES Currencies (CurrenciesID);

-- Reference: OrderDetails_StudiesOrder (table: OrderDetails)
ALTER TABLE OrderDetails ADD CONSTRAINT OrderDetails_StudiesOrder
    FOREIGN KEY (OrderID)
    REFERENCES StudiesOrder (OrderID);

-- Reference: OrderDetails_VAT (table: OrderDetails)
ALTER TABLE OrderDetails ADD CONSTRAINT OrderDetails_VAT
    FOREIGN KEY (Vat)
    REFERENCES VAT (VatChangeDate);

-- Reference: OrderDetails_WebinarOrder (table: OrderDetails)
ALTER TABLE OrderDetails ADD CONSTRAINT OrderDetails_WebinarOrder
    FOREIGN KEY ()
    REFERENCES WebinarOrder ();

-- Reference: Orders_OrderDetails (table: Orders)
ALTER TABLE Orders ADD CONSTRAINT Orders_OrderDetails
    FOREIGN KEY ()
    REFERENCES OrderDetails ();

-- Reference: Orders_OrderStatus (table: Orders)
ALTER TABLE Orders ADD CONSTRAINT Orders_OrderStatus
    FOREIGN KEY (<EMPTY>)
    REFERENCES OrderStatus (OrderID);

-- Reference: RODO_Students (table: RODO)
ALTER TABLE RODO ADD CONSTRAINT RODO_Students
    FOREIGN KEY (StudentID)
    REFERENCES Students (StudentID);

-- Reference: RODO_Teachers (table: RODO)
ALTER TABLE RODO ADD CONSTRAINT RODO_Teachers
    FOREIGN KEY (TeacherID)
    REFERENCES Teachers (TeacherID);

-- Reference: RODO_Translators (table: RODO)
ALTER TABLE RODO ADD CONSTRAINT RODO_Translators
    FOREIGN KEY (TranslatorID)
    REFERENCES Translators (TranslatorID);

-- Reference: Students_CourseMeetingAttendence (table: Students)
ALTER TABLE Students ADD CONSTRAINT Students_CourseMeetingAttendence
    FOREIGN KEY (StudentID)
    REFERENCES CourseMeetingAttendence (StudentID);

-- Reference: Students_Orders (table: Students)
ALTER TABLE Students ADD CONSTRAINT Students_Orders
    FOREIGN KEY (<EMPTY>)
    REFERENCES Orders (OrderID);

-- Reference: StudiesOrder_Studies (table: StudiesOrder)
ALTER TABLE StudiesOrder ADD CONSTRAINT StudiesOrder_Studies
    FOREIGN KEY (StudiesID)
    REFERENCES Studies (StudiesID);

-- Reference: Studies_SendingDiploma (table: Studies)
ALTER TABLE Studies ADD CONSTRAINT Studies_SendingDiploma
    FOREIGN KEY ()
    REFERENCES SendingDiploma ();

-- Reference: Studies_SubjectStatus (table: Studies)
ALTER TABLE Studies ADD CONSTRAINT Studies_SubjectStatus
    FOREIGN KEY (<EMPTY>)
    REFERENCES SubjectStatus (SubjectID);

-- Reference: Studium_Subjects (table: Studies)
ALTER TABLE Studies ADD CONSTRAINT Studium_Subjects
    FOREIGN KEY (StudiesID)
    REFERENCES Subjects (Studies);

-- Reference: Subjects_Class (table: Subjects)
ALTER TABLE Subjects ADD CONSTRAINT Subjects_Class
    FOREIGN KEY (SubjectID)
    REFERENCES ClassMeeting (<EMPTY>);

-- Reference: Subjects_Languages (table: Subjects)
ALTER TABLE Subjects ADD CONSTRAINT Subjects_Languages
    FOREIGN KEY (Language)
    REFERENCES Languages (LanguageID);

-- Reference: Subjects_SubjectStatus (table: Subjects)
ALTER TABLE Subjects ADD CONSTRAINT Subjects_SubjectStatus
    FOREIGN KEY (<EMPTY>)
    REFERENCES SubjectStatus (SubjectID);

-- Reference: Subjects_Teachers (table: Subjects)
ALTER TABLE Subjects ADD CONSTRAINT Subjects_Teachers
    FOREIGN KEY (Teacher)
    REFERENCES Teachers (TeacherID);

-- Reference: Subjects_Translators (table: Subjects)
ALTER TABLE Subjects ADD CONSTRAINT Subjects_Translators
    FOREIGN KEY (<EMPTY>)
    REFERENCES Translators (TranslatorID);

-- Reference: TranslatorsxLanguage_Languages (table: TranslatorsxLanguage)
ALTER TABLE TranslatorsxLanguage ADD CONSTRAINT TranslatorsxLanguage_Languages
    FOREIGN KEY (LanguageID)
    REFERENCES Languages (LanguageID);

-- Reference: TranslatorsxLanguage_Translators (table: TranslatorsxLanguage)
ALTER TABLE TranslatorsxLanguage ADD CONSTRAINT TranslatorsxLanguage_Translators
    FOREIGN KEY (TranslatorID)
    REFERENCES Translators (TranslatorID);

-- Reference: Webinars_Languages (table: Webinars)
ALTER TABLE Webinars ADD CONSTRAINT Webinars_Languages
    FOREIGN KEY (Language)
    REFERENCES Languages (LanguageID);

-- Reference: Webinars_Teachers (table: Webinars)
ALTER TABLE Webinars ADD CONSTRAINT Webinars_Teachers
    FOREIGN KEY (Teacher)
    REFERENCES Teachers (TeacherID);

-- Reference: Webinars_Translators (table: Webinars)
ALTER TABLE Webinars ADD CONSTRAINT Webinars_Translators
    FOREIGN KEY (TranslatorID)
    REFERENCES Translators (TranslatorID);

-- Reference: Webinars_WebinarOrder (table: Webinars)
ALTER TABLE Webinars ADD CONSTRAINT Webinars_WebinarOrder
    FOREIGN KEY ()
    REFERENCES WebinarOrder ();

-- End of file.

