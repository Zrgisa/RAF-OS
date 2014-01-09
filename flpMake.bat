D:
cd RAF_OS
cd vfd
vfd INSTALL
vfd START
vfd OPEN 1: D:\RAF_OS\raf_os.flp /W 
cd ..
pause
call make.bat
cd vfd
vfd SAVE 1:
vfd CLOSE 1:
vfd STOP
pause