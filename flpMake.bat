C:
cd Projekat
cd RAF-OS
cd vfd
vfd INSTALL
vfd START
vfd LINK 1 B
vfd OPEN B: C:\Projekat\RAF-OS\asd.flp /W 
cd ..
call make.bat
cd vfd
vfd SAVE B:
vfd CLOSE B:
vfd ULINK 1
vfd STOP
"C:\Program Files\DOSBox-0.74\DOSBox.exe" -userconf