@echo off
set SAW_VERSION=1.0.3839.3

pushd %~dp0

NuGet\nuget.exe restore -PackagesDirectory packages\

SET PS_COMMAND=%*

IF /I "%PS_COMMAND%" EQU "" (
    SET PS_COMMAND=help
)

packages\Microsoft.Ciqs.SAWCli.%SAW_VERSION%\lib\net452\saw.exe %PS_COMMAND% -SolutionsDirectory ..\Solutions

popd
