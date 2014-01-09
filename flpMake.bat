D:
cd RAF_OS
cd vfd
vfd INSTALL
vfd START
vfd LINK 1 B
vfd OPEN B: D:\RAF_OS\raf_os.flp /W 
cd ..
call make.bat
cd vfd
vfd SAVE B:
vfd CLOSE B:
vfd ULINK 1
vfd STOP