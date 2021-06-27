echo off
masm daccha;
link daccha;
exe2bin daccha.exe daccha.com
del daccha.obj
del daccha.exe
