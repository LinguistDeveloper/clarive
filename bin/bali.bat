@echo off

IF NOT "%BASELINER_HOME%"=="" (
    cd /D %BASELINER_HOME%
)

IF NOT "%BASELINER_NLS_LANG%"=="" (
    set NLS_LANG=%BASELINER_NLS_LANG%
)

perl script\bali.pl %*
