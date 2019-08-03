MODULE Squirt;

FROM System IMPORT GetArg,
                   Terminate;
FROM XIO IMPORT DispMode, BIOS,
                DispLine,
                DispLongCard,
                DispRepeat,
                DispString,
                DispChar,
                DispNL,
                InputLine;
FROM Directories IMPORT DirQuery,
                        DirEntry,
                        NORMAL;
FROM Files IMPORT Open,
                  READ,
                  Read,
                  WRITE,
                  Write,
                  Close,
                  Seek,
                  SeekMode;
FROM SYSTEM IMPORT ADR;
FROM Storage IMPORT ALLOCATE,
                    DEALLOCATE;
FROM Strings IMPORT Length,
                    Assign;
FROM XString IMPORT UpperCase;
FROM FileSpec IMPORT ExtractFileName;
FROM Bar IMPORT InitBar,
                DisplayBar,
                DisplayFullBar,
                UpdateBar;

TYPE
        pathspec = ARRAY [0..63] OF CHAR;
        patharray= ARRAY [0..1000] OF pathspec;
        arrayptr = POINTER TO patharray;
VAR
   OutputDevice,
   InputFiles : pathspec;
   Flag   : BOOLEAN;
   ArgLength: CARDINAL;
   Filecnt,x : CARDINAL;
   FileArray : arrayptr;

PROCEDURE CopyToDevice( FileToSquirt : pathspec);
CONST
     longcardwidth = 7;
     arraysize = 1024;
     CantOpen = -1;

TYPE
        Buff = ARRAY [0..arraysize] OF CHAR;
        pBuff= POINTER TO Buff;

VAR
   InputFileNumber,
   OutputFileNumber     : INTEGER;
   IOBuffer             : pBuff; (* ARRAY [0..arraysize] OF CHAR; *)
   NameLen,
   ReadWriteCount       : CARDINAL;
   FileLen,
   BytesSquirted     : LONGCARD;
   displayname          : ARRAY [0..11] OF CHAR;

BEGIN
     NEW(IOBuffer);
     BytesSquirted := 0L;
     FileLen := 0L;
     Flag := TRUE;
     Open(InputFileNumber,FileToSquirt,READ);
     Seek(InputFileNumber,SEEKEND,FileLen);
     Seek(InputFileNumber,SEEKABS,BytesSquirted);
     IF InputFileNumber = CantOpen THEN
        DispString("Could not open ");
        DispString(FileToSquirt);
        DispNL;
        RETURN
     END;
     Open(OutputFileNumber,OutputDevice,WRITE);
     IF OutputFileNumber = CantOpen THEN
        DispString("Could not open ");
        DispString(OutputDevice);
        DispString(" for output.");
        DispNL;
     ELSE
        ExtractFileName(FileToSquirt,displayname);
        DispString(displayname);
        NameLen := Length(displayname);
        IF NameLen < 12 THEN
                DispRepeat(12-NameLen," ")
        END;
        DispString(" -> ");
        UpperCase(OutputDevice);
        DispString(OutputDevice);
        DispString(": ");
        InitBar(33,FileLen);
        DisplayBar;

        Read(InputFileNumber,IOBuffer,arraysize,ReadWriteCount);
        IF ReadWriteCount = 0 THEN
            DisplayFullBar;
        ELSE
                LOOP
                    UpdateBar(ReadWriteCount);
                    IF ReadWriteCount=0 THEN
                       EXIT
                    END;
                    Write(OutputFileNumber,IOBuffer,ReadWriteCount,ReadWriteCount);
                    Read(InputFileNumber,IOBuffer,arraysize,ReadWriteCount);
                END;
        END;
        DispString(" ");
        DispLongCard(FileLen,longcardwidth);
        DispString(" bytes squirted.");
        DispNL;
        Close(InputFileNumber);
        Close(OutputFileNumber);
        DISPOSE(IOBuffer);
     END;

END CopyToDevice;

PROCEDURE BuildFileArray( file : DirEntry);
BEGIN
        Flag := TRUE;
        Assign(file.name,FileArray^[Filecnt]);
        INC(Filecnt)
END BuildFileArray;



BEGIN
     DispMode := BIOS;
     GetArg(InputFiles,ArgLength);
     IF ArgLength=0 THEN
           DispString('Name of .PRN file: ');
           InputLine(InputFiles);
           DispNL;
           IF InputFiles[0]=0C THEN
              Terminate(1);
           END;
     END;
     GetArg(OutputDevice,ArgLength);
     IF ArgLength = 0 THEN
        DispString('Output device: ');
        InputLine(OutputDevice);
        DispNL;
        IF OutputDevice[0] = 0C THEN
                Terminate(1)
        END;
     END;
     Flag := FALSE;
     Filecnt := 0;
     NEW(FileArray);
     DirQuery(InputFiles,NORMAL,BuildFileArray (* CopyToDevice *) );
     IF NOT Flag THEN
        DispString('File not found.');
        DispNL;
        Terminate(2)
     ELSE
        FOR x := 0 TO Filecnt-1 DO
                CopyToDevice(FileArray^[x])
        END;
        DISPOSE(FileArray)
     END;

     Terminate(0)
END Squirt.

